import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/employee_model.dart';

/// Employee list item widget
class EmployeeListItem extends StatefulWidget {
  final EmployeeModel employee;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onCheckboxChanged;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const EmployeeListItem({
    super.key,
    required this.employee,
    this.isSelected = false,
    this.onTap,
    this.onCheckboxChanged,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<EmployeeListItem> createState() => _EmployeeListItemState();
}

class _EmployeeListItemState extends State<EmployeeListItem> {
  late bool _isSelected;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.isSelected;
  }

  @override
  void didUpdateWidget(EmployeeListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      _isSelected = widget.isSelected;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return AppTheme.success;
      case 'RESIGNED':
        return AppTheme.warning;
      case 'TERMINATED':
        return AppTheme.error;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with checkbox and name
            Row(
              children: [
                Checkbox(
                  value: _isSelected,
                  onChanged: (value) {
                    setState(() {
                      _isSelected = value ?? false;
                    });
                    widget.onCheckboxChanged?.call();
                  },
                ),
                Expanded(
                  child: Text(
                    widget.employee.empName,
                    style: AppTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Info row - ID and Role
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ID: ${widget.employee.empId}',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Role: ${widget.employee.role.roleName}',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            
            // Email
            Text(
              'Email: ${widget.employee.email}',
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            // Status and Actions row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(
                      widget.employee.status,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.employee.status,
                    style: TextStyle(
                      color: _statusColor(widget.employee.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.edit, color: AppTheme.primary, size: 18),
                        onPressed: widget.onEdit,
                        tooltip: 'Edit',
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.delete, color: AppTheme.error, size: 18),
                        onPressed: widget.onDelete,
                        tooltip: 'Delete',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
