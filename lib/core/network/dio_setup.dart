import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../security/secure_storage_helper.dart';

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

    // Add Logging Interceptor - Only in debug mode
    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: false,
          responseHeader: false,
          error: true,
          compact: false,
          maxWidth: 120,
          logPrint: (object) => dev.log(object.toString(), name: 'API_LOG'),
        ),
      );
    }

    // Add JWT Token Interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorageHelper.getJwtToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            dev.log('[REQUEST] JWT token added', name: 'API_AUTH');
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await SecureStorageHelper.clearAllTokens();
            dev.log('[AUTH] Session expired - Token cleared', name: 'API_AUTH');
          }
          return handler.next(error);
        },
      ),
    );

    // Add Custom Detailed Logging - Only in debug mode
    if (kDebugMode) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            dev.log('[REQUEST] ${options.method} ${options.path}', name: 'API_DETAILED');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            dev.log('[RESPONSE] ${response.statusCode} - ${response.requestOptions.path}', name: 'API_DETAILED');
            return handler.next(response);
          },
          onError: (error, handler) {
            dev.log('[ERROR] ${error.message}', name: 'API_ERROR');
            return handler.next(error);
          },
        ),
      );
    }

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
