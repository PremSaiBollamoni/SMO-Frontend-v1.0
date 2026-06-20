import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/api/import_api_service.dart';
import '../../data/api/operation_api_service.dart';

class SamManagementScreen extends StatefulWidget {
  const SamManagementScreen({super.key});

  @override
  State<SamManagementScreen> createState() => _SamManagementScreenState();
}

class _SamManagementScreenState extends State<SamManagementScreen> {
  final _api = OperationApiService();
  final _importApi = ImportApiService();
  List<OperationModel> _ops = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String _selectedStage = 'ALL';

  List<String> get _stages {
    final all = _ops.map((o) => o.stage).toSet().toList()..sort();
    return ['ALL', ...all];
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ops = await _api.getOperations();
      if (mounted) setState(() { _ops = ops; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<OperationModel> get _filtered {
    final filtered = _ops.where((op) {
      final matchStage = _selectedStage == 'ALL' || op.stage == _selectedStage;
      final matchSearch = _search.isEmpty ||
          op.opName.toLowerCase().contains(_search.toLowerCase()) ||
          op.opCode.toLowerCase().contains(_search.toLowerCase());
      return matchStage && matchSearch;
    }).toList();
    filtered.sort((a, b) => a.sequenceNo.compareTo(b.sequenceNo));
    return filtered;
  }

  static const _gradeOptions = ['A+-grade', 'A-grade', 'B-grade', 'C-grade', 'Helper'];

  Future<void> _deleteOp(OperationModel op) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Operation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: RichText(text: TextSpan(style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5), children: [
          const TextSpan(text: 'Delete '),
          TextSpan(text: op.opName, style: const TextStyle(fontWeight: FontWeight.w700)),
          const TextSpan(text: '? This cannot be undone.'),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.deleteOperation(op.opId);
      _load();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _importExcel() async {
    // Step 1: Pick file
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(type: FileType.any, withData: false);
    } catch (e) {
      setState(() => _error = 'File picker error: $e');
      return;
    }
    if (picked == null) return;

    final file = picked.files.single;
    final filePath = file.path;
    if (filePath == null) {
      setState(() => _error = 'Cannot access file path');
      return;
    }

    // Step 2: Confirm before uploading
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.upload_file_rounded, color: AppTheme.primary),
          SizedBox(width: 10),
          Text('Import Excel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF5F5F7), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.table_chart_outlined, color: AppTheme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(file.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2)),
            ]),
          ),
          const SizedBox(height: 14),
          Text('The file will be sent to the server for processing. Operations will be matched by name — existing ones updated, new ones created. Stations will be created if not found.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.6)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.cloud_upload_rounded, size: 16),
            label: const Text('Upload & Import'),
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Step 3: Upload to backend (server parses with Apache POI)
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _importApi.uploadExcel(filePath);
      _load();
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32)),
              SizedBox(width: 10),
              Text('Import Complete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              _ResultRow(Icons.add_circle_outline_rounded, '${res.opsCreated}', 'Operations Created', AppTheme.primary),
              _ResultRow(Icons.edit_outlined, '${res.opsUpdated}', 'Operations Updated', AppTheme.secondary),
              _ResultRow(Icons.workspaces_outlined, '${res.stationsCreated}', 'Stations Created', AppTheme.tertiary),
              _ResultRow(Icons.link_rounded, '${res.stationsLinked}', 'Stations Linked', const Color(0xFF00897B)),
            ]),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _showOpDialog({OperationModel? op}) async {
    final isEdit = op != null;
    final codeCtrl = TextEditingController(text: op?.opCode ?? '');
    final nameCtrl = TextEditingController(text: op?.opName ?? '');
    final seqCtrl = TextEditingController(text: op?.sequenceNo.toString() ?? '');
    final stageCtrl = TextEditingController(text: op?.stage ?? '');
    final samCtrl = TextEditingController(text: op?.sam?.toStringAsFixed(3) ?? '');
    final targetCtrl = TextEditingController(text: op?.targetPcs?.toString() ?? '');
    String? selectedGrade = op?.skillGrade;
    final stageSuggestions = _ops.map((o) => o.stage).toSet().toList()..sort();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(isEdit ? Icons.edit_rounded : Icons.add_rounded, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isEdit ? 'Edit Operation' : 'New Operation',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  if (isEdit) Text(op!.opCode, style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                ])),
                IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(ctx, false)),
              ]),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (!isEdit) ...[
                      _inputField(codeCtrl, 'Operation Code', 'e.g. OP-35', TextInputType.text, Icons.tag_rounded),
                      const SizedBox(height: 12),
                    ],
                    _inputField(nameCtrl, 'Operation Name', 'e.g. Front Placket Attach', TextInputType.text, Icons.work_outline_rounded),
                    const SizedBox(height: 12),
                    _StageField(controller: stageCtrl, suggestions: stageSuggestions),
                    const SizedBox(height: 12),
                    _inputField(seqCtrl, 'Sequence No', '1–99', TextInputType.number, Icons.format_list_numbered_rounded),
                    const SizedBox(height: 12),
                    _inputField(samCtrl, 'SAM (min / piece)', '0.000', TextInputType.number, Icons.timer_outlined),
                    const SizedBox(height: 12),
                    _inputField(targetCtrl, 'Target Pcs / Shift', '480', TextInputType.number, Icons.track_changes_rounded),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _gradeOptions.contains(selectedGrade) ? selectedGrade : null,
                      decoration: InputDecoration(
                        labelText: 'Skill Grade',
                        prefixIcon: const Icon(Icons.star_outline_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: _gradeOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (v) => setSt(() => selectedGrade = v),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(isEdit ? 'Save Changes' : 'Create'),
                  ),
                ),
              ]),
            ]),
          ),
        );
      }),
    );

    if (saved != true) return;
    try {
      if (isEdit) {
        await _api.updateOperation(
          opId: op!.opId,
          opName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
          stage: stageCtrl.text.trim().isEmpty ? null : stageCtrl.text.trim().toUpperCase(),
          sequenceNo: int.tryParse(seqCtrl.text),
          sam: double.tryParse(samCtrl.text),
          skillGrade: selectedGrade,
          targetPcs: int.tryParse(targetCtrl.text),
        );
      } else {
        if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty || stageCtrl.text.trim().isEmpty) {
          setState(() => _error = 'Code, Name and Stage are required');
          return;
        }
        await _api.createOperation(
          opCode: codeCtrl.text.trim(),
          opName: nameCtrl.text.trim(),
          stage: stageCtrl.text.trim().toUpperCase(),
          sequenceNo: int.tryParse(seqCtrl.text) ?? 99,
          sam: double.tryParse(samCtrl.text),
          skillGrade: selectedGrade,
          targetPcs: int.tryParse(targetCtrl.text),
        );
      }
      _load();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  static Widget _inputField(TextEditingController ctrl, String label, String hint, TextInputType type, IconData icon) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<OperationModel>>{};
    for (final op in _filtered) {
      grouped.putIfAbsent(op.stage, () => []).add(op);
    }
    final stageKeys = grouped.keys.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Operations & SAM'),
        actions: [
          IconButton(
            tooltip: 'Import from Excel',
            icon: const Icon(Icons.upload_file_rounded),
            onPressed: _importExcel,
          ),
          IconButton(
            tooltip: 'Add Operation',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showOpDialog(),
          ),
        ],
      ),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by name or code...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: const Color(0xFFF5F5F7),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _stages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = _stages[i];
                final sel = s == _selectedStage;
                return GestureDetector(
                  onTap: () => setState(() => _selectedStage = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(s, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : Colors.black54)),
                  ),
                );
              },
            ),
          ),
        ),
        if (!_loading && _error == null)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(children: [
              _StatPill('${_filtered.length}', 'operations', Icons.build_circle_outlined, AppTheme.primary),
              const SizedBox(width: 8),
              _StatPill('${_filtered.where((o) => o.sam != null).length}', 'with SAM', Icons.check_circle_outline_rounded, AppTheme.success),
              const SizedBox(width: 8),
              if (_filtered.any((o) => o.sam == null))
                _StatPill('${_filtered.where((o) => o.sam == null).length}', 'no SAM', Icons.warning_amber_rounded, AppTheme.error),
            ]),
          ),
        if (_error != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!, style: TextStyle(color: AppTheme.error, fontSize: 12))),
              GestureDetector(onTap: () => setState(() => _error = null),
                  child: Icon(Icons.close_rounded, size: 16, color: AppTheme.error)),
            ]),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No operations found', style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Try a different search or add one', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: _selectedStage == 'ALL' ? stageKeys.length : 1,
                      itemBuilder: (_, si) {
                        final stageKey = _selectedStage == 'ALL' ? stageKeys[si] : _selectedStage;
                        final ops = grouped[stageKey] ?? [];
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 8),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
                                child: Text(stageKey, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(width: 8),
                              Text('${ops.length} operations', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ]),
                          ),
                          ...ops.map((op) => _OpCard(op: op, onEdit: () => _showOpDialog(op: op), onDelete: () => _deleteOp(op))),
                        ]);
                      },
                    ),
        ),
      ]),
    );
  }
}

