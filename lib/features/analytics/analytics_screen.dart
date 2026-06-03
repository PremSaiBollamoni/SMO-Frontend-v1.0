import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'screens/operations_analytics_screen.dart';
import 'screens/employee_analytics_screen.dart';
import 'screens/machine_analytics_screen.dart';
import 'screens/hourly_targets_screen.dart';

/// Entry point for Analytics — shows 3 dashboard types
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Select Dashboard', style: AppTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Choose a category to view detailed analytics',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
            _AnalyticsCard(
              icon: Icons.account_tree_outlined,
              title: 'Operations',
              subtitle: 'View output per operation, compare with targets',
              color: AppTheme.primary,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsAnalyticsScreen())),
            ),
            const SizedBox(height: 16),
            _AnalyticsCard(
              icon: Icons.people_outlined,
              title: 'Employees',
              subtitle: 'Hourly output, per-operation stats, target comparison',
              color: AppTheme.secondary,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeAnalyticsScreen())),
            ),
            const SizedBox(height: 16),
            _AnalyticsCard(
              icon: Icons.precision_manufacturing_outlined,
              title: 'Machine Utilisation',
              subtitle: 'Active vs idle time, per-operation usage',
              color: AppTheme.tertiary,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MachineAnalyticsScreen())),
            ),
            const SizedBox(height: 16),
            _AnalyticsCard(
              icon: Icons.timer_outlined,
              title: 'Hourly Targets',
              subtitle: 'View and edit standard targets per operation',
              color: AppTheme.warning,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HourlyTargetsScreen())),
            ),
          ],
        );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AnalyticsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.surfaceVariant),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
