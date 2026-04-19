# RakshaPoorvak – Project Folder Structure

This document defines the recommended folder structure for the RakshaPoorvak monorepo. All three applications (Hospital Dashboard, User App, Driver App) share a common backend and documentation.

---

## Root Structure

```
major-project-26/
├── README.md
├── .gitignore
├── docker-compose.raksha-db.yml  # PostgreSQL Docker setup
├── docs/                         # Documentation
│   ├── PROJECT_STRUCTURE.md
│   ├── ENVIRONMENT_SETUP.md
│   ├── CODING_RULES.md
│   ├── PRD.md
│   ├── BACKEND_TECHNICAL_SPEC.md
│   ├── HOSPITAL_DASHBOARD_TECHNICAL_DOC.md
│   ├── USER_APP_TECHNICAL_DOC.md
│   ├── DRIVER_APP_TECHNICAL_DOC.md
│   └── ...
├── seed/                         # Database seed SQL files
├── scripts/                      # Utility scripts (seed-all.sh, etc.)
├── backend/                      # Spring Boot API
├── hospital-dashboard/           # React + Vite (Web)
├── user-app/                     # Flutter (User Mobile)
└── driver-app/                   # Flutter (Driver Mobile)
```

---

## Backend (Spring Boot)

```
backend/
├── pom.xml
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/
│   │   │       └── rakshapoorvak/
│   │   │           ├── RakshaPoorvakApplication.java
│   │   │           ├── config/
│   │   │           │   ├── SecurityConfig.java
│   │   │           │   ├── WebSocketConfig.java      # STOMP/SockJS config
│   │   │           │   └── CorsConfig.java
│   │   │           ├── controller/
│   │   │           │   ├── AuthController.java
│   │   │           │   ├── SosController.java
│   │   │           │   ├── DispatchController.java
│   │   │           │   ├── AmbulanceController.java
│   │   │           │   ├── UserController.java
│   │   │           │   ├── DriverController.java
│   │   │           │   ├── DoctorController.java
│   │   │           │   ├── HospitalController.java
│   │   │           │   ├── TriageController.java
│   │   │           │   ├── LocationController.java
│   │   │           │   ├── NotificationController.java
│   │   │           │   ├── DashboardController.java
│   │   │           │   ├── AnalyticsController.java
│   │   │           │   ├── MapController.java
│   │   │           │   ├── PatientController.java
│   │   │           │   └── HealthController.java
│   │   │           ├── service/
│   │   │           │   ├── AuthService.java
│   │   │           │   ├── SosService.java
│   │   │           │   ├── DispatchService.java
│   │   │           │   ├── AmbulanceService.java
│   │   │           │   ├── DriverService.java
│   │   │           │   ├── DoctorService.java
│   │   │           │   ├── HospitalService.java
│   │   │           │   ├── TriageService.java
│   │   │           │   ├── NotificationService.java
│   │   │           │   ├── LocationService.java
│   │   │           │   ├── DashboardService.java
│   │   │           │   ├── AnalyticsService.java
│   │   │           │   ├── MapService.java
│   │   │           │   ├── PatientService.java
│   │   │           │   ├── UserService.java
│   │   │           │   └── WebSocketBroadcastService.java  # Real-time broadcasts
│   │   │           ├── repository/
│   │   │           │   ├── UserRepository.java
│   │   │           │   ├── SosEventRepository.java
│   │   │           │   ├── AmbulanceRepository.java
│   │   │           │   ├── DriverRepository.java
│   │   │           │   ├── DoctorRepository.java
│   │   │           │   ├── HospitalRepository.java
│   │   │           │   └── ...
│   │   │           ├── model/
│   │   │           │   ├── entity/
│   │   │           │   │   ├── User.java
│   │   │           │   │   ├── Role.java
│   │   │           │   │   ├── SosEvent.java
│   │   │           │   │   ├── Ambulance.java
│   │   │           │   │   ├── Driver.java
│   │   │           │   │   ├── Doctor.java
│   │   │           │   │   ├── Hospital.java
│   │   │           │   │   ├── TriageRecord.java
│   │   │           │   │   ├── Medication.java
│   │   │           │   │   ├── LocationUpdate.java
│   │   │           │   │   ├── Notification.java
│   │   │           │   │   ├── MedicalProfile.java
│   │   │           │   │   ├── EmergencyContact.java
│   │   │           │   │   └── RefreshToken.java
│   │   │           │   └── dto/
│   │   │           │       └── ... (organized by feature)
│   │   │           ├── exception/
│   │   │           │   ├── GlobalExceptionHandler.java
│   │   │           │   └── ... (custom exceptions)
│   │   │           └── security/
│   │   │               ├── JwtAuthenticationFilter.java
│   │   │               ├── JwtUtil.java
│   │   │               └── CustomUserDetailsService.java
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-dev.yml
│   │       └── db/migration/
│   │           ├── V1__init_schema.sql
│   │           ├── V2__add_doctor_specialization_driver_license.sql
│   │           └── V3__link_driver_ambulance.sql
│   └── test/
└── Dockerfile
```

