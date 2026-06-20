class ActiveJob {
  final int jobId;
  final int wsId;
  final int empId;
  final String empName;
  final String wsCode;
  final String opName;
  final String skillGrade;
  final String barcode;
  final int bundleQty;
  final double samValue;
  final double estMinutes;
  final int elapsedSeconds;
  final String status;
  final DateTime? endTime;
  final double? efficiencyPct;
  final int? targetPcs;

  const ActiveJob({
    required this.jobId,
    required this.wsId,
    required this.empId,
    required this.empName,
    required this.wsCode,
    required this.opName,
    required this.skillGrade,
    required this.barcode,
    required this.bundleQty,
    required this.samValue,
    required this.estMinutes,
    required this.elapsedSeconds,
    required this.status,
    this.endTime,
    this.efficiencyPct,
    this.targetPcs,
  });

  factory ActiveJob.fromJson(Map<String, dynamic> j) => ActiveJob(
    jobId: j['jobId'],
    wsId: j['wsId'] ?? 0,
    empId: j['empId'],
    empName: j['empName'] ?? '',
    wsCode: j['wsCode'] ?? '',
    opName: j['opName'] ?? '',
    skillGrade: j['skillGrade'] ?? '',
    barcode: j['barcode'] ?? '',
    bundleQty: j['bundleQty'] ?? 0,
    samValue: (j['samValue'] ?? 0).toDouble(),
    estMinutes: (j['estMinutes'] ?? 0).toDouble(),
    elapsedSeconds: j['elapsedSeconds'] ?? 0,
    status: j['status'] ?? '',
    endTime: j['endTime'] != null ? DateTime.parse(j['endTime']) : null,
    efficiencyPct: (j['efficiencyPct'] as num?)?.toDouble(),
    targetPcs: j['targetPcs'] as int?,
  );
}

class CompletedJob {
  final int jobId;
  final String empName;
  final String opName;
  final int bundleQty;
  final double samValue;
  final double estMinutes;
  final double actualMinutes;
  final double efficiencyPct;

  const CompletedJob({
    required this.jobId,
    required this.empName,
    required this.opName,
    required this.bundleQty,
    required this.samValue,
    required this.estMinutes,
    required this.actualMinutes,
    required this.efficiencyPct,
  });

  factory CompletedJob.fromJson(Map<String, dynamic> j) => CompletedJob(
        jobId: j['jobId'],
        empName: j['empName'] ?? '',
        opName: j['opName'] ?? '',
        bundleQty: j['bundleQty'] ?? 0,
        samValue: (j['samValue'] ?? 0).toDouble(),
        estMinutes: (j['estMinutes'] ?? 0).toDouble(),
        actualMinutes: (j['actualMinutes'] ?? 0).toDouble(),
        efficiencyPct: (j['efficiencyPct'] ?? 0).toDouble(),
      );
}

class ScanBundleResponse {
  final String action; // ASSIGN | COMPLETE
  final int jobId;
  final String barcode;
  final String wsCode;
  final String opName;
  final String skillGrade;
  final int bundleQty;
  final double samValue;
  final double estMinutes;
  final CompletedJob? completedJob;

  const ScanBundleResponse({
    required this.action,
    required this.jobId,
    required this.barcode,
    required this.wsCode,
    required this.opName,
    required this.skillGrade,
    required this.bundleQty,
    required this.samValue,
    required this.estMinutes,
    this.completedJob,
  });

  factory ScanBundleResponse.fromJson(Map<String, dynamic> j) => ScanBundleResponse(
        action: j['action'] ?? '',
        jobId: j['jobId'] ?? 0,
        barcode: j['barcode'] ?? '',
        wsCode: j['wsCode'] ?? '',
        opName: j['opName'] ?? '',
        skillGrade: j['skillGrade'] ?? '',
        bundleQty: j['bundleQty'] ?? 0,
        samValue: (j['samValue'] ?? 0).toDouble(),
        estMinutes: (j['estMinutes'] ?? 0).toDouble(),
        completedJob: j['completedJob'] != null ? CompletedJob.fromJson(j['completedJob']) : null,
      );
}
