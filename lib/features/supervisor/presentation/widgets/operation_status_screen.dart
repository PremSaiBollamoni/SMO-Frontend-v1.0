import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import 'qr_assignment_widget.dart';
import 'tracking_widget.dart';
import 'merging_widget.dart';

/// Operation Status Screen - Shows order/operation status with 3 action buttons
/// When user clicks a button, opens the corresponding widget
/// Status auto-updates based on flow
class OperationStatusScreen extends StatefulWidget {
  final int routingId;
  final int operationId;
  final String operationName;
  final String operationDescription;

  const OperationStatusScreen({
    super.key,
    required this.routingId,
    required this.operationId,
    required this.operationName,
    required this.operationDescription,
  });

  @override
  State<OperationStatusScreen> createState() => _OperationStatusScreenState();
}

class _OperationStatusScreenState extends State<OperationStatusScreen> {
  late Future<Map<String, dynamic>> _statusFuture;
  Map<String, dynamic>? _currentStatus;

  @override
  void initState() {
    super.initState();
    _statusFuture = _fetchOperationStatus();
  }

  Future<Map<String, dynamic>> _fetchOperationStatus() async {
    try {
      final response = await ApiClient().dio.get(
        '/api/processplan/operation-status/${widget.operationId}',
        queryParameters: {'routingId': widget.routingId},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        setState(() => _currentStatus = data);
        return data;
      }
      throw Exception('Failed to fetch status');
    } catch (e) {
      print('[OPERATION_STATUS] Error: $e');
      // Return default status if endpoint doesn't exist
      return {
        'operationId': widget.operationId,
        'operationName': widget.operationName,
        'status': 'PENDING',
        'orderNumber': 'N/A',
        'quantity': 0,
        'lastAction': 'None',
        'nextAction': 'QR Assignment',
      };
    }
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _statusFuture = _fetchOperationStatus();
    });
  }

  void _openActionWidget(String action) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
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
                  Icon(
                    _getActionIcon(action),
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Operation #${widget.operationId}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          action,
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
                      Future.delayed(const Duration(milliseconds: 500), _refreshStatus);
                    },
                  ),
                ],
              ),
            ),

            // Widget Content
            Expanded(
              child: _buildActionWidget(action),
            ),
          ],
        ),
      ),
    ).then((_) {
      // Refresh status when dialog closes
      _refreshStatus();
    });
  }

  Widget _buildActionWidget(String action) {
    switch (action) {
      case 'QR Assignment':
        return QrAssignmentWidget(
          operationId: widget.operationId,
          operationName: widget.operationName,
        );
      case 'Tracking':
        return TrackingWidget(
          operationId: widget.operationId,
          operationName: widget.operationName,
        );
      case 'Merging':
        return MergingWidget(
          operationId: widget.operationId,
          operationName: widget.operationName,
        );
      default:
        return const Center(child: Text('Unknown action'));
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'QR Assignment':
        return Icons.qr_code_2_outlined;
      case 'Tracking':
        return Icons.track_changes_outlined;
      case 'Merging':
        return Icons.merge_type_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
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
                const Icon(Icons.info_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Operation #${widget.operationId}',
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
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _statusFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.error, size: 48),
                        const SizedBox(height: 12),
                        Text('Error loading status',
                            style: AppTheme.bodyMedium),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refreshStatus,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final status = snapshot.data ?? {};
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Cards
                      _buildStatusCard(
                        'Current Status',
                        status['status'] ?? 'UNKNOWN',
                        _getStatusColor(status['status']),
                        Icons.info_outline,
                      ),
                      const SizedBox(height: 16),

                      // Order Information
                      if (status['orderNumber'] != null)
                        _buildInfoRow('Order Number', status['orderNumber']),
                      if (status['quantity'] != null)
                        _buildInfoRow('Quantity', status['quantity'].toString()),
                      if (status['lastAction'] != null)
                        _buildInfoRow('Last Action', status['lastAction']),
                      if (status['nextAction'] != null)
                        _buildInfoRow('Next Action', status['nextAction']),

                      const SizedBox(height: 32),

                      // Action Buttons
                      Text(
                        'Available Actions',
                        style: AppTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),

                      // QR Assignment Button
                      _buildActionButton(
                        'QR Assignment',
                        Icons.qr_code_2_outlined,
                        Colors.blue,
                        status['canQrAssign'] ?? true,
                        () => _openActionWidget('QR Assignment'),
                      ),
                      const SizedBox(height: 12),

                      // Tracking Button
                      _buildActionButton(
                        'Tracking',
                        Icons.track_changes_outlined,
                        Colors.green,
                        status['canTrack'] ?? true,
                        () => _openActionWidget('Tracking'),
                      ),
                      const SizedBox(height: 12),

                      // Merging Button
                      _buildActionButton(
                        'Merging',
                        Icons.merge_type_outlined,
                        Colors.orange,
                        status['canMerge'] ?? true,
                        () => _openActionWidget('Merging'),
                      ),

                      const SizedBox(height: 24),

                      // Refresh Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _refreshStatus,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Status'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    bool enabled,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'IN_PROGRESS':
      case 'ACTIVE':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
