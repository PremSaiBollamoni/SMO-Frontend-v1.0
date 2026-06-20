class ProductionSlot {
  final int hourSlot;
  final String timeLabel;
  final int piecesProduced;
  final double slotEfficiencyPct;

  const ProductionSlot({
    required this.hourSlot,
    required this.timeLabel,
    required this.piecesProduced,
    required this.slotEfficiencyPct,
  });

  factory ProductionSlot.fromJson(Map<String, dynamic> j) => ProductionSlot(
    hourSlot: j['hourSlot'] ?? 0,
    timeLabel: j['timeLabel'] ?? '',
    piecesProduced: j['piecesProduced'] ?? 0,
    slotEfficiencyPct: (j['slotEfficiencyPct'] ?? 0).toDouble(),
  );
}

class EmployeeEfficiency {
  final int empId;
  final String empName;
  final int totalPieces;
  final int productiveSlots;
  final double efficiencyPct;
  final List<String> operations;

  const EmployeeEfficiency({
    required this.empId,
    required this.empName,
    required this.totalPieces,
    required this.productiveSlots,
    required this.efficiencyPct,
    required this.operations,
  });

  factory EmployeeEfficiency.fromJson(Map<String, dynamic> j) => EmployeeEfficiency(
    empId: j['empId'] ?? 0,
    empName: j['empName'] ?? '',
    totalPieces: j['totalPieces'] ?? 0,
    productiveSlots: j['productiveSlots'] ?? 0,
    efficiencyPct: (j['efficiencyPct'] ?? 0).toDouble(),
    operations: List<String>.from(j['operations'] ?? []),
  );
}

class WorkerProduction {
  final int empId;
  final String empName;
  final String opName;
  final int targetPcs;
  final List<ProductionSlot> slots;
  final int totalPieces;
  final double efficiencyPct;

  const WorkerProduction({
    required this.empId,
    required this.empName,
    required this.opName,
    required this.targetPcs,
    required this.slots,
    required this.totalPieces,
    required this.efficiencyPct,
  });

  factory WorkerProduction.fromJson(Map<String, dynamic> j) => WorkerProduction(
    empId: j['empId'] ?? 0,
    empName: j['empName'] ?? '',
    opName: j['opName'] ?? '',
    targetPcs: j['targetPcs'] ?? 50,
    slots: (j['slots'] as List? ?? []).map((s) => ProductionSlot.fromJson(s)).toList(),
    totalPieces: j['totalPieces'] ?? 0,
    efficiencyPct: (j['efficiencyPct'] ?? 0).toDouble(),
  );
}
