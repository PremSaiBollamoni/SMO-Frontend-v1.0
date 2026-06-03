import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../core/theme/app_theme.dart';
import '../controller/supervisor_controller.dart';
import '../../domain/models/wip_stats_model.dart';

/// WIP Stats View - Real WIP tracking data with graphs
class WipStatsView extends StatefulWidget {
  const WipStatsView({super.key});

  @override
  State<WipStatsView> createState() => _WipStatsViewState();
}

class _WipStatsViewState extends State<WipStatsView> {
  late TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SupervisorController>();

    return Obx(() {
      final stats = controller.wipStats.value;
      final loading = controller.loadingWipStats.value;

      return RefreshIndicator(
        onRefresh: () => controller.fetchWipStats(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(loading, controller),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (stats == null)
              _buildCard(
                Text('No WIP data available. Pull to refresh.', style: AppTheme.bodyLarge),
              )
            else ...[
              // Overall Stats Cards
              _buildOverallStatsCards(stats),
              const SizedBox(height: 16),

              // Status Distribution Pie Chart
              if (stats.statusDistribution.isNotEmpty)
                _buildStatusDistributionChart(stats),
              const SizedBox(height: 16),

              // Hourly WIP Line Chart
              if (stats.hourlyStats.isNotEmpty)
                _buildHourlyWipChart(stats),
              const SizedBox(height: 16),

              // Operation-wise WIP Bar Chart
              if (stats.operationStats.isNotEmpty)
                _buildOperationWipChart(stats),
              const SizedBox(height: 16),

              // Operation Details Table
              if (stats.operationStats.isNotEmpty)
                _buildOperationDetailsTable(stats),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildHeader(bool loading, SupervisorController controller) {
    return _buildCard(
      Row(
        children: [
          Expanded(
            child: Text('Real WIP Stats', style: AppTheme.headlineMedium),
          ),
          IconButton(
            onPressed: loading ? null : () => controller.fetchWipStats(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatsCards(WipStatsModel stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total WIP',
                '${stats.totalWipCount}',
                AppTheme.primary,
                Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Active',
                '${stats.activeWipCount}',
                AppTheme.success,
                Icons.play_circle_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pending',
                '${stats.pendingWipCount}',
                AppTheme.warning,
                Icons.schedule_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Completed Today',
                '${stats.completedTodayCount}',
                AppTheme.success,
                Icons.check_circle_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return _buildCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: AppTheme.bodySmall),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistributionChart(WipStatsModel stats) {
    return _buildCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Distribution', style: AppTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: SfCircularChart(
              tooltipBehavior: _tooltipBehavior,
              series: <CircularSeries>[
                PieSeries<StatusDistribution, String>(
                  dataSource: stats.statusDistribution,
                  xValueMapper: (StatusDistribution data, _) => data.status,
                  yValueMapper: (StatusDistribution data, _) => data.count,
                  dataLabelMapper: (StatusDistribution data, _) =>
                      '${data.status}\n${data.count} (${data.percentage.toStringAsFixed(1)}%)',
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                  ),
                  pointColorMapper: (StatusDistribution data, _) =>
                      _getStatusColor(data.status),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyWipChart(WipStatsModel stats) {
    return _buildCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hourly WIP Trend (Last 24 Hours)', style: AppTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: SfCartesianChart(
              tooltipBehavior: _tooltipBehavior,
              primaryXAxis: CategoryAxis(),
              primaryYAxis: NumericAxis(),
              series: <CartesianSeries>[
                LineSeries<HourlyWipStats, String>(
                  dataSource: stats.hourlyStats,
                  xValueMapper: (HourlyWipStats data, _) => data.hour,
                  yValueMapper: (HourlyWipStats data, _) => data.completed,
                  name: 'Completed',
                  color: AppTheme.success,
                  markerSettings: const MarkerSettings(isVisible: true),
                ),
                LineSeries<HourlyWipStats, String>(
                  dataSource: stats.hourlyStats,
                  xValueMapper: (HourlyWipStats data, _) => data.hour,
                  yValueMapper: (HourlyWipStats data, _) => data.active,
                  name: 'Active',
                  color: AppTheme.primary,
                  markerSettings: const MarkerSettings(isVisible: true),
                ),
                LineSeries<HourlyWipStats, String>(
                  dataSource: stats.hourlyStats,
                  xValueMapper: (HourlyWipStats data, _) => data.hour,
                  yValueMapper: (HourlyWipStats data, _) => data.pending,
                  name: 'Pending',
                  color: AppTheme.warning,
                  markerSettings: const MarkerSettings(isVisible: true),
                ),
              ],
              legend: const Legend(isVisible: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationWipChart(WipStatsModel stats) {
    final topOperations = stats.operationStats.take(10).toList();

    return _buildCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WIP by Operation (Top 10)', style: AppTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: SfCartesianChart(
              tooltipBehavior: _tooltipBehavior,
              primaryXAxis: CategoryAxis(),
              primaryYAxis: NumericAxis(),
              series: <CartesianSeries>[
                BarSeries<OperationWipStats, String>(
                  dataSource: topOperations,
                  xValueMapper: (OperationWipStats data, _) =>
                      data.operationName.length > 15
                          ? '${data.operationName.substring(0, 12)}...'
                          : data.operationName,
                  yValueMapper: (OperationWipStats data, _) => data.wipCount,
                  name: 'WIP Count',
                  color: AppTheme.primary,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationDetailsTable(WipStatsModel stats) {
    return _buildCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Operation Details', style: AppTheme.titleLarge),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Operation')),
                DataColumn(label: Text('WIP'), numeric: true),
                DataColumn(label: Text('Completed'), numeric: true),
                DataColumn(label: Text('Avg Time (min)'), numeric: true),
              ],
              rows: stats.operationStats
                  .map(
                    (op) => DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: Text(
                              op.operationName,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.bodySmall,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${op.wipCount}',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${op.completedCount}',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            op.avgTimeMinutes.toStringAsFixed(1),
                            style: AppTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return AppTheme.warning;
      case 'ACTIVE':
        return AppTheme.primary;
      case 'COMPLETED':
        return AppTheme.success;
      default:
        return AppTheme.primary;
    }
  }
}
