import 'package:get/get.dart';

class SupervisorController extends GetxController {
  final isLoading = false.obs;
  final employeeName = ''.obs;
  final empId = ''.obs;
  final role = ''.obs;

  void initialize(String employeeId, String name, String userRole) {
    empId.value = employeeId;
    employeeName.value = name;
    role.value = userRole;
  }
}
