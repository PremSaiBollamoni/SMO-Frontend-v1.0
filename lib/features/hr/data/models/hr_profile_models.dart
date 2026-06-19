class ProfileRoleInfo {
  final String roleName;
  ProfileRoleInfo({required this.roleName});
  factory ProfileRoleInfo.fromJson(Map<String, dynamic> j) =>
      ProfileRoleInfo(roleName: (j['roleName'] ?? '').toString());
}

class HrProfileResponse {
  final String empName;
  final String email;
  final String phone;
  final String address;
  final String dob;
  final String bloodGroup;
  final String emergencyContact;
  final String aadharNumber;
  final String panCardNumber;
  final String status;
  final ProfileRoleInfo role;

  HrProfileResponse({
    required this.empName,
    required this.email,
    required this.phone,
    required this.address,
    required this.dob,
    required this.bloodGroup,
    required this.emergencyContact,
    required this.aadharNumber,
    required this.panCardNumber,
    required this.status,
    required this.role,
  });

  factory HrProfileResponse.fromJson(Map<String, dynamic> j) {
    return HrProfileResponse(
      empName: (j['empName'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      phone: (j['phone'] ?? '').toString(),
      address: (j['address'] ?? '').toString(),
      dob: (j['dob'] ?? '').toString(),
      bloodGroup: (j['bloodGroup'] ?? '').toString(),
      emergencyContact: (j['emergencyContact'] ?? '').toString(),
      aadharNumber: (j['aadharNumber'] ?? '').toString(),
      panCardNumber: (j['panCardNumber'] ?? '').toString(),
      status: (j['status'] ?? 'ACTIVE').toString(),
      role: j['role'] != null
          ? ProfileRoleInfo.fromJson(Map<String, dynamic>.from(j['role'] as Map))
          : ProfileRoleInfo(roleName: '-'),
    );
  }
}

class UpdateHrProfileRequest {
  final String empName;
  final String email;
  final String? phone;
  final String? address;
  final String? dob;
  final String? bloodGroup;
  final String? emergencyContact;
  final String? aadharNumber;
  final String? panCardNumber;
  final String status;
  final String? password;

  UpdateHrProfileRequest({
    required this.empName,
    required this.email,
    this.phone,
    this.address,
    this.dob,
    this.bloodGroup,
    this.emergencyContact,
    this.aadharNumber,
    this.panCardNumber,
    required this.status,
    this.password,
  });

  Map<String, dynamic> toJson() => {
        'empName': empName,
        'email': email,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (dob != null) 'dob': dob,
        if (bloodGroup != null) 'bloodGroup': bloodGroup,
        if (emergencyContact != null) 'emergencyContact': emergencyContact,
        if (aadharNumber != null) 'aadharNumber': aadharNumber,
        if (panCardNumber != null) 'panCardNumber': panCardNumber,
        'status': status,
        if (password != null) 'password': password,
      };
}
