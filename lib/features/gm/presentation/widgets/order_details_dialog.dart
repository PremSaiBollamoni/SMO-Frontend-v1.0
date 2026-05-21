import 'package:flutter/material.dart';
import '../../domain/models/order_model.dart';

/// Dialog showing detailed order information
class OrderDetailsDialog extends StatelessWidget {
  final OrderModel order;
  final String empId;

  const OrderDetailsDialog({
    super.key,
    required this.order,
    required this.empId,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
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
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Order Number', order.orderNumber),
                    const SizedBox(height: 16),
                    _buildDetailRow('Product ID', order.productId.toString()),
                    const SizedBox(height: 16),
                    if (order.productName != null && order.productName!.isNotEmpty)
                      ...[
                        _buildDetailRow('Product Name', order.productName!),
                        const SizedBox(height: 16),
                      ],
                    _buildDetailRow('Order Quantity', order.orderQty.toString()),
                    const SizedBox(height: 16),
                    _buildDetailRow('Status', _buildStatusBadge(order.status)),
                    const SizedBox(height: 16),
                    _buildDetailRow('Routing ID', order.routingId.toString()),
                    if (order.customerName != null && order.customerName!.isNotEmpty)
                      ...[
                        const SizedBox(height: 16),
                        _buildDetailRow('Customer Name', order.customerName!),
                      ],
                    if (order.productionStartDate != null && order.productionStartDate!.isNotEmpty)
                      ...[
                        const SizedBox(height: 16),
                        _buildDetailRow('Production Start Date', order.productionStartDate!),
                      ],
                    if (order.expectedCompletionDate != null && order.expectedCompletionDate!.isNotEmpty)
                      ...[
                        const SizedBox(height: 16),
                        _buildDetailRow('Expected Completion Date', order.expectedCompletionDate!),
                      ],
                    if (order.createdAt != null && order.createdAt!.isNotEmpty)
                      ...[
                        const SizedBox(height: 16),
                        _buildDetailRow('Created At', order.createdAt!),
                      ],
                    if (order.completed != null && order.completed! > 0)
                      ...[
                        const SizedBox(height: 16),
                        _buildDetailRow('Completed Units', order.completed!.toString()),
                      ],
                    if (order.pending != null && order.pending! > 0)
                      ...[
                        const SizedBox(height: 16),
                        _buildDetailRow('Pending Units', order.pending!.toString()),
                      ],
                    if (order.progressPercent != null && order.progressPercent! > 0)
                      ...[
                        const SizedBox(height: 16),
                        _buildDetailRow('Progress', '${order.progressPercent!.toStringAsFixed(1)}%'),
                      ],
                    const SizedBox(height: 24),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: value is Widget
              ? value
              : Text(
                  value?.toString() ?? 'N/A',
                  style: const TextStyle(fontSize: 14),
                ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color bgColor;
    Color textColor;

    switch (status?.toUpperCase()) {
      case 'ACTIVE':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[900]!;
        break;
      case 'DRAFT':
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[900]!;
        break;
      case 'COMPLETED':
        bgColor = Colors.grey[300]!;
        textColor = Colors.grey[900]!;
        break;
      case 'ON_HOLD':
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[900]!;
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status ?? 'UNKNOWN',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
