import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../controller/hr_controller.dart';

class RoleStatusFilter extends StatelessWidget {
  final HrController controller;
  const RoleStatusFilter({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.roleStatusFilter.value;
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
            Text(isFiltered ? current : 'All Status',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isFiltered ? AppTheme.primary : AppTheme.onSurfaceVariant)),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isFiltered ? AppTheme.primary : AppTheme.onSurfaceVariant),
          ]),
        ),
      );
    });
  }

  void _showFilterSheet(BuildContext context) {
    const options = ['ALL', 'ACTIVE', 'INACTIVE'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Obx(() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Filter by Status', style: AppTheme.titleSmall),
          const SizedBox(height: 12),
          ...options.map((opt) {
            final selected = controller.roleStatusFilter.value == opt;
            return InkWell(
              onTap: () { controller.roleStatusFilter.value = opt; Navigator.pop(context); },
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
                  Text(opt == 'ALL' ? 'All Status' : opt,
                      style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppTheme.primary : AppTheme.onSurface)),
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
