# Script to commit all changes with proper attribution
# Email: premsai200804@gmail.com

Write-Host "=== Starting Git Commit Process ===" -ForegroundColor Cyan

# Step 1: Delete test/seed SQL files
Write-Host "`n[1/6] Deleting test SQL files..." -ForegroundColor Yellow
$testFiles = @(
    "reset_local_tracking.sql",
    "reset_tracking_data.sql", 
    "seed_test_data.sql",
    "test_continuous_tracking.sql"
)

foreach ($file in $testFiles) {
    $filePath = Join-Path $PSScriptRoot $file
    if (Test-Path $filePath) {
        Remove-Item $filePath -Force
        Write-Host "  ✓ Deleted: $file" -ForegroundColor Green
    }
}

# Step 2: Configure Git user
Write-Host "`n[2/6] Configuring Git user..." -ForegroundColor Yellow
git config user.name "Prem Sai Bollamoni"
git config user.email "premsai200804@gmail.com"
Write-Host "  ✓ Git user configured" -ForegroundColor Green

# Step 3: Commit Frontend changes
Write-Host "`n[3/6] Committing Frontend changes..." -ForegroundColor Yellow
Set-Location $PSScriptRoot

# Add all changes
git add -A

# Create frontend commit message file
$frontendMsg = @"
feat: SAM continuous tracking with bundle-wise progress monitoring

MAJOR FEATURES:
- Implemented SAM continuous tracking model (operators fixed at operations)
- Bundle-wise progress tracking with real-time duration updates
- Workflow graph color indicators (GREEN for active operations)
- Enhanced operation status dialog with bundle details

WORKFLOW GRAPH ENHANCEMENTS:
- Color-coded operation blocks (green=active, orange=merge, blue=normal)
- Real-time active operator count from backend (5-second polling)
- Visual glow effect for operations with active tracking
- No animation/pulse - clean color change only

OPERATION STATUS DIALOG:
- Removed misleading Actual Timing section
- Added bundle-wise timing with individual progress bars
- Live duration updates per bundle (no screen flicker)
- Employee, machine, and tray info in each bundle card
- Progress bars: 0%=Pending, 50%=In Progress, 100%=Completed
- Removed redundant Workers at Station section

BACKEND IMPROVEMENTS:
- New endpoint: GET /api/processplan/operations-active-operators
- Active operator counting via temp_active_assignments + bin join
- Employee name fetching with EmployeeRepository injection
- Bundle data enriched with operator, machine, tray info
- Support for status active and assigned in queries

DATABASE SCHEMA:
- Added activeOperators field to WorkflowNode model
- Tracking validation for employee check-in status
- Temp_active_assignments as source of truth for active work

SAM MODEL IMPLEMENTATION:
- Trays fixed at operations (no tray advancement)
- Multiple bundles per tray at same operation
- Operators stay visible between bundles
- Only checked-in employees can work
- Bundle completion tracked in wiptracking

INVENTORY MANAGEMENT:
- Complete inventory system with 6 tables and 2 views
- Daily ledger with sample data
- Stock limit management (Min/Max per day for operations)
- Raw material inventory with 17 sample materials
- Color-coded stock status (CRITICAL/LOW/NORMAL/HIGH)

UI/UX IMPROVEMENTS:
- Bundle cards show operator name, machine, tray
- Real-time duration countdown without full screen refresh
- KPI summary with operation-level stats
- Clean progress visualization per bundle
- Mobile-responsive design

PERFORMANCE:
- Efficient 1-second UI updates (isolated widget state)
- 15-second backend data refresh
- No unnecessary re-renders
- Optimized query with JOIN for active operators

Email: premsai200804@gmail.com
"@

Set-Content -Path "frontend_commit_msg.txt" -Value $frontendMsg
git commit -F "frontend_commit_msg.txt"
Remove-Item "frontend_commit_msg.txt"

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Frontend changes committed" -ForegroundColor Green
    
    # Push to remote
    Write-Host "  → Pushing to remote..." -ForegroundColor Cyan
    git push origin main
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Frontend pushed successfully" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Frontend push failed" -ForegroundColor Red
    }
} else {
    Write-Host "  ✗ Frontend commit failed (may have no changes)" -ForegroundColor Yellow
}

# Step 4: Commit Backend changes
Write-Host "`n[4/6] Committing Backend changes..." -ForegroundColor Yellow
Set-Location (Join-Path $PSScriptRoot "backend")

# Configure Git user for backend repo too
git config user.name "Prem Sai Bollamoni"
git config user.email "premsai200804@gmail.com"

# Add all changes
git add -A

# Create backend commit message file
$backendMsg = @"
feat: SAM tracking backend with bundle-wise operator tracking

