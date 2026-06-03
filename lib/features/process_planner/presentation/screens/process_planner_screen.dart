import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../login_screen.dart';
import '../../../../profile_tab.dart';
import '../controller/process_planner_controller.dart';
import '../widgets/dashboard_view.dart';
import '../widgets/products_view.dart';
import '../widgets/operations_view.dart';
import '../widgets/routings_view.dart';
import '../widgets/routing_steps_view.dart';
import '../widgets/edit_routing_view.dart';
import '../widgets/create_product_dialog.dart';
import '../widgets/create_operation_dialog.dart';
import '../widgets/create_routing_dialog.dart';
import '../widgets/create_routing_step_dialog.dart';

/// Process Planner Screen - Clean Architecture Implementation
class ProcessPlannerScreen extends StatefulWidget {
  final String empId;
  final String employeeName;
  final String role;

  const ProcessPlannerScreen({
    super.key,
    required this.empId,
    required this.employeeName,
    required this.role,
  });

  @override
  State<ProcessPlannerScreen> createState() => _ProcessPlannerScreenState();
}

class _ProcessPlannerScreenState extends State<ProcessPlannerScreen> {
  final ProcessPlannerController _controller = Get.put(ProcessPlannerController());

  @override
  void initState() {
    super.initState();
    _loadSessionAndData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadSessionAndData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final employeeName = prefs.getString('EMPLOYEE_NAME') ?? widget.employeeName;
      final empId = prefs.getString('EMP_ID') ?? widget.empId;

      ApiClient().setEmpId(empId);
      _controller.initialize(empId, employeeName);
      await _controller.refreshAll();
    } catch (e) {
      debugPrint('Session load error: $e');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _showCreateProductDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => CreateProductDialog(
        onCreateProduct: ({
          required int productId,
          required String name,
          required String category,
          required String status,
        }) async {
          final success = await _controller.createProduct(
            productId: productId, name: name, category: category, status: status,
          );
          if (!mounted) return success;
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product created successfully'), backgroundColor: Colors.green),
            );
          }
          return success;
        },
      ),
    );
  }

  Future<void> _showCreateOperationDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => CreateOperationDialog(
        onCreateOperation: ({
          required int operationId,
          required String name,
          required String description,
          required int sequence,
          required int standardTime,
          required bool isParallel,
          required bool mergePoint,
          required int stageGroup,
        }) async {
          final success = await _controller.createOperation(
            operationId: operationId, name: name, sequence: sequence,
            standardTime: standardTime, isParallel: isParallel, mergePoint: mergePoint,
          );
          if (!mounted) return success;
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Operation created successfully'), backgroundColor: Colors.green),
            );
          }
          return success;
        },
      ),
    );
  }

  Future<void> _showCreateRoutingDialog() async {
    await _controller.fetchProducts();
    if (_controller.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a product first'), backgroundColor: Colors.red),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => CreateRoutingDialog(
        onCreateRouting: ({
          required int routingId,
          required int productId,
          required int version,
          required String status,
          required String approvalStatus,
        }) async {
          final success = await _controller.createRouting(
            routingId: routingId, productId: productId, version: version,
            status: status, approvalStatus: approvalStatus,
          );
          if (!mounted) return success;
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Routing created successfully'), backgroundColor: Colors.green),
            );
          }
          return success;
        },
      ),
    );
  }

  Future<void> _showCreateRoutingStepDialog() async {
    await Future.wait([_controller.fetchRoutings(), _controller.fetchOperations()]);
    if (_controller.routings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a routing first'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_controller.operations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create an operation first'), backgroundColor: Colors.red),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => CreateRoutingStepDialog(
        onCreateRoutingStep: ({
          required int routingStepId,
          required int routingId,
          required int operationId,
          required int stageGroup,
        }) async {
          final success = await _controller.createRoutingStep(
            routingStepId: routingStepId, routingId: routingId,
            operationId: operationId, stageGroup: stageGroup,
          );
          if (!mounted) return success;
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Routing step created successfully'), backgroundColor: Colors.green),
            );
          }
          return success;
        },
      ),
    );
  }

  List<FeatureGroup> _buildGroups() {
    final planning = <FeatureCard>[
      FeatureCard(
        icon: Icons.dashboard_outlined,
        label: 'New Process Plan',
        screen: DashboardView(),
        color: AppTheme.primary,
      ),
      FeatureCard(
        icon: Icons.category_outlined,
        label: 'Products',
        screen: const ProductsView(),
        color: AppTheme.secondary,
        fab: FloatingActionButton(
          onPressed: () => _showCreateProductDialog(),
          child: const Icon(Icons.add),
        ),
      ),
      FeatureCard(
        icon: Icons.settings_outlined,
        label: 'Operations',
        screen: const OperationsView(),
        color: AppTheme.tertiary,
        fab: FloatingActionButton(
          onPressed: () => _showCreateOperationDialog(),
          child: const Icon(Icons.add),
        ),
      ),
      FeatureCard(
        icon: Icons.route_outlined,
        label: 'Routings',
        screen: const RoutingsView(),
        color: AppTheme.info,
        fab: FloatingActionButton(
          onPressed: () => _showCreateRoutingDialog(),
          child: const Icon(Icons.add),
        ),
      ),
      FeatureCard(
        icon: Icons.linear_scale_outlined,
        label: 'Routing Steps',
        screen: const RoutingStepsView(),
        color: AppTheme.primary,
        fab: FloatingActionButton(
          onPressed: () => _showCreateRoutingStepDialog(),
          child: const Icon(Icons.add),
        ),
      ),
      FeatureCard(
        icon: Icons.edit_outlined,
        label: 'Edit Routing',
        screen: EditRoutingView(),
        color: AppTheme.secondary,
      ),
    ];

    final account = <FeatureCard>[
      FeatureCard(
        icon: Icons.person_outline,
        label: 'My Profile',
        screen: ProfileTab(empId: widget.empId.trim()),
        color: AppTheme.onSurfaceVariant,
      ),
    ];

    return [
      FeatureGroup(title: 'Process Planning', cards: planning),
      FeatureGroup(title: 'Account', cards: account),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Process Planner',
      employeeName: widget.employeeName,
      empId: widget.empId,
      role: widget.role,
      roleIcon: Icons.account_tree_outlined,
      groups: _buildGroups(),
      onLogout: _logout,
    );
  }
}

