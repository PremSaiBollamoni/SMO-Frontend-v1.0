# Script to commit and push all remaining files one at a time
# Frontend repo: c:\Users\HP\SMOBZAV2 -> SMO-Frontend-v1.0.git
# Backend repo: c:\Users\HP\SMOBZAV2\backend -> SMO-Backedn-v1.0.git

$ErrorActionPreference = "Stop"

function CommitPush-Frontend {
    param([string]$file, [string]$msg)
    Write-Host "[FRONTEND] $file" -ForegroundColor Cyan
    git add $file
    git commit -m $msg
    git push origin main
    Write-Host "  [OK]" -ForegroundColor Green
}

function CommitPush-Backend {
    param([string]$file, [string]$msg)
    Write-Host "[BACKEND] $file" -ForegroundColor Yellow
    git -C backend add $file
    git -C backend commit -m $msg
    git -C backend push origin main
    Write-Host "  [OK]" -ForegroundColor Green
}

Write-Host "========================================" -ForegroundColor Magenta
Write-Host "COMMITTING ALL REMAINING FILES" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

# ============================================================
# FRONTEND FILES (16 remaining)
# ============================================================
Write-Host "`n--- FRONTEND REPO ---" -ForegroundColor Cyan

CommitPush-Frontend "lib/core/config/app_config.dart" "config: update backend IP to 192.168.1.11"
CommitPush-Frontend "lib/features/gm/presentation/widgets/approved_process_plans_view.dart" "feat: GM approved process plans view with graph visualization"
CommitPush-Frontend "lib/features/process_planner/presentation/widgets/approved_process_plans_view.dart" "feat: process planner approved plans view"
CommitPush-Frontend "lib/features/process_planner/presentation/widgets/dashboard_view.dart" "feat: process planner dashboard view updates"
CommitPush-Frontend "lib/features/process_planner/presentation/widgets/workflow_graph/workflow_graph_builder.dart" "feat: workflow graph builder with parallel paths and merge points"
CommitPush-Frontend "lib/features/supervisor/presentation/controllers/merging_controller.dart" "feat: merging controller with comprehensive logging"
CommitPush-Frontend "lib/features/supervisor/presentation/controllers/tracking_controller.dart" "feat: tracking controller with two-phase workflow logging"
CommitPush-Frontend "lib/features/supervisor/presentation/screens/supervisor_screen.dart" "feat: supervisor screen with process plan graph integration"
CommitPush-Frontend "lib/features/supervisor/presentation/widgets/workflow_monitoring_view.dart" "feat: workflow monitoring view for supervisor"
CommitPush-Frontend "lib/features/supervisor/presentation/widgets/merging_widget.dart" "feat: merging widget for combining trays at merge points"
CommitPush-Frontend "lib/features/supervisor/presentation/widgets/operation_status_dialog.dart" "feat: operation status dialog with QR assign, tracking, merging buttons"
CommitPush-Frontend "lib/features/supervisor/presentation/widgets/operation_status_screen.dart" "feat: operation status screen for detailed operation view"

# Skip non-code files that shouldn't be in repo
# .claude/ - IDE config
# Process Plan for GTG.xlsx - test data
# reset_db.sql - local script
# test_process_plan_3paths.xlsx - test data

# ============================================================
# BACKEND FILES (68 remaining)
# ============================================================
Write-Host "`n--- BACKEND REPO ---" -ForegroundColor Yellow

