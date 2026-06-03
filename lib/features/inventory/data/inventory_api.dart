import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smo_flutter/core/config/app_config.dart';
import 'package:smo_flutter/features/inventory/domain/models/operation_stock_view.dart';
import 'package:smo_flutter/features/inventory/domain/models/stock_limit.dart';

class InventoryApi {
  static String get baseUrl => '${AppConfig.baseUrl}/api/inventory';

  // Get dashboard data
  static Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load dashboard: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching dashboard: $e');
    }
  }

  // Get dashboard data with custom URL (for routing filter)
  static Future<Map<String, dynamic>> getDashboardWithUrl(String path) async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}$path'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load dashboard: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching dashboard: $e');
    }
  }

  // Get all stock limits
  static Future<List<StockLimit>> getAllStockLimits() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stock-limits'));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => StockLimit.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load stock limits');
      }
    } catch (e) {
      throw Exception('Error fetching stock limits: $e');
    }
  }

  // Get stock limit by operation ID
  static Future<StockLimit?> getStockLimit(int operationId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stock-limits/$operationId'));
      
      if (response.statusCode == 200) {
        return StockLimit.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load stock limit');
      }
    } catch (e) {
      throw Exception('Error fetching stock limit: $e');
    }
  }

  // Save stock limit
  static Future<Map<String, dynamic>> saveStockLimit(StockLimit limit) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stock-limits'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(limit.toJson()),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to save stock limit: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error saving stock limit: $e');
    }
  }

  // Delete stock limit
  static Future<Map<String, dynamic>> deleteStockLimit(int operationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/stock-limits/$operationId'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete stock limit');
      }
    } catch (e) {
      throw Exception('Error deleting stock limit: $e');
    }
  }

  // Get operations for dropdown
  static Future<List<Map<String, dynamic>>> getOperations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/operations'));
      
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load operations');
      }
    } catch (e) {
      throw Exception('Error fetching operations: $e');
    }
  }
}
