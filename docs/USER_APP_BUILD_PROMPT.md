# User Android App – Full Build Prompt

**Use this document as the complete specification for building the RakshaPoorvak User Mobile Application (Flutter, Android).** Follow every instruction exactly. No deviations unless explicitly marked optional.

**IMPORTANT:** This MVP operates for a **single hospital chain** — **MGM Hospital, Navi Mumbai** (3 branches: Vashi, Kamothe, CBD Belapur). All ambulances are owned by MGM. When SOS is triggered, the system auto-assigns the nearest MGM branch as the destination hospital. The user does NOT choose a hospital.

---

## 1. Project Context & References

- **Project:** RakshaPoorvak – Emergency Ambulance Dispatch & Triage System
- **Component:** User Mobile App (Android) – for citizens/patients to request emergency ambulance
- **Backend:** Spring Boot API at `http://10.0.2.2:8080` for Android emulator (or `http://localhost:8080` on device; configurable via environment)
- **Read before building:**
  - `docs/PRD.md` – Product requirements, especially Section 5 (User Application)
  - `docs/BACKEND_TECHNICAL_SPEC.md` – API endpoints, auth, response formats
  - `docs/CODING_RULES.md` – Flutter/Dart rules
  - `docs/PROJECT_STRUCTURE.md` – User App folder structure

---

## 2. Tech Stack (Mandatory)

- **Flutter** 3.x – cross-platform (Android primary; iOS optional later)
- **Dart** 3.x – null safety enabled
- **Maps:** `flutter_map` with **OpenStreetMap** tiles (no API key, free)
- **Location:** `geolocator` – GPS, permissions
- **HTTP:** `dio` – single configured client, interceptors for auth and 401/refresh
- **State management:** `flutter_riverpod` or `provider` – choose one and use consistently
- **Routing:** `go_router` or `auto_route` – declarative routing
- **Storage:** `flutter_secure_storage` – tokens; `shared_preferences` for simple prefs
- **Icons:** `lucide_icons` or `phosphor_flutter` – consistent icon set
- **Date formatting:** `intl` package
- **Deep links / tel:** `url_launcher` – open phone dialer for driver
- **Permissions:** `permission_handler` or `geolocator` for location
- **No** `dynamic`; define models for all API responses

---

## 3. Design System (Mandatory)

### 3.1 Theme (Light – Emergency-App Aesthetic)

- **Primary color:** Emergency red/coral (e.g. `#E53935` or `#DC2626`) – SOS button, critical actions, links
- **Accent:** Calm blue (e.g. `#2563EB`) – tracking, info, secondary actions
- **Background:** Off-white (`#FAFAFA`) for main screens; white for cards
- **Card/panel:** White with `elevation: 2`, `borderRadius: 12`
- **Text:** `#1F2937` primary, `#6B7280` secondary, `#9CA3AF` tertiary
- **Status colors (match backend):**
  - `CREATED` / `DISPATCHING` – amber (`#F59E0B`)
  - `AMBULANCE_ASSIGNED` / `DRIVER_ENROUTE_TO_PATIENT` – blue (`#3B82F6`)
  - `REACHED_PATIENT` / `PICKED_UP` / `ENROUTE_TO_HOSPITAL` – indigo (`#6366F1`)
  - `ARRIVED_AT_HOSPITAL` / `COMPLETED` – green (`#22C55E`)
  - `CANCELLED` – red (`#EF4444`)
  - Criticality: LOW (gray), MEDIUM (amber), HIGH (orange), CRITICAL (red)

### 3.2 Typography

- **Headings:** `fontWeight: FontWeight.w700`, `fontSize: 24` (page), `20` (section), `18` (card)
- **Body:** `fontSize: 16`, `fontWeight: FontWeight.w400`
- **Caption:** `fontSize: 14` for secondary text; `12` for timestamps
- Use a clean sans-serif (e.g. `GoogleFonts.roboto()` or `inter()`)

### 3.3 Spacing & Layout

- Base unit: 8
- Screen padding: `EdgeInsets.symmetric(horizontal: 16, vertical: 20)`
- Card padding: `EdgeInsets.all(16)` or `20`
- Button height: 48–56
- Bottom navigation / FAB safe areas

### 3.4 Components

- **Primary button:** filled, primary color, rounded 12
- **Secondary button:** outlined, primary color
- **SOS button:** large, prominent (see Section 6.2), with animation
- **Input fields:** bordered, `roundedBorder: 12`, focus ring
- **Cards:** white, elevation 2, radius 12
- **Badges:** rounded, status-colored background
- **SnackBar/Toast:** for success/error; use `fluttertoast` or `snackbar`

