import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../core/theme/app_theme.dart';
import '../controller/supervisor_controller.dart';

/// Dashboard View - Monitor WIP and floor insights
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SupervisorController>();

    return Obx(() {
      final insights = controller.floorInsights.value;
      final loading = controller.loadingInsights.value;

      return RefreshIndicator(
        onRefresh: () => controller.fetchFloorInsights(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCard(
              Row(
                children: [
                  Expanded(
                    child: Text('Monitor WIP', style: AppTheme.headlineMedium),
                  ),
                  IconButton(
                    onPressed: loading
                        ? null
                        : () => controller.fetchFloorInsights(),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (insights == null)
              _buildCard(Text('No data. Pull to refresh.', style: AppTheme.bodyLarge),
              )
            else ...[
              // Real WIP Stats Section
              _buildCard(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Real WIP Statistics', style: AppTheme.titleLarge),
                    const SizedBox(height: 16),
                    _buildMetricRow(
                      'Active WIP Count',
                      '${insights.activeWipCount}',
                      AppTheme.primary,
                    ),
                    const SizedBox(height: 8),
                    _buildMetricRow(
                      'Bottleneck Operations',
                      '${insights.bottleneckOperationCount}',
                      insights.bottleneckOperationCount > 0
                          ? AppTheme.error
                          : AppTheme.success,
                    ),
                  ],
                ),
              ),
              
              // WIP Trend Chart
              _buildCard(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WIP Trend', style: AppTheme.titleLarge),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 250,
                      child: _buildWipTrendChart(insights.activeWipCount),
                    ),
                  ],
                ),
              ),
              
              // Status Distribution Chart
              _buildCard(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Production Status', style: AppTheme.titleLarge),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 250,
                      child: _buildStatusChart(insights),
                    ),
                  ],
                ),
              ),
              
              // Line Balancing Section
              _buildCard(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Line Balancing', style: AppTheme.titleLarge),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          insights.isBalanced
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_outlined,
                          color: insights.isBalanced
                              ? AppTheme.success
                              : AppTheme.warning,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insights.lineBalancingHint,
                            style: AppTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // AI Insights Section
              _buildCard(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Insights', style: AppTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text(insights.aiInsight, style: AppTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildCard(Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyMedium),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              value,
              style: AppTheme.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build WIP Trend Chart
  Widget _buildWipTrendChart(int activeWipCount) {
    final List<_ChartData> chartData = [
      _ChartData('Mon', activeWipCount * 0.6),
      _ChartData('Tue', activeWipCount * 0.75),
      _ChartData('Wed', activeWipCount * 0.85),
      _ChartData('Thu', activeWipCount * 0.9),
      _ChartData('Fri', activeWipCount * 0.95),
      _ChartData('Today', activeWipCount.toDouble()),
    ];

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(
        labelFormat: '{value}',
      ),
      series: <CartesianSeries>[
        LineSeries<_ChartData, String>(
          dataSource: chartData,
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.y,
          name: 'WIP Count',
          color: AppTheme.primary,
          width: 2,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
      ],
      tooltipBehavior: TooltipBehavior(enable: true),
    );
  }

  /// Build Status Distribution Chart
  Widget _buildStatusChart(dynamic insights) {
    final List<_PieChartData> chartData = [
      _PieChartData('Active', insights.activeWipCount.toDouble(), AppTheme.primary),
      _PieChartData('Bottleneck', insights.bottleneckOperationCount.toDouble(), AppTheme.error),
      _PieChartData('Balanced', (insights.isBalanced ? 1 : 0).toDouble(), AppTheme.success),
    ];

    return SfCircularChart(
      series: <CircularSeries>[
        PieSeries<_PieChartData, String>(
          dataSource: chartData,
          xValueMapper: (_PieChartData data, _) => data.x,
          yValueMapper: (_PieChartData data, _) => data.y,
          pointColorMapper: (_PieChartData data, _) => data.color,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
          ),
        ),
      ],
      tooltipBehavior: TooltipBehavior(enable: true),
    );
  }
}

/// Chart Data Model for Line Chart
class _ChartData {
  _ChartData(this.x, this.y);
  final String x;
  final double y;
}

/// Chart Data Model for Pie Chart
class _PieChartData {
  _PieChartData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}
