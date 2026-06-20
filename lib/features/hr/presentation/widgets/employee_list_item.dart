import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/employee_model.dart';

class EmployeeListItem extends StatefulWidget {
  final EmployeeModel employee;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onCheckboxChanged;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onManageRoles;

  const EmployeeListItem({
    super.key,
    required this.employee,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onTap,
    this.onLongPress,
    this.onCheckboxChanged,
    this.onDelete,
    this.onEdit,
    this.onManageRoles,
  });

  @override
  State<EmployeeListItem> createState() => _EmployeeListItemState();
}

class _EmployeeListItemState extends State<EmployeeListItem> {
  late bool _isSelected;

  @override
  void initState() { super.initState(); _isSelected = widget.isSelected; }

  @override
  void didUpdateWidget(EmployeeListItem old) {
    super.didUpdateWidget(old);
    if (old.isSelected != widget.isSelected) setState(() => _isSelected = widget.isSelected);
  }

  Color get _statusColor {
    switch (widget.employee.status.toUpperCase()) {
      case 'ACTIVE': return AppTheme.success;
      case 'RESIGNED': return AppTheme.warning;
      case 'TERMINATED': return AppTheme.error;
      default: return AppTheme.primary;
    }
  }

  Color get _avatarColor {
    final colors = [
      const Color(0xFF1565C0), const Color(0xFF6A1B9A), const Color(0xFF00695C),
      const Color(0xFFE65100), const Color(0xFF283593), const Color(0xFF4A148C),
    ];
    return colors[widget.employee.empName.length % colors.length];
  }

  String get _initials {
    final parts = widget.employee.empName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _isSelected ? AppTheme.primary.withValues(alpha: 0.05) : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isSelected ? AppTheme.primary.withValues(alpha: 0.4) : AppTheme.surfaceVariant,
          width: _isSelected ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: widget.isSelectionMode ? widget.onCheckboxChanged : widget.onTap,
        onLongPress: widget.onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              if (_isSelected)
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 22),
                ),
              CircleAvatar(
                radius: 22,
                backgroundColor: _avatarColor,
                child: Text(_initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.employee.empName, style: AppTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(widget.employee.email, style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      _chip(widget.employee.empId, AppTheme.primary.withValues(alpha: 0.1), AppTheme.primary),
                      _chip(widget.employee.role.roleName, AppTheme.secondary.withValues(alpha: 0.12), AppTheme.secondary),
                      _chip(widget.employee.status, _statusColor.withValues(alpha: 0.1), _statusColor),
                    ]),
                  ],
                ),
              ),
              if (!widget.isSelectionMode)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppTheme.onSurfaceVariant),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) {
                    if (v == 'roles') widget.onManageRoles?.call();
                    if (v == 'edit') widget.onEdit?.call();
                    if (v == 'delete') widget.onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'roles', child: Row(children: [Icon(Icons.manage_accounts_rounded, color: Color(0xFF6A1B9A), size: 18), SizedBox(width: 10), Text('Manage Roles')])),
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, color: AppTheme.primary, size: 18), SizedBox(width: 10), Text('Edit')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, color: AppTheme.error, size: 18), SizedBox(width: 10), Text('Delete', style: TextStyle(color: AppTheme.error))])),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600)),
  );

}
