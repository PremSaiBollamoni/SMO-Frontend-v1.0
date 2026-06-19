/// Role response model from authentication
class RoleResponse {
  final String role;
  final String employeeName;
  final String empId;
  final String activities;
  final List<Map<String, dynamic>> allRoles;
  final String? token;
  final String? refreshToken;
  final int? tokenExpiresIn;

  RoleResponse({
    required this.role,
    required this.employeeName,
    required this.empId,
    required this.activities,
    required this.allRoles,
    this.token,
    this.refreshToken,
    this.tokenExpiresIn,
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
      token: json['token'] as String?,
      refreshToken: json['refreshToken'] as String?,
      tokenExpiresIn: json['tokenExpiresIn'] as int?,
    );
  }
}