---

## Hospital Dashboard (React + Vite)

```
hospital-dashboard/
├── package.json
├── vite.config.ts
├── tsconfig.json
├── tsconfig.app.json
├── tsconfig.node.json
├── index.html
├── .env.example
│
├── public/
│
└── src/
    ├── main.tsx
    ├── App.tsx
    │
    ├── api/
    │   ├── client.ts              # Axios with interceptors
    │   ├── auth.api.ts
    │   ├── sos.api.ts
    │   ├── dispatch.api.ts
    │   ├── dashboard.api.ts
    │   ├── hospitals.api.ts
    │   ├── ambulances.api.ts
    │   ├── doctors.api.ts
    │   ├── drivers.api.ts
    │   ├── triage.api.ts
    │   ├── analytics.api.ts
    │   ├── notifications.api.ts
    │   ├── patients.api.ts
    │   └── map.api.ts
    │
    ├── components/
    │   ├── common/
    │   │   ├── Badge.tsx
    │   │   ├── Button.tsx
    │   │   ├── Card.tsx
    │   │   ├── DataTable.tsx
    │   │   ├── Input.tsx
    │   │   └── Modal.tsx
    │   ├── layout/
    │   │   ├── Layout.tsx
    │   │   ├── Sidebar.tsx
    │   │   └── Topbar.tsx
    │   ├── dashboard/
    │   │   └── StatCard.tsx
    │   └── sos/
    │       └── StatusTimeline.tsx
    │
    ├── pages/
    │   ├── Login.tsx
    │   ├── Dashboard.tsx
    │   ├── SosMonitor.tsx
    │   ├── SosDetail.tsx
    │   ├── LiveMap.tsx
    │   ├── Ambulances.tsx
    │   ├── Staff.tsx
    │   ├── Analytics.tsx
    │   ├── Notifications.tsx
    │   └── Patients.tsx
    │
    ├── hooks/
    │   ├── useAuth.ts
    │   ├── useHospital.ts
    │   ├── useStompSubscription.ts   # WebSocket subscriptions
    │   ├── useNotificationPolling.ts
    │   └── useLocationNames.ts
    │
    ├── store/
    │   ├── authStore.ts
    │   ├── hospitalStore.ts
    │   ├── notificationStore.ts
    │   └── websocketStore.ts        # STOMP client management
    │
    ├── types/
    │   └── index.ts
    │
    ├── utils/
    │   ├── formatDate.ts
    │   ├── parseStatus.ts
    │   └── geocode.ts
    │
    ├── routes/
    │   └── index.tsx
    │
    └── styles/
        └── index.css
```

---

## User App (Flutter)