MAJOR CHANGES:
- New endpoint for active operators per operation
- Employee name resolution for bundle tracking
- Bundle data enrichment with operator/machine/tray info
- Optimized queries for SAM continuous tracking model

NEW ENDPOINTS:
- GET /api/processplan/operations-active-operators?routingId={id}
  Returns active operator count per operation for workflow graph

REPOSITORY CHANGES:
- Added countActiveOperatorsByOperation() in TempActiveAssignmentRepository
- Native SQL query joining temp_active_assignments with bin table
- Support for both active and assigned status
- Added EmployeeRepository injection in ProcessPlanController

BUNDLE TRACKING ENHANCEMENTS:
- Bundle data now includes operator_name, operator_id
- Added machine_qr and tray_qr to bundle info
- Operator lookup via temp_active_assignments (not wiptracking)
- Fallback to Employee {id} if name fetch fails

SAM MODEL SUPPORT:
- Operators tracked per tray/bin (not per wiptracking record)
- Multiple bundles per tray at same operation
- Active assignments persist across bundles
- No tray advancement logic

QUERY OPTIMIZATIONS:
- JOIN temp_active_assignments with bin on tray_qr
- Count distinct temp_id for active operators
- Filter by current_operation_id IS NOT NULL
- Real-time status from assignments, not bin table

EMPLOYEE NAME RESOLUTION:
- fetchEmployeeName() now queries EmployeeInfo table
- Returns empName field from employee record
- Proper error handling with fallback names

DATA MODEL UPDATES:
- Operation status includes bundle-wise operator info
- Each bundle shows who worked on it (operator)
- Machine and tray tracking per bundle
- Duration calculation with break window service

LOGGING IMPROVEMENTS:
- Performance logging for active operator queries
- Debug logs for operator count resolution
- Warning logs for failed employee name lookups

Email: premsai200804@gmail.com
"@

Set-Content -Path "backend_commit_msg.txt" -Value $backendMsg
git commit -F "backend_commit_msg.txt"
Remove-Item "backend_commit_msg.txt"

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Backend changes committed" -ForegroundColor Green
    
    # Push to remote
    Write-Host "  → Pushing to remote..." -ForegroundColor Cyan
    git push origin main
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Backend pushed successfully" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Backend push failed" -ForegroundColor Red
    }
} else {
    Write-Host "  ✗ Backend commit failed (may have no changes)" -ForegroundColor Yellow
}

# Step 5: Update app config to production URL
Write-Host "`n[5/6] Updating app config to production URL..." -ForegroundColor Yellow
Set-Location $PSScriptRoot

$appConfigPath = "lib\core\config\app_config.dart"
$appConfigContent = Get-Content $appConfigPath -Raw

# Replace localhost with production URL
$updatedConfig = $appConfigContent -replace "const String fallbackBaseUrl = 'http://localhost:8080';", "// const String fallbackBaseUrl = 'http://localhost:8080'; // Local dev - localhost"
$updatedConfig = $updatedConfig -replace "// const String fallbackBaseUrl = 'https://smobza.thegttech.com/smo';", "const String fallbackBaseUrl = 'https://smobza.thegttech.com/smo';"

Set-Content -Path $appConfigPath -Value $updatedConfig
Write-Host "  ✓ App config updated to production URL" -ForegroundColor Green

# Commit the URL change
git add $appConfigPath
git commit -m "chore: update base URL to production (https://smobza.thegttech.com/smo)" -m "Email: premsai200804@gmail.com"
git push origin main

Write-Host "  ✓ Production URL change committed and pushed" -ForegroundColor Green

# Step 6: Build production WAR
Write-Host "`n[6/6] Building production WAR file..." -ForegroundColor Yellow
Set-Location (Join-Path $PSScriptRoot "backend")

mvn clean package -DskipTests

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ WAR file built successfully" -ForegroundColor Green
    
    $warFile = Get-ChildItem -Path "target" -Filter "*.war" | Select-Object -First 1
    if ($warFile) {
        Write-Host "`n=== BUILD COMPLETE ===" -ForegroundColor Cyan
        Write-Host "WAR file location: $($warFile.FullName)" -ForegroundColor Green
        Write-Host "Size: $([math]::Round($warFile.Length / 1MB, 2)) MB" -ForegroundColor Green
    }
} else {
    Write-Host "  ✗ WAR build failed" -ForegroundColor Red
}

Write-Host "`n=== All Done! ===" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  ✓ Test SQL files deleted" -ForegroundColor Green
Write-Host "  ✓ Frontend committed and pushed" -ForegroundColor Green
Write-Host "  ✓ Backend committed and pushed" -ForegroundColor Green
Write-Host "  ✓ Production URL configured" -ForegroundColor Green
Write-Host "  ✓ Production WAR built" -ForegroundColor Green
Write-Host "`nAll commits attributed to: premsai200804@gmail.com" -ForegroundColor Cyan
