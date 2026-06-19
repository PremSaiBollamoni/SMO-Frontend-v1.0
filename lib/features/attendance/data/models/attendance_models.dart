class AttendanceRecord {
  final int attId;
  final int empId;
  final String empName;
  final String tempQrToken;
  final String machineCode;
  final String? shiftName;
  final String attDate;
  final String checkIn;
  final String? checkOut;
  final String status;

  const AttendanceRecord({
    required this.attId,
    required this.empId,
    required this.empName,
    required this.tempQrToken,
    required this.machineCode,
    this.shiftName,
    required this.attDate,
    required this.checkIn,
    this.checkOut,
    required this.status,
  });

  bool get isCheckedIn => status == 'CHECKED_IN';

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        attId: j['attId'] as int,
        empId: j['empId'] as int,
        empName: j['empName'] as String? ?? '',
        tempQrToken: j['tempQrToken'] as String,
        machineCode: j['machineCode'] as String,
        shiftName: j['shiftName'] as String?,
        attDate: j['attDate'] as String,
        checkIn: j['checkIn'] as String,
        checkOut: j['checkOut'] as String?,
        status: j['status'] as String,
      );
}

class EmployeeOption {
  final int empId;
  final String name;

  const EmployeeOption({required this.empId, required this.name});

  factory EmployeeOption.fromJson(Map<String, dynamic> j) => EmployeeOption(
        empId: j['empId'] as int,
        name: j['empName'] as String? ?? j['name'] as String? ?? '',
      );

  @override
  String toString() => name;
}