---

## 4. App Structure & Navigation

### 4.1 Routes

```
/                     → Home (SOS-ready or redirect to active SOS)
/login                → Login
/register             → Register
/home                 → Main home (SOS button, quick actions)
/sos/create           → SOS creation (auto-capture location)
/sos/confirm          → SOS confirmation (symptoms, criticality)
/sos/{id}/tracking    → Live tracking (map, ETA, status)
/sos/{id}/detail      → SOS detail view
/history              → Emergency history
/profile              → Profile
/profile/edit         → Edit profile
/profile/medical      → Medical profile
/profile/contacts     → Emergency contacts
/notifications        → Notifications
```

### 4.2 Navigation Flow

- **Guest:** Login / Register only
- **Logged in, no active SOS:** Home → SOS Create → SOS Confirm → SOS Tracking
- **Logged in, active SOS exists:** Redirect to SOS Tracking on app open
- **Bottom nav or drawer:** Home, History, Profile, Notifications

### 4.3 Deep Linking (Optional)

- Handle `rakshapoorvak://sos/{id}` to open tracking for SOS ID

---

## 5. Feature-by-Feature Implementation

### 5.1 Authentication

#### 5.1.1 Login Screen

- **Route:** `/login`
- **API:** `POST /api/auth/login`
  - Request: `{ "email": string, "password": string }`
  - Response: `{ "accessToken", "refreshToken", "expiresIn", "user": { id, email, fullName, phone, roles } }`
- **UI:** Email field, password field (obscured), "Login" button
- **On success:** Store tokens in secure storage; fetch active SOS; redirect to `/sos/{id}/tracking` if active SOS, else `/home`
- **On error:** Show message below form (from `error.message`)
- **Link:** "Don't have an account? Register"

#### 5.1.2 Register Screen

- **Route:** `/register`
- **API:** `POST /api/auth/register`
  - Request: `{ "email", "password", "fullName", "phone" }` (roles: omit or `["USER"]`)
  - Response: same as login
- **UI:** Full name, email, phone, password, confirm password
- **Validation:** Email format, password min 6 chars, phone optional
- **On success:** Store tokens; redirect to `/home`

#### 5.1.3 Token Refresh

- **API:** `POST /api/auth/refresh` with `{ "refreshToken": string }`
- **When:** 401 on any request; Dio interceptor
- **Flow:** Retry original request with new access token; on refresh failure, clear storage and redirect to login

#### 5.1.4 Logout

- **API:** `POST /api/auth/logout` (optional; client can just clear tokens)
- Clear secure storage; navigate to `/login`

---

### 5.2 SOS Activation (One-Tap SOS)

#### 5.2.1 Home Screen – SOS Button

- **Route:** `/home`
- **UI:**
  - Large, centered **SOS button** – primary color, prominent, impossible to miss
  - Optional: "Request Ambulance" label
  - Background: minimal, calming (light gradient or solid off-white)
- **SOS Button Animation (Mandatory):**
  - **Idle:** Subtle pulse animation (scale 1.0 → 1.02 → 1.0, 2s loop)
  - **Pressed:** Scale down to 0.95, haptic feedback
  - **Long-press or tap:** Navigate to `/sos/create` with current location
- **Check active SOS:** On load, call `GET /api/sos-events/my/active`. If non-empty, redirect to `/sos/{firstActiveId}/tracking`

#### 5.2.2 SOS Create (Auto-Capture Location)

- **Route:** `/sos/create`
- **Flow:**
  1. Request location permission (`geolocator`)
  2. Get current position (with timeout; show loading)
  3. Optionally reverse-geocode for address (Nominatim or skip for MVP)
  4. **API:** `POST /api/sos-events`
     - Request: `{ "latitude": double, "longitude": double, "address": string? }` (symptoms, criticality optional here)
  5. On success: Navigate to `/sos/confirm` with `sosId` (or pass SOS object)
- **Error:** No location → show "Enable location" with button to open settings
- **UI:** Loading spinner + "Getting your location..."; minimal form (can add symptoms/criticality in confirm)

#### 5.2.3 SOS Confirmation Screen

- **Route:** `/sos/confirm` (with `sosId` from create)
- **API:** `PATCH /api/sos-events/{id}` – update symptoms, criticality
  - Request: `{ "symptoms": string?, "criticality": "LOW"|"MEDIUM"|"HIGH"|"CRITICAL" }`
