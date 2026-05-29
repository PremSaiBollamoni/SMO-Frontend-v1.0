import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';

/// Shown after login when an employee has multiple roles.
/// The user picks which role they want to work as in this session.
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
            colors: [AppTheme.primary, AppTheme.primaryVariant],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.switch_account,
                      size: 56,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select Your Role',
                      style: AppTheme.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome, ${widget.employeeName}',
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have ${widget.roles.length} roles assigned. Pick which one to use for this session.',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...List.generate(widget.roles.length, (i) {
                      final role = widget.roles[i];
                      final roleName = (role['roleName'] ?? '').toString();
                      final activities = (role['activities'] ?? '').toString();
                      final isSelected = _selectedIndex == i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _selectedIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary.withValues(alpha: 0.1)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isSelected
                                      ? AppTheme.primary
                                      : Colors.grey.shade300,
                                  child: Icon(
                                    _iconForRole(roleName),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        roleName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: isSelected
                                              ? AppTheme.primary
                                              : AppTheme.onSurface,
                                        ),
                                      ),
                                      if (activities.isNotEmpty)
                                        Text(
                                          _summarizeActivities(activities),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle,
                                      color: AppTheme.primary),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedIndex == null
                            ? null
                            : () async {
                                final role = widget.roles[_selectedIndex!];
                                final roleName = (role['roleName'] ?? '').toString();
                                final activities = (role['activities'] ?? '').toString();

                                // Save to prefs
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setString('EMPLOYEE_NAME', widget.employeeName);
                                await prefs.setString('ROLE', roleName);
                                await prefs.setString('EMP_ID', widget.empId);
                                await prefs.setString('ACTIVITIES', activities);

                                // Notify parent to navigate
                                widget.onRoleSelected(roleName, activities);
                              },
                        style: AppTheme.primaryButtonStyle,
                        child: const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text(
                            'Continue',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForRole(String roleName) {
    final r = roleName.toUpperCase();
    if (r.contains('HR') || r.contains('ADMIN')) return Icons.people;
    if (r.contains('SUPERVISOR')) return Icons.supervisor_account;
    if (r.contains('GM') || r.contains('GENERAL')) return Icons.business;
    if (r.contains('PLANNER') || r.contains('PROCESS')) return Icons.account_tree;
    if (r.contains('OPERATOR')) return Icons.precision_manufacturing;
    if (r.contains('STORE')) return Icons.warehouse;
    if (r.contains('QC') || r.contains('QUALITY')) return Icons.verified;
    if (r.contains('PURCHASE')) return Icons.shopping_cart;
    return Icons.badge;
  }

  String _summarizeActivities(String activities) {
    final parts = activities.split(',').map((a) => a.trim()).toList();
    if (parts.length <= 2) return parts.join(', ');
    return '${parts.take(2).join(', ')} +${parts.length - 2} more';
  }
}
