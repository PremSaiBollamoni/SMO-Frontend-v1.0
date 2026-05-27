import '../api/supervisor_api_service.dart';
import '../models/merge_bins_request.dart';
import '../models/wip_stats_response.dart';
import '../../domain/models/floor_insights_model.dart';
import '../../domain/models/wip_stats_model.dart';

/// Supervisor Repository - Business logic and data access
class SupervisorRepository {
  final SupervisorApiService _apiService;

  SupervisorRepository({SupervisorApiService? apiService})
    : _apiService = apiService ?? SupervisorApiService();

  // ── Floor Insights ────────────────────────────────────────────────────────

  Future<FloorInsightsModel> getFloorInsights() async {
    final response = await _apiService.fetchFloorInsights();
    return response.toDomain();
  }

  // ── WIP Stats ────────────────────────────────────────────────────────────

  Future<WipStatsModel> getWipStats() async {
    final response = await _apiService.fetchWipStats();
    return response.toDomain();
  }

  // ── Merge Bins ────────────────────────────────────────────────────────────

  Future<String> mergeBins({
    required int targetBundleId,
    required int sourceBundleId,
  }) async {
    final request = MergeBinsRequest(
      targetBundleId: targetBundleId,
      sourceBundleId: sourceBundleId,
    );
    return await _apiService.mergeBins(request);
  }
}