- **UI:**
  - Confirmation message: "SOS sent! Help is on the way."
  - Optional form: Symptoms (text field), Criticality (dropdown/chips: LOW, MEDIUM, HIGH, CRITICAL)
  - "View Tracking" button → navigate to `/sos/{id}/tracking`
- **Back:** Prevent back to create; only allow "View Tracking"

---

### 5.3 Live Ambulance Tracking (Core Feature)

#### 5.3.1 Tracking Screen

- **Route:** `/sos/{id}/tracking`
- **APIs:**
  - `GET /api/sos-events/{id}` – SOS details (status, driver, hospital, etc.)
  - `GET /api/sos-events/{id}/tracking` – live tracking
    - Response: `{ sosEventId, status, ambulanceLatitude, ambulanceLongitude, driverName, driverPhone, estimatedMinutesArrival, locationHistory: [{ latitude, longitude, recordedAt }] }`

#### 5.3.2 Polling

- Poll tracking every **5–10 seconds** when status is not COMPLETED/CANCELLED
- Use `Future.delayed` + `setState` or Riverpod `ref.watch` with timer

#### 5.3.3 Map (OpenStreetMap via flutter_map)

- **Tile URL:** `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- **Dependencies:** `flutter_map`, `latlong2`
- **Markers:**
  - **User/Patient:** Red pin at SOS latitude/longitude
  - **Ambulance:** Custom marker (ambulance icon or green circle) at `ambulanceLatitude`, `ambulanceLongitude` when available
- **Polyline:** Draw route from ambulance to patient using `locationHistory` (connect points in order) OR ambulance → patient straight line if no history
- **Camera:**
  - Fit bounds to show both patient and ambulance with padding
  - If only patient: center on patient, zoom 15
  - Animate camera when ambulance position updates

#### 5.3.4 Ambulance Indicator & ETA (Mandatory)

- **Ambulance marker:** Use a distinct, recognizable ambulance icon (e.g. truck or custom SVG)
  - Color: green when en route, blue when at hospital
  - Show registration number in marker popup/tooltip if available
- **ETA display:**
  - Prominent card: "Estimated arrival: X min" (from `estimatedMinutesArrival`)
  - If `estimatedMinutesArrival == null`, show "Calculating..."
  - Update with each poll

#### 5.3.5 Status Bar

- Horizontal timeline or status chips: CREATED → DISPATCHING → AMBULANCE_ASSIGNED → DRIVER_ENROUTE_TO_PATIENT → REACHED_PATIENT → PICKED_UP → ENROUTE_TO_HOSPITAL → ARRIVED_AT_HOSPITAL → COMPLETED
- Highlight current status
- Human-readable labels (e.g. "Ambulance assigned", "Driver en route", "Reached you", "On the way to hospital")

#### 5.3.6 Driver Info Card

- Driver name, phone (tappable to call via `url_launcher` – `tel:`)
- Ambulance registration
- Destination hospital name and address (e.g. "MGM Hospital, Vashi")

#### 5.3.7 Medical Context Reassurance

On the SOS confirmation screen, show:
- "Your medical profile has been shared with the ambulance team"
- Blood group badge, allergies list (if set in profile)
- "Emergency contacts will be notified" (if contacts exist)
- This reassures the patient that the hospital is prepared

#### 5.3.8 Cancel SOS

- If status is CREATED or DISPATCHING: show "Cancel SOS" button
- **API:** `DELETE /api/sos-events/{id}`
- Confirm dialog before cancel
- On success: navigate to `/home`

---

### 5.4 Status Tracking (Inline in Tracking)

- Same as 5.3.5; ensure all statuses from backend are mapped to user-friendly labels
- Status flow: `CREATED` | `DISPATCHING` | `AMBULANCE_ASSIGNED` | `DRIVER_ENROUTE_TO_PATIENT` | `REACHED_PATIENT` | `PICKED_UP` | `ENROUTE_TO_HOSPITAL` | `ARRIVED_AT_HOSPITAL` | `COMPLETED` | `CANCELLED`

---

### 5.5 Emergency History

- **Route:** `/history`
- **API:** `GET /api/sos-events/my` – returns user's SOS list
- **UI:** List of cards; each card: SOS ID, date, symptoms (truncated), status, criticality
- **Tap card:** Navigate to `/sos/{id}/detail` (read-only)
- **Empty state:** "No past emergencies"

---

### 5.6 SOS Detail (Read-Only)

- **Route:** `/sos/{id}/detail`
- **API:** `GET /api/sos-events/{id}`
- **UI:** Full SOS info – date, symptoms, criticality, status, driver, hospital
- **If active:** "View Tracking" button → `/sos/{id}/tracking`

---

### 5.7 Profile Management

- **Route:** `/profile`
- **API:** `GET /api/users/profile` (or `GET /api/auth/me` for basic info)
- **UI:** Full name, email, phone (read); "Edit Profile" button
- **Edit profile:** `PATCH /api/users/profile` – fullName, phone

#### 5.7.1 Medical Profile

- **Route:** `/profile/medical`
- **APIs:** `GET /api/users/medical-profile`, `PATCH /api/users/medical-profile`
- **Fields:** Blood group, allergies, conditions (per backend DTO)
- **Auto-sent with SOS:** Backend may use this for triage

#### 5.7.2 Emergency Contacts

- **Route:** `/profile/contacts`
- **APIs:**
  - `GET /api/users/emergency-contacts`
  - `POST /api/users/emergency-contacts` – `{ name, phone, relationship }`
  - `PUT /api/users/emergency-contacts/{id}` – update
  - `DELETE /api/users/emergency-contacts/{id}`
- **UI:** List of contacts; add/edit/delete

---

### 5.8 Notifications

- **Route:** `/notifications`
- **APIs:**
  - `GET /api/notifications?page=0&size=20`
  - `GET /api/notifications/unread-count` – for badge
  - `PATCH /api/notifications/{id}/read`
  - `POST /api/notifications/read-all`
- **UI:** List of notifications (title, body, timestamp, read/unread)
- **Badge:** Show unread count in app bar or tab
- **Types:** "Ambulance assigned", "Driver en route", "Ambulance arriving", etc.

---

### 5.9 Communication (Call Driver)

- **Implementation:** Use `url_launcher` with `tel:${driverPhone}` when driver phone is available
- **UI:** "Call Driver" button on tracking screen

---

## 6. API Integration (Exact Spec)

### 6.1 Base Configuration

- Base URL: from env (e.g. `http://10.0.2.2:8080` for emulator)
- Create `lib/core/network/api_client.dart` – Dio with base URL, timeout 15s, `Content-Type: application/json`
- Request interceptor: add `Authorization: Bearer ${accessToken}` from secure storage
- Response interceptor: on 401, call refresh → retry; on refresh failure, logout and redirect to login

