import 'package:dio/dio.dart';

/// Extracts a human-readable error message from any exception.
/// Works with DioException (HTTP errors) and generic exceptions.
/// Never shows raw technical strings to the user.
class ApiErrorHelper {
  /// Returns a clean, user-friendly error message.
  static String getMessage(dynamic error) {
    if (error is DioException) {
      return _fromDio(error);
    }
    // Generic exception — strip class name if present
    final raw = error.toString();
    if (raw.contains('DioException') || raw.contains('DioError')) {
      return _parseFallback(raw);
    }
    // If it already looks like a clean message (no stack trace, no class names)
    if (!raw.contains('Exception:') && !raw.contains('Error:') && raw.length < 200) {
      return raw;
    }
    return 'Something went wrong. Please try again.';
  }

  static String _fromDio(DioException e) {
    // 1. Try to extract message from response body first
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        // Try common message fields
        final msg = data['message'] ?? data['error'] ?? data['detail'] ?? data['msg'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return _clean(msg.toString());
        }
        // Spring validation errors often come as { "errors": [...] }
        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          return _clean(errors.first.toString());
        }
      }
      if (data is String && data.trim().isNotEmpty && data.length < 300) {
        // Sometimes backend sends plain string
        if (!data.contains('<html') && !data.contains('<!DOCTYPE')) {
          return _clean(data);
        }
      }
    }

    // 2. Fall back to status-code-based messages
    final status = e.response?.statusCode;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet and try again.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to server. Please check your internet connection.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badResponse:
        return _fromStatusCode(status);
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  static String _fromStatusCode(int? status) {
    switch (status) {
      case 400:
        return 'Invalid input. Please check the details and try again.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested record was not found.';
      case 409:
        return 'This record already exists. Please use a different value.';
      case 422:
        return 'Validation failed. Please check all fields and try again.';
      case 500:
        return 'Server error. Please try again in a moment.';
      case 503:
        return 'Server is temporarily unavailable. Please try again later.';
      default:
        if (status != null) {
          return 'Request failed (error $status). Please try again.';
        }
        return 'Something went wrong. Please try again.';
    }
  }

  static String _parseFallback(String raw) {
    // Try to extract status code from raw string like "DioException [bad response]: 409"
    final match = RegExp(r'(\d{3})').firstMatch(raw);
    if (match != null) {
      final code = int.tryParse(match.group(1) ?? '');
      if (code != null && code >= 400) {
        return _fromStatusCode(code);
      }
    }
    return 'Something went wrong. Please try again.';
  }

  /// Remove technical prefixes from backend messages
  static String _clean(String msg) {
    // Remove common Spring/Java prefixes
    var clean = msg
        .replaceAll(RegExp(r'^(Error:|Exception:|RuntimeException:)\s*'), '')
        .trim();
    // Capitalize first letter
    if (clean.isNotEmpty) {
      clean = clean[0].toUpperCase() + clean.substring(1);
    }
    // Add period if missing
    if (clean.isNotEmpty && !clean.endsWith('.') && !clean.endsWith('!') && !clean.endsWith('?')) {
      clean = '$clean.';
    }
    return clean;
  }
}
