import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../controller/store_controller.dart';

/// Inventory View - Display inventory list
class InventoryView extends StatelessWidget {
  const InventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StoreController>();

    return Obx(() {
      return RefreshIndicator(
        onRefresh: controller.fetchInventory,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration,
              child: Row(
                children: [
                  Expanded(
                    child: Text('Inventory', style: AppTheme.headlineMedium),
                  ),
                  IconButton(
                    onPressed: controller.loadingInventory.value
                        ? null
                        : controller.fetchInventory,
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (controller.loadingInventory.value)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (controller.inventory.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: AppTheme.cardDecoration,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text('No inventory data', style: AppTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Pull to refresh',
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              ...controller.inventory.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock #${item.stockId ?? '-'}',
                          style: AppTheme.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Item ID: ${item.itemId ?? '-'}', style: AppTheme.bodyMedium),
                        Text('Qty: ${item.qty ?? '-'}', style: AppTheme.bodyMedium),
                        Text('Location: ${item.location ?? '-'}', style: AppTheme.bodyMedium),
                        Text('Batch: ${item.batch ?? '-'}', style: AppTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
