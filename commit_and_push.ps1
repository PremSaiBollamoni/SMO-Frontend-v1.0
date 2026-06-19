# Configure git user email for tracking
git config user.email "premsai200804@gmail.com"

# Backend - Attendance Service (QR freeing logic)
git add "backend/src/main/java/com/cutm/smo/services/AttendanceService.java"
git commit -m "feat: auto-checkout employees on free-all-qrs endpoint"

# Backend - Attendance Repository (findByAttDateAndStatus)
git add "backend/src/main/java/com/cutm/smo/repositories/AttendanceRepository.java"
git commit -m "feat: add findByAttDateAndStatus repository method"

# Backend - TempQrMapping Repository (findByQrTokenAndMappingDate)
git add "backend/src/main/java/com/cutm/smo/repositories/TempQrMappingRepository.java"
git commit -m "feat: add findByQrTokenAndMappingDate method without freed filter"

# Frontend - Attendance Screen (UI redesign with tabs)
git add "lib/features/attendance/presentation/screens/attendance_screen.dart"
git commit -m "refactor: redesign attendance screen with All/Active/History tabs"

# Frontend - Assignment History Screen (new)
git add "lib/features/supervisor/presentation/screens/assignment_history_screen.dart"
git commit -m "feat: add assignment history screen for supervisor"

# Frontend - Efficiency Report Screen (new)
git add "lib/features/supervisor/presentation/screens/efficiency_screen.dart"
git commit -m "feat: add efficiency report screen for supervisor"

# Frontend - Supervisor Screen (integrate new screens)
git add "lib/features/supervisor/presentation/screens/supervisor_screen.dart"
git commit -m "feat: integrate assignment history and efficiency screens"

# Frontend - README (comprehensive update)
git add "README.md"
git commit -m "docs: update frontend README with complete PALMS feature list"

# Backend - README (comprehensive update)
git add "backend/README.md"
git commit -m "docs: update backend README with API and architecture details"

# All other modified files as a cleanup
git add -A
git commit -m "chore: cleanup and project structure updates"

# Push to remote
Write-Host "Pushing commits to remote repository..." -ForegroundColor Cyan
git push -u origin main

Write-Host "All commits pushed successfully!" -ForegroundColor Green
Write-Host "Tracked by: premsai200804@gmail.com" -ForegroundColor Yellow
Write-Host ""
git log --oneline -10
