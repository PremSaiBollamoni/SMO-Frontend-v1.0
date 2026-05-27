import '../../domain/models/wip_stats_model.dart';

/// WIP Stats API Response DTO
class WipStatsResponse {
  final int totalWipCount;
  final int activeWipCount;
  final int completedTodayCount;
  final int pendingWipCount;
  final int pendingStatus;
  final int activeStatus;
  final int completedStatus;
  final List<OperationWipStatsDto> operationStats;
  final List<HourlyWipStatsDto> hourlyStats;
  final List<StatusDistributionDto> statusDistribution;

  WipStatsResponse({
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

  factory WipStatsResponse.fromJson(Map<String, dynamic> json) {
    return WipStatsResponse(
      totalWipCount: (json['totalWipCount'] ?? 0) as int,
      activeWipCount: (json['activeWipCount'] ?? 0) as int,
      completedTodayCount: (json['completedTodayCount'] ?? 0) as int,
      pendingWipCount: (json['pendingWipCount'] ?? 0) as int,
      pendingStatus: (json['pendingStatus'] ?? 0) as int,
      activeStatus: (json['activeStatus'] ?? 0) as int,
      completedStatus: (json['completedStatus'] ?? 0) as int,
      operationStats: (json['operationStats'] as List<dynamic>?)
          ?.map((e) => OperationWipStatsDto.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      hourlyStats: (json['hourlyStats'] as List<dynamic>?)
          ?.map((e) => HourlyWipStatsDto.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      statusDistribution: (json['statusDistribution'] as List<dynamic>?)
          ?.map((e) => StatusDistributionDto.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  WipStatsModel toDomain() {
    return WipStatsModel(
      totalWipCount: totalWipCount,
      activeWipCount: activeWipCount,
      completedTodayCount: completedTodayCount,
      pendingWipCount: pendingWipCount,
      pendingStatus: pendingStatus,
      activeStatus: activeStatus,
      completedStatus: completedStatus,
      operationStats: operationStats.map((e) => e.toDomain()).toList(),
      hourlyStats: hourlyStats.map((e) => e.toDomain()).toList(),
      statusDistribution: statusDistribution.map((e) => e.toDomain()).toList(),
    );
  }
}

/// Operation WIP Stats DTO
class OperationWipStatsDto {
  final int operationId;
  final String operationName;
  final int wipCount;
  final int completedCount;
  final double avgTimeMinutes;

  OperationWipStatsDto({
    required this.operationId,
    required this.operationName,
    required this.wipCount,
    required this.completedCount,
    required this.avgTimeMinutes,
  });

  factory OperationWipStatsDto.fromJson(Map<String, dynamic> json) {
    return OperationWipStatsDto(
      operationId: (json['operationId'] ?? 0) as int,
      operationName: (json['operationName'] ?? 'Unknown') as String,
      wipCount: (json['wipCount'] ?? 0) as int,
      completedCount: (json['completedCount'] ?? 0) as int,
      avgTimeMinutes: ((json['avgTimeMinutes'] ?? 0) as num).toDouble(),
    );
  }

  OperationWipStats toDomain() {
    return OperationWipStats(
      operationId: operationId,
      operationName: operationName,
      wipCount: wipCount,
      completedCount: completedCount,
      avgTimeMinutes: avgTimeMinutes,
    );
  }
}

/// Hourly WIP Stats DTO
class HourlyWipStatsDto {
  final String hour;
  final int completed;
  final int pending;
  final int active;

  HourlyWipStatsDto({
    required this.hour,
    required this.completed,
    required this.pending,
    required this.active,
  });

  factory HourlyWipStatsDto.fromJson(Map<String, dynamic> json) {
    return HourlyWipStatsDto(
      hour: (json['hour'] ?? '00:00') as String,
      completed: (json['completed'] ?? 0) as int,
      pending: (json['pending'] ?? 0) as int,
      active: (json['active'] ?? 0) as int,
    );
  }

  HourlyWipStats toDomain() {
    return HourlyWipStats(
      hour: hour,
      completed: completed,
      pending: pending,
      active: active,
    );
  }
}

/// Status Distribution DTO
class StatusDistributionDto {
  final String status;
  final int count;
  final double percentage;

  StatusDistributionDto({
    required this.status,
    required this.count,
    required this.percentage,
  });

  factory StatusDistributionDto.fromJson(Map<String, dynamic> json) {
    return StatusDistributionDto(
      status: (json['status'] ?? 'UNKNOWN') as String,
      count: (json['count'] ?? 0) as int,
      percentage: ((json['percentage'] ?? 0) as num).toDouble(),
    );
  }

  StatusDistribution toDomain() {
    return StatusDistribution(
      status: status,
      count: count,
      percentage: percentage,
    );
  }
}