class _StageField extends StatefulWidget {
  final TextEditingController controller;
  final List<String> suggestions;
  const _StageField({required this.controller, required this.suggestions});

  @override
  State<_StageField> createState() => _StageFieldState();
}

class _StageFieldState extends State<_StageField> {
  OverlayEntry? _overlay;
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() { if (!_focusNode.hasFocus) _close(); });
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _close();
    _focusNode.dispose();
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    _close();
    if (!_focusNode.hasFocus) return;
    final text = widget.controller.text.toUpperCase();
    final matches = widget.suggestions.where((s) => s.contains(text) && s != text).toList();
    if (matches.isEmpty) return;
    _overlay = OverlayEntry(builder: (_) => Positioned(
      width: 260,
      child: CompositedTransformFollower(
        link: _layerLink,
        offset: const Offset(0, 58),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(mainAxisSize: MainAxisSize.min,
              children: matches.map((s) => ListTile(
                dense: true,
                title: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                leading: Icon(Icons.layers_outlined, size: 16, color: AppTheme.primary),
                onTap: () {
                  widget.controller.value = TextEditingValue(
                    text: s,
                    selection: TextSelection.collapsed(offset: s.length),
                  );
                  _close();
                },
              )).toList(),
            ),
          ),
        ),
      ),
    ));
    Overlay.of(context).insert(_overlay!);
  }

  void _close() { _overlay?.remove(); _overlay = null; }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          labelText: 'Stage',
          hintText: 'Type new or pick existing',
          prefixIcon: const Icon(Icons.layers_outlined, size: 20),
          helperText: 'Existing stages shown as suggestions',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatPill(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        RichText(text: TextSpan(children: [
          TextSpan(text: '$value ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          TextSpan(text: label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ])),
      ]),
    );
  }
}

