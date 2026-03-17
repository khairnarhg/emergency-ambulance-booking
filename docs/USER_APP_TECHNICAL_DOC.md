# RakshaPoorvak User App – Technical Documentation

**Component:** User Mobile Application (Android)
**Version:** 1.0
**Last Updated:** March 2026

---

## Table of Contents

1. [Overview](#1-overview)
2. [Tech Stack & Dependencies](#2-tech-stack--dependencies)
3. [Project Structure](#3-project-structure)
4. [Getting Started](#4-getting-started)
5. [Architecture](#5-architecture)
6. [Configuration](#6-configuration)
7. [Design System](#7-design-system)
8. [Data Models](#8-data-models)
9. [State Management (Riverpod)](#9-state-management-riverpod)
10. [API Layer](#10-api-layer)
11. [Routing & Navigation](#11-routing--navigation)
12. [Screens – Detailed Reference](#12-screens--detailed-reference)
13. [Shared Widgets](#13-shared-widgets)
14. [SOS Flow – End-to-End](#14-sos-flow--end-to-end)
15. [Live Tracking & Map](#15-live-tracking--map)
16. [Animations](#16-animations)
17. [Location & Permissions](#17-location--permissions)
18. [Error Handling](#18-error-handling)
19. [Test Credentials](#19-test-credentials)
20. [Common Tasks for New Developers](#20-common-tasks-for-new-developers)

---

## 1. Overview

The RakshaPoorvak User App is a **Flutter Android application** for citizens and patients to request emergency ambulance services. It is one of three client applications in the RakshaPoorvak system, alongside the Hospital Dashboard (React) and Driver App (Flutter).

### What This App Does

- **One-tap SOS** — instantly request an ambulance with auto-detected GPS location
- **Live ambulance tracking** — see ambulance position on OpenStreetMap, ETA countdown, route polyline
- **SOS status timeline** — real-time status updates from `CREATED` through `COMPLETED`
- **Driver communication** — call the assigned driver directly from the tracking screen
- **Emergency history** — view all past SOS requests with details
- **Medical profile** — store blood group, allergies, and conditions (auto-used during triage)
- **Emergency contacts** — manage contacts the system can notify
- **Notifications** — receive status updates for every SOS event

### Out of Scope (Current Phase)

- Video/audio consultation with doctor
- iOS-specific builds (Android only)
- WebSocket real-time push (polling-based in Phase 1)
- Dark theme
- Multi-language support

### System Context

```
User App (Flutter Android)
        │
        │ REST API (JSON over HTTP)
        │ Bearer JWT auth
        ▼
RakshaPoorvak Backend (Spring Boot)
        │
        ├── PostgreSQL (data)
        ├── Hospital Dashboard (React)
        └── Driver App (Flutter Android)
```

---

## 2. Tech Stack & Dependencies

### Core

| Package | Version | Purpose |
|---------|---------|---------|
| Flutter SDK | 3.41.4 | Cross-platform UI framework |
| Dart SDK | 3.x | Language (null-safety enabled) |
| `flutter_riverpod` | 2.6.1 | State management (providers + notifiers) |
| `go_router` | 14.6.3 | Declarative routing with redirects |
| `dio` | 5.7.0 | HTTP client with interceptors |

### Storage

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_secure_storage` | 9.2.4 | Encrypted JWT storage (Keystore/Keychain) |
| `shared_preferences` | 2.3.4 | Simple key-value preferences |

### Maps & Location

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_map` | 7.0.2 | OpenStreetMap tiles, markers, polylines |
| `latlong2` | 0.9.1 | LatLng types for flutter_map |
| `geolocator` | 13.0.2 | GPS coordinates, permission flow |
| `permission_handler` | 11.3.1 | Runtime permission requests |

### UI & UX

| Package | Version | Purpose |
|---------|---------|---------|
| `google_fonts` | 6.2.1 | Inter font family |
| `shimmer` | 3.0.0 | Skeleton loading states |
| `url_launcher` | 6.3.1 | Open phone dialer (`tel:`) |
| `intl` | 0.19.0 | Date/time formatting |

### `pubspec.yaml` (abridged)

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  go_router: ^14.6.3
  dio: ^5.7.0
  flutter_secure_storage: ^9.2.4
  flutter_map: ^7.0.2
  latlong2: ^0.9.1
  geolocator: ^13.0.2
  permission_handler: ^11.3.1
  google_fonts: ^6.2.1
  shimmer: ^3.0.0
  url_launcher: ^6.3.1
  intl: ^0.19.0
```

---

## 3. Project Structure

```
user-app/
├── pubspec.yaml
├── analysis_options.yaml
├── .env.example
├── android/
│   └── app/
│       ├── build.gradle.kts        # minSdk=21, applicationId
│       └── src/main/
│           └── AndroidManifest.xml # INTERNET, LOCATION, CALL permissions
├── lib/
│   ├── main.dart                   # Entry point – ProviderScope, orientation lock
│   ├── app/
│   │   ├── app.dart                # MaterialApp.router + AppTheme
│   │   └── routes.dart             # GoRouter config + ShellRoute + bottom nav
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart  # Base URL, storage keys, status strings, poll interval
│   │   ├── theme/
│   │   │   └── app_theme.dart      # AppColors + AppTheme (Material 3)
│   │   ├── network/
│   │   │   └── api_client.dart     # Dio singleton, auth interceptor, 401 refresh
│   │   └── utils/
│   │       └── format_date.dart    # formatDateTime, formatDate, timeAgo
│   ├── data/
│   │   ├── api/
│   │   │   ├── auth_api.dart       # login, register, logout, getMe
│   │   │   ├── sos_api.dart        # createSos, updateSos, getSos, getTracking, cancel
│   │   │   ├── user_api.dart       # profile, medical profile, emergency contacts
│   │   │   └── notification_api.dart  # list, unreadCount, markRead, markAllRead
│   │   ├── models/
│   │   │   ├── auth_response.dart  # AuthResponse, login/register response shape
│   │   │   ├── user.dart           # UserSummary, UserProfile, MedicalProfile, EmergencyContact
│   │   │   ├── sos_event.dart      # SosEvent (full DTO + helpers isActive, isCancellable)
│   │   │   ├── tracking.dart       # TrackingInfo + LocationPoint
│   │   │   └── notification.dart   # AppNotification
│   │   └── repositories/           # (reserved for future use)
│   ├── providers/
│   │   ├── auth_provider.dart      # AuthNotifier (login, register, logout, persist)
│   │   ├── sos_provider.dart       # ActiveSosNotifier, sosHistoryProvider, trackingProvider
│   │   └── notification_provider.dart  # UnreadCountNotifier + notificationsProvider
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
│   └── shared/widgets/
│       ├── sos_button.dart          # Animated SOS button (pulse + haptic)
│       ├── status_badge.dart        # StatusBadge, CriticalityBadge, SosStatusTimeline
│       └── map_tracking_widget.dart # FlutterMap with patient + ambulance markers
└── test/
    └── widget_test.dart
```

---

## 4. Getting Started

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter SDK | 3.41.4 (stable) |
| Dart SDK | 3.x |
| Android Studio / VS Code | Latest |
| Android Emulator | API 24+ recommended (min SDK 21) |
| Backend running | `http://10.0.2.2:8080` (emulator) |

### Setup

```bash
# 1. Install dependencies
cd user-app
flutter pub get

# 2. Connect an Android device or start the emulator

# 3. Make sure the backend is running
cd ../backend && mvn spring-boot:run

# 4. Seed the database (if first run)
cd .. && ./scripts/seed-all.sh

# 5. Run the app
cd user-app && flutter run
```

### Switching Base URL

The app targets `http://10.0.2.2:8080` (Android emulator loopback to host machine) by default.

To use a physical device, change `AppConstants.baseUrl` in [lib/core/constants/app_constants.dart](../user-app/lib/core/constants/app_constants.dart):

```dart
// Emulator (default)
static const String baseUrl = 'http://10.0.2.2:8080';

// Physical device – replace with your machine's local IP
static const String baseUrl = 'http://192.168.1.100:8080';
```

### Build for Release

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 5. Architecture

The app follows a **layered feature-first architecture**:

```
Presentation (Screens / Widgets)
        │  reads/watches
        ▼
Providers (Riverpod Notifiers / FutureProviders)
        │  calls
        ▼
API Classes (Dio HTTP)
        │  parses
        ▼
Models (typed Dart classes, fromJson/toJson)
        │
        ▼
Backend REST API
```

### Layer Responsibilities

| Layer | Location | Responsibility |
|-------|----------|----------------|
| **Screens** | `lib/features/*/presentation/` | UI rendering, user input, call providers |
| **Providers** | `lib/providers/` | State management, business logic, orchestration |
| **API classes** | `lib/data/api/` | HTTP requests, response parsing, error handling |
| **Models** | `lib/data/models/` | Typed response shapes, `fromJson`/`toJson` |
| **Core** | `lib/core/` | Theme, constants, Dio client, utilities |
| **Shared widgets** | `lib/shared/widgets/` | Reusable UI components used across features |

### Key Design Decisions

- **Riverpod over Provider/Bloc** — simpler scoping, compile-time safety, no BuildContext needed in providers
- **Polling over WebSocket** — backend Phase 1 is REST only; tracking screen polls every 7 seconds
- **`flutter_secure_storage`** — tokens stored in Android Keystore (encrypted at rest)
- **No `dynamic`** — all JSON is parsed into typed models; no `Map<String, dynamic>` leaking into UI
- **GoRouter ShellRoute** — bottom navigation is a shell that wraps `/home`, `/history`, `/profile`, `/notifications`; SOS/profile sub-routes are outside the shell (full-screen)

---

## 6. Configuration

### `AppConstants` — [lib/core/constants/app_constants.dart](../user-app/lib/core/constants/app_constants.dart)

All global configuration lives in one file:

```dart
class AppConstants {
  static const String baseUrl = 'http://10.0.2.2:8080';   // Change for physical device
  static const String apiPrefix = '/api';

  // Secure storage keys
  static const String accessTokenKey  = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey       = 'user_id';
  static const String userEmailKey    = 'user_email';
  static const String userNameKey     = 'user_name';
  static const String userPhoneKey    = 'user_phone';

  // Timeouts
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;

  // Polling intervals (seconds)
  static const int trackingPollIntervalSeconds    = 7;
  static const int notificationPollIntervalSeconds = 30;

  // Map
  static const String osmTileUrl    = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmUserAgent  = 'com.rakshapoorvak.userapp';
  static const double defaultMapZoom = 15.0;
  static const double defaultLat    = 19.0760; // Mumbai fallback
  static const double defaultLng    = 72.8777;

  // SOS status constants (match backend enum exactly)
  static const String statusCreated          = 'CREATED';
  static const String statusDispatching      = 'DISPATCHING';
  static const String statusAmbulanceAssigned = 'AMBULANCE_ASSIGNED';
  static const String statusDriverEnroute    = 'DRIVER_ENROUTE_TO_PATIENT';
  static const String statusReachedPatient   = 'REACHED_PATIENT';
  static const String statusPickedUp         = 'PICKED_UP';
  static const String statusEnrouteHospital  = 'ENROUTE_TO_HOSPITAL';
  static const String statusArrivedHospital  = 'ARRIVED_AT_HOSPITAL';
  static const String statusCompleted        = 'COMPLETED';
  static const String statusCancelled        = 'CANCELLED';
}
```

### Android Manifest Permissions

Defined in [android/app/src/main/AndroidManifest.xml](../user-app/android/app/src/main/AndroidManifest.xml):

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.VIBRATE" />
```

`android:usesCleartextTraffic="true"` is set on the `<application>` tag to allow HTTP to `10.0.2.2:8080` during development. **Remove this for production and use HTTPS.**

---

## 7. Design System

### Color Palette — `AppColors`

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#DC2626` | SOS button, links, critical actions |
| `primaryLight` | `#EF4444` | Hover/active state, gradient |
| `primaryDark` | `#B91C1C` | Shadow color, gradient end |
| `accent` | `#2563EB` | Tracking info, secondary actions, ETA card |
| `accentLight` | `#3B82F6` | Ambulance assigned status, unread badge |
| `background` | `#F9FAFB` | Scaffold background |
| `surface` | `#FFFFFF` | Cards, modals |
| `surfaceVariant` | `#F3F4F6` | Input fill, shimmer base |
| `textPrimary` | `#1F2937` | Headings, primary text |
| `textSecondary` | `#6B7280` | Labels, captions |
| `textTertiary` | `#9CA3AF` | Timestamps, placeholders |
| `divider` | `#E5E7EB` | Separators |
| `success` | `#22C55E` | Completed status, ambulance marker |
| `error` | `#EF4444` | Cancelled status, error state |
| `warning` | `#F59E0B` | Created/Dispatching status |

### Status Color Mapping

| SOS Status | Color Token | Hex |
|------------|-------------|-----|
| `CREATED`, `DISPATCHING` | `warning` | `#F59E0B` (amber) |
| `AMBULANCE_ASSIGNED`, `DRIVER_ENROUTE_TO_PATIENT` | `accentLight` | `#3B82F6` (blue) |
| `REACHED_PATIENT`, `PICKED_UP`, `ENROUTE_TO_HOSPITAL` | `#6366F1` | indigo |
| `ARRIVED_AT_HOSPITAL`, `COMPLETED` | `success` | `#22C55E` (green) |
| `CANCELLED` | `error` | `#EF4444` (red) |

### Criticality Color Mapping

| Level | Hex |
|-------|-----|
| `LOW` | `#9CA3AF` (gray) |
| `MEDIUM` | `#F59E0B` (amber) |
| `HIGH` | `#F97316` (orange) |
| `CRITICAL` | `#EF4444` (red) |

### Typography

Font family: **Inter** (via `google_fonts`).

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `headlineLarge` | 24 | 700 | Page titles |
| `headlineMedium` | 20 | 700 | Section headings, ETA value |
| `titleLarge` | 18 | 600 | Card titles, app bar |
| `titleMedium` | 16 | 500 | Sub-titles, list item labels |
| `bodyLarge` | 16 | 400 | Main body copy |
| `bodyMedium` | 14 | 400 | Secondary text, descriptions |
| `bodySmall` | 12 | 400 | Timestamps, metadata |
| `labelLarge` | 16 | 600 | Button labels |

### Spacing

Base unit: **8px**

| Usage | Value |
|-------|-------|
| Screen horizontal padding | 20–24px |
| Screen vertical padding | 16–20px |
| Card internal padding | 16–20px |
| Component gap | 8–16px |
| Button height | 52px |
| Bottom nav safe area | automatic via SafeArea |

### Component Standards

- **Cards** — `elevation: 2`, `borderRadius: 12`, white background
- **Buttons** — `borderRadius: 12`, height `52`, full-width by default
- **Input fields** — `borderRadius: 12`, filled with `surfaceVariant`, focus ring `primary`
- **Badges** — pill shape (`borderRadius: 100`), status-colored background + border

---

## 8. Data Models

All models live in `lib/data/models/`. Every model has a typed `fromJson` factory. No `dynamic` is used in the app.

### `AuthResponse` — [auth_response.dart](../user-app/lib/data/models/auth_response.dart)

```dart
class AuthResponse {
  final String    accessToken;
  final String    refreshToken;
  final int       expiresIn;
  final UserSummary user;
}
```

Maps to `POST /api/auth/login` and `POST /api/auth/register` responses.

### `UserSummary` — [user.dart](../user-app/lib/data/models/user.dart)

```dart
class UserSummary {
  final int          id;
  final String       email;
  final String       fullName;
  final String?      phone;
  final List<String> roles;
}
```

Returned inside `AuthResponse.user`. Also stored in `flutter_secure_storage` across sessions.

### `UserProfile`

Same fields as `UserSummary`. Returned by `GET /api/users/me`.

### `MedicalProfile`

```dart
class MedicalProfile {
  final int?    id;
  final int?    userId;
  final String? bloodGroup;   // e.g. "A+", "O-"
  final String? allergies;    // free text
  final String? conditions;   // free text
  final String? notes;        // free text
}
```

Returned by `GET /api/users/me/medical-profile`. Sent via `PATCH /api/users/me/medical-profile`.

### `EmergencyContact`

```dart
class EmergencyContact {
  final int?    id;
  final int?    userId;
  final String  name;
  final String  phone;
  final String? relationship;
}
```

### `SosEvent` — [sos_event.dart](../user-app/lib/data/models/sos_event.dart)

The central model of the app:

```dart
class SosEvent {
  final int     id;
  final int?    userId;
  final String? userName;
  final String? userPhone;
  final int?    hospitalId;
  final String? hospitalName;
  final int?    ambulanceId;
  final String? ambulanceRegistrationNumber;
  final int?    driverId;
  final String? driverName;
  final int?    doctorId;
  final String? doctorName;
  final double  latitude;
  final double  longitude;
  final String? address;
  final String  status;      // see status constants
  final String? symptoms;
  final String? criticality; // LOW | MEDIUM | HIGH | CRITICAL
  final String? completedAt;
  final String  createdAt;
  final String? updatedAt;

  // Computed helpers
  bool get isActive       // true for all non-terminal statuses
  bool get isCancellable  // true for CREATED and DISPATCHING only
}
```

### `TrackingInfo` — [tracking.dart](../user-app/lib/data/models/tracking.dart)

```dart
class TrackingInfo {
  final int              sosEventId;
  final String           status;
  final double?          ambulanceLatitude;
  final double?          ambulanceLongitude;
  final String?          driverName;
  final String?          driverPhone;
  final int?             estimatedMinutesArrival;
  final List<LocationPoint> locationHistory;

  bool get hasAmbulanceLocation  // true when lat/lng both non-null
}

class LocationPoint {
  final double  latitude;
  final double  longitude;
  final String? recordedAt;
}
```

Returned by `GET /api/sos-events/{id}/tracking`.

### `AppNotification` — [notification.dart](../user-app/lib/data/models/notification.dart)

```dart
class AppNotification {
  final int     id;
  final String  title;
  final String  body;
  final bool    isRead;
  final String? createdAt;
}
```

---

## 9. State Management (Riverpod)

All state is managed with `flutter_riverpod`. The app uses `ProviderScope` at the root (`main.dart`).

### Provider Overview

| Provider | Type | Location | Purpose |
|----------|------|----------|---------|
| `authNotifierProvider` | `StateNotifierProvider<AuthNotifier, AuthState>` | `auth_provider.dart` | Login, register, logout, session hydration |
| `isAuthenticatedProvider` | `Provider<bool>` | `auth_provider.dart` | Convenience: `authState.isAuthenticated` |
| `currentUserProvider` | `Provider<UserSummary?>` | `auth_provider.dart` | Currently logged-in user |
| `activeSosProvider` | `StateNotifierProvider<ActiveSosNotifier, AsyncValue<SosEvent?>>` | `sos_provider.dart` | Currently active (non-terminal) SOS |
| `sosHistoryProvider` | `FutureProvider<List<SosEvent>>` | `sos_provider.dart` | All past SOS events for user |
| `sosEventProvider` | `FutureProvider.family<SosEvent, int>` | `sos_provider.dart` | Single SOS by ID |
| `trackingProvider` | `StateNotifierProvider.family<TrackingNotifier, …, int>` | `sos_provider.dart` | Live tracking with auto-polling |
| `notificationsProvider` | `FutureProvider<List<AppNotification>>` | `notification_provider.dart` | All notifications (one fetch) |
| `unreadCountProvider` | `StateNotifierProvider<UnreadCountNotifier, int>` | `notification_provider.dart` | Notification badge count (polled) |

### `AuthNotifier` — Login / Session Flow

```dart
class AuthState {
  final UserSummary? user;
  final bool         isLoading;
  final String?      error;
  final bool         isAuthenticated;
}
```

On app start, `AuthNotifier._initialize()` reads tokens from `flutter_secure_storage`. If a valid token is found, the user is restored without a network call — the screen shows immediately.

```dart
// Login
final success = await ref.read(authNotifierProvider.notifier).login(email, password);
if (success) context.go('/home');

// Check auth
final isAuth = ref.watch(isAuthenticatedProvider);

// Current user
final user = ref.watch(currentUserProvider);
```

### `TrackingNotifier` — Auto-Polling

Tracking is implemented via a `StateNotifier` that starts a `Timer` when created:

```dart
class TrackingNotifier extends StateNotifier<AsyncValue<TrackingInfo?>> {
  Timer? _timer;

  void startPolling() {
    _timer = Timer.periodic(
      const Duration(seconds: AppConstants.trackingPollIntervalSeconds),
      (_) => _fetch(),
    );
  }

  void stopPolling() { _timer?.cancel(); }
  // Auto-stops when status is COMPLETED or CANCELLED
}
```

Used in the tracking screen:

```dart
final trackingAsync = ref.watch(trackingProvider(sosId));
```

The timer disposes automatically when the provider is disposed (screen popped).

### `UnreadCountNotifier` — Badge Polling

Polls `GET /api/notifications/unread-count` every 30 seconds. The badge in the bottom nav reflects this count live.

---

## 10. API Layer

### `ApiClient` — [lib/core/network/api_client.dart](../user-app/lib/core/network/api_client.dart)

A singleton `Dio` instance with two interceptors:

**Auth Interceptor (`_AuthInterceptor`)**

```
Request → attach Authorization: Bearer {accessToken}
Response 401 → call POST /auth/refresh
             → on success: retry original request with new token
             → on failure: clear storage, trigger redirect to /login
```

The interceptor extends `QueuedInterceptorsWrapper` to avoid concurrent refresh storms (multiple simultaneous 401s will queue instead of each triggering a refresh).

**Log Interceptor**

Logs request/response errors to the debug console (disabled in release builds).

### Error Extraction

```dart
String extractErrorMessage(dynamic error) {
  // Parses backend error format: { "error": { "message": "..." } }
  // Falls back to network error messages for timeout/connection failures
}
```

Called in every `catch` block before displaying a `SnackBar`.

### API Classes

#### `AuthApi` — [auth_api.dart](../user-app/lib/data/api/auth_api.dart)

| Method | HTTP | Endpoint | Notes |
|--------|------|----------|-------|
| `login(email, password)` | POST | `/auth/login` | Returns `AuthResponse` |
| `register(email, password, fullName, phone?)` | POST | `/auth/register` | Sends `roles: ['USER']` |
| `logout()` | POST | `/auth/logout` | Best-effort, always clears storage |
| `getMe()` | GET | `/auth/me` | Returns raw Map |

#### `SosApi` — [sos_api.dart](../user-app/lib/data/api/sos_api.dart)

| Method | HTTP | Endpoint | Notes |
|--------|------|----------|-------|
| `createSos(lat, lng, address?, symptoms?, criticality?)` | POST | `/sos-events` | Returns `SosEvent` |
| `updateSos(id, symptoms?, criticality?)` | PATCH | `/sos-events/{id}` | Returns updated `SosEvent` |
| `getSosEvent(id)` | GET | `/sos-events/{id}` | Returns `SosEvent` |
| `getMySosEvents()` | GET | `/sos-events/my` | Returns `List<SosEvent>` |
| `getMyActiveSos()` | GET | `/sos-events/my/active` | Returns `List<SosEvent>` (usually 0 or 1) |
| `getTracking(sosId)` | GET | `/sos-events/{id}/tracking` | Returns `TrackingInfo` |
| `cancelSos(id)` | DELETE | `/sos-events/{id}` | No return body |

#### `UserApi` — [user_api.dart](../user-app/lib/data/api/user_api.dart)

| Method | HTTP | Endpoint |
|--------|------|----------|
| `getProfile()` | GET | `/users/me` |
| `updateProfile(fullName?, phone?)` | PATCH | `/users/me` |
| `getMedicalProfile()` | GET | `/users/me/medical-profile` |
| `updateMedicalProfile(profile)` | PATCH | `/users/me/medical-profile` |
| `getEmergencyContacts()` | GET | `/users/me/emergency-contacts` |
| `addEmergencyContact(contact)` | POST | `/users/me/emergency-contacts` |
| `updateEmergencyContact(id, contact)` | PATCH | `/users/me/emergency-contacts/{id}` |
| `deleteEmergencyContact(id)` | DELETE | `/users/me/emergency-contacts/{id}` |

#### `NotificationApi` — [notification_api.dart](../user-app/lib/data/api/notification_api.dart)

| Method | HTTP | Endpoint |
|--------|------|----------|
| `getNotifications(page, size)` | GET | `/notifications?page=0&size=20` |
| `getUnreadCount()` | GET | `/notifications/unread-count` |
| `markRead(id)` | PATCH | `/notifications/{id}/read` |
| `markAllRead()` | PATCH | `/notifications/read-all` |

### Response Normalization

Some backend endpoints wrap data in `{ "data": { ... } }`. The API classes handle both shapes:

```dart
final data = response.data;
if (data is Map && data.containsKey('data')) {
  return SosEvent.fromJson(data['data'] as Map<String, dynamic>);
}
return SosEvent.fromJson(data as Map<String, dynamic>);
```

---

## 11. Routing & Navigation

### Router — [lib/app/routes.dart](../user-app/lib/app/routes.dart)

Built with `go_router`. The router is a Riverpod `Provider<GoRouter>` that watches `authNotifierProvider` and redirects automatically on auth state changes.

#### Route Tree

```
/login                          → LoginScreen
/register                       → RegisterScreen
/sos/create                     → SosCreateScreen          (full-screen)
/sos/confirm/:id                → SosConfirmScreen          (full-screen)
/sos/:id/tracking               → SosTrackingScreen         (full-screen)
/sos/:id/detail                 → SosDetailScreen           (full-screen)
/profile/edit                   → EditProfileScreen         (full-screen)
/profile/medical                → MedicalProfileScreen      (full-screen)
/profile/contacts               → EmergencyContactsScreen   (full-screen)
ShellRoute (/home shell)
  /home                         → HomeScreen
  /history                      → HistoryScreen
  /profile                      → ProfileScreen
  /notifications                → NotificationsScreen
```

#### Redirect Logic

```dart
redirect: (context, state) {
  final isAuth = authState.isAuthenticated;
  final loc    = state.matchedLocation;

  if (!isAuth && !isAuthRoute) return '/login';   // Unauthenticated → login
  if (isAuth  &&  isAuthRoute) return '/home';    // Authenticated on login → home
  return null;                                     // No redirect
},
```

#### Bottom Navigation (ShellRoute)

The `ScaffoldWithNavBar` widget wraps all shell routes with a `BottomNavigationBar`. It:

- Reads the current `matchedLocation` to highlight the correct tab
- Watches `unreadCountProvider` and renders a `Badge` on the Alerts tab
- Uses `context.go()` for tab switches (replaces stack, not pushes)

#### Navigation Patterns

```dart
// Full-screen push (back button returns)
context.push('/profile/medical');
context.push('/sos/42/detail');

// Replace current stack entry (no back)
context.go('/home');
context.go('/sos/42/tracking');
```

---

## 12. Screens – Detailed Reference

### Login Screen — `/login`

**File:** [lib/features/auth/presentation/login_screen.dart](../user-app/lib/features/auth/presentation/login_screen.dart)

| Element | Detail |
|---------|--------|
| Entry animation | Fade + slide up (600ms, `easeOut`) |
| Fields | Email (keyboard: `emailAddress`), Password (obscured, toggle) |
| Validation | Email regex, non-empty password |
| On success | Stores tokens → `context.go('/home')` |
| Error display | Red banner below form with backend `error.message` |
| Test credentials | Shown at bottom in subtle card |

**Flow:**
```
Tap "Sign In"
  → validate form
  → AuthNotifier.login()
    → POST /api/auth/login
    → save tokens to FlutterSecureStorage
    → update AuthState.isAuthenticated = true
  → GoRouter redirect → /home
```

---

### Register Screen — `/register`

**File:** [lib/features/auth/presentation/register_screen.dart](../user-app/lib/features/auth/presentation/register_screen.dart)

Fields: Full Name, Email, Phone (optional), Password (min 6 chars), Confirm Password. Validation is client-side before API call.

---

### Home Screen — `/home`

**File:** [lib/features/home/presentation/home_screen.dart](../user-app/lib/features/home/presentation/home_screen.dart)

| Element | Detail |
|---------|--------|
| Entry animation | Fade in (700ms) |
| Greeting | `"Hello, {firstName}!"` from `currentUserProvider` |
| Active SOS check | On mount, watches `activeSosProvider`. If an active SOS is found, redirects to `/sos/{id}/tracking` automatically |
| SOS button | Large animated button, centered in a gradient container |
| Quick actions | History, Medical Profile, Emergency Contacts (3-column grid) |
| How it works | Vertical step list with icons |
| Notification badge | AppBar icon shows unread count from `unreadCountProvider` |

---

### SOS Create Screen — `/sos/create`

**File:** [lib/features/sos/presentation/sos_create_screen.dart](../user-app/lib/features/sos/presentation/sos_create_screen.dart)

This screen is fully automatic — it runs the location + SOS creation flow on mount, showing status updates to the user.

**Flow:**
```
Mount
  → Request location permission
  → If denied: show error state with "Open Settings" + "Try Again" buttons
  → Geolocator.getCurrentPosition() (12s timeout, high accuracy)
  → POST /api/sos-events { latitude, longitude }
  → activeSosProvider.setActiveSos(sos)
  → context.go('/sos/confirm/{sos.id}')
```

**States:**
1. **Loading** — spinning ring animation + linear progress bar + status message
2. **Location denied** — icon + message + "Open Settings" button + "Try Again" + "Cancel"
3. **Network error** — same layout with error message from `extractErrorMessage`

---

### SOS Confirm Screen — `/sos/confirm/:id`

**File:** [lib/features/sos/presentation/sos_confirm_screen.dart](../user-app/lib/features/sos/presentation/sos_confirm_screen.dart)

| Element | Detail |
|---------|--------|
| Entry animation | Scale-in green check icon (elasticOut, 600ms) |
| Back navigation | Disabled (`PopScope(canPop: false)`) |
| Symptoms | Multi-line text field, max 300 chars |
| Criticality | Filter chips: LOW / MEDIUM / HIGH / CRITICAL (toggle-select) |
| Primary action | "View Tracking" → PATCH symptoms/criticality → navigate to tracking |
| Skip action | "Skip and track →" → navigate directly without updating |

---

### SOS Tracking Screen — `/sos/:id/tracking`

**File:** [lib/features/sos/presentation/sos_tracking_screen.dart](../user-app/lib/features/sos/presentation/sos_tracking_screen.dart)

The most important screen in the app. Composes several cards.

**Data sources:**
- `sosEventProvider(sosId)` — full SOS details (driver, hospital, etc.)
- `trackingProvider(sosId)` — live location + ETA (auto-polling every 7s)

| Widget | Content |
|--------|---------|
| `MapTrackingWidget` | OSM map with patient (red) + ambulance (green) markers and polyline |
| `SosStatusTimeline` | Horizontal scrollable timeline of all 9 statuses |
| ETA Card | "Estimated Arrival: X min" from `estimatedMinutesArrival` |
| Driver Info Card | Name, ambulance reg, hospital destination, "Call Driver" button |
| SOS Info Card | Symptoms, severity, request time, address |
| Cancel SOS | Shown only when `sos.isCancellable` (CREATED / DISPATCHING); requires confirm dialog |

**Cancel flow:**
```
Tap "Cancel SOS"
  → setState: _showCancelConfirm = true (inline confirm UI)
  → Tap "Yes, Cancel"
  → DELETE /api/sos-events/{id}
  → activeSosProvider.clearActiveSos()
  → context.go('/home')
```

---

### SOS Detail Screen — `/sos/:id/detail`

**File:** [lib/features/sos/presentation/sos_detail_screen.dart](../user-app/lib/features/sos/presentation/sos_detail_screen.dart)

Read-only view of a completed or in-progress SOS. Shows status timeline, all incident details, response team. If the SOS is still active, shows a "View Live Tracking" button.

---

### History Screen — `/history`

**File:** [lib/features/history/presentation/history_screen.dart](../user-app/lib/features/history/presentation/history_screen.dart)

| Element | Detail |
|---------|--------|
| Loading state | Shimmer skeleton list (5 items) |
| Error state | Icon + message + retry button |
| Empty state | Illustrated empty state with copy |
| List | Sorted newest-first; each card shows SOS ID, date, symptoms, status badge, criticality badge, hospital name |
| Tap card | Navigates to `/sos/{id}/detail` |
| Refresh | App bar icon invalidates `sosHistoryProvider` |

---

### Profile Screen — `/profile`

**File:** [lib/features/profile/presentation/profile_screen.dart](../user-app/lib/features/profile/presentation/profile_screen.dart)

| Section | Content |
|---------|---------|
| Header | Avatar (initials), full name, email, phone |
| Health & Safety | Medical Profile, Emergency Contacts |
| Account | History, Notifications |
| Sign Out | Confirm dialog → `AuthNotifier.logout()` → `/login` |

---

### Edit Profile Screen — `/profile/edit`

**File:** [lib/features/profile/presentation/edit_profile_screen.dart](../user-app/lib/features/profile/presentation/edit_profile_screen.dart)

`PATCH /api/users/me` with `fullName` and `phone`. Pre-filled from `currentUserProvider`.

---

### Medical Profile Screen — `/profile/medical`

**File:** [lib/features/profile/presentation/medical_profile_screen.dart](../user-app/lib/features/profile/presentation/medical_profile_screen.dart)

Two modes: **view mode** (formatted info tiles) and **edit mode** (form with blood group dropdown, text fields). Blood group uses `DropdownButtonFormField` with the 8 standard types.

`GET /api/users/me/medical-profile` on load. `PATCH /api/users/me/medical-profile` on save. If no profile exists yet, shows an "Add Medical Info" CTA.

---

### Emergency Contacts Screen — `/profile/contacts`

**File:** [lib/features/profile/presentation/emergency_contacts_screen.dart](../user-app/lib/features/profile/presentation/emergency_contacts_screen.dart)

Add/edit/delete contacts via `ModalBottomSheet`. Each contact card has: avatar (initial), name, phone, relationship, call icon, edit icon, delete icon (with confirm dialog).

---

### Notifications Screen — `/notifications`

**File:** [lib/features/notifications/presentation/notifications_screen.dart](../user-app/lib/features/notifications/presentation/notifications_screen.dart)

| Element | Detail |
|---------|--------|
| Loading | Shimmer skeleton rows |
| Unread item | Accent-tinted background, bold title, blue dot indicator |
| Read item | Normal background |
| Tap | Marks notification as read via `PATCH /notifications/{id}/read`; updates badge count |
| "Mark all read" | `PATCH /notifications/read-all`; resets badge to 0 |
| Timestamps | `timeAgo()` format (e.g. "5m ago", "2h ago") |
| Pull-to-refresh | `RefreshIndicator` re-fetches list + unread count |

---

## 13. Shared Widgets

### `SosButton` — [lib/shared/widgets/sos_button.dart](../user-app/lib/shared/widgets/sos_button.dart)

The primary call-to-action of the entire app.

```dart
SosButton(
  onPressed: () => context.push('/sos/create'),
  size: 180,  // optional, default 180
)
```

**Visual structure:**
```
┌──────────────────────────────────────────┐
│         Outer ring (alpha 10%)           │
│   ┌──────────────────────────────────┐   │
│   │    Middle ring (alpha 20%)       │   │
│   │  ┌────────────────────────────┐  │   │
│   │  │   Main circle (gradient)   │  │   │
│   │  │   🚨  SOS  TAP FOR HELP    │  │   │
│   │  └────────────────────────────┘  │   │
│   └──────────────────────────────────┘   │
└──────────────────────────────────────────┘
```

**Animations:**
- **Idle pulse** — `AnimationController` repeating, scale `1.0 → 1.04 → 1.0`, 2s loop via `CurvedAnimation(Curves.easeInOut)`
- **Press** — `onTapDown` sets `_isPressed = true` → scale 0.94; `onTapUp` restores 1.0
- **Haptic** — `HapticFeedback.mediumImpact()` on `onTapDown`
- **Shadow** — dynamically reduces blur and offset when pressed

---

### `StatusBadge` — [lib/shared/widgets/status_badge.dart](../user-app/lib/shared/widgets/status_badge.dart)

Pill badge with colored dot. Maps any backend status string to a human-readable label and appropriate color.

```dart
StatusBadge(status: 'DRIVER_ENROUTE_TO_PATIENT')
// → blue pill "En Route"

StatusBadge(status: 'COMPLETED')
// → green pill "Completed"
```

### `CriticalityBadge`

Small all-caps badge for `LOW / MEDIUM / HIGH / CRITICAL`.

```dart
CriticalityBadge(criticality: 'HIGH')
// → orange pill "HIGH"
```

### `SosStatusTimeline`

Horizontal scrollable step-indicator. Shows all 9 statuses (CREATED → COMPLETED). Past steps are green, current is red with glow shadow, future are gray.

```dart
SosStatusTimeline(currentStatus: sos.status)
```

For `CANCELLED` status, renders a single centered red badge instead of the timeline.

### `MapTrackingWidget` — [lib/shared/widgets/map_tracking_widget.dart](../user-app/lib/shared/widgets/map_tracking_widget.dart)

```dart
MapTrackingWidget(
  sosEvent: sos,       // for patient lat/lng
  tracking: tracking,  // nullable; used for ambulance position + history
  height: 320,         // optional
)
```

**Map layers (in render order):**
1. `TileLayer` — OSM tiles at `tile.openstreetmap.org`
2. `PolylineLayer` — blue route line (from `locationHistory` points + ambulance current position, or straight line if no history)
3. `MarkerLayer` — patient (red circle + pin tail) + ambulance (green circle with taxi icon)

**Camera behavior:**
- On first load: centers on patient at zoom 15
- When ambulance position available: `fitBounds` to show both markers with 48px padding
- `didUpdateWidget` detects ambulance position changes and re-fits bounds

**`_PinTailPainter`:** Custom `CustomPainter` using `dart:ui.Path` (aliased as `ui.Path` to avoid name clash with flutter_map's `Path<LatLng>`) to draw the triangular tail under the patient pin.

---

## 14. SOS Flow – End-to-End

Complete journey from patient tapping SOS to ambulance arrival:

```
Patient taps SOS button on HomeScreen
        │
        ▼
SosCreateScreen (/sos/create)
  Requests GPS permission
  Gets current position (high accuracy, 12s timeout)
  POST /api/sos-events { lat, lng }
        │
        ▼
SosConfirmScreen (/sos/confirm/{id})
  Shows "SOS Sent!" + SOS #ID
  Optional: symptoms text + criticality chip
  PATCH /api/sos-events/{id} (if symptoms/criticality added)
  Tap "View Tracking"
        │
        ▼
SosTrackingScreen (/sos/{id}/tracking)
  Polls GET /api/sos-events/{id} for status
  Polls GET /api/sos-events/{id}/tracking for ambulance location (every 7s)
  Shows map, ETA, driver info, status timeline
        │
   [Hospital dispatches ambulance → status: AMBULANCE_ASSIGNED]
   [Driver accepts → status: DRIVER_ENROUTE_TO_PATIENT]
   [Driver arrives → status: REACHED_PATIENT]
   [Patient picked up → status: PICKED_UP]
   [En route to hospital → status: ENROUTE_TO_HOSPITAL]
   [Arrived → status: ARRIVED_AT_HOSPITAL]
   [Completed → status: COMPLETED]
        │
        ▼
Tracking polling stops (terminal status)
Patient can view SosDetailScreen for full summary
```

---

## 15. Live Tracking & Map

### Polling Architecture

```
trackingProvider(sosId) created
  └─ TrackingNotifier._fetch() called immediately
  └─ startPolling() → Timer.periodic(7 seconds)
       └─ every tick → GET /api/sos-events/{sosId}/tracking
            └─ updates state → MapTrackingWidget re-renders
            └─ if COMPLETED/CANCELLED → stopPolling()

Screen popped → Riverpod disposes TrackingNotifier → timer cancelled
```

The 7-second interval (`AppConstants.trackingPollIntervalSeconds`) can be changed in `AppConstants`. The first fetch happens immediately on provider creation, so there is no 7-second delay before the first location appears.

### Map Setup

**Tile URL:** `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
**User agent:** `com.rakshapoorvak.userapp` (required by OSM acceptable use policy)
**Map controller:** `MapController` instance for programmatic camera moves

### Fitting Bounds

```dart
// When both patient and ambulance are visible:
final bounds = LatLngBounds.fromPoints([patientLatLng, ambulanceLatLng]);
_mapController.fitCamera(
  CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(48)),
);

// Patient only:
_mapController.move(patientLatLng, AppConstants.defaultMapZoom);
```

### Polyline Route

The route line is drawn using `locationHistory` (list of GPS points recorded by the driver). If history is empty, a straight line from ambulance to patient is drawn as a fallback. Stroke width: 4, color: `AppColors.accent` at 70% opacity.

---

## 16. Animations

### SOS Button Pulse

```dart
_pulseController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 2000),
)..repeat(reverse: true);

_pulseAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
  CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
);
```

Scales the entire button (including rings) between 1.0 and 1.04 continuously. Press overrides scale to 0.94 via `setState`.

### Auth Screen Transitions

Login and Register use `AnimationController` + `FadeTransition` + `SlideTransition` (slide from bottom 15%) on `initState` → `forward()`.

### SOS Confirm Success Animation

```dart
_checkCtrl = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 600),
);
_checkScale = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
```

The green checkmark icon scales in with an elastic overshoot effect.

### Status Badge Animated Dot

The current-status dot in `SosStatusTimeline` uses `AnimatedContainer` to grow from 10px to 14px and add a glow `BoxShadow` when the status becomes current (300ms transition).

---

## 17. Location & Permissions

### Permission Flow

```dart
// In SosCreateScreen._initSos()
LocationPermission permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
  permission = await Geolocator.requestPermission();
}
if (permission == LocationPermission.denied ||
    permission == LocationPermission.deniedForever) {
  // Show error state, offer "Open Settings"
  return;
}
```

`Geolocator.openAppSettings()` opens Android Settings → App → Permissions.

### Position Request

```dart
final position = await Geolocator.getCurrentPosition(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 12),
  ),
);
```

`LocationAccuracy.high` uses GPS chip. 12-second timeout prevents the screen hanging indefinitely. If timeout is reached, a `TimeoutException` is caught and shown as an error.

### Android Manifest

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

Both are required. `ACCESS_FINE_LOCATION` is needed for high-accuracy GPS. `ACCESS_COARSE_LOCATION` is its declared coarser counterpart.

---

## 18. Error Handling

### API Errors

Backend error format:
```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "SOS event not found",
    "timestamp": "2026-03-17T10:30:00Z"
  }
}
```

`extractErrorMessage(e)` in `api_client.dart` parses this and falls back to network-level messages:

| Scenario | Message shown |
|----------|--------------|
| Backend validation error | Backend's `error.message` |
| 401 (token expired, not refreshable) | Redirect to login |
| Connection timeout | "Connection timed out. Please check your network." |
| No internet | "Connection failed. Please check your internet." |
| Unknown | "Something went wrong. Please try again." |

### UI Error Patterns

| Pattern | Used in |
|---------|---------|
| `SnackBar` | Mutation failures (update profile, cancel SOS, add contact) |
| Error banner (red container) | Login / Register form errors |
| Error state (full-screen icon + message + retry) | History, Notifications list load failures |
| Inline error state | SOS Create (location error) |

### Auth / 401 Handling

The Dio interceptor catches 401 responses:
1. Attempts to refresh token via `POST /api/auth/refresh`
2. On success: retries original request transparently
3. On failure: calls `_storage.deleteAll()` — `AuthNotifier._initialize()` will not find tokens on next app start, triggering redirect to `/login`

---

## 19. Test Credentials

### Seeded Users

Run `./scripts/seed-all.sh` from the project root to populate the database.

| Email | Password | Role |
|-------|----------|------|
| `patient1@test.com` | `password123` | USER |
| `patient2@test.com` | `password123` | USER |

### Register a New Account

The Register screen (`/register`) is fully functional. New accounts are immediately usable. Roles default to `['USER']`.

---

## 20. Common Tasks for New Developers

### Add a New API Call

1. Add the method to the appropriate API class in `lib/data/api/`
2. Add a response model in `lib/data/models/` if the response shape is new
3. Either use a `FutureProvider` for one-shot reads or add a method to an existing `Notifier`

```dart
// Example: add a new endpoint in SosApi
Future<SosEvent> getMySosByDate(DateTime date) async {
  final response = await _client.dio.get('/sos-events/my',
    queryParameters: {'date': date.toIso8601String()});
  // parse response
}
```

### Add a New Screen

1. Create `lib/features/<feature>/presentation/<screen_name>_screen.dart`
2. Add a route in `lib/app/routes.dart`
3. Navigate with `context.go('/new-route')` (replace) or `context.push('/new-route')` (push)

### Change Polling Interval

Edit `AppConstants` in `lib/core/constants/app_constants.dart`:

```dart
static const int trackingPollIntervalSeconds    = 7;   // tracking screen
static const int notificationPollIntervalSeconds = 30; // notification badge
```

### Change the Backend URL

For physical device testing, change in `lib/core/constants/app_constants.dart`:

```dart
static const String baseUrl = 'http://192.168.1.100:8080'; // your machine's IP
```

Ensure the Android device and your development machine are on the same Wi-Fi network.

### Add a New SOS Status

1. Add the status string constant to `AppConstants`
2. Add it to `AppConstants.activeStatuses` if it is non-terminal
3. Add color mapping in `AppColors` and `StatusBadge._color`
4. Add human-readable label in `StatusBadge.label`
5. Add the step in `SosStatusTimeline._statuses`

### Run Flutter Analyze

```bash
cd user-app
flutter analyze
# Expected: "No issues found!"
```

### Build Debug APK

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Build Release APK

```bash
flutter build apk --release
# Requires signing config in build.gradle.kts for Play Store submission
```

---

## Appendix A — SOS Status Reference

| Status String | Human Label | Color | Terminal |
|--------------|-------------|-------|---------|
| `CREATED` | Created | Amber | No |
| `DISPATCHING` | Dispatching | Amber | No |
| `AMBULANCE_ASSIGNED` | Assigned | Blue | No |
| `DRIVER_ENROUTE_TO_PATIENT` | En Route | Blue | No |
| `REACHED_PATIENT` | Reached You | Indigo | No |
| `PICKED_UP` | Picked Up | Indigo | No |
| `ENROUTE_TO_HOSPITAL` | To Hospital | Indigo | No |
| `ARRIVED_AT_HOSPITAL` | At Hospital | Green | No |
| `COMPLETED` | Completed | Green | **Yes** |
| `CANCELLED` | Cancelled | Red | **Yes** |

Polling stops automatically when a terminal status is received.

---

## Appendix B — File → Screen Quick Reference

| File | Screen / Route |
|------|----------------|
| `features/auth/presentation/login_screen.dart` | `/login` |
| `features/auth/presentation/register_screen.dart` | `/register` |
| `features/home/presentation/home_screen.dart` | `/home` |
| `features/sos/presentation/sos_create_screen.dart` | `/sos/create` |
| `features/sos/presentation/sos_confirm_screen.dart` | `/sos/confirm/:id` |
| `features/sos/presentation/sos_tracking_screen.dart` | `/sos/:id/tracking` |
| `features/sos/presentation/sos_detail_screen.dart` | `/sos/:id/detail` |
| `features/history/presentation/history_screen.dart` | `/history` |
| `features/profile/presentation/profile_screen.dart` | `/profile` |
| `features/profile/presentation/edit_profile_screen.dart` | `/profile/edit` |
| `features/profile/presentation/medical_profile_screen.dart` | `/profile/medical` |
| `features/profile/presentation/emergency_contacts_screen.dart` | `/profile/contacts` |
| `features/notifications/presentation/notifications_screen.dart` | `/notifications` |

---

*This document is the single source of truth for the RakshaPoorvak User App architecture, patterns, and development guidance.*
