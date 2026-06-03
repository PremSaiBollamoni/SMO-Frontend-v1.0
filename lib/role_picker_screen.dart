import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';

/// Shown after login when an employee has multiple roles.
class RolePickerScreen extends StatefulWidget {
  final String empId;
  final String employeeName;
  final List<Map<String, dynamic>> roles;
  final Function(String roleName, String activities) onRoleSelected;

  const RolePickerScreen({
    super.key,
    required this.empId,
    required this.employeeName,
    required this.roles,
    required this.onRoleSelected,
  });

  @override
  State<RolePickerScreen> createState() => _RolePickerScreenState();
}

class _RolePickerScreenState extends State<RolePickerScreen> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryVariant, Color(0xFF062229)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -50, right: -40,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -40, left: -50,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.switch_account,
                            size: 38,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select Your Role',
                          style: AppTheme.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Welcome, ${widget.employeeName}',
                          style: AppTheme.titleMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.roles.length} roles assigned — pick one for this session',
                          textAlign: TextAlign.center,
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Role cards
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Drag handle
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            width: 40, height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                              children: [
                                ...List.generate(widget.roles.length, (i) {
                                  final role = widget.roles[i];
                                  final roleName = (role['roleName'] ?? '').toString();
                                  final activities = (role['activities'] ?? '').toString();
                                  final isSelected = _selectedIndex == i;
                                  final color = _colorForRole(roleName);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedIndex = i),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? color.withValues(alpha: 0.08)
                                              : AppTheme.surface,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected ? color : AppTheme.surfaceVariant,
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: isSelected ? [
                                            BoxShadow(
                                              color: color.withValues(alpha: 0.15),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ] : [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.04),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            // Role icon
                                            Container(
                                              width: 48, height: 48,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? color.withValues(alpha: 0.15)
                                                    : AppTheme.surfaceVariant,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                _iconForRole(roleName),
                                                color: isSelected ? color : AppTheme.onSurfaceVariant,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            // Role info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    roleName,
                                                    style: AppTheme.titleMedium.copyWith(
                                                      fontWeight: FontWeight.w700,
                                                      color: isSelected ? color : AppTheme.onSurface,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _summarizeActivities(activities),
                                                    style: AppTheme.bodySmall.copyWith(
                                                      color: AppTheme.onSurfaceVariant,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Check indicator
                                            AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 200),
                                              child: isSelected
                                                  ? Icon(Icons.check_circle, color: color, size: 24, key: const ValueKey('check'))
                                                  : Icon(Icons.radio_button_unchecked, color: AppTheme.surfaceVariant, size: 24, key: const ValueKey('uncheck')),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          // Continue button
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            child: SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _selectedIndex == null
                                    ? null
                                    : () async {
                                        final role = widget.roles[_selectedIndex!];
                                        final roleName = (role['roleName'] ?? '').toString();
                                        final activities = (role['activities'] ?? '').toString();
                                        final prefs = await SharedPreferences.getInstance();
                                        await prefs.setString('EMPLOYEE_NAME', widget.employeeName);
                                        await prefs.setString('ROLE', roleName);
                                        await prefs.setString('EMP_ID', widget.empId);
                                        await prefs.setString('ACTIVITIES', activities);
                                        widget.onRoleSelected(roleName, activities);
                                      },
                                style: AppTheme.primaryButtonStyle,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _selectedIndex == null ? 'Select a Role' : 'Continue as ${widget.roles[_selectedIndex!]['roleName']}',
                                      style: AppTheme.labelLarge.copyWith(
                                        color: AppTheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_selectedIndex != null) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 20, color: AppTheme.onPrimary),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForRole(String roleName) {
    final r = roleName.toUpperCase();
    if (r.contains('SUPERVISOR')) return AppTheme.primary;
    if (r.contains('HR') || r.contains('ADMIN')) return AppTheme.info;
    if (r.contains('GM') || r.contains('GENERAL')) return AppTheme.secondary;
    if (r.contains('PLANNER') || r.contains('PROCESS')) return AppTheme.tertiary;
    if (r.contains('OPERATOR')) return const Color(0xFF7B5EA7);
    if (r.contains('STORE')) return const Color(0xFF00838F);
    if (r.contains('QC') || r.contains('QUALITY')) return AppTheme.success;
    if (r.contains('PURCHASE')) return AppTheme.warning;
    return AppTheme.primary;
  }

  IconData _iconForRole(String roleName) {
    final r = roleName.toUpperCase();
    if (r.contains('HR') || r.contains('ADMIN')) return Icons.people_outlined;
    if (r.contains('SUPERVISOR')) return Icons.supervisor_account_outlined;
    if (r.contains('GM') || r.contains('GENERAL')) return Icons.business_outlined;
    if (r.contains('PLANNER') || r.contains('PROCESS')) return Icons.account_tree_outlined;
    if (r.contains('OPERATOR')) return Icons.precision_manufacturing_outlined;
    if (r.contains('STORE')) return Icons.warehouse_outlined;
    if (r.contains('QC') || r.contains('QUALITY')) return Icons.verified_outlined;
    if (r.contains('PURCHASE')) return Icons.shopping_cart_outlined;
    return Icons.badge_outlined;
  }

  String _summarizeActivities(String activities) {
    final parts = activities.split(',').map((a) => a.trim()).toList();
    if (parts.length <= 2) return parts.join(', ');
    return '${parts.take(2).join(', ')} +${parts.length - 2} more';
  }
}
