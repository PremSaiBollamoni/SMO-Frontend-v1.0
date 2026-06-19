import '../../../../core/network/api_client.dart';
import '../models/job_assignment_model.dart';

class JobApiService {
  final _dio = ApiClient().dio;

  Future<ScanBundleResponse> scanBundle({
    required String barcode,
    required int wsId,
    required int empId,
    required int assignedBy,
    int? bundleQty,
  }) async {
    final res = await _dio.post('/api/jobs/scan', data: {
      'barcode': barcode,
      'wsId': wsId,
      'empId': empId,
      'assignedBy': assignedBy,
      if (bundleQty != null) 'bundleQty': bundleQty,
    });
    return ScanBundleResponse.fromJson(res.data);
  }

  Future<List<ActiveJob>> getActiveJobs() async {
    final res = await _dio.get('/api/jobs/active');
    return (res.data as List).map((j) => ActiveJob.fromJson(j)).toList();
  }

  Future<List<ActiveJob>> getActiveJobsByStation(int wsId) async {
    final res = await _dio.get('/api/jobs/station/$wsId/active');
    return (res.data as List).map((j) => ActiveJob.fromJson(j)).toList();
  }

  Future<List<ActiveJob>> getAllJobs() async {
    final res = await _dio.get('/api/jobs');
    return (res.data as List).map((j) => ActiveJob.fromJson(j)).toList();
  }
}
