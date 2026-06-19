// Facade — delegates to RoleApiService and EmployeeApiService.
// Kept for backward compatibility with HrRepository.
export 'role_api_service.dart';
export 'employee_api_service.dart';

import 'package:dio/dio.dart';
import '../models/create_role_request.dart';
import '../models/create_employee_request.dart';
import '../models/create_login_request.dart';
import '../../domain/models/role_model.dart';
import '../../domain/models/employee_model.dart';
import '../../domain/models/employee_profile_model.dart';
import 'role_api_service.dart';
import 'employee_api_service.dart';

class HrApiService {
  final RoleApiService _roles;
  final EmployeeApiService _employees;

  HrApiService({Dio? dio})
      : _roles = RoleApiService(dio: dio),
        _employees = EmployeeApiService(dio: dio);

  Future<List<RoleModel>> fetchRoles(String actorEmpId) => _roles.fetchRoles(actorEmpId);
  Future<void> createRole(CreateRoleRequest request) => _roles.createRole(request);
  Future<void> deleteRole(int roleId) => _roles.deleteRole(roleId);
  Future<void> deleteRoles(List<int> roleIds) => _roles.deleteRoles(roleIds);

  Future<List<EmployeeModel>> fetchEmployees(String actorEmpId) => _employees.fetchEmployees(actorEmpId);
  Future<EmployeeProfileModel> fetchEmployeeProfile(String empId, String actorEmpId) => _employees.fetchEmployeeProfile(empId, actorEmpId);
  Future<Map<String, dynamic>> createEmployee(CreateEmployeeRequest request) => _employees.createEmployee(request);
  Future<void> createEmployeeLogin(CreateLoginRequest request) => _employees.createEmployeeLogin(request);
  Future<void> updateEmployee(String empId, CreateEmployeeRequest request) => _employees.updateEmployee(empId, request);
  Future<void> updateEmployeeLogin(String empId, CreateLoginRequest request) => _employees.updateEmployeeLogin(empId, request);
  Future<void> deleteEmployee(String empId) => _employees.deleteEmployee(empId);
  Future<void> deleteEmployees(List<String> empIds) => _employees.deleteEmployees(empIds);
  Future<List<Map<String, dynamic>>> exportEmployees(String actorEmpId) => _employees.exportEmployees(actorEmpId);
}
