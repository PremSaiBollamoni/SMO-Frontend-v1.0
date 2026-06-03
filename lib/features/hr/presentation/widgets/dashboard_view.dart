import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../core/theme/app_theme.dart';
import '../controller/hr_controller.dart';

/// Dashboard view widget with statistics chart
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HrController>();

    return Obx(() {
      final dashboard = controller.dashboard.value;
      if (dashboard == null) {
        return const Center(child: CircularProgressIndicator());
      }

      final chartData = [
        _ChartData('Roles', dashboard.totalRoles.toDouble(), AppTheme.primary),
        _ChartData('Employees', dashboard.totalEmployees.toDouble(), AppTheme.secondary),
      ];

      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard Overview', style: AppTheme.headlineMedium),
                const SizedBox(height: 32),

                // Statistics Chart
                Container(
                  decoration: AppTheme.cardDecoration,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HR Statistics', style: AppTheme.titleLarge),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 300,
                          width: double.infinity,
                          child: SfCartesianChart(
                            primaryXAxis: const CategoryAxis(
                              majorGridLines: MajorGridLines(width: 0),
                            ),
                            primaryYAxis: const NumericAxis(
                              axisLine: AxisLine(width: 0),
                              majorTickLines: MajorTickLines(size: 0),
                            ),
                            tooltipBehavior: TooltipBehavior(enable: true),
                            series: <CartesianSeries>[
                              ColumnSeries<_ChartData, String>(
                                dataSource: chartData,
                                xValueMapper: (_ChartData data, _) =>
                                    data.category,
                                yValueMapper: (_ChartData data, _) =>
                                    data.value,
                                pointColorMapper: (_ChartData data, _) =>
                                    data.color,
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                  textStyle: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Roles',
                        dashboard.totalRoles.toString(),
                        Icons.work_outline,
                        AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Employees',
                        dashboard.totalEmployees.toString(),
                        Icons.people_outline,
                        AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTheme.displaySmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Chart data model
class _ChartData {
  _ChartData(this.category, this.value, this.color);
  final String category;
  final double value;
  final Color color;
}
