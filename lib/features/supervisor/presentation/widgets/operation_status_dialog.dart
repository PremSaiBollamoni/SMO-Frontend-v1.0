import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import 'qr_assignment_widget.dart';
import 'tracking_widget.dart';
import 'merging_widget.dart';

/// Operation Status Dialog - Shows operation status with 3 action buttons
/// Similar to Strategic Monitor but focused on operation-level actions
/// Auto-updates status based on flow
class OperationStatusDialog extends StatefulWidget {
  final int routingId;
  final int operationId;
  final String operationName;
  final String operationDescription;

  const OperationStatusDialog({
    super.key,
    required this.routingId,
    required this.operationId,
    required this.operationName,
    required this.operationDescription,
  });

  @override
  State<OperationStatusDialog> createState() => _OperationStatusDialogState();
}

class _OperationStatusDialogState extends State<OperationStatusDialog> {
  Timer? _refreshTimer;
  Map<String, dynamic>? _operationStatus;
  bool _isLoading = true;
  String? _selectedAction; // Track which action is being performed

  @override
  void initState() {
    super.initState();
    _loadOperationStatus();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _loadOperationStatus();
    });
  }

  Future<void> _loadOperationStatus() async {
    try {
      final response = await ApiClient().dio.get(
        '/api/processplan/operation-status',
        queryParameters: {
          'routingId': widget.routingId,
          'operationId': widget.operationId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        if (mounted) {
          setState(() {
            _operationStatus = response.data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('[OperationStatus] Error loading operation status: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showActionWidget(String action) {
    showDialog(
      context: context,
      builder: (ctx) {
        Widget actionWidget;
        String title;

        switch (action) {
          case 'QR_ASSIGN':
            actionWidget = QrAssignmentWidget(
              operationId: widget.operationId,
              operationName: widget.operationName,
              routingId: widget.routingId,
            );
            title = 'QR Assignment';
            break;
          case 'TRACKING':
            actionWidget = TrackingWidget(
              operationId: widget.operationId,
              operationName: widget.operationName,
            );
            title = 'Tracking';
            break;
          case 'MERGING':
            actionWidget = MergingWidget(
              operationId: widget.operationId,
              operationName: widget.operationName,
            );
            title = 'Merging';
            break;
          default:
            return const SizedBox.shrink();
        }

        return Dialog(
          backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.settings_outlined,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            widget.operationName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(ctx);
                        // Refresh status after action completes
                        Future.delayed(const Duration(milliseconds: 800), () {
                          _loadOperationStatus();
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: actionWidget),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operation #${widget.operationId}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.operationName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _operationStatus == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Unable to load operation status',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadOperationStatus,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // KPI Summary
                            _buildKPISummary(dark),
                            const SizedBox(height: 24),

                            // Progress Strip
                            _buildProgressStrip(dark),
                            const SizedBox(height: 24),

                            // Status Details
                            _buildStatusDetails(dark),
                            const SizedBox(height: 24),

                            // Action Buttons
                            _buildActionButtons(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPISummary(bool dark) {
    final status = _operationStatus!['status'] ?? 'PENDING';
    final activeBins = _operationStatus!['active_bins'] ?? 0;
    final wipQuantity = _operationStatus!['wip_quantity'] ?? 0;
    final completedQuantity = _operationStatus!['completed_quantity'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildKPICard('Status', status, dark),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKPICard('Active Bins', activeBins.toString(), dark),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKPICard('Completed', completedQuantity.toString(), dark),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(String label, String value, bool dark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStrip(bool dark) {
    final status = _operationStatus!['status'] ?? 'PENDING';
    final activeBins = _operationStatus!['active_bins'] ?? 0;
    final activeOperators = _operationStatus!['active_operators'] ?? 0;
    final lastAction = _operationStatus!['last_action'] ?? 'None';
    final lastActionTime = _formatTimestamp(_operationStatus!['last_action_time']);

    // Calculate progress percentage
    double progressPercent = 0.0;
    Color progressColor = Colors.grey;

    if (status == 'PENDING') {
      progressPercent = 0.0;
      progressColor = Colors.red;
    } else if (status == 'IN_PROGRESS') {
      progressPercent = 50.0;
      progressColor = Colors.orange;
    } else if (status == 'COMPLETED') {
      progressPercent = 100.0;
      progressColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppTheme.darkSurface : Colors.grey.shade50,
        border: Border.all(
          color: dark ? Colors.white12 : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Operation Progress',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: progressColor,
                ),
              ),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$activeOperators operators',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPercent / 100,
              minHeight: 8,
              backgroundColor: dark ? Colors.white12 : Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last Action: $lastAction',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                lastActionTime,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDetails(bool dark) {
    final description = _operationStatus!['description'] ?? widget.operationDescription;
    final estimatedTime = _operationStatus!['estimated_time'] ?? 'N/A';
    final nextOperation = _operationStatus!['next_operation'] ?? 'N/A';
    final actualStart = _formatTimestamp(_operationStatus!['actual_start_time']);
    final actualEnd = _operationStatus!['actual_end_time'] == 'In progress...'
        ? 'In progress...'
        : _formatTimestamp(_operationStatus!['actual_end_time']);
    final actualDuration = _operationStatus!['actual_duration'] ?? 'N/A';

    final hasActualTiming = actualStart != 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppTheme.darkSurface : Colors.grey.shade50,
        border: Border.all(
          color: dark ? Colors.white12 : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operation Details',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Description', description),
          const SizedBox(height: 8),
          _buildDetailRow('Est. Time', estimatedTime),
          const SizedBox(height: 8),
          _buildDetailRow('Next Operation', nextOperation),
          if (hasActualTiming) ...[
            const SizedBox(height: 12),
            Divider(color: dark ? Colors.white12 : Colors.grey.shade300, height: 1),
            const SizedBox(height: 12),
            Text(
              'Actual Timing',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.teal.shade700,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Start Time', actualStart),
            const SizedBox(height: 8),
            _buildDetailRow('End Time', actualEnd),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Duration',
              actualDuration,
              valueColor: actualDuration.contains('ongoing')
                  ? Colors.orange
                  : Colors.teal.shade700,
            ),
          ],
        ],
      ),
    );
  }

  /// Format an ISO timestamp string like "2026-05-25T14:51:20.970323"
  /// into a readable "25 May 2026, 02:51 PM"
  String _formatTimestamp(dynamic raw) {
    if (raw == null || raw.toString() == 'N/A' || raw.toString().isEmpty) {
      return 'N/A';
    }
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year, ${hour.toString().padLeft(2, '0')}:$minute $ampm';
    } catch (_) {
      return raw.toString();
    }
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final status = _operationStatus!['status'] ?? 'PENDING';
    final canQrAssign = status == 'PENDING' || status == 'IN_PROGRESS';
    final canTrack = status == 'IN_PROGRESS';
    final canMerge = status == 'IN_PROGRESS';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Actions',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.qr_code_2_outlined,
                label: 'QR Assign',
                enabled: canQrAssign,
                onPressed: () => _showActionWidget('QR_ASSIGN'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                icon: Icons.track_changes_outlined,
                label: 'Tracking',
                enabled: canTrack,
                onPressed: () => _showActionWidget('TRACKING'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                icon: Icons.merge_type_outlined,
                label: 'Merging',
                enabled: canMerge,
                onPressed: () => _showActionWidget('MERGING'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: enabled ? AppTheme.primary : Colors.grey.shade300,
        foregroundColor: enabled ? Colors.white : Colors.grey.shade600,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,
      ),
    );
  }
}