CommitPush-Backend ".gitattributes" "chore: add gitattributes for line ending normalization"
CommitPush-Backend "Dockerfile" "chore: add Dockerfile for containerized deployment"
CommitPush-Backend "README.md" "docs: comprehensive backend README with API documentation"
CommitPush-Backend "cleanup_all_test_data.sql" "chore: add SQL script to cleanup all test data"
CommitPush-Backend "cleanup_tracking_data.sql" "chore: add SQL script to cleanup tracking data"
CommitPush-Backend "create_test_employees.sql" "chore: add SQL script to create test employees"
CommitPush-Backend "fix_wip_schema.sql" "fix: SQL script to fix WIP schema"
CommitPush-Backend "fix_wiptracking_schema.sql" "fix: SQL script to fix wiptracking AUTO_INCREMENT"
CommitPush-Backend "mvnw" "chore: add Maven wrapper for consistent builds"
CommitPush-Backend "mvnw.cmd" "chore: add Maven wrapper CMD for Windows"
CommitPush-Backend "render.yaml" "chore: add Render.com deployment configuration"
CommitPush-Backend "src/main/java/com/cutm/smo/controllers/DiscoveryController.java" "feat: service discovery controller for auto-detection"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/CreateEmployeeRequest.java" "feat: DTO for employee creation request"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/CreateRoleRequest.java" "feat: DTO for role creation request"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/EmployeeDto.java" "feat: employee data transfer object"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/EmployeeExportDto.java" "feat: employee export DTO for data export"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/HrDashboardResponse.java" "feat: HR dashboard response DTO"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/HrProfileResponse.java" "feat: HR profile response DTO"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/LoginRequest.java" "feat: login request DTO"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/LoginResponse.java" "feat: login response DTO with role info"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/MergingRequest.java" "feat: merging request DTO for bin merge operations"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/NodeMetricsResponse.java" "feat: node metrics response DTO for workflow monitoring"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/ProcessPlanDraftRequest.java" "feat: process plan draft request DTO with edges support"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/ProcessPlanRequest.java" "feat: process plan request DTO"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/ProcessPlanResponse.java" "feat: process plan response DTO with operations and edges"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/ProcessPlanStepRequest.java" "feat: process plan step request DTO"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/QrAssignmentRequest.java" "feat: QR assignment request DTO with operationId field"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/RoleDto.java" "feat: role data transfer object"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/TempQrScanRequest.java" "feat: temp QR scan request DTO"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/TempQrScanResponse.java" "feat: temp QR scan response DTO"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/TrackingRequest.java" "feat: tracking request DTO with auto-detect operationId"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/UpdateHrProfileRequest.java" "feat: update HR profile request DTO"
CommitPush-Backend "src/main/java/com/cutm/smo/dto/WorkflowEdge.java" "feat: workflow edge DTO for routing graph"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/BinAssignmentHistoryRepository.java" "feat: bin assignment history repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/BinMergeHistoryRepository.java" "feat: bin merge history repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/BinRepository.java" "feat: bin repository with findByOrderId and node metrics queries"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/BomRepository.java" "feat: BOM repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/BundleRepository.java" "feat: bundle repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/ButtonsRepository.java" "feat: buttons repository for master data"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/EmployeeInfoRepository.java" "feat: employee info repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/EmployeeLoginRepository.java" "feat: employee login repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/EmployeeRepository.java" "feat: employee repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/GarmentRepository.java" "feat: garment repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/GrnItemsRepository.java" "feat: GRN items repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/GrnRepository.java" "feat: GRN repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/InventoryStockRepository.java" "feat: inventory stock repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/ItemRepository.java" "feat: item repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/LabelRepository.java" "feat: label repository for master data"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/MachineRepository.java" "feat: machine repository for master data"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/MergeBinRepository.java" "feat: merge bin repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/OperationRepository.java" "feat: operation repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/PackagingRepository.java" "feat: packaging repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/PoItemsRepository.java" "feat: PO items repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/ProductRepository.java" "feat: product repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/PurchaseOrderRepository.java" "feat: purchase order repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/QcRepository.java" "feat: QC repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/QrEventRepository.java" "feat: QR event repository for audit trail"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/RoleRepository.java" "feat: role repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/RoutingEdgeRepository.java" "feat: routing edge repository for parallel path lookup"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/RoutingRepository.java" "feat: routing repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/RoutingStepRepository.java" "feat: routing step repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/StockMovementRepository.java" "feat: stock movement repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/StyleRepository.java" "feat: style repository for master data"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/StyleVariantRepository.java" "feat: style variant repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/TempActiveAssignmentRepository.java" "feat: temp active assignment repository for two-phase tracking"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/TempAssignmentLogRepository.java" "feat: temp assignment log repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/TempBinMergeRepository.java" "feat: temp bin merge repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/ThreadsRepository.java" "feat: threads repository for master data"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/VendorRepository.java" "feat: vendor repository"
CommitPush-Backend "src/main/java/com/cutm/smo/repositories/WipTrackingRepository.java" "feat: WIP tracking repository"
CommitPush-Backend "src/main/java/com/cutm/smo/validation/OperationValidator.java" "feat: operation validator for process plan validation"
CommitPush-Backend "src/main/resources/db/migration/V1__Fix_WipTracking_AutoIncrement.sql" "fix: database migration for wiptracking AUTO_INCREMENT"
CommitPush-Backend "src/test/java/com/cutm/smo/SmoApplicationTests.java" "test: add Spring Boot application context test"
CommitPush-Backend "test_end_to_end.sh" "test: add end-to-end test script for backend validation"

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "ALL COMMITS AND PUSHES COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
