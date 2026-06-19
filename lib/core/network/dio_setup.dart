import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'dart:developer' as dev;
import '../config/app_config.dart';
import '../security/secure_storage_helper.dart';

/// Centralized Dio setup and configuration
class DioSetup {
  static Dio createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: Duration(seconds: Timeouts.connectionTimeout),
        receiveTimeout: Duration(seconds: Timeouts.receiveTimeout),
        sendTimeout: Duration(seconds: Timeouts.sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add Logging Interceptor
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: true,
        error: true,
        compact: false,
        maxWidth: 120,
        logPrint: (object) => dev.log(object.toString(), name: 'API_LOG'),
      ),
    );

    // Add JWT Token Interceptor - Adds JWT token to all authenticated requests
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorageHelper.getJwtToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            dev.log('[REQUEST] JWT token added to Authorization header', name: 'API_AUTH');
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            dev.log('[AUTH] Unauthorized - Token may have expired', name: 'API_AUTH');
          }
          return handler.next(error);
        },
      ),
    );

    // Add Custom Detailed Logging Interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          dev.log(
            '[REQUEST] ${options.method} ${options.path}\n'
            'Base URL: ${options.baseUrl}\n'
            'Full URL: ${options.uri}\n'
            'Headers: ${options.headers}\n'
            'Query Params: ${options.queryParameters}',
            name: 'API_DETAILED',
          );

          final empId = dio.options.headers['X-EMP-ID'];
          if (empId != null) {
            options.queryParameters[QueryParams.actorEmpId] = empId;
            dev.log('[REQUEST] Added Actor EMP ID: $empId', name: 'API_DETAILED');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          dev.log(
            '[RESPONSE] ${response.statusCode}\n'
            'URL: ${response.requestOptions.uri}\n'
            'Data: ${response.data}',
            name: 'API_DETAILED',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          final errorMessage = _handleError(e);
          dev.log(
            '[ERROR] $errorMessage\n'
            'Type: ${e.type}\n'
            'URL: ${e.requestOptions.uri}\n'
            'Status Code: ${e.response?.statusCode}\n'
            'Response: ${e.response?.data}\n'
            'Error: ${e.error}\n'
            'Stack Trace: ${e.stackTrace}',
            name: 'API_ERROR',
            error: e,
          );
          return handler.next(e);
        },
      ),
    );

    return dio;
  }

  static String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "Connection timed out. Please check your internet.";
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        if (statusCode == 400) return "Bad Request: ${data ?? 'Invalid input'}";
        if (statusCode == 401) return "Unauthorized: Please login again.";
        if (statusCode == 403) return "Forbidden: Access denied.";
        if (statusCode == 404) return "Not Found: Server resource missing.";
        if (statusCode == 500) return "Server Error: Please try again later.";
        return "HTTP Error $statusCode: ${data ?? 'Unknown error'}";
      case DioExceptionType.cancel:
        return "Request cancelled.";
      case DioExceptionType.connectionError:
        return "No internet connection.";
      default:
        return "Something went wrong. Please try again.";
    }
  }
}
