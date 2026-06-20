import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/role_model.dart';

class RoleListItem extends StatefulWidget {
  final RoleModel role;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onCheckboxChanged;
  final VoidCallback? onDelete;

  const RoleListItem({
    super.key,
    required this.role,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onTap,
    this.onLongPress,
    this.onCheckboxChanged,
    this.onDelete,
  });

  @override
  State<RoleListItem> createState() => _RoleListItemState();
}

class _RoleListItemState extends State<RoleListItem> {
  late bool _isSelected;

  @override
  void initState() { super.initState(); _isSelected = widget.isSelected; }

  @override
  void didUpdateWidget(RoleListItem old) {
    super.didUpdateWidget(old);
    if (old.isSelected != widget.isSelected) setState(() => _isSelected = widget.isSelected);
  }

  Color get _statusColor => widget.role.status.toUpperCase() == 'ACTIVE' ? AppTheme.success : AppTheme.warning;

  Color get _roleColor {
    switch (widget.role.roleName.toUpperCase()) {
      case 'HR': return const Color(0xFF1565C0);
      case 'SUPERVISOR': return const Color(0xFF6A1B9A);
      case 'GM': return const Color(0xFF00695C);
      case 'OPERATOR': return const Color(0xFFE65100);
      default: return AppTheme.primary;
    }
  }

  String get _roleIcon {
    switch (widget.role.roleName.toUpperCase()) {
      case 'HR': return 'HR';
      case 'SUPERVISOR': return 'SV';
      case 'GM': return 'GM';
      case 'OPERATOR': return 'OP';
      default: return widget.role.roleName.substring(0, widget.role.roleName.length.clamp(0, 2)).toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activities = widget.role.activity.split(',').where((a) => a.trim().isNotEmpty).toList();

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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (_isSelected)
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 22),
                  ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _roleColor,
                  child: Text(_roleIcon, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.role.roleName, style: AppTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text('ID: ${widget.role.roleId}  •  ${activities.length} activities',
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(widget.role.status, style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 4),
                if (!widget.isSelectionMode)
                  SizedBox(width: 32, height: 32,
                    child: IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.delete_rounded, color: AppTheme.error, size: 19),
                        onPressed: widget.onDelete, tooltip: 'Delete role')),
              ]),
              if (activities.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...activities.take(6).map((a) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _roleColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                      child: Text(a.trim(), style: TextStyle(color: _roleColor, fontSize: 10, fontWeight: FontWeight.w500)),
                    )),
                    if (activities.length > 6)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(6)),
                        child: Text('+${activities.length - 6} more', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w500)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
