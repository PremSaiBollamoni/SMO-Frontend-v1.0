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
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        if (isMobile) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              onChanged: (v) => controller.employeeSearchQuery.value = v,
              decoration: AppTheme.inputDecoration('Search employees...'),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _RoleFilter(controller: controller)),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.refresh), onPressed: controller.fetchEmployees, tooltip: 'Refresh'),
            ]),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Export'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            ),
          ]);
        }
        return Row(children: [
          Expanded(
            child: TextField(
              onChanged: (v) => controller.employeeSearchQuery.value = v,
              decoration: AppTheme.inputDecoration('Search employees...'),
            ),
          ),
          const SizedBox(width: 8),
          _RoleFilter(controller: controller),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.refresh), onPressed: controller.fetchEmployees, tooltip: 'Refresh'),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.download),
            label: const Text('Export'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
          ),
        ]);
      }),
    );
  }
}

class _RoleFilter extends StatelessWidget {
  final HrController controller;

  const _RoleFilter({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => DropdownButton<String>(
          value: controller.employeeRoleFilter.value,
          isExpanded: true,
          items: [
            const DropdownMenuItem(value: 'ALL', child: Text('ALL')),
            ...controller.roles.map((r) => DropdownMenuItem(
                  value: r.roleName,
                  child: Text(r.roleName, overflow: TextOverflow.ellipsis),
                )),
          ],
          onChanged: (v) { if (v != null) controller.employeeRoleFilter.value = v; },
        ));
  }
}