class _OpCard extends StatelessWidget {
  final OperationModel op;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _OpCard({required this.op, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final hasSam = op.sam != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hasSam ? const Color(0xFFEEEEEE) : AppTheme.error.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onEdit,
          onLongPress: onDelete,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text('${op.sequenceNo}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.primary))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(op.opName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  Text(op.opCode, style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  if (op.skillGrade != null) ...[
                    Text(' · ', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                    Text(op.skillGrade!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ]),
              ])),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasSam ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hasSam ? '${op.sam!.toStringAsFixed(3)} min' : 'No SAM',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                        color: hasSam ? AppTheme.success : AppTheme.error),
                  ),
                ),
                if (op.targetPcs != null) ...[
                  const SizedBox(height: 3),
                  Text('${op.targetPcs} pcs/shift', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                ],
              ]),
              const SizedBox(width: 4),
              Icon(Icons.edit_outlined, color: Colors.grey.shade300, size: 18),
            ]),
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HeaderCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool bold;
  const _DataCell(this.text, {required this.flex, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(text,
            style: TextStyle(fontSize: 11, fontWeight: bold ? FontWeight.w600 : FontWeight.normal, color: Colors.black87),
            maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final Color color;
  const _ResultRow(this.icon, this.count, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
      ]),
    );
  }
}
