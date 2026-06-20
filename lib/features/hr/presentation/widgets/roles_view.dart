import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../controller/hr_controller.dart';
import 'role_list_item.dart';
import 'role_status_filter.dart';

/// Roles management view widget
class RolesView extends StatelessWidget {
  const RolesView({super.key});

  Future<void> _deleteRole(
    BuildContext context,
    HrController controller,
    int roleId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Role'),
        content: const Text('Are you sure you want to delete this role?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await controller.deleteRole(roleId);
      if (context.mounted) {
        if (success) {
          CustomSnackbar.showSuccess(context, 'Role deleted');
        } else {
          CustomSnackbar.showError(
            context,
            'Failed to delete role. Backend delete endpoint may not be implemented yet.',
          );
        }
      }
    }
  }

  Future<void> _deleteBulkRoles(
    BuildContext context,
    HrController controller,
  ) async {
    final selectedIds = controller.selectedRoleIds
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toList();

    if (selectedIds.isEmpty) {
      CustomSnackbar.showError(context, 'Select roles to delete');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Roles'),
        content: Text('Delete ${selectedIds.length} role(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await controller.deleteRoles(selectedIds);
      if (context.mounted) {
        if (success) {
          CustomSnackbar.showSuccess(
            context,
            '${selectedIds.length} role(s) deleted',
          );
        } else {
          CustomSnackbar.showError(
            context,
            'Failed to delete roles. Backend delete endpoint may not be implemented yet.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HrController>();

    return Obx(() {
      final filteredRoles = controller.filteredRoles;
      final selectedCount = controller.selectedRoleIds.length;

      return Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(children: [
              TextField(
                onChanged: (v) => controller.roleSearchQuery.value = v,
                decoration: InputDecoration(
                  hintText: 'Search roles...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.surfaceVariant)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.surfaceVariant)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                  filled: true, fillColor: AppTheme.surface,
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                RoleStatusFilter(controller: controller),
                const Spacer(),
                _iconBtn(Icons.refresh_rounded, AppTheme.primary, controller.fetchRoles, context),
              ]),
            ]),
          ),
          // Bulk delete bar
          if (selectedCount > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('$selectedCount selected', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                const Spacer(),
                GestureDetector(
                  onTap: controller.clearRoleSelections,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Clear', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _deleteBulkRoles(context, controller),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.error, borderRadius: BorderRadius.circular(8)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.delete_rounded, color: Colors.white, size: 15),
                      SizedBox(width: 4),
                      Text('Delete', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
            ),
          // Role list
          Expanded(
            child: filteredRoles.isEmpty
                ? Center(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(32),
                      decoration: AppTheme.cardDecoration,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.work_outline, size: 64, color: AppTheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text('No roles found', style: AppTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to create your first role',
                            style: AppTheme.bodyMedium.copyWith(color: AppTheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 80,
                    ),
                    itemCount: filteredRoles.length,
                    itemBuilder: (context, index) {
                      final role = filteredRoles[index];
                      return RoleListItem(
                        role: role,
                        isSelected: controller.selectedRoleIds.contains(role.roleId.toString()),
                        isSelectionMode: controller.selectedRoleIds.isNotEmpty,
                        onLongPress: () => controller.toggleRoleSelection(role.roleId.toString()),
                        onCheckboxChanged: () => controller.toggleRoleSelection(role.roleId.toString()),
                        onDelete: () => _deleteRole(context, controller, role.roleId),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }

  static Widget _iconBtn(IconData icon, Color color, VoidCallback onTap, BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 20),
    ),
  );
}
