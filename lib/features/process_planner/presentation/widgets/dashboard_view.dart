import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:excel/excel.dart' as excel_pkg hide Border;
import '../../../../core/theme/app_theme.dart';
import '../controller/process_planner_controller.dart';
import 'workflow_graph/workflow_node.dart';
import 'workflow_graph/horizontal_workflow_graph.dart';

/// Dashboard View - Excel upload, parsing, and graph visualization
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final ProcessPlannerController _controller =
      Get.find<ProcessPlannerController>();

  PlatformFile? _selectedFile;
  List<String> _tableHeaders = [];
  List<List<dynamic>> _tableRows = [];
  bool _isReadingFile = false;
  bool _isSubmitting = false;

  // Terminal sentinel values (case-insensitive)
  // These are valid terminators, not unknown targets
  static const Set<String> _terminalSentinels = {
    'END',
    'STOP',
    'FINISH',
    'COMPLETE',
    'TERMINAL',
    'N/A',
    '-',
  };

  bool _isTerminalSentinel(String value) {
    return _terminalSentinels.contains(value.toUpperCase());
  }

  /// Detects spreadsheet type based on headers
  /// Returns: 'dag' for DAG mode, 'sequential' for sequential mode
  String _detectSpreadsheetType() {
    if (_tableHeaders.isEmpty) return 'sequential'; // Default to sequential

    final headerLower = _tableHeaders.map((h) => h.toLowerCase()).toList();

    // Check for DAG mode indicators
    bool hasCurrentWS = headerLower.any((h) => h.contains('current'));
    bool hasNextWS = headerLower.any((h) => h.contains('next'));

    if (hasCurrentWS && hasNextWS) {
      return 'dag';
    }

    // Check for sequential mode indicators
    bool hasSNo = headerLower.any((h) => 
        h.contains('s.no') || h.contains('s no') || h.contains('sequence') || h.contains('order'));
    bool hasProcessName = headerLower.any((h) => 
        h.contains('process') || h.contains('operation') || h.contains('step') || h.contains('activity'));

    if (hasSNo && hasProcessName && !hasNextWS) {
      return 'sequential';
    }

    return 'sequential'; // Default to sequential
  }

  /// Builds linear DAG from sequential spreadsheet (S.No / Process Name / Machine Type / SMV...)
  /// Connects row i to row i+1 by S.No order
  List<WorkflowNode> _buildSequentialDAG() {
    final colIndices = _detectColumnIndices();
    final currentWSCol = colIndices['currentWSCol']!;

    final List<WorkflowNode> nodes = [];
    final Map<String, int> wsCodeToNodeIndex = {};

    // Create nodes from Process Name column in S.No order
    for (int i = 0; i < _tableRows.length; i++) {
      final row = _tableRows[i];

      final processName = currentWSCol < row.length
          ? row[currentWSCol]?.toString().trim() ?? ''
          : '';

      if (processName.isEmpty) continue;

      // Skip duplicates
      if (wsCodeToNodeIndex.containsKey(processName)) {
        continue;
      }

      // Detect merge from keywords
      bool isMerge = processName.toLowerCase().contains('merge') ||
          processName.toLowerCase().contains('final') ||
          processName.toLowerCase().contains('goods');

      final node = WorkflowNode(
        id: processName,
        displayName: processName,
        description: processName,
        isMerge: isMerge,
        connections: [],
        sequenceIndex: i,
      );

      wsCodeToNodeIndex[processName] = nodes.length;
      nodes.add(node);
    }

    // Connect nodes sequentially: row i → row i+1
    for (int i = 0; i < nodes.length - 1; i++) {
      nodes[i].connections.add(i + 1);
    }

    return nodes;
  }

  Future<void> _browseFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
          _tableHeaders = [];
          _tableRows = [];
        });
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<void> _readFile() async {
    if (_selectedFile == null) {
      _showError('Please select a file first');
      return;
    }
    setState(() => _isReadingFile = true);
    try {
      var bytes = _selectedFile!.bytes;
      if (bytes == null && _selectedFile!.path != null) {
        bytes = await File(_selectedFile!.path!).readAsBytes();
      }
      if (bytes == null) {
        _showError('Could not read file content');
        return;
      }
      try {
        final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: false);
        if (decoder.tables.keys.isEmpty) {
          _showError('No sheets found in the Excel file');
          return;
        }
        final sheetName = decoder.tables.keys.first;
        final sheet = decoder.tables[sheetName];
        final rows = sheet?.rows ?? [];
        if (rows.isEmpty) {
          _showError('No data found in the Excel file');
          setState(() {
            _tableHeaders = [];
            _tableRows = [];
          });
          return;
        }
        setState(() {
          _tableHeaders = rows[0].map((e) => e?.toString() ?? '').toList();
          final headerCount = _tableHeaders.length;
          _tableRows = rows.skip(1).map((row) {
            final list = List<dynamic>.from(row);
            while (list.length < headerCount) list.add('');
            return list.take(headerCount).toList();
          }).toList();
        });
      } catch (e) {
        // Fallback to Excel package
        final excel = excel_pkg.Excel.decodeBytes(bytes);
        if (excel.tables.keys.isEmpty) {
          _showError('No sheets found in the Excel file');
          return;
        }
        final firstSheet = excel.tables.keys.first;
        final table = excel.tables[firstSheet];
        final rows = table?.rows ?? [];
        if (rows.isEmpty) {
          _showError('No data found in the Excel file');
          setState(() {
            _tableHeaders = [];
            _tableRows = [];
          });
          return;
        }
        setState(() {
          _tableHeaders = rows.first
              .map((e) => e?.value?.toString() ?? '')
              .toList();
          final headerCount = _tableHeaders.length;
          _tableRows = rows.skip(1).map((row) {
            final list = row
                .map((cell) => cell?.value?.toString() ?? '')
                .toList();
            while (list.length < headerCount) list.add('');
            return list.take(headerCount).toList();
          }).toList();
        });
      }
      _showSuccess('File read successfully');
    } catch (e) {
      _showError('Unable to read this Excel file');
    } finally {
      setState(() => _isReadingFile = false);
    }
  }

  /// Detects column indices based on header names
  /// Returns: {currentWSColIndex, nextWSColIndex, mergeTargetColIndex}
  /// Treats Current WS as canonical identity for nodes
  Map<String, int> _detectColumnIndices() {
    Map<String, int> indices = {
      'currentWSCol': 1,  // Default: Current WS (Process Name) in column 1
      'nextWSCol': 2,     // Default: Next WS in column 2
      'mergeTargetCol': 3, // Default: Merge Target in column 3
    };

    if (_tableHeaders.isEmpty) return indices;

    // Detect each column by header keywords
    for (int i = 0; i < _tableHeaders.length; i++) {
      final header = _tableHeaders[i].toLowerCase();

      // Detect Current WS column (canonical node identity)
      // Keywords: current, process, operation, step, activity, task, ws, work station
      if (header.contains('current') ||
          header.contains('process') ||
          header.contains('operation') ||
          header.contains('step') ||
          header.contains('activity') ||
          header.contains('task') ||
          (header.contains('ws') && !header.contains('next')) ||
          header.contains('work station')) {
        indices['currentWSCol'] = i;
      }

      // Detect Next WS column (target references)
      if (header.contains('next') ||
          header.contains('next ws') ||
          header.contains('next step') ||
          header.contains('next operation')) {
        indices['nextWSCol'] = i;
      }

      // Detect Merge Target column (metadata only, not edges)
      if (header.contains('merge') ||
          header.contains('merge target') ||
          header.contains('merge point')) {
        indices['mergeTargetCol'] = i;
      }
    }

    return indices;
  }

  /// Validates spreadsheet for DAG correctness
  /// Returns error message if validation fails, null if valid
  /// Skips DAG validation for sequential mode
  String? _validateSpreadsheet() {
    final spreadsheetType = _detectSpreadsheetType();

    // Skip DAG validation for sequential mode
    if (spreadsheetType == 'sequential') {
      return null; // Sequential mode doesn't need DAG validation
    }

    final colIndices = _detectColumnIndices();
    final currentWSCol = colIndices['currentWSCol']!;
    final nextWSCol = colIndices['nextWSCol']!;

    // Extract all Current WS codes
    final Set<String> currentWSSet = {};
    final List<String> currentWSList = [];
    
    for (final row in _tableRows) {
      final currentWS = currentWSCol < row.length
          ? row[currentWSCol]?.toString().trim() ?? ''
          : '';
      
      if (currentWS.isEmpty) continue;
      
      // Check for duplicates
      if (currentWSSet.contains(currentWS)) {
        return 'Duplicate Current WS found: "$currentWS". Each operation must be unique.';
      }
      
      currentWSSet.add(currentWS);
      currentWSList.add(currentWS);
    }

    if (currentWSSet.isEmpty) {
      return 'No valid operations found in spreadsheet.';
    }

    // Validate all Next WS targets exist
    for (int i = 0; i < _tableRows.length; i++) {
      final row = _tableRows[i];
      final currentWS = currentWSCol < row.length
          ? row[currentWSCol]?.toString().trim() ?? ''
          : '';
      
      if (currentWS.isEmpty) continue;

      final nextWSRaw = nextWSCol < row.length
          ? row[nextWSCol]?.toString().trim() ?? ''
          : '';

      if (nextWSRaw.isNotEmpty) {
        final targets = nextWSRaw.split(',').map((t) => t.trim()).toList();
        for (final target in targets) {
          if (target.isNotEmpty && 
              !currentWSSet.contains(target) && 
              !_isTerminalSentinel(target)) {
            return 'Unknown Next WS target: "$target" (referenced by "$currentWS"). Target does not exist in Current WS column.';
          }
        }
      }
    }

    // Build adjacency list for cycle detection
    final Map<String, List<String>> adjacencyList = {};
    for (final ws in currentWSSet) {
      adjacencyList[ws] = [];
    }

    for (final row in _tableRows) {
      final currentWS = currentWSCol < row.length
          ? row[currentWSCol]?.toString().trim() ?? ''
          : '';
      
      if (currentWS.isEmpty) continue;

      final nextWSRaw = nextWSCol < row.length
          ? row[nextWSCol]?.toString().trim() ?? ''
          : '';

      if (nextWSRaw.isNotEmpty) {
        final targets = nextWSRaw.split(',').map((t) => t.trim()).toList();
        for (final target in targets) {
          if (target.isNotEmpty) {
            adjacencyList[currentWS]!.add(target);
          }
        }
      }
    }

    // Cycle detection using DFS
    final String? cycleError = _detectCycle(adjacencyList);
    if (cycleError != null) {
      return cycleError;
    }

    // Note: Disconnected components are allowed — parallel branches in a
    // process plan naturally produce multiple graph components. The DAG
    // builder handles them correctly, so we do not block visualization here.

    return null; // Valid
  }

  /// Detects cycles in DAG using DFS
  /// Returns error message if cycle found, null otherwise
  String? _detectCycle(Map<String, List<String>> adjacencyList) {
    final Set<String> visited = {};
    final Set<String> recursionStack = {};

    String? dfs(String node, List<String> path) {
      visited.add(node);
      recursionStack.add(node);
      path.add(node);

      for (final neighbor in adjacencyList[node] ?? []) {
        if (!visited.contains(neighbor)) {
          final result = dfs(neighbor, List.from(path));
          if (result != null) return result;
        } else if (recursionStack.contains(neighbor)) {
          // Cycle detected
          final cycleStart = path.indexOf(neighbor);
          final cycle = path.sublist(cycleStart) + [neighbor];
          return 'Cyclic dependency detected: ${cycle.join(' → ')}';
        }
      }

      recursionStack.remove(node);
      return null;
    }

    for (final node in adjacencyList.keys) {
      if (!visited.contains(node)) {
        final result = dfs(node, []);
        if (result != null) return result;
      }
    }

    return null;
  }

  /// Detects disconnected components in graph
  /// Returns warning if multiple components found, null otherwise
  String? _detectDisconnectedComponents(
      Map<String, List<String>> adjacencyList, Set<String> allNodes) {
    final Set<String> visited = {};

    void bfs(String start) {
      final queue = [start];
      visited.add(start);

      while (queue.isNotEmpty) {
        final node = queue.removeAt(0);
        for (final neighbor in adjacencyList[node] ?? []) {
          if (!visited.contains(neighbor)) {
            visited.add(neighbor);
            queue.add(neighbor);
          }
        }
      }
    }

    int componentCount = 0;
    for (final node in allNodes) {
      if (!visited.contains(node)) {
        bfs(node);
        componentCount++;
      }
    }

    if (componentCount > 1) {
      return 'Warning: Graph has $componentCount disconnected components. This may indicate missing dependencies.';
    }

    return null;
  }

  /// Generic DAG parser for routing spreadsheets
  /// Invariants:
  /// - Each Current WS row = exactly one unique node
  /// - Current WS code is canonical identity
  /// - No duplicate nodes
  /// - Next WS references resolve to existing Current WS nodes
  /// - Merge Target is metadata only
  List<WorkflowNode> _buildGenericDAG() {
    final colIndices = _detectColumnIndices();
    final currentWSCol = colIndices['currentWSCol']!;
    final nextWSCol = colIndices['nextWSCol']!;
    final mergeTargetCol = colIndices['mergeTargetCol']!;

    final List<WorkflowNode> nodes = [];
    final Map<String, int> wsCodeToNodeIndex = {}; // Current WS code → node index

    // PHASE 1: Create nodes from Current WS column (canonical identity)
    // Invariant: One Current WS code = exactly one node
    for (int i = 0; i < _tableRows.length; i++) {
      final row = _tableRows[i];

      // Extract Current WS code (canonical node identity)
      final currentWS = currentWSCol < row.length
          ? row[currentWSCol]?.toString().trim() ?? ''
          : '';

      if (currentWS.isEmpty) continue;

      // Check for duplicate nodes (invariant violation)
      if (wsCodeToNodeIndex.containsKey(currentWS)) {
        // Skip duplicate - already have this node
        continue;
      }

      // Detect if this is a merge node (metadata from Merge Target column)
      bool isMerge = false;
      if (mergeTargetCol < row.length) {
        final mergeTarget = row[mergeTargetCol]?.toString().toLowerCase() ?? '';
        isMerge = mergeTarget.isNotEmpty && 
                  (mergeTarget.contains('merge') || mergeTarget.contains('yes'));
      }

      // Also detect merge from node name keywords
      isMerge = isMerge ||
          currentWS.toLowerCase().contains('merge') ||
          currentWS.toLowerCase().contains('final') ||
          currentWS.toLowerCase().contains('goods');

      // Create node with Current WS as canonical identity
      final node = WorkflowNode(
        id: currentWS, // Use Current WS code as unique ID
        displayName: currentWS,
        description: currentWS,
        isMerge: isMerge,
        connections: [],
        sequenceIndex: i,
      );

      wsCodeToNodeIndex[currentWS] = nodes.length;
      nodes.add(node);
    }

    // PHASE 2: Build edges from Next WS column
    // Invariant: Next WS references must resolve to existing Current WS nodes
    for (int i = 0; i < _tableRows.length; i++) {
      final row = _tableRows[i];

      // Get current node
      final currentWS = currentWSCol < row.length
          ? row[currentWSCol]?.toString().trim() ?? ''
          : '';

      if (currentWS.isEmpty || !wsCodeToNodeIndex.containsKey(currentWS)) {
        continue;
      }

      final currentNodeIndex = wsCodeToNodeIndex[currentWS]!;
      bool hasExplicitEdges = false;

      // Parse Next WS column for target references
      final nextWSRaw = nextWSCol < row.length
          ? row[nextWSCol]?.toString().trim() ?? ''
          : '';

      if (nextWSRaw.isNotEmpty) {
        // Split by comma for multiple targets
        final targets = nextWSRaw.split(',').map((t) => t.trim()).toList();

        for (final target in targets) {
          if (target.isEmpty) continue;

          // Resolve target to existing node (invariant: must exist)
          if (wsCodeToNodeIndex.containsKey(target)) {
            final targetNodeIndex = wsCodeToNodeIndex[target]!;
            // Avoid duplicate edges
            if (!nodes[currentNodeIndex].connections.contains(targetNodeIndex)) {
              nodes[currentNodeIndex].connections.add(targetNodeIndex);
              hasExplicitEdges = true;
            }
          }
          // If target doesn't exist, skip it (don't create synthetic nodes)
        }
      }

      // Fallback: sequential connection if no explicit Next WS
      if (!hasExplicitEdges && i < _tableRows.length - 1) {
        // Find next non-empty Current WS
        for (int j = i + 1; j < _tableRows.length; j++) {
          final nextRow = _tableRows[j];
          final nextWS = currentWSCol < nextRow.length
              ? nextRow[currentWSCol]?.toString().trim() ?? ''
              : '';

          if (nextWS.isNotEmpty && wsCodeToNodeIndex.containsKey(nextWS)) {
            final nextNodeIndex = wsCodeToNodeIndex[nextWS]!;
            if (!nodes[currentNodeIndex].connections.contains(nextNodeIndex)) {
              nodes[currentNodeIndex].connections.add(nextNodeIndex);
            }
            break;
          }
        }
      }
    }

    // PHASE 3: Ensure all non-terminal nodes have at least one outgoing edge
    for (int i = 0; i < nodes.length - 1; i++) {
      if (nodes[i].connections.isEmpty) {
        // Connect to next node in sequence
        nodes[i].connections.add(i + 1);
      }
    }

    return nodes;
  }

  void _visualizeWorkflow() {
    if (_tableRows.isEmpty) {
      _showError('No data to visualize. Please read a file first.');
      return;
    }

    // Detect spreadsheet type
    final spreadsheetType = _detectSpreadsheetType();

    // Validate spreadsheet (skips validation for sequential mode)
    final validationError = _validateSpreadsheet();
    if (validationError != null) {
      _showError(validationError);
      return;
    }

    // Build graph based on spreadsheet type
    final List<WorkflowNode> nodes;
    if (spreadsheetType == 'dag') {
      nodes = _buildGenericDAG();
    } else {
      nodes = _buildSequentialDAG();
    }

    if (nodes.isEmpty) {
      _showError('No valid workflow nodes found in spreadsheet.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Process Flow Graph',
                      style: TextStyle(
                        color: AppTheme.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.onPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ClipRect(child: HorizontalWorkflowGraph(nodes: nodes)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForReview() async {
    if (_tableRows.isEmpty) {
      _showError('No data to submit.');
      return;
    }

    // Validate spreadsheet before submission
    final validationError = _validateSpreadsheet();
    if (validationError != null) {
      _showError(validationError);
      return;
    }

    await _controller.fetchProducts();
    if (_controller.products.isEmpty) {
      _showError('Please create a product first.');
      return;
    }

    final productId = _controller.products.first.productId;

    setState(() => _isSubmitting = true);
    try {
      // Detect column indices based on headers
      final colIndices = _detectColumnIndices();
      final currentWSCol = colIndices['currentWSCol']!;
      final nextWSCol = colIndices['nextWSCol']!;

      // Find dedicated parallel/merge columns by header only (not by scanning
      // all cell values — that causes false positives from notes/description cols)
      int? parallelCol;
      int? mergeCol;
      for (int i = 0; i < _tableHeaders.length; i++) {
        final h = _tableHeaders[i].toLowerCase();
        if (h.contains('parallel')) parallelCol = i;
        if (h.contains('merge target') || h == 'merge') mergeCol = i;
      }

      // Build a name→sequence map for edge resolution
      final Map<String, int> nameToSequence = {};
      int seq = 1;
      for (final row in _tableRows) {
        if (row.isEmpty) continue;
        final name = currentWSCol < row.length
            ? row[currentWSCol]?.toString().trim() ?? ''
            : '';
        if (name.isNotEmpty && !nameToSequence.containsKey(name)) {
          nameToSequence[name] = seq++;
        }
      }

      final List<Map<String, dynamic>> steps = [];
      // edges: list of {from_name, to_name, edge_type}
      final List<Map<String, dynamic>> edges = [];
      // Track operation names to avoid duplicates
      final Set<String> addedOperationNames = {};

      int stepSeq = 1;
      for (int i = 0; i < _tableRows.length; i++) {
        final row = _tableRows[i];
        if (row.isEmpty) continue;

        // Extract data using detected column indices
        final String name = currentWSCol < row.length
            ? row[currentWSCol]?.toString().trim() ?? ''
            : '';

        if (name.isEmpty) continue;

        // Skip if this operation name has already been added
        if (addedOperationNames.contains(name)) {
          continue;
        }

        const int standardTime = 5;

        // Description: use Op Description column (currentWSCol + 1) if present
        String description = '';
        if (currentWSCol + 1 < row.length) {
          description = row[currentWSCol + 1]?.toString().trim() ?? '';
        }

        // Parallel/merge: only check dedicated columns, never free-text columns
        bool isParallel = false;
        bool isMerge = false;

        if (parallelCol != null && parallelCol < row.length) {
          final v = row[parallelCol]?.toString().toUpperCase() ?? '';
          if (v.isNotEmpty && v != 'NO' && v != 'FALSE' && v != '0') {
            isParallel = true;
          }
        }
        if (mergeCol != null && mergeCol < row.length) {
          final v = row[mergeCol]?.toString().toUpperCase() ?? '';
          if (v.isNotEmpty && v != 'NO' && v != 'FALSE' && v != '0') {
            isMerge = true;
          }
        }

        final int stageGroup = isMerge ? 2 : 1;
        String operationType = 'SEQUENTIAL';
        if (isParallel) {
          operationType = 'PARALLEL_BRANCH';
        } else if (isMerge) {
          operationType = 'MERGE';
        }

        steps.add({
          'name': name,
          'description': description.isNotEmpty ? description : 'No description',
          'sequence': stepSeq++,
          'operation_type': operationType,
          'stage_group': stageGroup,
          'standard_time': standardTime,
        });
        addedOperationNames.add(name);

        // Build edges from Next WS column
        final String nextWSRaw = nextWSCol < row.length
            ? row[nextWSCol]?.toString().trim() ?? ''
            : '';

        if (nextWSRaw.isNotEmpty) {
          final targets = nextWSRaw.split(',').map((t) => t.trim()).toList();
          for (final target in targets) {
            if (target.isNotEmpty && nameToSequence.containsKey(target)) {
              edges.add({
                'from_name': name,
                'to_name': target,
                'edge_type': isParallel ? 'PARALLEL' : 'SEQUENTIAL',
              });
            }
          }
        }
      }

      if (steps.isEmpty) {
        _showError('No valid steps found in Excel. Please check your data.');
        return;
      }

      final result = await _controller.submitProcessPlanDraft(
        productId: productId,
        steps: steps,
        edges: edges,
      );

      if (result != null) {
        _showSuccess(
          'Process submitted for review successfully (Routing #${result['routing_id']})',
        );
        setState(() {
          _tableRows.clear();
          _tableHeaders.clear();
          _selectedFile = null;
        });
        await _controller.fetchRoutings();
      } else {
        _showError('Submission failed');
      }
    } catch (e) {
      _showError('Submission failed: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    CustomSnackbar.showError(context, message);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    CustomSnackbar.showSuccess(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration:
                AppTheme.cardDecoration
                    .copyWith(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  color: AppTheme.primary,
                  child: const Text(
                    'Create a New Process Plan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onPrimary,
                      inherit: true,
                    ),
                  ),
                ),
                Container(
                  color: AppTheme.surface,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // File selection row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                OutlinedButton(
                                  onPressed: _browseFile,
                                  style: AppTheme.outlinedButtonStyle.copyWith(
                                    padding: WidgetStateProperty.all(
                                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                  child: const Text('Browse File'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedFile?.name ?? 'no file selected',
                                    style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _isReadingFile ? null : _readFile,
                            child: _isReadingFile
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Read'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Data table
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: _tableHeaders.isEmpty
                              ? 150
                              : MediaQuery.of(context).size.height * 0.5,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.surfaceVariant,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _tableHeaders.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Center(
                                  child: Text(
                                    'No data loaded. Please upload and read an Excel file.',
                                    textAlign: TextAlign.center,
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              )
                            : Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: AppTheme.surfaceVariant,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(
                                        AppTheme.surfaceVariant,
                                      ),
                                      headingTextStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppTheme.onSurface,
                                        inherit: true,
                                      ),
                                      dataTextStyle: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.onSurface,
                                        inherit: true,
                                      ),
                                      dataRowMinHeight: 48,
                                      dataRowMaxHeight: 100,
                                      columnSpacing: 24,
                                      horizontalMargin: 16,
                                      columns: _tableHeaders
                                          .map(
                                            (h) => DataColumn(
                                              label: SizedBox(
                                                width: 140,
                                                child: Text(
                                                  h,
                                                  style: AppTheme.bodySmall.copyWith(
                                                    color: AppTheme.onSurface,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  softWrap: true,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      rows: _tableRows.map((row) {
                                        return DataRow(
                                          cells: row
                                              .map(
                                                (cell) => DataCell(
                                                  Container(
                                                    width: 140,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 4,
                                                        ),
                                                    child: Text(
                                                      cell?.toString() ?? '',
                                                      softWrap: true,
                                                      overflow:
                                                          TextOverflow.visible,
                                                      style: AppTheme.bodySmall,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),
                      // Action buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: _visualizeWorkflow,
                            style: AppTheme.primaryButtonStyle,
                            child: const Text('Visualize'),
                          ),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForReview,
                            style: AppTheme.tertiaryButtonStyle,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.onPrimary,
                                    ),
                                  )
                                : const Text('Submit for Review'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedFile = null;
                                _tableHeaders = [];
                                _tableRows = [];
                              });
                            },
                            style: AppTheme.outlinedButtonStyle,
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
