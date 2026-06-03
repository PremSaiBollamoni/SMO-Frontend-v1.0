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
    // Fetch fresh data from backend every 15 seconds only
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

                            // Bundle-wise Timing (SAM continuous tracking)
                            _buildBundleWiseTiming(dark),
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
    final completedQuantity = _operationStatus!['completed_quantity'] ?? 0;
    final trayQuantity = _operationStatus!['tray_quantity'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryVariant],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildKPICard('Status', status, dark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKPICard('Active Bins', activeBins.toString(), dark),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildKPICard('Tray Qty', trayQuantity.toString(), dark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKPICard('Completed', completedQuantity.toString(), dark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(String label, String value, bool dark) {
    // Format status text to be readable
    String displayValue = value;
    if (value == 'IN_PROGRESS') displayValue = 'In Progress';
    if (value == 'PENDING') displayValue = 'Pending';
    if (value == 'COMPLETED') displayValue = 'Completed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              displayValue,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStrip(bool dark) {
    // Empty - we moved bundle progress into bundle-wise timing section
    return const SizedBox.shrink();
  }

  Widget _buildStatusDetails(bool dark) {
    final description = _operationStatus!['description'] ?? widget.operationDescription;
    final estimatedTime = _operationStatus!['estimated_time'] ?? 'N/A';
    final nextOperation = _operationStatus!['next_operation'] ?? 'N/A';

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

  Widget _buildActionButtons() {
    final status = _operationStatus!['status'] ?? 'PENDING';
    final canQrAssign = status == 'PENDING' || status == 'IN_PROGRESS';
    // Allow tracking at all times (PENDING, IN_PROGRESS, COMPLETED) for SAM tracking model
    // Operators can scan multiple times at same operation for different batches
    final canTrack = status == 'PENDING' || status == 'IN_PROGRESS' || status == 'COMPLETED';
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
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        backgroundColor: enabled ? AppTheme.primary : AppTheme.surfaceVariant,
        foregroundColor: enabled ? Colors.white : AppTheme.onSurfaceVariant,
        disabledBackgroundColor: AppTheme.surfaceVariant,
        disabledForegroundColor: AppTheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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

  /// Bundle-wise timing for SAM continuous tracking model
  Widget _buildBundleWiseTiming(bool dark) {
    final bundles = _operationStatus!['bundles'] as List? ?? [];
    if (bundles.isEmpty) return const SizedBox.shrink();

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
            'Bundle-wise Timing (${bundles.length} bundles)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...bundles.asMap().entries.map((e) {
            final idx = e.key + 1;
            final bundle = e.value as Map<String, dynamic>;
            final startTime = bundle['start_time'] ?? 'N/A';
            final endTime = bundle['end_time'] ?? 'N/A';
            final qty = bundle['quantity'] ?? 0;
            final status = bundle['status'] ?? 'PENDING';

            // Color based on status
            Color statusColor = Colors.grey;
            if (status == 'PENDING') statusColor = Colors.orange;
            if (status == 'COMPLETED' || status == 'Completed') statusColor = Colors.green;

            // Calculate progress based on status
            double progress;
            if (status == 'COMPLETED' || status == 'Completed') {
              progress = 1.0;
            } else if (endTime == 'N/A' || endTime == 'In progress...') {
              progress = 0.5; // In progress
            } else {
              progress = 0.0; // Pending
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bundle $idx',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          status,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: statusColor.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Employee, machine, and tray info
                    if (bundle['operator_id'] != null) ...[
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Operator: ${bundle['operator_name'] ?? 'ID ${bundle['operator_id']}'}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (bundle['machine_qr'] != null) ...[
                      Row(
                        children: [
                          Icon(Icons.precision_manufacturing, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Machine: ${bundle['machine_qr']}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (bundle['tray_qr'] != null) ...[
                      Row(
                        children: [
                          Icon(Icons.inbox, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Tray: ${bundle['tray_qr']}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      'Qty: $qty pieces',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start Time: $startTime',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'End Time: $endTime',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    // Live duration widget - updates independently without rebuilding whole dialog
                    _LiveDurationWidget(
                      key: ValueKey('duration_${bundle['wip_id']}_$idx'),
                      startTime: startTime,
                      endTime: endTime,
                      completedDuration: bundle['duration'] ?? 'N/A',
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}


/// Separate widget that updates duration in real-time without rebuilding parent
class _LiveDurationWidget extends StatefulWidget {
  final String startTime;
  final String endTime;
  final String completedDuration;

  const _LiveDurationWidget({
    Key? key,
    required this.startTime,
    required this.endTime,
    required this.completedDuration,
  }) : super(key: key);

  @override
  State<_LiveDurationWidget> createState() => _LiveDurationWidgetState();
}

class _LiveDurationWidgetState extends State<_LiveDurationWidget> {
  Timer? _timer;
  String _duration = '';
  Color _color = Colors.grey;

  @override
  void initState() {
    super.initState();
    _updateDuration();
    
    // Only start timer if ongoing
    if (widget.endTime == 'N/A' || widget.endTime == 'In progress...') {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          _updateDuration();
        }
      });
    }
  }

  @override
  void didUpdateWidget(_LiveDurationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart timer if status changed from completed to ongoing
    if (oldWidget.endTime != widget.endTime) {
      _timer?.cancel();
      if (widget.endTime == 'N/A' || widget.endTime == 'In progress...') {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) {
            _updateDuration();
          }
        });
      }
      _updateDuration();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateDuration() {
    if (widget.endTime == 'N/A' || widget.endTime == 'In progress...') {
      // Ongoing - calculate live duration
      try {
        final start = DateTime.parse(widget.startTime.replaceAll(' ', 'T'));
        final now = DateTime.now();
        final elapsed = now.difference(start);
        
        final hours = elapsed.inHours;
        final minutes = elapsed.inMinutes.remainder(60);
        final seconds = elapsed.inSeconds.remainder(60);
        
        setState(() {
          if (hours > 0) {
            _duration = '${hours}h ${minutes}m ${seconds}s (ongoing)';
          } else if (minutes > 0) {
            _duration = '${minutes}m ${seconds}s (ongoing)';
          } else {
            _duration = '${seconds}s (ongoing)';
          }
          _color = Colors.orange;
        });
      } catch (e) {
        setState(() {
          _duration = 'Ongoing';
          _color = Colors.orange;
        });
      }
    } else {
      // Completed - use provided duration
      setState(() {
        _duration = widget.completedDuration;
        _color = Colors.teal.shade700;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Duration: $_duration',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _color,
      ),
    );
  }
}
