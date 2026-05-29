import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/create_product_request.dart';
import '../models/create_operation_request.dart';
import '../models/create_routing_request.dart';
import '../models/create_routing_step_request.dart';
import '../../domain/models/product_model.dart';
import '../../domain/models/operation_model.dart';
import '../../domain/models/routing_model.dart';
import '../../domain/models/routing_step_model.dart';

/// Process Planner API Service - Handles all process planning API calls
class ProcessPlannerApiService {
  final Dio _dio;

  ProcessPlannerApiService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  // ── Products ──────────────────────────────────────────────────────────────

  Future<List<ProductModel>> fetchProducts() async {
    try {
      final response = await _dio.get('/api/production/products');
      if (response.statusCode == 200) {
        final list = (response.data as List<dynamic>)
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      throw Exception('Failed to fetch products: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createProduct(CreateProductRequest request) async {
    try {
      final response = await _dio.post(
        '/api/production/products',
        data: request.toJson(),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create product: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(int productId) async {
    try {
      final response = await _dio.delete('/api/production/products/$productId');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete product: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── Operations ────────────────────────────────────────────────────────────

  Future<List<OperationModel>> fetchOperations() async {
    try {
      final response = await _dio.get('/api/production/operations');
      if (response.statusCode == 200) {
        final list = (response.data as List<dynamic>)
            .map((e) => OperationModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      throw Exception('Failed to fetch operations: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createOperation(CreateOperationRequest request) async {
    try {
      final response = await _dio.post(
        '/api/production/operations',
        data: request.toJson(),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create operation: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteOperation(int operationId) async {
    try {
      final response = await _dio.delete(
        '/api/production/operations/$operationId',
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete operation: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── Routings ──────────────────────────────────────────────────────────────

  Future<List<RoutingModel>> fetchRoutings() async {
    try {
      final response = await _dio.get('/api/production/routings');
      if (response.statusCode == 200) {
        final list = (response.data as List<dynamic>)
            .map((e) => RoutingModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      throw Exception('Failed to fetch routings: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createRouting(CreateRoutingRequest request) async {
    try {
      final response = await _dio.post(
        '/api/production/routings',
        data: request.toJson(),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create routing: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteRouting(int routingId) async {
    try {
      final response = await _dio.delete('/api/production/routings/$routingId');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete routing: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── Routing Steps ─────────────────────────────────────────────────────────

  Future<List<RoutingStepModel>> fetchRoutingSteps(int routingId) async {
    try {
      final response = await _dio.get(
        '/api/production/routingsteps/routing/$routingId',
      );
      if (response.statusCode == 200) {
        final list = (response.data as List<dynamic>)
            .map((e) => RoutingStepModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      throw Exception('Failed to fetch routing steps: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createRoutingStep(CreateRoutingStepRequest request) async {
    try {
      final response = await _dio.post(
        '/api/production/routingsteps',
        data: request.toJson(),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to create routing step: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteRoutingStep(int routingStepId) async {
    try {
      final response = await _dio.delete(
        '/api/production/routingsteps/$routingStepId',
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete routing step: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── Process Plan Draft ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> submitProcessPlanDraft(
    int productId,
    List<Map<String, dynamic>> steps,
    List<Map<String, dynamic>> edges, {
    String actorEmpId = 'SYSTEM',
  }) async {
    try {
      print('[ProcessPlanAPI] Submitting process plan draft...');
      print('[ProcessPlanAPI] Product ID: $productId');
      print('[ProcessPlanAPI] Steps count: ${steps.length}');
      print('[ProcessPlanAPI] Edges count: ${edges.length}');
      print('[ProcessPlanAPI] Actor Employee ID: $actorEmpId');
      
      final response = await _dio.post(
        '/api/processplan/draft',
        queryParameters: {
          'productId': productId,
          'actorEmpId': actorEmpId,
        },
        data: {
          'steps': steps,
          'edges': edges,
        },
      );
      
      print('[ProcessPlanAPI] Response status: ${response.statusCode}');
      print('[ProcessPlanAPI] Response data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to submit process plan: ${response.statusCode}');
    } catch (e) {
      print('[ProcessPlanAPI] ERROR: $e');
      rethrow;
    }
  }

  // ── Edit-in-place: Insert / Rename within a routing ───────────────────────

  /// Get full process plan (operations + edges) for a routing.
  /// Used to render the live graph preview when editing.
  Future<Map<String, dynamic>> getProcessPlan(int routingId,
      {String actorEmpId = 'SYSTEM'}) async {
    final response = await _dio.get(
      '/api/processplan/$routingId',
      queryParameters: {'actorEmpId': actorEmpId},
    );
    if (response.statusCode == 200 && response.data != null) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Failed to fetch process plan: ${response.statusCode}');
  }

  /// Insert a new operation into a routing. Returns the updated process plan.
  Future<Map<String, dynamic>> insertOperationIntoRouting({
    required int routingId,
    required String position, // 'AFTER' or 'BEFORE' (used in SPLIT_EDGE mode)
    String mode = 'SPLIT_EDGE', // 'SPLIT_EDGE' or 'ADD_BRANCH'
    int? afterOperationId,
    int? beforeOperationId,
    int? mergeTargetOperationId, // for ADD_BRANCH mode
    bool useExisting = false,
    int? existingOperationId,
    String? name,
    String? description,
    int? sequence,
    String? operationType,
    int? stageGroup,
    int? standardTime,
    String actorEmpId = 'SYSTEM',
  }) async {
    final body = <String, dynamic>{
      'mode': mode,
      'position': position,
      if (afterOperationId != null) 'afterOperationId': afterOperationId,
      if (beforeOperationId != null) 'beforeOperationId': beforeOperationId,
      if (mergeTargetOperationId != null) 'mergeTargetOperationId': mergeTargetOperationId,
      'useExisting': useExisting,
      if (existingOperationId != null) 'existingOperationId': existingOperationId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (sequence != null) 'sequence': sequence,
      if (operationType != null) 'operationType': operationType,
      if (stageGroup != null) 'stageGroup': stageGroup,
      if (standardTime != null) 'standardTime': standardTime,
    };
    final response = await _dio.post(
      '/api/processplan/$routingId/insert-operation',
      queryParameters: {'actorEmpId': actorEmpId},
      data: body,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Failed to insert operation: ${response.statusCode}');
  }

  /// Rename an operation within a single routing. Returns updated plan.
  Future<Map<String, dynamic>> renameOperationInRouting({
    required int routingId,
    required int operationId,
    required String newName,
    String? newDescription,
    String actorEmpId = 'SYSTEM',
  }) async {
    final body = <String, dynamic>{
      'operationId': operationId,
      'newName': newName,
      if (newDescription != null) 'newDescription': newDescription,
    };
    final response = await _dio.put(
      '/api/processplan/$routingId/rename-operation',
      queryParameters: {'actorEmpId': actorEmpId},
      data: body,
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Failed to rename operation: ${response.statusCode}');
  }

  /// Remove an operation from a routing's flow (auto-bridges by default).
  Future<Map<String, dynamic>> removeOperationFromRouting({
    required int routingId,
    required int operationId,
    bool autoBridge = true,
    String actorEmpId = 'SYSTEM',
  }) async {
    final response = await _dio.delete(
      '/api/processplan/$routingId/operations/$operationId',
      queryParameters: {
        'autoBridge': autoBridge,
        'actorEmpId': actorEmpId,
      },
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Failed to delete operation: ${response.statusCode}');
  }

  /// Redirect an existing edge to a new target.
  Future<Map<String, dynamic>> reconnectEdge({
    required int routingId,
    required int fromOperationId,
    required int oldToOperationId,
    required int newToOperationId,
    String actorEmpId = 'SYSTEM',
  }) async {
    final body = {
      'fromOperationId': fromOperationId,
      'oldToOperationId': oldToOperationId,
      'newToOperationId': newToOperationId,
    };
    final response = await _dio.post(
      '/api/processplan/$routingId/reconnect',
      queryParameters: {'actorEmpId': actorEmpId},
      data: body,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Failed to reconnect: ${response.statusCode}');
  }

  /// Move an existing operation to a new position in the routing.
  Future<Map<String, dynamic>> moveOperation({
    required int routingId,
    required int operationId,
    required String mode, // 'SPLIT_EDGE', 'ADD_BRANCH', or 'TERMINAL'
    String? position, // 'AFTER' or 'BEFORE'
    int? anchorOperationId,
    int? otherEndOperationId,
    int? mergeTargetOperationId,
    bool skipAutoBridge = false,
    String actorEmpId = 'SYSTEM',
  }) async {
    final body = <String, dynamic>{
      'operationId': operationId,
      'mode': mode,
      if (position != null) 'position': position,
      if (anchorOperationId != null) 'anchorOperationId': anchorOperationId,
      if (otherEndOperationId != null) 'otherEndOperationId': otherEndOperationId,
      if (mergeTargetOperationId != null) 'mergeTargetOperationId': mergeTargetOperationId,
      'skipAutoBridge': skipAutoBridge,
    };
    final response = await _dio.post(
      '/api/processplan/$routingId/move-operation',
      queryParameters: {'actorEmpId': actorEmpId},
      data: body,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Failed to move operation: ${response.statusCode}');
  }

  /// Add a new connection between two existing steps in a routing.
  Future<Map<String, dynamic>> addEdge({
    required int routingId,
    required int fromOperationId,
    required int toOperationId,
    String edgeType = 'sequential',
    String actorEmpId = 'SYSTEM',
  }) async {
    final body = {
      'fromOperationId': fromOperationId,
      'toOperationId': toOperationId,
      'edgeType': edgeType,
    };
    final response = await _dio.post(
      '/api/processplan/$routingId/add-edge',
      queryParameters: {'actorEmpId': actorEmpId},
      data: body,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Failed to add connection: ${response.statusCode}');
  }
}
