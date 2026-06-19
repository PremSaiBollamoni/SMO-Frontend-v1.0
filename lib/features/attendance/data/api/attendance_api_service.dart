import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/attendance_models.dart';

class AttendanceApiService {
  final Dio _dio = ApiClient().dio;

  /// Map a temp QR card to an employee for today.
  Future<void> mapQr({
    required String qrToken,
    required int empId,
    required int mappedBy,
  }) async {
    await _dio.post('/api/attendance/map-qr', data: {
      'qrToken': qrToken,
      'empId': empId,
      'mappedBy': mappedBy,
    });
  }

  /// Resolve which employee holds a temp QR today.
  /// Returns empId or throws if not mapped.
  Future<int> resolveQr(String qrToken) async {
    final res = await _dio.get('/api/attendance/resolve-qr', queryParameters: {'qrToken': qrToken});
    return (res.data['empId'] as num).toInt();
  }

  /// Check in: temp QR + machine QR + optional shift.
  Future<AttendanceRecord> checkIn({
    required String tempQrToken,
    required String machineCode,
    int? shiftTemplateId,
    required int markedBy,
  }) async {
    final res = await _dio.post('/api/attendance/checkin', data: {
      'tempQrToken': tempQrToken,
      'machineCode': machineCode,
      if (shiftTemplateId != null) 'shiftTemplateId': shiftTemplateId,
      'markedBy': markedBy,
    });
    return AttendanceRecord.fromJson(res.data as Map<String, dynamic>);
  }

  /// Check out by scanning temp QR again.
  Future<AttendanceRecord> checkOut({
    required String tempQrToken,
    required int markedBy,
  }) async {
    final res = await _dio.post('/api/attendance/checkout', data: {
      'tempQrToken': tempQrToken,
      'markedBy': markedBy,
    });
    return AttendanceRecord.fromJson(res.data as Map<String, dynamic>);
  }

  /// Today's attendance list.
  Future<List<AttendanceRecord>> getTodayAttendance() async {
    final res = await _dio.get('/api/attendance/today');
    return (res.data as List)
        .map((j) => AttendanceRecord.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Free all temp QR mappings (end of day).
  Future<int> freeAllQrs() async {
    final res = await _dio.post('/api/attendance/free-qrs');
    return (res.data['freed'] as num).toInt();
  }

  /// All employees for dropdown.
  Future<List<EmployeeOption>> getEmployees() async {
    final res = await _dio.get('/api/hr/employees');
    return (res.data as List)
        .map((j) => EmployeeOption.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
