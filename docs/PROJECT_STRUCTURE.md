# RakshaPoorvak – Project Folder Structure

This document defines the recommended folder structure for the RakshaPoorvak monorepo. All three applications (Hospital Dashboard, User App, Driver App) share a common backend and documentation.

---

## Root Structure

```
major-project-26/
├── README.md
├── .gitignore
├── docs/
│   ├── PROJECT_STRUCTURE.md      # This file
│   ├── ENVIRONMENT_SETUP.md
│   ├── CODING_RULES.md
│   └── PRD.md
│
├── backend/                      # Spring Boot API
├── hospital-dashboard/           # React + Vite (Web)
├── user-app/                     # Flutter (User Mobile)
├── driver-app/                   # Flutter (Driver Mobile)
└── shared/                       # Shared types, constants, OpenAPI spec (optional)
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
│   │   │           │   ├── WebSocketConfig.java
│   │   │           │   └── CorsConfig.java
│   │   │           ├── controller/
│   │   │           │   ├── AuthController.java
│   │   │           │   ├── SosController.java
│   │   │           │   ├── AmbulanceController.java
│   │   │           │   ├── UserController.java
│   │   │           │   ├── DriverController.java
│   │   │           │   ├── HospitalController.java
│   │   │           │   ├── TriageController.java
│   │   │           │   └── WebSocketController.java
│   │   │           ├── service/
│   │   │           │   ├── AuthService.java
│   │   │           │   ├── SosService.java
│   │   │           │   ├── DispatchService.java
│   │   │           │   ├── AmbulanceService.java
│   │   │           │   ├── TriageService.java
│   │   │           │   ├── NotificationService.java
│   │   │           │   └── LocationService.java
│   │   │           ├── repository/
│   │   │           │   ├── UserRepository.java
│   │   │           │   ├── SosEventRepository.java
│   │   │           │   ├── AmbulanceRepository.java
│   │   │           │   ├── DriverRepository.java
│   │   │           │   └── ...
│   │   │           ├── model/
│   │   │           │   ├── entity/
│   │   │           │   │   ├── User.java
│   │   │           │   │   ├── SosEvent.java
│   │   │           │   │   ├── Ambulance.java
│   │   │           │   │   ├── Driver.java
│   │   │           │   │   └── TriageRecord.java
│   │   │           │   └── dto/
│   │   │           │       ├── SosEventDto.java
│   │   │           │       ├── LocationDto.java
│   │   │           │       └── ...
│   │   │           ├── mapper/
│   │   │           ├── exception/
│   │   │           │   ├── GlobalExceptionHandler.java
│   │   │           │   └── CustomExceptions.java
│   │   │           ├── security/
│   │   │           │   ├── JwtFilter.java
│   │   │           │   └── JwtUtil.java
│   │   │           └── websocket/
│   │   │               └── LocationBroadcastHandler.java
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-dev.yml
│   │       ├── application-prod.yml
│   │       └── db/
│   │           └── migration/          # Flyway/Liquibase
│   │               └── V1__init.sql
│   └── test/
│       └── java/
│           └── com/
│               └── rakshapoorvak/
│                   ├── controller/
│                   ├── service/
│                   └── integration/
└── Dockerfile
```

---

## Hospital Dashboard (React + Vite)

```
hospital-dashboard/
├── package.json
├── vite.config.ts
├── tsconfig.json
├── index.html
├── .env.example
├── .env.local
│
├── public/
│   └── favicon.ico
│
└── src/
    ├── main.tsx
    ├── App.tsx
    ├── vite-env.d.ts
    │
    ├── api/
    │   ├── client.ts              # Axios/fetch setup
    │   ├── auth.api.ts
    │   ├── sos.api.ts
    │   ├── ambulance.api.ts
    │   └── websocket.ts
    │
    ├── components/
    │   ├── common/                # Reusable UI
    │   │   ├── Button/
    │   │   ├── Card/
    │   │   ├── Modal/
    │   │   └── Map/
    │   ├── layout/
    │   │   ├── Header/
    │   │   ├── Sidebar/
    │   │   └── Layout.tsx
    │   ├── dashboard/
    │   │   ├── CommandDashboard.tsx
    │   │   ├── SosMonitor.tsx
    │   │   ├── LiveMap.tsx
    │   │   ├── AmbulanceList.tsx
    │   │   └── DoctorAssignment.tsx
    │   ├── triage/
    │   │   ├── VitalsView.tsx
    │   │   └── InTransitRecords.tsx
    │   └── analytics/
    │       └── ResponseTimeChart.tsx
    │
    ├── pages/
    │   ├── Login.tsx
    │   ├── Dashboard.tsx
    │   ├── SosDetail.tsx
    │   ├── AmbulanceTracking.tsx
    │   └── Analytics.tsx
    │
    ├── hooks/
    │   ├── useAuth.ts
    │   ├── useWebSocket.ts
    │   └── useSosEvents.ts
    │
    ├── store/                     # Zustand/Redux (if used)
    │   └── authStore.ts
    │
    ├── types/
    │   └── index.ts
    │
    ├── utils/
    │   └── helpers.ts
    │
    ├── routes/
    │   └── index.tsx
    │
    └── styles/
        └── global.css
```

