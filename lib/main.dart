import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'core/network/api_client.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/services/service_discovery.dart';
import 'core/widgets/splash_screen.dart';
import 'login_screen.dart';

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
  bool _connectionSuccess = false;
  String _connectionStatus = '';
  Widget? _home;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    Get.put(ServiceDiscoveryService());
    await _restoreSession();
    _checkBackendConnection();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final role = (prefs.getString('ROLE') ?? '').toUpperCase().trim();
    final empId = prefs.getString('EMP_ID');
    final employeeName = prefs.getString('EMPLOYEE_NAME') ?? 'Employee';
    final activities = prefs.getString('ACTIVITIES') ?? '';

    if (empId != null && empId.isNotEmpty && role.isNotEmpty) {
      ApiClient().setEmpId(empId);
      _home = AppRouter.buildHomeForRole(
        role: role,
        empId: empId,
        employeeName: employeeName,
        activities: activities,
        setDarkMode: (_) {},
      );
      return;
    }
    _home = LoginScreen(setDarkMode: (_) {});
  }

  Future<void> _checkBackendConnection() async {
    try {
      final res = await ApiClient().dio.get('/api/health',
          options: Options(receiveTimeout: const Duration(seconds: 45), sendTimeout: const Duration(seconds: 45)));
      if (mounted) setState(() { _connectionSuccess = res.statusCode == 200; _connectionStatus = 'Server is running'; });
    } on DioException catch (e) {
      if (mounted) setState(() {
        _connectionSuccess = false;
        _connectionStatus = switch (e.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout => 'Server waking up. Please wait...',
          DioExceptionType.connectionError => 'Cannot connect to server.',
          _ => 'Connection failed: ${e.message}',
        };
      });
    } catch (e) {
      if (mounted) setState(() { _connectionSuccess = false; _connectionStatus = 'Unexpected error: $e'; });
    }
  }

  void _showConnectionSnackbar(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectionSuccess
          ? CustomSnackbar.showSuccess(context, 'Connected to ${AppConfig.baseUrl}')
          : CustomSnackbar.showError(context, 'Connection issue: $_connectionStatus');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        title: 'SMO App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData,
        home: const SplashScreen(),
      );
    }
    return MaterialApp(
      title: 'SMO App',
      theme: AppTheme.themeData,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: Builder(builder: (context) {
        _showConnectionSnackbar(context);
        return _home ?? LoginScreen(setDarkMode: (_) {});
      }),
    );
  }
}
