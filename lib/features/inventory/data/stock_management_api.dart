import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smo_flutter/core/config/app_config.dart';

class StockManagementApi {
  static Future<List<Map<String, dynamic>>> getAllRawMaterials() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/stock/raw-materials'),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load raw materials');
    }
  }

  static Future<Map<String, dynamic>> getRawMaterialById(int id) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/stock/raw-materials/$id'),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load material');
    }
  }

  static Future<List<Map<String, dynamic>>> getLowStockMaterials() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/stock/raw-materials/low-stock'),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load low stock materials');
    }
  }

  static Future<Map<String, dynamic>> addRawMaterial(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/stock/raw-materials'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> receiveStock(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/stock/receive'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> issueStock(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/stock/issue'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> adjustStock(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/stock/adjust'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    
    return json.decode(response.body);
  }

  static Future<List<Map<String, dynamic>>> getMaterialMovements(int materialId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/stock/movements/raw-material/$materialId'),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load movements');
    }
  }

  static Future<List<Map<String, dynamic>>> getRecentMovements({int limit = 50}) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/stock/movements/recent?limit=$limit'),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load recent movements');
    }
  }
}
