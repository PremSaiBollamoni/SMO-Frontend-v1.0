import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../controller/hr_controller.dart';

class EmployeeToolbar extends StatelessWidget {
  final VoidCallback onExport;

  const EmployeeToolbar({super.key, required this.onExport});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HrController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Column(children: [
        // Search bar
        TextField(
          onChanged: (v) => controller.employeeSearchQuery.value = v,
          decoration: InputDecoration(
            hintText: 'Search employees...',
            prefixIcon: const Icon(Icons.search, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.surfaceVariant)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.surfaceVariant)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
            filled: true, fillColor: AppTheme.surface,
          ),
        ),
        const SizedBox(height: 8),
        // Filter row
        Row(children: [
          Expanded(child: _RoleFilter(controller: controller)),
          const SizedBox(width: 8),
          _iconBtn(Icons.refresh_rounded, AppTheme.primary, controller.fetchEmployees, 'Refresh'),
          const SizedBox(width: 4),
          _iconBtn(Icons.download_rounded, AppTheme.secondary, onExport, 'Export'),
        ]),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap, String tooltip) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
    ),
  );
}

class _RoleFilter extends StatelessWidget {
  final HrController controller;

  const _RoleFilter({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.employeeRoleFilter.value;
      final isFiltered = current != 'ALL';
      return GestureDetector(
        onTap: () => _showFilterSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isFiltered ? AppTheme.primary.withValues(alpha: 0.08) : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isFiltered ? AppTheme.primary : AppTheme.surfaceVariant),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.filter_list_rounded, size: 16, color: isFiltered ? AppTheme.primary : AppTheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              isFiltered ? current : 'All Roles',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isFiltered ? AppTheme.primary : AppTheme.onSurfaceVariant),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isFiltered ? AppTheme.primary : AppTheme.onSurfaceVariant),
          ]),
        ),
      );
    });
  }

  void _showFilterSheet(BuildContext context) {
    final options = ['ALL', ...controller.roles.map((r) => r.roleName)];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Obx(() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Filter by Role', style: AppTheme.titleSmall),
          const SizedBox(height: 12),
          ...options.map((opt) {
            final selected = controller.employeeRoleFilter.value == opt;
            return InkWell(
              onTap: () { controller.employeeRoleFilter.value = opt; Navigator.pop(context); },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary.withValues(alpha: 0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? AppTheme.primary : AppTheme.surfaceVariant),
                ),
                child: Row(children: [
                  Text(opt == 'ALL' ? 'All Roles' : opt, style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppTheme.primary : AppTheme.onSurface)),
                  const Spacer(),
                  if (selected) const Icon(Icons.check_rounded, color: AppTheme.primary, size: 18),
                ]),
              ),
            );
          }),
        ]),
      )),
    );
  }
}