```
user-app/
├── pubspec.yaml
├── analysis_options.yaml
│
├── android/
│   └── app/src/main/AndroidManifest.xml
├── lib/
│   ├── main.dart
│   │
│   ├── app/
│   │   ├── app.dart
│   │   └── routes.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── network/
│   │   │   ├── api_client.dart
│   │   │   └── websocket_service.dart    # STOMP WebSocket
│   │   └── utils/
│   │       └── format_date.dart
│   │
│   ├── data/
│   │   ├── api/
│   │   │   ├── auth_api.dart
│   │   │   ├── sos_api.dart
│   │   │   ├── user_api.dart
│   │   │   └── notification_api.dart
│   │   └── models/
│   │       ├── auth_response.dart
│   │       ├── user.dart
│   │       ├── sos_event.dart
│   │       ├── tracking.dart
│   │       └── notification.dart
│   │
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── sos_provider.dart
│   │   └── notification_provider.dart
│   │
│   ├── features/
│   │   ├── auth/presentation/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── home/presentation/
│   │   │   └── home_screen.dart
│   │   ├── sos/presentation/
│   │   │   ├── sos_create_screen.dart
│   │   │   ├── sos_confirm_screen.dart
│   │   │   ├── sos_tracking_screen.dart
│   │   │   └── sos_detail_screen.dart
│   │   ├── history/presentation/
│   │   │   └── history_screen.dart
│   │   ├── profile/presentation/
│   │   │   ├── profile_screen.dart
│   │   │   ├── edit_profile_screen.dart
│   │   │   ├── medical_profile_screen.dart
│   │   │   └── emergency_contacts_screen.dart
│   │   └── notifications/presentation/
│   │       └── notifications_screen.dart
│   │
│   └── shared/widgets/
│       ├── sos_button.dart
│       ├── status_badge.dart
│       └── map_tracking_widget.dart
│
└── test/
```

---

## Driver App (Flutter)

```
driver-app/
├── pubspec.yaml
├── analysis_options.yaml
│
├── android/
│   └── app/src/main/AndroidManifest.xml
├── lib/
│   ├── main.dart
│   │
│   ├── app/
│   │   ├── app.dart
│   │   └── routes.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── network/
│   │   │   ├── api_client.dart
│   │   │   ├── websocket_service.dart    # STOMP WebSocket
│   │   │   └── osrm_client.dart          # Route calculation
│   │   └── utils/
│   │       ├── format_date.dart
│   │       ├── haversine.dart
│   │       └── location_service.dart
│   │
│   ├── data/
│   │   ├── api/
│   │   │   ├── auth_api.dart
│   │   │   ├── dispatch_api.dart
│   │   │   ├── sos_api.dart
│   │   │   ├── driver_api.dart
│   │   │   ├── ambulance_api.dart
│   │   │   ├── triage_api.dart
│   │   │   ├── location_api.dart
│   │   │   └── notification_api.dart
│   │   └── models/
│   │       ├── user.dart
│   │       ├── driver.dart
│   │       ├── sos_event.dart
│   │       ├── tracking.dart
│   │       ├── route_info.dart
│   │       ├── triage_record.dart
│   │       ├── medication.dart
│   │       └── notification.dart
│   │
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── dispatch_provider.dart
│   │   ├── driver_provider.dart
│   │   └── notification_provider.dart
│   │
│   ├── features/
│   │   ├── auth/presentation/
│   │   │   └── login_screen.dart
│   │   ├── home/presentation/
│   │   │   └── home_screen.dart
│   │   ├── dispatch/presentation/
│   │   │   └── request_screen.dart
│   │   ├── case/presentation/
│   │   │   ├── active_case_screen.dart
│   │   │   ├── triage_screen.dart
│   │   │   ├── medications_screen.dart
│   │   │   └── case_complete_screen.dart
│   │   ├── history/presentation/
│   │   │   └── history_screen.dart
│   │   ├── profile/presentation/
│   │   │   └── profile_screen.dart
│   │   └── notifications/presentation/
│   │       └── notifications_screen.dart
│   │
│   └── shared/widgets/
│
└── test/
```

---

## Configuration Files at Root

| File | Purpose |
|------|---------|
| `.gitignore` | Ignore node_modules, build outputs, .env, IDE files |
| `docker-compose.raksha-db.yml` | PostgreSQL container for development |
| `README.md` | Project overview and quick start |

---

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Java classes | PascalCase | `SosEventService` |
| Java packages | lowercase | `com.rakshapoorvak.service` |
| React components | PascalCase | `LiveMap.tsx` |
| React hooks | camelCase, `use` prefix | `useWebSocket` |
| Flutter files | snake_case | `sos_confirmation_screen.dart` |
| Flutter classes | PascalCase | `SosConfirmationScreen` |
| API endpoints | kebab-case | `/api/sos-events` |
| Environment vars | UPPER_SNAKE_CASE | `VITE_API_URL` |

---

## Summary

- **Backend:** Layered architecture (controller → service → repository → entity)
- **Hospital Dashboard:** Feature-based components + pages + API layer
- **User/Driver Apps:** Feature-first structure with `data`, `domain`, `features`, and `core`
- **Shared:** Optional OpenAPI spec and shared types for consistency