### 6.2 API Modules (lib/data/api/)

- `auth_api.dart` – login, register, refresh, me
- `sos_api.dart` – create, update, get, my, myActive, tracking, cancel
- `user_api.dart` – profile, medical profile, emergency contacts
- `notification_api.dart` – list, unread count, mark read, read all

### 6.3 Models (lib/data/models/)

- `user.dart`, `auth_response.dart`, `sos_event.dart`, `tracking.dart`, `notification.dart`, `emergency_contact.dart`, `medical_profile.dart`
- Use `json_serializable` or manual `fromJson`/`toJson`
- All fields match backend DTOs (camelCase in JSON)

### 6.4 Error Handling

- Backend error: `{ "error": { "code", "message", "timestamp" } }`
- Show `message` in SnackBar
- Network errors: "Connection failed. Please check your internet."

---

## 7. Maps (OpenStreetMap – flutter_map)

### 7.1 Setup

```yaml
dependencies:
  flutter_map: ^6.0.0
  latlong2: ^0.9.0
```

### 7.2 Tile Layer

```dart
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.rakshapoorvak.userapp',
)
```

### 7.3 Markers

- **Patient:** `Marker` with `Icon` (red pin) at `LatLng(sos.latitude, sos.longitude)`
- **Ambulance:** `Marker` with custom `Icon` (ambulance/truck) at `LatLng(tracking.ambulanceLatitude, tracking.ambulanceLongitude)`
  - Only show when `ambulanceLatitude != null && ambulanceLongitude != null`

### 7.4 Route Polyline (OSRM – Actual Road Route)

- Use **OSRM** to show the actual driving route from ambulance to patient (not just a straight line or location history trail):
  ```
  GET https://router.project-osrm.org/route/v1/driving/{ambLng},{ambLat};{patientLng},{patientLat}?overview=full&geometries=geojson
  ```
- Decode `routes[0].geometry.coordinates` → list of `LatLng` → draw as blue `Polyline` (strokeWidth 4-5)
- Recalculate every 30s when ambulance position changes
- When status is ENROUTE_TO_HOSPITAL: show route from ambulance → hospital instead
- If OSRM fails: fallback to straight line from `locationHistory`

### 7.5 Fit Bounds

- Compute `LatLngBounds` from patient + ambulance; `mapController.fitBounds(bounds, padding: EdgeInsets.all(40))`
- Animate on ambulance position update

