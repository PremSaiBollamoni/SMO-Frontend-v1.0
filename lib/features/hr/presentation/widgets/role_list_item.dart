import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/role_model.dart';

/// Role list item widget with proper state management for checkbox
class RoleListItem extends StatefulWidget {
  final RoleModel role;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onCheckboxChanged;
  final VoidCallback? onDelete;

  const RoleListItem({
    super.key,
    required this.role,
    this.isSelected = false,
    this.onTap,
    this.onCheckboxChanged,
    this.onDelete,
  });

  @override
  State<RoleListItem> createState() => _RoleListItemState();
}

class _RoleListItemState extends State<RoleListItem> {
  late bool _isSelected;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.isSelected;
  }

  @override
  void didUpdateWidget(RoleListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      setState(() {
        _isSelected = widget.isSelected;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return AppTheme.success;
      case 'INACTIVE':
        return AppTheme.warning;
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
                    widget.role.roleName,
                    style: AppTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Info row - ID and Activity
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ID: ${widget.role.roleId}',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Activity: ${widget.role.activity}',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Status and Actions row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(widget.role.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.role.status,
                    style: TextStyle(
                      color: _statusColor(widget.role.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.delete, color: AppTheme.error, size: 18),
                    onPressed: widget.onDelete,
                    tooltip: 'Delete role',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
