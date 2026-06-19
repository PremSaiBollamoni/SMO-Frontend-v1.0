# 🏭 PALMS - Parallel Assembly Line Management System (Frontend)

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.8.1-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![GetX](https://img.shields.io/badge/GetX-State%20Management-8B5CF6?style=for-the-badge)
![Material Design 3](https://img.shields.io/badge/Material%20Design-3-757575?style=for-the-badge)
![Commits](https://img.shields.io/badge/Commits-461-blue?style=for-the-badge)

**Intelligent garment factory management system with real-time production tracking and role-based workflows**

[Features](#-completed-features) • [Coming Soon](#-coming-soon) • [Architecture](#-architecture) • [Setup](#-getting-started)

**Total Commits:** 461  
**Project Lead:** Prem Sai Bollamoni  
**Tracking Email:** premsai200804@gmail.com

---

## ✅ Completed Features

### 🔐 Authentication & Authorization
- [x] Employee login with temporary QR codes (EMP-TEMP-XXX format)
- [x] Role-based access control (RBAC) with 5 roles: Supervisor, Operator, HR, GM, Process Planner
- [x] Session management with SharedPreferences
- [x] Auto-logout and session recovery

### 👨‍💼 HR & Admin Dashboard
- [x] Employee management (CRUD operations)
- [x] Role management with activity-based permissions
- [x] Attendance tracking with check-in/out via QR codes
- [x] Employee attendance reports
- [x] Shift & breaks management
- [x] Profile management for all users
- [x] Free all QRs button (end-of-shift functionality with auto-checkout)
- [x] Attendance tabs: All | Active | History

### 🏭 Supervisor Module
- [x] Work assignment - QR-based tray assignment to operators
  - Employee QR scan (EMP-TEMP-XXX)
  - Tray QR scan (TRAY-XXX) with quantity input
  - Auto-tray creation on first scan
- [x] Station management
  - Create/edit stations with operation assignment
  - Machine code linking (optional)
  - Station code editing
- [x] Operations & SAM management
  - Create operations with full details (code, name, stage, SAM, target pcs, skill grade)
  - Edit all operation fields
  - Delete operations (long-press)
  - Dynamic stage creation (no fixed list)
  - Search and filter by stage
  - Excel import with smart headers (detects headers anywhere in sheet)
- [x] Active job monitoring
  - Live elapsed time tracking (Stream.periodic)
  - Job completion with tray status management
  - Job status: ON TRACK, OVERDUE, COMPLETED
  - SAM vs actual performance metrics
- [x] Assignment History
  - View all completed jobs
  - Filter by Today/All
  - Efficiency % display (SAM vs actual time)
  - Color-coded performance (green=on-time, orange=over)
- [x] Efficiency Report
  - Overall line efficiency %
  - Per-employee efficiency breakdown
  - Target efficiency: 95%
- [x] Attendance tracking
- [x] Line balancing placeholder

### 🎯 Operations Management
- [x] SAM (Standard Allowed Minutes) management per operation
- [x] Tray-based job assignment (replacing bundle system)
- [x] Multi-stage operations support (27 Sub Assembly + 7 Full Garment = 34 total)
- [x] Sequential operation support
- [x] Skill grade assignment (A+-grade, A-grade, B-grade, C-grade, Helper)
- [x] Target pieces per shift configuration
- [x] Auto operation code generation from operation name

### 📊 Data Management
- [x] Excel import for operations with smart header detection
  - Supports flexible header row placement
  - Auto-creates stations linked to operations
  - Batch operation creation/update
  - Conflict resolution (operation exists = update, new = create)
- [x] Tray lifecycle management (FREE → ASSIGNED → FREE)
- [x] Job assignment with tray quantity tracking
- [x] Real-time job status updates

### 🎨 UI/UX
- [x] Clean Material Design 3 interface
- [x] Responsive layouts for different screen sizes
- [x] Color-coded status indicators
- [x] Tab-based navigation
- [x] Smooth animations and transitions
- [x] Search and filter functionality
- [x] Error handling with user-friendly messages
- [x] Loading states and progress indicators

### 🔄 Database Integration
- [x] RESTful API client with Dio
- [x] Automatic QR mapping resolution
- [x] Attendance record management
- [x] Job assignment persistence
- [x] Tray status tracking

---

## 🚀 Coming Soon

### 📱 Operator Module
- [ ] Personal job dashboard
- [ ] Efficiency tracking
- [ ] Performance metrics
- [ ] Work history

### 📈 Advanced Analytics
- [ ] Daily stock position board
- [ ] Bottleneck detection
- [ ] Pacemaker registry
- [ ] Production loss & shift risk scoring
- [ ] 12 standard PALMS reports

### 🏪 Stock Management (GM Module)
- [ ] WIP (Work In Progress) tracking
- [ ] Stock position management
- [ ] Inventory reports
- [ ] Material allocation

### ✅ Quality Control
- [ ] QC inspector role
- [ ] Defect logging
- [ ] Quality reports
- [ ] Rework tracking

### 🎛️ Advanced Features
- [ ] Shift-wise efficiency tracking
- [ ] Concurrent operation support
- [ ] Dynamic line balancing suggestions
- [ ] Predictive analytics
- [ ] Mobile notifications

---

## 🏗️ Architecture

### State Management
- **GetX** for reactive state management
- GetxController for business logic
- Efficient rebuild optimization

### Clean Architecture
```
lib/
├── features/
│   ├── auth/
│   ├── attendance/
│   ├── hr/
│   ├── supervisor/
│   ├── gm/
│   └── ...
├── core/
│   ├── network/
│   ├── theme/
│   ├── utils/
│   └── widgets/
└── main.dart
```

### Data Flow
- UI Layer (Screens) → Controllers (GetX) → Services (API/Local) → Network Layer (Dio)

---

## 📱 Getting Started

### Prerequisites
- Flutter 3.8.1 or higher
- Dart 3.0 or higher
- Android SDK (API 21+) or iOS SDK
- VS Code or Android Studio

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/PremSaiBollamoni/PALMS-Frontend.git
cd PALMS-Frontend
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Configure backend URL:**
Edit `lib/core/network/api_client.dart` and set your backend URL:
```dart
static const String baseUrl = 'http://your-backend-url:8080';
```

4. **Run the application:**
```bash
flutter run -d <device>
```

### Build APK
```bash
flutter build apk --release
```

---

## 🗄️ Database Schema

### Key Tables
- `employee` - Employee information & credentials
- `role` - User roles with comma-separated activities
- `attendance` - Daily check-in/out records
- `operation` - Manufacturing operations (SAM, skill grade, targets)
- `workstation` - Physical stations linked to operations
- `job_assignment` - Active job assignments with tray tracking
- `tray` - Reusable tray management (FREE/ASSIGNED status)
- `temp_qr_mapping` - Dynamic QR-to-employee mapping for the day

---

## 🔑 Key Concepts

### QR-Based Workflow
1. **Employee Check-in:** Scan EMP-TEMP-XXX QR to verify daily presence
2. **Job Assignment:** Scan TRAY-XXX QR + enter quantity → job created
3. **Job Completion:** Scan same TRAY-XXX → job completed, tray freed
4. **End of Shift:** "Free All QRs" auto-checks out active employees

### Tray Lifecycle
- **FREE** → Available for assignment
- **ASSIGNED** → Currently assigned to employee
- **FREE** → Released after job completion (reusable)

### SAM (Standard Allowed Minutes)
- Time standard per operation (e.g., 0.5 min/piece)
- Used to calculate expected job duration
- Compared against actual elapsed time for efficiency %

### Efficiency Calculation
```
Efficiency = (Expected Time / Actual Time) × 100
Target: 95% or higher
```

---

## 🛠️ Development

### Code Style
- Follow Dart conventions (camelCase for variables, PascalCase for classes)
- Max 200 lines per file (single responsibility)
- One screen = one activity constant in DB
- Import organization: dart → flutter → packages → local

### Git Workflow
```bash
# Create feature branch
git checkout -b feature/feature-name

# Commit changes
git commit -m "feat: description"

# Push to remote
git push origin feature/feature-name

# Create pull request via GitHub
```

---

## 📞 Support & Contact

**Project Lead:** Prem Sai Bollamoni  
**Email:** premsai200804@gmail.com  
**GitHub:** [@PremSaiBollamoni](https://github.com/PremSaiBollamoni)

**Total Commits:** 461

---

## 📄 License

Proprietary - All rights reserved

---

**Last Updated:** June 19, 2026  
**Maintained by:** Prem Sai Bollamoni