---

## User App (Flutter)

```
user-app/
├── pubspec.yaml
├── analysis_options.yaml
├── .env.example
│
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   │
│   ├── app/
│   │   ├── app.dart
│   │   └── routes.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   ├── theme/
│   │   ├── utils/
│   │   └── errors/
│   │
│   ├── data/
│   │   ├── api/
│   │   │   ├── api_client.dart
│   │   │   ├── auth_api.dart
│   │   │   ├── sos_api.dart
│   │   │   └── websocket_client.dart
│   │   ├── models/
│   │   │   ├── user.dart
│   │   │   ├── sos_event.dart
│   │   │   └── ambulance.dart
│   │   └── repositories/
│   │
│   ├── domain/
│   │   ├── entities/
│   │   └── repositories/          # Abstract interfaces
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── presentation/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   └── ...
│   │   ├── sos/
│   │   │   ├── presentation/
│   │   │   │   ├── sos_button_screen.dart
│   │   │   │   ├── sos_confirmation_screen.dart
│   │   │   │   └── sos_active_screen.dart
│   │   │   └── ...
│   │   ├── tracking/
│   │   │   └── presentation/
│   │   │       └── live_tracking_screen.dart
│   │   ├── history/
│   │   │   └── presentation/
│   │   │       └── emergency_history_screen.dart
│   │   └── profile/
│   │       └── presentation/
│   │           └── profile_screen.dart
│   │
│   └── shared/
│       └── widgets/
│           ├── map_widget.dart
│           └── status_badge.dart
│
└── test/
```

---

## Driver App (Flutter)

```
driver-app/
├── pubspec.yaml
├── analysis_options.yaml
├── .env.example
│
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   │
│   ├── app/
│   │   ├── app.dart
│   │   └── routes.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   ├── theme/
│   │   ├── utils/
│   │   └── errors/
│   │
│   ├── data/
│   │   ├── api/
│   │   │   ├── api_client.dart
│   │   │   ├── auth_api.dart
│   │   │   ├── sos_api.dart
│   │   │   ├── triage_api.dart
│   │   │   ├── location_api.dart
│   │   │   └── websocket_client.dart
│   │   ├── models/
│   │   └── repositories/
│   │
│   ├── domain/
│   │   ├── entities/
│   │   └── repositories/
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   └── presentation/
│   │   │       └── login_screen.dart
│   │   ├── dispatch/
│   │   │   └── presentation/
│   │   │       ├── incoming_request_screen.dart
│   │   │       └── assigned_case_screen.dart
│   │   ├── navigation/
│   │   │   └── presentation/
│   │   │       └── navigation_screen.dart
│   │   ├── triage/
│   │   │   └── presentation/
│   │   │       ├── vitals_entry_screen.dart
│   │   │       └── medications_screen.dart
│   │   ├── status/
│   │   │   └── presentation/
│   │   │       └── status_update_screen.dart
│   │   └── communication/
│   │       └── presentation/
│   │           └── video_call_screen.dart
│   │
│   └── shared/
│       └── widgets/
│           ├── map_widget.dart
│           └── route_display.dart
│
└── test/
```

---

## Shared (Optional)

```
shared/
├── openapi/
│   └── rakshapoorvak-api.yaml    # OpenAPI 3.0 spec for backend
├── types/
│   └── sos_status.ts              # Shared enums (if codegen used)
└── README.md
```

---

## Configuration Files at Root

| File | Purpose |
|------|---------|
| `.gitignore` | Ignore node_modules, build outputs, .env, IDE files |
| `docker-compose.yml` | Optional: Run PostgreSQL + Backend in containers |
| `Makefile` | Optional: Common commands (run backend, dashboard, etc.) |

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
