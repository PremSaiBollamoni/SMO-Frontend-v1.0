/// Role response model from authentication
class RoleResponse {
  final String role;
  final String employeeName;
  final String empId;
  final String activities;
  final List<Map<String, dynamic>> allRoles;

  RoleResponse({
    required this.role,
    required this.employeeName,
    required this.empId,
    required this.activities,
    required this.allRoles,
  });

  factory RoleResponse.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['allRoles'];
    List<Map<String, dynamic>> roles = [];
    if (rawRoles is List) {
      roles = rawRoles.map((r) => Map<String, dynamic>.from(r as Map)).toList();
    }
    return RoleResponse(
      role: (json['role'] ?? '').toString(),
      employeeName: (json['employeeName'] ?? '').toString(),
      empId: (json['empId'] ?? '').toString(),
      activities: (json['activities'] ?? '').toString(),
      allRoles: roles,
    );
  }
}
