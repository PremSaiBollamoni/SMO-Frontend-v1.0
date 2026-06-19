# 🏭 PALMS - Parallel Assembly Line Management System

<div align="center">

<img src="https://img.shields.io/badge/Flutter-3.8.1-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter"/>
<img src="https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat-square&logo=dart&logoColor=white" alt="Dart"/>
<img src="https://img.shields.io/badge/Spring%20Boot-3.0+-6DB33F?style=flat-square&logo=spring-boot&logoColor=white" alt="Spring Boot"/>
<img src="https://img.shields.io/badge/MySQL-8.0-4479A1?style=flat-square&logo=mysql&logoColor=white" alt="MySQL"/>
<img src="https://img.shields.io/badge/Commits-1000+-success?style=flat-square" alt="Commits"/>

**Smart garment factory management system with QR-based workflow automation**

[Features](#-features) • [Architecture](#-architecture) • [Setup](#-setup) • [API](#-api-endpoints) • [Database](#-database)

</div>

---

## 📋 Overview

PALMS is a comprehensive **Parallel Assembly Line Management System** designed to revolutionize garment factory operations. Built with Flutter (cross-platform) and Spring Boot (scalable backend), it provides real-time production tracking, QR-based job assignment, and intelligent efficiency metrics.

### 🎯 Key Metrics
- **Platforms:** Android, iOS, Windows, Web
- **Total Commits:** 1000+
- **Backend APIs:** 40+
- **Database Tables:** 15+
- **Supported Roles:** 5 (HR, Supervisor, Operator, GM, Process Planner)

---

## ✨ Features

### 🔐 Authentication & Role Management
✅ Multi-role employee login system  
✅ Role-based access control (RBAC)  
✅ Activity-based permission mapping  
✅ Session management & auto-logout  

### 👥 HR & Employee Management
✅ Complete employee CRUD operations  
✅ Role assignment & management  
✅ Employee profile management  
✅ Shift & break scheduling  
✅ Attendance reports & analytics  

### 🎯 Supervisor Features
| Feature | Description |
|---------|-------------|
| **Work Assignment** | QR-based tray assignment to employees |
| **Active Jobs** | Real-time job monitoring with SAM tracking |
| **Station Management** | Create/edit stations with operation linking |
| **Operations & SAM** | Standard Allowed Minutes configuration |
| **Assignment History** | View completed jobs with efficiency metrics |
| **Efficiency Report** | Line performance analytics (Target: 95%) |
| **Attendance Tracking** | Check-in/out with QR codes |

### 📊 Operations Management
✅ **34 Operations Total:**
- 27 Sub Assembly operations
- 7 Full Garment operations

✅ **Operation Features:**
- SAM (Standard Allowed Minutes) per piece
- Skill grade assignment (A+, A, B, C, Helper)
- Target pieces per shift
- Stage/zone-based organization
- Sequential operation support
- Excel batch import with smart headers

### 💼 GM (General Manager) Features
✅ WIP tracking  
✅ Stock management  
✅ Production reports  
✅ Strategic monitoring  

### 📱 Operator Features
✅ Personal job dashboard  
✅ Real-time work updates  
✅ Performance tracking  
✅ Work history  

### 🔄 QR-Based Workflow
```
Employee QR (EMP-TEMP-XXX)
        ↓
    Check-in
        ↓
Tray QR (TRAY-XXX)
        ↓
Job Assignment (Auto-tray creation)
        ↓
Job Completion (Tray freed & reusable)
        ↓
Check-out (Free All QRs auto-checkout)
```

### 📈 Key Metrics
- **Efficiency Calculation:** (Expected Time / Actual Time) × 100
- **Target Efficiency:** 95% or higher
- **Live Tracking:** Stream-based elapsed time updates
- **Performance Colors:** Green (On-Time) | Orange (Overdue)

---

## 🏗️ Architecture

### Frontend Stack
```
Flutter 3.8.1
    ├── GetX (State Management)
    ├── Dio (HTTP Client)
    ├── Material Design 3
    └── Clean Architecture
```

### Backend Stack
```
Spring Boot 3.0+
    ├── JPA/Hibernate
    ├── MySQL 8.0
    ├── Apache POI (Excel)
    └── RESTful API
```

### Project Structure
```
📁 Frontend (Flutter)
├── lib/
│   ├── features/
│   │   ├── auth/
│   │   ├── attendance/
│   │   ├── hr/
│   │   ├── supervisor/
│   │   └── gm/
│   ├── core/
│   │   ├── network/
│   │   ├── theme/
│   │   └── utils/
│   └── main.dart

📁 Backend (Spring Boot)
├── src/main/java/com/cutm/smo/
│   ├── controller/
│   ├── service/
│   ├── repository/
│   ├── models/
│   └── dto/
└── pom.xml
```

---

## 🗄️ Database Schema

### Core Tables
| Table | Purpose | Records |
|-------|---------|---------|
| `employee` | Employee info & credentials | 1000+ |
| `role` | User roles with activities | 5 |
| `operation` | Manufacturing operations | 34 |
| `workstation` | Physical stations | 50+ |
| `job_assignment` | Active & completed jobs | Unlimited |
| `tray` | Reusable physical trays | Variable |
| `attendance` | Daily check-in/out records | Unlimited |
| `temp_qr_mapping` | Daily QR-to-employee mapping | Variable |

### Entity Relationships
```
Employee ──→ Role
    ↓
Attendance (Daily)
    ↓
Job Assignment ──→ Operation, Workstation, Tray
    ↓
Job Status (IN_PROGRESS / COMPLETED)
```

---

## 📡 API Endpoints

### Authentication
```http
POST   /api/auth/login              # Employee login
POST   /api/auth/logout             # Logout
GET    /api/auth/verify             # Verify session
```

### HR Operations
```http
GET    /api/hr/employees            # List all employees
POST   /api/hr/employees            # Create employee
PUT    /api/hr/employees/{id}       # Update employee
DELETE /api/hr/employees/{id}       # Delete employee
```

### Operations & SAM
```http
GET    /api/hr/operations           # List operations
POST   /api/hr/operations           # Create operation
PATCH  /api/hr/operations/{id}/sam  # Update SAM/target
DELETE /api/hr/operations/{id}      # Deactivate
POST   /api/hr/import/upload        # Excel import
```

### Stations
```http
GET    /api/hr/workstations        # List stations
POST   /api/hr/workstations        # Create station
PATCH  /api/hr/workstations/{id}   # Update station
DELETE /api/hr/workstations/{id}   # Delete station
```

### Jobs & Tracking
```http
GET    /api/supervisor/jobs        # List all jobs
POST   /api/supervisor/jobs/scan   # Scan tray & assign/complete
GET    /api/supervisor/jobs/active # Active jobs at station
```

### Attendance
```http
GET    /api/attendance/today       # Today's records
POST   /api/attendance/check-in    # Manual check-in
POST   /api/attendance/check-out   # Manual check-out
POST   /api/attendance/free-all-qrs # End-of-shift auto-checkout
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.8.1+
- Dart 3.0+
- Java 17+
- Maven 3.8+
- MySQL 8.0+
- Android SDK (API 21+) or iOS SDK

### Frontend Setup

```bash
# Clone repository
git clone https://github.com/PremSaiBollamoni/PALMS-Frontend.git
cd PALMS-Frontend

# Get dependencies
flutter pub get

# Configure backend URL
# Edit lib/core/network/api_client.dart
# Set: static const String baseUrl = 'http://your-backend:8080';

# Run app
flutter run -d <device>

# Build APK
flutter build apk --release
```

### Backend Setup

```bash
# Clone repository
git clone https://github.com/PremSaiBollamoni/PALMS-Backend.git
cd PALMS-Backend

# Create database
mysql -u root -p
CREATE DATABASE PALMSV1;

# Update application.properties
# Set: spring.datasource.url=jdbc:mysql://localhost:3306/PALMSV1
# Set: spring.datasource.password=your-password

# Build & run
mvn clean package
java -jar target/palms-backend-1.0.0.jar
```

---

## 📊 Excel Import Format

### Operations Import
```
| Stage | Operation Name | SAM | Target | Skill Grade | Station Number |
|-------|----------------|-----|--------|-------------|-----------------|
| Sub Asm | Hemming | 0.5 | 100 | A-grade | ST-01 |
| Sub Asm | Button | 0.3 | 150 | B-grade | ST-02 |
```

**Features:**
- ✅ Smart header detection (finds headers anywhere)
- ✅ Auto-creates stations if needed
- ✅ Batch create/update operations
- ✅ Conflict resolution (exists = update, new = create)

---

## 🔑 Key Concepts

### SAM (Standard Allowed Minutes)
Industry standard for time per piece:
```
Job Duration = SAM × Quantity
Example: 0.5 min/piece × 100 pieces = 50 minutes
```

### Efficiency Scoring
```
Efficiency % = (Expected Time / Actual Time) × 100

Example:
- Expected: 50 minutes (SAM-based)
- Actual: 48 minutes
- Efficiency: (50/48) × 100 = 104.2% ✅ GOOD
```

### Tray Lifecycle
```
FREE → ASSIGNED → IN_PROGRESS → COMPLETED → FREE (reusable)
```

### Multi-Role System
Single employee can have multiple roles:
- Role Picker screen after login
- Switch roles dynamically
- Role-based dashboard customization

---

## 🛠️ Development

### Code Standards
- **Max File Size:** 200 lines per file
- **Naming:** camelCase (vars), PascalCase (classes)
- **Architecture:** Clean Architecture + GetX
- **Testing:** Unit tests for business logic

### Git Workflow
```bash
# Create feature branch
git checkout -b feature/feature-name

# Commit with meaningful messages
git commit -m "feat: description"

# Push & create PR
git push origin feature/feature-name
```

### Testing
```bash
# Run Flutter tests
flutter test

# Run backend tests
mvn test
```

---

## 📱 Roles & Features Matrix

| Feature | HR | Supervisor | Operator | GM | Planner |
|---------|----|----|----|----|---------|
| Employee Management | ✅ | ❌ | ❌ | ❌ | ❌ |
| Role Assignment | ✅ | ❌ | ❌ | ❌ | ❌ |
| Attendance | ✅ | ✅ | ✅ | ❌ | ❌ |
| Work Assignment | ❌ | ✅ | ❌ | ❌ | ❌ |
| Job Tracking | ❌ | ✅ | ✅ | ❌ | ❌ |
| Efficiency Report | ❌ | ✅ | ❌ | ❌ | ❌ |
| WIP & Stock | ❌ | ❌ | ❌ | ✅ | ❌ |
| Process Planning | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## 📞 Contact & Support

**Project Lead:** Prem Sai Bollamoni  
**Email:** premsai200804@gmail.com  
**GitHub:** [@PremSaiBollamoni](https://github.com/PremSaiBollamoni)

**Repositories:**
- 🎨 Frontend: https://github.com/PremSaiBollamoni/PALMS-Frontend
- 🔧 Backend: https://github.com/PremSaiBollamoni/PALMS-Backend

---

## 📄 License

Proprietary - All rights reserved © 2026

---

**Last Updated:** June 19, 2026  
**Total Commits:** 1000+  
**Contributors:** Prem Sai Bollamoni
