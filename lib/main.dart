import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

// Core imports
import 'core/network/api_client.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/services/service_discovery.dart';

// Feature imports
import 'login_screen.dart';
import 'features/hr/presentation/screens/hr_dashboard_screen.dart';
import 'features/operator/presentation/screens/operator_screen.dart';
import 'features/store/presentation/screens/store_screen.dart';
import 'qc_workspace.dart';
import 'purchase_workspace.dart';
import 'features/supervisor/presentation/screens/supervisor_screen.dart';
import 'gm_workspace.dart';
import 'features/process_planner/presentation/screens/process_planner_screen.dart';
import 'access_denied_screen.dart';

// Current app version — update this when releasing a new build
const String kAppVersion = '1.0';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  String _connectionStatus = 'Checking server connection...';
  bool _connectionSuccess = false;
  Widget? _home;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    debugPrint('Initializing app...');
    
    // Initialize GetX service locator
    Get.put(ServiceDiscoveryService());
    
    await _loadThemePreference();
    debugPrint('Theme loaded');
    
    // Discover backend service
    await _discoverBackendService();
    
    await _restoreSession();
    debugPrint('Session restored, home: ${_home?.runtimeType}');

    // Start connection check but don't block on it
    _checkBackendConnection();

    // Minimum splash screen display time (1.5 seconds)
    await Future.delayed(const Duration(milliseconds: 1500));

    debugPrint('Setting isLoading to false');
    setState(() => _isLoading = false);
  }

  Future<void> _discoverBackendService() async {
    setState(() {
      _connectionStatus = 'Discovering SMO backend service...';
    });
    
    // Service discovery disabled - using only deployed URL
    setState(() {
      _connectionStatus = 'Using deployed URL: ${AppConfig.baseUrl}';
    });
    debugPrint('[Main] Using deployed URL: ${AppConfig.baseUrl}');
    
    /*
    try {
      final discoveryService = Get.find<ServiceDiscoveryService>();
      final backendUrl = await discoveryService.discoverBackend();
      
      if (backendUrl != null) {
        AppConfig.setBaseUrl(backendUrl);
        setState(() {
          _connectionStatus = 'Backend discovered at $backendUrl';
        });
        debugPrint('[Main] Backend discovered: $backendUrl');
      } else {
        setState(() {
          _connectionStatus = 'Using fallback URL: ${AppConfig.baseUrl}';
        });
        debugPrint('[Main] No backend discovered, using fallback');
      }
    } catch (e) {
      setState(() {
        _connectionStatus = 'Discovery failed, using fallback URL';
      });
      debugPrint('[Main] Discovery error: $e');
    }
    */
  }

  Future<void> _checkBackendConnection() async {
    try {
      // Use a longer timeout for the health check (45 seconds) for Render cold start
      debugPrint('[Main] Attempting to connect to: ${AppConfig.baseUrl}/api/health');
      debugPrint('[Main] Base URL: ${AppConfig.baseUrl}');
      debugPrint('[Main] Full URL: ${AppConfig.baseUrl}/api/health');
      
      final res = await ApiClient().dio.get(
        '/api/health',
        options: Options(
          receiveTimeout: const Duration(seconds: 45),
          sendTimeout: const Duration(seconds: 45),
        ),
      );
      debugPrint('[Main] Health check response: ${res.statusCode}');
      debugPrint('[Main] Response data: ${res.data}');
      
      if (res.statusCode == 200) {
        setState(() {
          _connectionStatus = 'Server is running';
          _connectionSuccess = true;
        });
        debugPrint('[Main] Connection successful');
      } else {
        setState(() {
          _connectionStatus = 'Server returned error: ${res.statusCode}';
          _connectionSuccess = false;
        });
        debugPrint('[Main] Server error: ${res.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('[Main] DioException: ${e.type} - ${e.message}');
      debugPrint('[Main] Exception details: $e');
      debugPrint('[Main] Status code: ${e.response?.statusCode}');
      debugPrint('[Main] Response: ${e.response?.data}');
      debugPrint('[Main] Error: ${e.error}');
      
      setState(() {
        _connectionSuccess = false;
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            _connectionStatus =
                'Server is waking up (Render free tier). Please wait...';
            break;
          case DioExceptionType.connectionError:
            _connectionStatus =
                'Cannot connect to server. Please check your network.';
            debugPrint('[Main] Connection error: ${e.message}');
            break;
          case DioExceptionType.badResponse:
            _connectionStatus = 'Server error: ${e.response?.statusCode}';
            debugPrint('[Main] Bad response: ${e.response?.statusCode}');
            break;
          case DioExceptionType.cancel:
            _connectionStatus = 'Request was cancelled.';
            break;
          default:
            _connectionStatus = 'Connection failed: ${e.message}';
        }
      });
    } catch (e) {
      debugPrint('[Main] Unexpected error: $e');
      setState(() {
        _connectionStatus = 'Unexpected error: $e';
        _connectionSuccess = false;
      });
    }
  }

  Future<void> _loadThemePreference() async {
    // Light mode only — no dark theme
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final role = (prefs.getString('ROLE') ?? '').toUpperCase().trim();
    final empId = prefs.getString('EMP_ID');
    final employeeName = prefs.getString('EMPLOYEE_NAME') ?? 'Employee';
    final activities = prefs.getString('ACTIVITIES') ?? '';

    if (empId != null && empId.isNotEmpty && role.isNotEmpty) {
      ApiClient().setEmpId(empId);
      _home = _buildHomeForRole(role, empId, employeeName, activities);
      return;
    }
    _home = LoginScreen(setDarkMode: setDarkMode);
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
        setDarkMode: setDarkMode,
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
      return HrDashboardScreen(setDarkMode: setDarkMode);
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

    // Supervisor
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

    // GM
    if (activityList.contains('PP_APPROVE') ||
        activityList.contains('PP_VIEW_ALL')) {
      return GmWorkspace(empId: empId, employeeName: employeeName, role: role, activities: activityList);
    }

    // Process Planner
    if (activityList.contains('PP_SUBMIT') ||
        activityList.contains('PP_APPROVE')) {
      return ProcessPlannerScreen(
        empId: empId,
        employeeName: employeeName,
        role: role,
      );
    }

    // No matching activity found - deny access
    return AccessDeniedScreen(
      message: 'Your role does not have permission to access any screens.',
      roleName: role,
      activities: activities,
      setDarkMode: setDarkMode,
    );
  }

  void setDarkMode(bool isDarkMode) {
    // Dark mode removed — light only
  }

  void _showConnectionSnackbar(BuildContext context) {
    // Show snackbar with connection result
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_connectionSuccess) {
        CustomSnackbar.showSuccess(
          context,
          'Server is running, Connected to ${AppConfig.baseUrl}',
        );
      } else {
        CustomSnackbar.showError(
          context,
          'Connection issue: $_connectionStatus',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        title: 'SMO App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData,
        home: Scaffold(
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
                  top: -50, right: -40,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40, left: -50,
                  child: Container(
                    width: 180, height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.secondary.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                // Center content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo badge
                      Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.precision_manufacturing,
                          size: 60,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'SMO System',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sewing Machine Operations',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 56),
                      SizedBox(
                        width: 32, height: 32,
                        child: CircularProgressIndicator(
                          color: Colors.white.withValues(alpha: 0.9),
                          strokeWidth: 3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Footer
                Positioned(
                  bottom: 32,
                  left: 0, right: 0,
                  child: Center(
                    child: Text(
                      'Developed for GramTarang Technologies',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'SMO App',
      theme: AppTheme.themeData,
      themeMode: ThemeMode.light,
      home: Builder(
        builder: (context) {
          _showConnectionSnackbar(context);
          return _home ?? LoginScreen(setDarkMode: setDarkMode);
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
