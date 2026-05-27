/// WIP Stats Domain Model
class WipStatsModel {
  final int totalWipCount;
  final int activeWipCount;
  final int completedTodayCount;
  final int pendingWipCount;
  final int pendingStatus;
  final int activeStatus;
  final int completedStatus;
  final List<OperationWipStats> operationStats;
  final List<HourlyWipStats> hourlyStats;
  final List<StatusDistribution> statusDistribution;

  WipStatsModel({
    required this.totalWipCount,
    required this.activeWipCount,
    required this.completedTodayCount,
    required this.pendingWipCount,
    required this.pendingStatus,
    required this.activeStatus,
    required this.completedStatus,
    required this.operationStats,
    required this.hourlyStats,
    required this.statusDistribution,
  });
}

/// Operation WIP Stats
class OperationWipStats {
  final int operationId;
  final String operationName;
  final int wipCount;
  final int completedCount;
  final double avgTimeMinutes;

  OperationWipStats({
    required this.operationId,
    required this.operationName,
    required this.wipCount,
    required this.completedCount,
    required this.avgTimeMinutes,
  });
}

/// Hourly WIP Stats
class HourlyWipStats {
  final String hour;
  final int completed;
  final int pending;
  final int active;

  HourlyWipStats({
    required this.hour,
    required this.completed,
    required this.pending,
    required this.active,
  });
}

/// Status Distribution
class StatusDistribution {
  final String status;
  final int count;
  final double percentage;

  StatusDistribution({
    required this.status,
    required this.count,
    required this.percentage,
  });
}
