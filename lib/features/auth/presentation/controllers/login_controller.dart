import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/security/secure_storage_helper.dart';
import '../../data/models/login_request.dart';
import '../../domain/models/role_response.dart';
import '../../../../core/routing/app_router.dart';

class LoginController extends GetxController {
  final isLoading = false.obs;

  Future<void> performLogin({
    required BuildContext context,
    required String username,
    required String password,
    Function(bool)? setDarkMode,
  }) async {
    isLoading.value = true;
    try {
      final request = LoginRequest(loginid: username, password: password);
      final response = await ApiClient().dio.post(
        '/api/auth/login',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final roleResponse = RoleResponse.fromJson(response.data);
        final prefs = await SharedPreferences.getInstance();

        ApiClient().setEmpId(roleResponse.empId);

        // Store JWT token securely
        if (roleResponse.token != null) {
          await SecureStorageHelper.saveJwtToken(roleResponse.token!);
        }
        if (roleResponse.refreshToken != null) {
          await SecureStorageHelper.saveRefreshToken(roleResponse.refreshToken!);
        }
        if (roleResponse.tokenExpiresIn != null) {
          final expiryTime = DateTime.now().add(
            Duration(milliseconds: roleResponse.tokenExpiresIn!.toInt()),
          );
          await SecureStorageHelper.saveTokenExpiry(expiryTime);
        }

        // Store non-sensitive data in shared preferences
        await prefs.setString('EMPLOYEE_NAME', roleResponse.employeeName);
        await prefs.setString('EMP_ID', roleResponse.empId);
        await prefs.setString('ALL_ROLES', encodeRoles(roleResponse.allRoles));

        if (roleResponse.allRoles.length > 1) {
          if (!context.mounted) return;
          AppRouter.toRolePicker(
            context: context,
            roleResponse: roleResponse,
            setDarkMode: setDarkMode,
          );
          return;
        }

        await prefs.setString('ROLE', roleResponse.role);
        await prefs.setString('ACTIVITIES', roleResponse.activities);

        if (!context.mounted) return;
        CustomSnackbar.showSuccess(context, 'Welcome ${roleResponse.employeeName}');
        AppRouter.toHome(
          context: context,
          role: roleResponse.role.toUpperCase().trim(),
          empId: roleResponse.empId,
          employeeName: roleResponse.employeeName,
          activities: roleResponse.activities,
          setDarkMode: setDarkMode,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      String message = 'Login failed';
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          message = 'Invalid username or password';
        } else {
          final data = e.response?.data;
          if (data is Map && data.containsKey('message')) {
            message = data['message'];
          } else if (data is String && data.isNotEmpty) {
            message = data;
          } else if (e.type == DioExceptionType.connectionError) {
            message = 'Cannot connect to server. Check network and backend URL.';
          }
        }
      }
      CustomSnackbar.showError(context, message);
    } finally {
      isLoading.value = false;
    }
  }

  String encodeRoles(List<Map<String, dynamic>> roles) {
    return roles.map((r) {
      final id = r['roleId']?.toString() ?? '';
      final name = (r['roleName'] ?? '').toString().replaceAll('|', '-');
      final acts = (r['activities'] ?? '').toString();
      return '$id|$name|$acts';
    }).join(';;');
  }
}
