import '../../../../core/network/api_client.dart';
import '../models/report_models.dart';

class ReportApiService {
  final _dio = ApiClient().dio;

  Future<ReportResult> generateReport() async {
    final res = await _dio.get('/api/report/generate');
    return ReportResult.fromJson(res.data);
  }
}
