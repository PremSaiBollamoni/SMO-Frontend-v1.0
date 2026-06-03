import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'models.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'features/hr/presentation/screens/hr_dashboard_screen.dart';
import 'features/operator/presentation/screens/operator_screen.dart';
import 'features/store/presentation/screens/store_screen.dart';
import 'qc_workspace.dart';
import 'purchase_workspace.dart';
import 'features/supervisor/presentation/screens/supervisor_screen.dart';
import 'gm_workspace.dart';
import 'features/process_planner/presentation/screens/process_planner_screen.dart';
import 'features/inventory/presentation/screens/inventory_manager_screen.dart';
import 'core/network/api_client.dart';
import 'access_denied_screen.dart';
import 'role_picker_screen.dart';

class LoginScreen extends StatefulWidget {
  final Function(bool)? setDarkMode;

  const LoginScreen({super.key, this.setDarkMode});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Employee ID is required';
    }
    if (value.trim().length < 3) {
      return 'Employee ID must be at least 3 characters';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
      return 'Employee ID must contain only numbers';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.trim().length < 4) {
      return 'Password must be at least 4 characters';
    }
    return null;
  }

  Future<void> _performLogin() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      CustomSnackbar.showError(
        context,
        "Please enter both Employee ID and Password",
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('[LOGIN] Attempting login for Employee ID: $username');
      debugPrint('[LOGIN] Backend URL: ${ApiClient().dio.options.baseUrl}');
      
      final request = LoginRequest(loginid: username, password: password);
      debugPrint('[LOGIN] Request payload: ${request.toJson()}');

      final response = await ApiClient().dio.post(
        '/api/auth/login',
        data: request.toJson(),
      );

      debugPrint('[LOGIN] Response status: ${response.statusCode}');
      debugPrint('[LOGIN] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final roleResponse = RoleResponse.fromJson(response.data);
        debugPrint('[LOGIN] Login successful for: ${roleResponse.employeeName}');
        debugPrint('[LOGIN] Role: ${roleResponse.role}');
        debugPrint('[LOGIN] Activities: ${roleResponse.activities}');
        debugPrint('[LOGIN] All roles count: ${roleResponse.allRoles.length}');

        // If employee has multiple roles, show role picker
        if (roleResponse.allRoles.length > 1) {
          if (!mounted) return;
          // Store empId now so it's available when role is picked
          ApiClient().setEmpId(roleResponse.empId);
          // Persist allRoles so Switch Role works mid-session
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('EMPLOYEE_NAME', roleResponse.employeeName);
          await prefs.setString('EMP_ID', roleResponse.empId);
          await prefs.setString('ALL_ROLES', _encodeRoles(roleResponse.allRoles));
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (pickerContext) => RolePickerScreen(
                empId: roleResponse.empId,
                employeeName: roleResponse.employeeName,
                roles: roleResponse.allRoles,
                onRoleSelected: (selectedRole, selectedActivities) {
                  final home = _buildHomeForRole(
                    selectedRole.toUpperCase().trim(),
                    roleResponse.empId,
                    roleResponse.employeeName,
                    selectedActivities,
                  );
                  // Navigate from the picker's context — it's still mounted
                  Navigator.of(pickerContext).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => home),
                    (_) => false,
                  );
                },
              ),
            ),
          );
          return;
        }

        // Single role — proceed as before
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('EMPLOYEE_NAME', roleResponse.employeeName);
        await prefs.setString('ROLE', roleResponse.role);
        await prefs.setString('EMP_ID', roleResponse.empId);
        await prefs.setString('ACTIVITIES', roleResponse.activities);
        // Single role — no switch option needed
        await prefs.setString('ALL_ROLES', '');

        // Set Emp ID in ApiClient
        ApiClient().setEmpId(roleResponse.empId);

        if (!mounted) return;

        final normalizedRole = roleResponse.role.toUpperCase().trim();
        final Widget home = _buildHomeForRole(
          normalizedRole,
          roleResponse.empId,
          roleResponse.employeeName,
          roleResponse.activities,
        );

        CustomSnackbar.showSuccess(
          context,
          'Welcome ${roleResponse.employeeName}',
        );
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => home));
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('[LOGIN] Login error: $e');
      if (e is DioException) {
        debugPrint('[LOGIN] DioException type: ${e.type}');
        debugPrint('[LOGIN] Status code: ${e.response?.statusCode}');
        debugPrint('[LOGIN] Response: ${e.response?.data}');
        debugPrint('[LOGIN] Error message: ${e.message}');
      }

      String message = "Login failed";
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          message = "Invalid username or password";
        } else {
          // ApiClient already logs and handles basic errors,
          // but we can extract specific messages from response body if available
          final data = e.response?.data;
          if (data is Map && data.containsKey('message')) {
            message = data['message'];
          } else if (data is String && data.isNotEmpty) {
            message = data;
          } else if (e.type == DioExceptionType.connectionError) {
            message = "Cannot connect to server. Check network and backend URL.";
          }
        }
      }
      CustomSnackbar.showError(context, message);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Encode allRoles list to a JSON string for SharedPreferences storage
  String _encodeRoles(List<Map<String, dynamic>> roles) {
    // Simple encoding: roleId|roleName|activities joined by ;;
    return roles.map((r) {
      final id = r['roleId']?.toString() ?? '';
      final name = (r['roleName'] ?? '').toString().replaceAll('|', '-');
      final acts = (r['activities'] ?? '').toString();
      return '$id|$name|$acts';
    }).join(';;');
  }

  Widget _buildHomeForRole(
    String role,
    String empId,
    String employeeName,
    String activities,
  ) {
    // STRICT ACTIVITY-BASED ROUTING
    // If no activities assigned, deny access
    if (activities.isEmpty) {
      return AccessDeniedScreen(
        message: 'No activities assigned to your role.',
        roleName: role,
        activities: activities,
        setDarkMode: widget.setDarkMode,
      );
    }

    final activityList = activities
        .split(',')
        .map((a) => a.trim().toUpperCase())
        .toList();

    // Check for specific activities and route accordingly
    // HR / Admin
    if (activityList.contains('HR_DASHBOARD') ||
        activityList.contains('ADMIN')) {
      return HrDashboardScreen(setDarkMode: widget.setDarkMode);
    }

    // Operator roles
    if (activityList.contains('OPERATOR_SCAN_BARCODE') ||
        activityList.contains('OPERATOR_COMPLETE_OPERATION')) {
      return OperatorScreen(
        empId: empId,
        employeeName: employeeName,
        role: role,
      );
    }

    // Store Manager
    if (activityList.contains('STORE_MANAGE_INVENTORY') ||
        activityList.contains('STORE_RECEIVE_MATERIALS')) {
      return StoreScreen(empId: empId, employeeName: employeeName, role: role);
    }

    // Purchase Manager
    if (activityList.contains('PURCHASE_CREATE_PO') ||
        activityList.contains('PURCHASE_MANAGE_SUPPLIERS')) {
      return PurchaseWorkspace(
        empId: empId,
        employeeName: employeeName,
        role: role,
      );
    }

    // QC roles
    if (activityList.contains('QC_INSPECT_QUALITY') ||
        activityList.contains('QC_APPROVE_REJECT')) {
      return QcWorkspace(empId: empId, employeeName: employeeName, role: role);
    }

    // Supervisor (includes QR Assignment, Monitor WIP, Line Balancing, Tracking, Merging, etc.)
    if (activityList.contains('SUPERVISOR_MONITOR_WIP') ||
        activityList.contains('SUPERVISOR_LINE_BALANCING') ||
        activityList.contains('SUPERVISOR_QR_ASSIGNMENT') ||
        activityList.contains('SUPERVISOR_TRACKING') ||
        activityList.contains('SUPERVISOR_MERGING')) {
      return SupervisorScreen(
        empId: empId,
        employeeName: employeeName,
        role: role,
        activities: activityList,
      );
    }

    // Process Planner (check BEFORE GM - has PROCESS_ROUTING activity)
    if (activityList.contains('PROCESS_ROUTING')) {
      return ProcessPlannerScreen(
        empId: empId,
        employeeName: employeeName,
        role: role,
      );
    }

    // GM (check AFTER Process Planner - has GM_VIEW_PRODUCTION activity)
    if (activityList.contains('GM_VIEW_PRODUCTION') ||
        activityList.contains('GM_VIEW_REPORTS') ||
        activityList.contains('GM_VIEW_INVENTORY_ANALYSIS')) {
      return GmWorkspace(
        empId: empId,
        employeeName: employeeName,
        role: role,
        activities: activityList,
      );
    }

    // Inventory Manager
    if (activityList.contains('INVENTORY_VIEW_DASHBOARD') ||
        activityList.contains('INVENTORY_MANAGE_STOCK_LIMITS')) {
      return InventoryManagerScreen(
        empId: empId,
        employeeName: employeeName,
        role: role,
        activities: activityList,
      );
    }

    // No matching activity found - deny access
    return AccessDeniedScreen(
      message: 'Your role does not have permission to access any screens.',
      roleName: role,
      activities: activities,
      setDarkMode: widget.setDarkMode,
    );
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is removed
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryVariant, Color(0xFF062229)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              top: 80,
              left: -60,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.secondary.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.vertical),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Brand header
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.precision_manufacturing,
                            size: 48,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "SMO System",
                          textAlign: TextAlign.center,
                          style: AppTheme.displaySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Sewing Machine Operations",
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 36),
                        // Login card
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(28.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    "Welcome Back",
                                    style: AppTheme.headlineMedium.copyWith(
                                      color: AppTheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Sign in to continue to your workspace",
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  // Employee ID field
                                  TextFormField(
                                    controller: _usernameController,
                                    validator: _validateUsername,
                                    keyboardType: TextInputType.number,
                                    decoration: AppTheme.inputDecoration("Employee ID").copyWith(
                                      prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Password field
                                  TextFormField(
                                    controller: _passwordController,
                                    validator: _validatePassword,
                                    obscureText: _obscurePassword,
                                    decoration: AppTheme.inputDecoration("Password").copyWith(
                                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                          color: AppTheme.onSurfaceVariant,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    onFieldSubmitted: (_) => _isLoading ? null : _performLogin(),
                                  ),
                                  const SizedBox(height: 28),
                                  // Login button
                                  SizedBox(
                                    height: 54,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _performLogin,
                                      style: AppTheme.primaryButtonStyle.copyWith(
                                        elevation: WidgetStateProperty.all(4),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24, height: 24,
                                              child: CircularProgressIndicator(
                                                color: AppTheme.onPrimary,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "Sign In",
                                                  style: AppTheme.labelLarge.copyWith(
                                                    color: AppTheme.onPrimary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(Icons.arrow_forward, size: 20),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Version $appVersion | GramTarang Technologies",
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
