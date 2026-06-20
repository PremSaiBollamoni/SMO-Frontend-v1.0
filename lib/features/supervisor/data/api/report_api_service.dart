import '../../../../core/network/api_client.dart';
import '../models/report_models.dart';

class ReportApiService {
  final _dio = ApiClient().dio;

  Future<ReportResult> generateReport(DateTime date) async {
    final d = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final res = await _dio.get('/api/report/generate', queryParameters: {'date': d});
    return ReportResult.fromJson(res.data);
  }
}