---

## 8. Animations (Mandatory)

### 8.1 SOS Button

- **Pulse:** `AnimationController` + `TweenSequence` for scale (1.0 → 1.03 → 1.0), repeat
- **Press:** Scale 0.95 on tap down, 1.0 on tap up
- **Haptic:** `HapticFeedback.mediumImpact()` on tap

### 8.2 Screen Transitions

- Use `PageRouteBuilder` with `fadeTransition` or `slideTransition` (150–200ms)

### 8.3 Map Marker Updates

- Animate camera to new ambulance position (smooth `fitBounds` or `move`)

### 8.4 Status Changes

- Optional: subtle fade-in when status chip updates

---

## 9. File Structure (Match PROJECT_STRUCTURE.md)

```
user-app/
├── pubspec.yaml
├── .env.example
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   └── routes.dart
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── network/
│   │   │   └── api_client.dart
│   │   └── utils/
│   │       └── format_date.dart
│   ├── data/
│   │   ├── api/
│   │   │   ├── auth_api.dart
│   │   │   ├── sos_api.dart
│   │   │   ├── user_api.dart
│   │   │   └── notification_api.dart
│   │   ├── models/
│   │   │   ├── user.dart
│   │   │   ├── sos_event.dart
│   │   │   ├── tracking.dart
│   │   │   └── ...
│   │   └── repositories/
│   ├── features/
│   │   ├── auth/
│   │   │   └── presentation/
│   │   │       ├── login_screen.dart
│   │   │       └── register_screen.dart
│   │   ├── home/
│   │   │   └── presentation/
│   │   │       └── home_screen.dart
│   │   ├── sos/
│   │   │   └── presentation/
│   │   │       ├── sos_create_screen.dart
│   │   │       ├── sos_confirm_screen.dart
│   │   │       ├── sos_tracking_screen.dart
│   │   │       └── sos_detail_screen.dart
│   │   ├── history/
│   │   │   └── presentation/
│   │   │       └── history_screen.dart
│   │   ├── profile/
│   │   │   └── presentation/
│   │   │       ├── profile_screen.dart
│   │   │       ├── edit_profile_screen.dart
│   │   │       ├── medical_profile_screen.dart
│   │   │       └── emergency_contacts_screen.dart
│   │   └── notifications/
│   │       └── presentation/
│   │           └── notifications_screen.dart
│   └── shared/
│       └── widgets/
│           ├── sos_button.dart
│           ├── status_badge.dart
│           └── map_tracking_widget.dart
└── android/
```

---

## 10. Android-Specific

### 10.1 Permissions (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### 10.2 Runtime Permissions

- Use `permission_handler` or `geolocator`'s permission flow
- Request location before SOS create; show rationale if denied

### 10.3 Minimum SDK

- `minSdkVersion` 21 or higher

---

### 5.10 Destination Hospital Info (on Tracking Screen)

Show a card on the tracking screen:
- "Destination: MGM Hospital, Vashi" (from `hospitalName` in SOS response)
- Hospital address
- This tells the patient which MGM branch they are being taken to

---

## 11. Out of Scope (Do Not Build)

- Video/audio call with doctor (PRD 5.5) – skip for MVP
- iOS-specific code – Android only for now
- WebSocket push – use polling
- Dark theme – light only
- Multi-language – English only

---

## 12. Quality Checklist

- [ ] All API calls use correct endpoints, methods, headers
- [ ] No `dynamic`; all models typed
- [ ] Map uses OpenStreetMap (flutter_map), shows patient + ambulance markers
- [ ] Ambulance marker is distinct; ETA displayed prominently
- [ ] Polyline from ambulance to patient (or location history) when available
- [ ] SOS button has pulse + press animation and haptic
- [ ] 401 triggers refresh or redirect to login
- [ ] Error messages shown for failed API calls
- [ ] Loading states for async operations
- [ ] Empty states (history, notifications)
- [ ] Location permission requested before SOS create
- [ ] Polling for tracking every 5–10s

---

## 13. Test Credentials

- **User:** Register via app or use seeded user (e.g. `user@test.com` / `password123` if seeded)

---

## 14. Final Instruction

Build the User Android App as a **complete, production-ready, emergency-first application**. Every feature listed must be implemented and wired to the backend. The app must feel **seamless and easy to use** in a stressful situation: one tap to SOS, clear tracking with ambulance on map and ETA, and no friction. Prioritize correctness, clarity, and smooth UX. The result should be an **awesome user application** for the RakshaPoorvak use case.
