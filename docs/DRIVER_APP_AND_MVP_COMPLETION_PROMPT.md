# Driver App Build + MVP Completion Prompt

**This document is the final build specification for the RakshaPoorvak MVP.** It covers:
1. Driver Mobile App (Flutter, Android)
2. Backend upgrades for smart dispatch, cascading fallback, cross-branch allocation, and cross-app sync
3. Hospital Dashboard enhancements
4. User App enhancements
5. Seed data for realistic demos (MGM Hospitals, Navi Mumbai)
6. Step-by-step demo guide

**Follow every instruction exactly.** Use creativity to make the UX premium – micro-animations, polished cards, smooth transitions. No broken code, no placeholders, no "TODO" sections. This MVP must impress judges and secure funding.

---

## IMPORTANT CONTEXT — SINGLE HOSPITAL CHAIN MODEL

This MVP operates for a **single hospital chain**: **MGM Hospital, Navi Mumbai**. All three branches belong to the same organization. The product is sold to a hospital chain, not to individual hospitals.

**Implications:**
- All hospitals in the DB are branches of MGM Hospital
- All ambulances are owned by MGM and attached to a specific branch
- All drivers and doctors work for MGM at a specific branch
- Dashboard staff can see data across all branches (admin view) or their own branch
- When a patient triggers SOS, the system auto-assigns the **nearest MGM branch** as the destination hospital
- Ambulance dispatch prefers the **nearest branch's ambulances** first, then cascades to other branches if none are available
- Patient is always routed to the nearest MGM hospital — they don't choose

---

## PART 1 — DRIVER MOBILE APPLICATION (Flutter, Android)

---

### 1.1 Project Context

- **Project:** RakshaPoorvak – Emergency Ambulance Dispatch & Triage System
- **Component:** Driver Mobile App – for ambulance drivers/paramedics of MGM Hospital chain
- **Backend:** Spring Boot at `http://10.0.2.2:8080` (emulator) or `http://<local-ip>:8080` (device)
- **Role:** `DRIVER` – authenticated via JWT
- **Docs to reference:** `docs/PRD.md` (Section 6), `docs/BACKEND_TECHNICAL_SPEC.md`, `docs/CODING_RULES.md`, `docs/PROJECT_STRUCTURE.md`

---

### 1.2 Tech Stack

| Purpose | Package |
|---------|---------|
| Framework | Flutter 3.x, Dart 3.x, null safety |
| Maps | `flutter_map` + `latlong2` (OpenStreetMap tiles, no API key) |
| Route navigation | OSRM free API: `https://router.project-osrm.org/route/v1/driving/{lng1},{lat1};{lng2},{lat2}?overview=full&geometries=geojson` |
| Location | `geolocator` (GPS), `permission_handler` |
| HTTP | `dio` with interceptors |
| State | `flutter_riverpod` (consistent with user app) |
| Routing (app) | `go_router` |
| Storage | `flutter_secure_storage` (tokens), `shared_preferences` |
| Icons | `lucide_icons` or `phosphor_flutter` |
| Dates | `intl` |
| Phone calls | `url_launcher` |

---

### 1.3 Design System (Same Emergency Theme as User App)

#### Colors
- **Primary:** Emergency red/coral `#E53935` – actions, critical states
- **Accent:** Calm blue `#2563EB` – tracking, navigation, info
- **Success:** `#22C55E` – available, completed
- **Warning:** `#F59E0B` – pending, new requests
- **Background:** `#FAFAFA`, cards white
- **Text:** `#1F2937` primary, `#6B7280` secondary

#### Status Colors (match backend exactly)
| Status | Color |
|--------|-------|
| CREATED / DISPATCHING | Amber `#F59E0B` |
| AMBULANCE_ASSIGNED / DRIVER_ENROUTE_TO_PATIENT | Blue `#3B82F6` |
| REACHED_PATIENT / PICKED_UP / ENROUTE_TO_HOSPITAL | Indigo `#6366F1` |
| ARRIVED_AT_HOSPITAL / COMPLETED | Green `#22C55E` |
| CANCELLED | Red `#EF4444` |

#### UI
- Cards: white, elevation 2–4, borderRadius 16
- Buttons: height 52, borderRadius 14, bold text
- Inputs: borderRadius 12, border 1.5
- Animations: page transitions (slide 200ms), button press (scale 0.96), map marker (bounce on update), status changes (fade + slide), incoming request (slide-up with slight overshoot bounce)

---

### 1.4 App Structure & Routes

```
/login                       → Login (DRIVER role only)
/home                        → Dashboard (pending requests, active case, go online/offline)
/request/{sosId}             → Incoming dispatch request (accept/reject with timer)
/case/{sosId}                → Active case (map, navigation, status, patient info)
/case/{sosId}/triage         → Enter vitals
/case/{sosId}/medications    → Enter medications
/case/{sosId}/complete       → Case summary & completion
/history                     → Past cases
/profile                     → Driver profile, license, ambulance info
/notifications               → Notifications
```

**Bottom nav:** Home, History, Profile

---

### 1.5 Feature-by-Feature Implementation

#### 1.5.1 Authentication

**Login Screen (`/login`)**
- **API:** `POST /api/auth/login` → `{ email, password }` → `{ accessToken, refreshToken, expiresIn, user }`
- Validate user has DRIVER role; reject non-drivers with "Access denied. This app is for MGM ambulance drivers only."
- Store tokens in `flutter_secure_storage`
- On success → `/home`

**Token refresh:** Dio interceptor on 401 → `POST /api/auth/refresh`

**Logout:** Clear tokens, navigate to `/login`
- **API:** `POST /api/auth/logout`

---

#### 1.5.2 Home / Dashboard Screen (`/home`)

**Purpose:** Driver's command center – see status, pending requests, active case at a glance

**APIs on load:**
- `GET /api/drivers/me` → driver profile (status, hospital name, ambulance registration)
- `GET /api/dispatch/pending-requests` → pending SOS requests assigned to this driver
- `GET /api/sos-events/driver/active` → check for already-active cases (status between AMBULANCE_ASSIGNED and ARRIVED_AT_HOSPITAL)

**UI layout:**
1. **Header card:** Driver name, ambulance registration, branch name (e.g. "MGM Vashi"), profile photo placeholder
2. **Status toggle:** Large, prominent toggle: Online (AVAILABLE) / Offline (OFFLINE)
   - `PATCH /api/drivers/me` with `{ "status": "AVAILABLE" }` or `{ "status": "OFFLINE" }`
   - Animation: smooth slide + color morph (green ↔ gray), icon change (check ↔ moon)
   - When OFFLINE: dim the screen slightly, show "You are offline – go online to receive requests"
   - When BUSY (active case): show "On active case" in amber, toggle disabled
3. **Active case banner (if exists):** Prominent card at top: urgency pulse animation, "Active Case #X – Patient: Name – Tap to continue" → `/case/{sosId}`
4. **Pending requests section:** Cards for each incoming request
   - Each card shows: criticality badge (large, colored), patient name, symptoms (1-line), distance from driver (Haversine calculation), time since SOS created
   - Tap → `/request/{sosId}`
   - If empty: "No pending requests" with a calm illustration
5. **Stats footer (optional):** Today's completed cases count, total distance driven

**Polling:** Every 8s for pending requests when AVAILABLE and no active case. Stop polling when OFFLINE or on active case.

---

#### 1.5.3 Incoming Request Screen (`/request/{sosId}`)

**API:** `GET /api/dispatch/{sosId}/request-details` → full SOS details

**UI (designed to convey urgency):**
- **Criticality banner at top:** Full-width colored bar (red for CRITICAL, orange for HIGH, amber for MEDIUM, gray for LOW) with label
- **Map preview (upper half):** Map showing:
  - Patient location (red pulsing pin)
  - Driver's current location (blue dot)
  - Route polyline between them (from OSRM)
  - Fit bounds to show both markers
- **Info card (lower half):**
  - Patient name, phone
  - Address (if available)
  - Symptoms (full text)
  - Distance: X.X km (from OSRM `distance`)
  - ETA: X min (from OSRM `duration`)
  - Destination hospital: nearest MGM branch name
- **Action buttons (bottom, side by side):**
  - **Accept** (green, filled, large): `POST /api/dispatch/{sosId}/accept` → navigate to `/case/{sosId}`
  - **Reject** (red, outlined): `POST /api/dispatch/{sosId}/reject` → navigate back to `/home`
    - On reject: backend will automatically notify the next nearest available driver (see Part 2 cascading dispatch)
- **Countdown timer (60s):** Circular progress indicator counting down. If timer expires, auto-reject and notify next driver
  - Show "Respond within X seconds" text
- **Entrance animation:** Slide up from bottom with slight bounce overshoot

---

#### 1.5.4 Active Case Screen (`/case/{sosId}`) – THE CORE SCREEN

This is the most important screen. It handles the entire case from acceptance to hospital arrival.

**APIs:**
- `GET /api/sos-events/{sosId}` → SOS details (patient, hospital, status)
- `GET /api/sos-events/{sosId}/tracking` → tracking info
- OSRM API → route polyline to current destination
- `PATCH /api/sos-events/{sosId}/status` → advance status
- `PATCH /api/ambulances/{ambulanceId}/location` → send GPS
- `POST /api/locations` → record location trail

**Layout (full screen, map-centric):**

```
┌──────────────────────────────┐
│  STATUS BAR (current step)   │ ← Compact horizontal timeline
├──────────────────────────────┤
│                              │
│       FULL-SCREEN MAP        │ ← Route, markers, camera following driver
│                              │
│  ┌─────────────────────────┐ │
│  │  ETA: 4 min  │  1.2 km  │ │ ← Floating chip on map
│  └─────────────────────────┘ │
├──────────────────────────────┤
│  DRAGGABLE BOTTOM SHEET      │ ← Collapsed: action button + patient name
│  ├── Patient info            │    Expanded: full info + quick actions
│  ├── Destination info        │
│  ├── ACTION BUTTON (primary) │
│  └── Quick: Vitals, Meds, Call│
└──────────────────────────────┘
```

**Map behavior:**
- Show route polyline from driver's current location to destination
  - Phase 1 (DRIVER_ENROUTE_TO_PATIENT → REACHED_PATIENT): destination = patient location
  - Phase 2 (PICKED_UP → ARRIVED_AT_HOSPITAL): destination = hospital location
- **Markers:**
  - Driver/Ambulance: Custom ambulance icon (distinct, not generic pin), rotates with heading if possible
  - Patient: Red pin with subtle pulse ring animation
  - Hospital: Blue building icon (destination) with "MGM Vashi" label
- Route: Blue polyline (strokeWidth 5, slight glow effect with opacity layer behind)
- Camera: Smooth follow on driver position, slight look-ahead in direction of travel
- Recalculate route every 30s or on status change

**GPS Broadcasting (CRITICAL for cross-app sync):**
- Start broadcasting immediately when case status is AMBULANCE_ASSIGNED or beyond
- Every **5 seconds**: `geolocator.getCurrentPosition()` → `PATCH /api/ambulances/{ambulanceId}/location` and `POST /api/locations`
- This drives the ambulance movement visible on user app and dashboard
- Continue until COMPLETED or CANCELLED
- Handle GPS failure gracefully (retry, show "GPS signal lost" indicator)

**Status Flow & Actions:**

One prominent, full-width action button changes per status:

| Current Status | Button Text | API Call | Visual |
|---|---|---|---|
| AMBULANCE_ASSIGNED | "🚑 Start Navigation" | `PATCH status → DRIVER_ENROUTE_TO_PATIENT` | Blue, pulsing border |
| DRIVER_ENROUTE_TO_PATIENT | "📍 I've Reached the Patient" | `PATCH status → REACHED_PATIENT` | Blue |
| REACHED_PATIENT | "🏥 Patient Picked Up" | `PATCH status → PICKED_UP` | Indigo |
| PICKED_UP | "🏥 Heading to Hospital" | `PATCH status → ENROUTE_TO_HOSPITAL` | Indigo |
| ENROUTE_TO_HOSPITAL | "✅ Arrived at Hospital" | `PATCH status → ARRIVED_AT_HOSPITAL` | Green |
| ARRIVED_AT_HOSPITAL | "✅ Complete Case" | `POST /api/sos-events/{sosId}/complete` | Green, confirm dialog |

- **Haptic feedback** (medium impact) on every status change
- **Confirmation dialog** before "Complete Case" with case summary
- After "Start Navigation": compute OSRM route ambulance → patient
- After "Heading to Hospital": compute OSRM route current pos → hospital (from SOS `hospitalId`)

**Bottom sheet quick actions (when expanded):**
- "📊 Enter Vitals" → `/case/{sosId}/triage` (enabled when REACHED_PATIENT, PICKED_UP, or ENROUTE_TO_HOSPITAL)
- "💊 Add Medication" → `/case/{sosId}/medications`
- "📞 Call Patient" → `tel:${userPhone}` via `url_launcher`
- Patient medical profile summary: blood group, allergies, conditions (fetched from SOS or user endpoint)

---

#### 1.5.5 Navigation with OSRM (Route Display)

**OSRM API (free, no key):**
```
GET https://router.project-osrm.org/route/v1/driving/{startLng},{startLat};{endLng},{endLat}?overview=full&geometries=geojson&steps=true
```

**Response:**
- `routes[0].geometry.coordinates` → `[[lng, lat], ...]` → convert to `LatLng` list for polyline
- `routes[0].duration` → seconds → "X min"
- `routes[0].distance` → meters → "X.X km"

**Display:**
- Blue polyline (strokeWidth 5)
- Floating ETA/distance chip on map (semi-transparent background)
- Recalculate every 30s while en route
- On status change to ENROUTE_TO_HOSPITAL: recalculate route from current position → hospital coordinates
- If OSRM fails (network): show straight-line fallback with "Route unavailable" note

---

#### 1.5.6 Triage Entry (`/case/{sosId}/triage`)

**API:** `POST /api/triage/records` → `{ "sosEventId", "heartRate", "systolicBp", "diastolicBp", "spo2", "temperature", "notes" }`

**UI (clean medical form):**
- Labeled numeric inputs with units and normal-range hints:
  - Heart Rate: ___ bpm (normal: 60-100)
  - Systolic BP: ___ mmHg / Diastolic BP: ___ mmHg
  - SpO2: ___ % (normal: 95-100)
  - Temperature: ___ °C (normal: 36.1-37.2)
  - Notes: multiline
- Color indicators: green if value is normal, amber if borderline, red if critical
- "Save Vitals" button → toast "Vitals recorded" → navigate back
- **Previous records:** Timeline of existing records below the form (`GET /api/triage/records?sosEventId={sosId}`)
- These vitals appear on the hospital dashboard in real-time

---

#### 1.5.7 Medication Entry (`/case/{sosId}/medications`)

**API:** `POST /api/triage/medications` → `{ "sosEventId", "name", "dosage", "notes" }`

**UI:**
- Form: Medication name (text), Dosage (text, e.g. "300mg"), Notes (multiline)
- "Add Medication" button
- **Previous medications:** Cards below (`GET /api/triage/medications?sosEventId={sosId}`)

---

#### 1.5.8 Case Completion (`/case/{sosId}/complete`)

**Shown after driver completes the case via `POST /api/sos-events/{sosId}/complete`**

**UI:**
- Animated green checkmark (Lottie or custom animation)
- Summary card: Patient name, pickup address, hospital name, total duration, triage records count, medications count
- "Back to Home" button → `/home`

**Backend:** On completion, ambulance → AVAILABLE, driver → AVAILABLE (handled server-side)

---

#### 1.5.9 History (`/history`)

**API:** `GET /api/sos-events/driver/history` (new endpoint, see Part 2)

**UI:** List of completed/cancelled case cards: SOS ID, patient name, date, duration, criticality badge, status badge
- Tap → read-only case detail

---

#### 1.5.10 Profile (`/profile`)

**APIs:** `GET /api/drivers/me`, `PATCH /api/drivers/me`

**UI:** Profile card: Name, email, phone, license number, ambulance registration, MGM branch name
- Status toggle (same as home)
- Logout button

---

#### 1.5.11 Notifications (`/notifications`)

- `GET /api/notifications?page=0&size=20`
- `GET /api/notifications/unread-count`
- `PATCH /api/notifications/{id}/read`
- `POST /api/notifications/read-all`

Badge on bottom nav or app bar.

---

### 1.6 File Structure

```
driver-app/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   └── routes.dart
│   ├── core/
│   │   ├── constants/app_constants.dart
│   │   ├── theme/app_theme.dart
│   │   ├── network/
│   │   │   ├── api_client.dart
│   │   │   └── osrm_client.dart
│   │   └── utils/
│   │       ├── format_date.dart
│   │       ├── haversine.dart
│   │       └── location_service.dart
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
│   │   ├── models/
│   │   │   ├── user.dart, driver.dart, sos_event.dart, tracking.dart
│   │   │   ├── route_info.dart, triage_record.dart, medication.dart
│   │   │   └── notification.dart
│   │   └── repositories/
│   ├── features/
│   │   ├── auth/presentation/login_screen.dart
│   │   ├── home/presentation/home_screen.dart
│   │   ├── dispatch/presentation/request_screen.dart
│   │   ├── case/presentation/
│   │   │   ├── active_case_screen.dart
│   │   │   ├── triage_screen.dart
│   │   │   ├── medications_screen.dart
│   │   │   └── case_complete_screen.dart
│   │   ├── history/presentation/history_screen.dart
│   │   ├── profile/presentation/profile_screen.dart
│   │   └── notifications/presentation/notifications_screen.dart
│   └── shared/widgets/
│       ├── status_badge.dart, map_widget.dart, route_map.dart
└── android/
```

---

## PART 2 — BACKEND UPGRADES FOR MVP

---

### 2.1 Cascading Smart Dispatch Algorithm (Upgrade DispatchService)

This is the **core intelligence** of the system. When `POST /api/dispatch/{sosId}/find-ambulance` is called:

**Step 1 — Auto-assign nearest hospital (if not set)**
- If `sosEvent.hospitalId == null`: calculate Haversine distance from SOS lat/lng to ALL hospitals, pick the closest → set on SOS
- This ensures the patient goes to the nearest MGM branch

**Step 2 — Find nearest available ambulance (prefer same branch)**
1. Get AVAILABLE ambulances from the **assigned hospital's branch** first
2. For each: calculate Haversine distance to SOS location
3. Sort ascending by distance
4. If ≥1 found: pick the closest → proceed to Step 3

**Step 3 — Cross-branch fallback (if no ambulance at nearest branch)**
1. If no AVAILABLE ambulances at the assigned branch: search **ALL other branches**
2. Get all AVAILABLE ambulances across all hospitals
3. For each: calculate Haversine distance to SOS location
4. Sort ascending, pick closest
5. If found: use that ambulance (even though it's from another branch)
6. If still none: return error `{ "error": { "code": "NO_AMBULANCE_AVAILABLE", "message": "No ambulance available across all MGM branches. Please try again shortly." } }`

**Step 4 — Assign ambulance + driver**
1. Set ambulance status → DISPATCHED
2. Set ambulance on SOS event
3. Find an AVAILABLE driver at the **ambulance's hospital** → assign driver, set driver status → BUSY
4. Set SOS status → AMBULANCE_ASSIGNED
5. Create notifications:
   - DRIVER notification: "New emergency dispatch – [Patient Name], [Criticality]"
   - USER notification: "Ambulance assigned! An MGM ambulance is on the way."
   - HOSPITAL notification: "Ambulance [RegNo] dispatched for SOS #[id]"

### 2.2 Cascading on Driver Reject

When `POST /api/dispatch/{sosId}/reject` is called:

1. Unassign the current ambulance and driver from the SOS
2. Set ambulance → AVAILABLE, driver → AVAILABLE
3. Set SOS status back to DISPATCHING
4. **Auto-retry dispatch:** Immediately re-run the dispatch algorithm (Step 2 above), excluding the just-rejected ambulance
5. If a new ambulance is found: assign and notify the new driver
6. If no ambulance: set SOS status → CREATED, notify hospital: "No ambulance accepted. Manual dispatch required."

### 2.3 Driver History Endpoint

Add to `SosController`:
```
GET /api/sos-events/driver/history
@PreAuthorize("hasRole('DRIVER')")
```
Returns SOS events where `driverId` matches current driver's ID, ordered by `createdAt DESC`.

Also add:
```
GET /api/sos-events/driver/active
@PreAuthorize("hasRole('DRIVER')")
```
Returns active SOS (status between AMBULANCE_ASSIGNED and ARRIVED_AT_HOSPITAL) assigned to the current driver.

### 2.4 Ambulance + Driver Status Reset on Completion

In `SosService.complete()`:
1. Set SOS status → COMPLETED, `completedAt = Instant.now()`
2. Set `ambulance.status = AVAILABLE`
3. Set `driver.status = AVAILABLE`
4. Create notifications:
   - USER: "Your emergency case #X has been completed. Stay safe!"
   - HOSPITAL: "SOS #X completed. Ambulance [RegNo] is now available."

### 2.5 Notification Creation on All Status Changes

In `SosService.updateStatus()`, add notifications for each transition:

| New Status | Recipient | Title | Body |
|---|---|---|---|
| DRIVER_ENROUTE_TO_PATIENT | USER | "Ambulance On The Way!" | "Your MGM ambulance is en route. ETA: X min" |
| DRIVER_ENROUTE_TO_PATIENT | HOSPITAL | "Driver En Route" | "Driver [Name] is heading to patient for SOS #X" |
| REACHED_PATIENT | USER | "Ambulance Arrived" | "The ambulance has reached your location" |
| REACHED_PATIENT | HOSPITAL | "Patient Reached" | "Driver reached patient for SOS #X" |
| PICKED_UP | HOSPITAL | "Patient Picked Up" | "Patient picked up, heading to [Hospital Name]" |
| ENROUTE_TO_HOSPITAL | HOSPITAL | "En Route to Hospital" | "Ambulance [RegNo] heading to [Hospital]. Prepare for arrival." |
| ARRIVED_AT_HOSPITAL | HOSPITAL | "Ambulance Arrived" | "Ambulance [RegNo] arrived at hospital with patient" |
| ARRIVED_AT_HOSPITAL | USER | "Arrived at Hospital" | "You have arrived at [Hospital Name]" |

### 2.6 Auto-Attach Medical Context to SOS

When SOS is created (`SosService.create()`):
1. Fetch the user's `MedicalProfile` (blood group, allergies, conditions)
2. Fetch the user's `EmergencyContacts`
3. Include in the SOS response DTO (or create a new field/endpoint)
4. This data is then visible to the driver (bottom sheet) and hospital dashboard (SOS detail)

Add to `SosEventDto`:
- `bloodGroup: String?`
- `allergies: String?`
- `medicalConditions: String?`
- `emergencyContacts: List<EmergencyContactDto>?`

### 2.7 Smart Resource Allocation – Hotspot Analysis

Add `GET /api/analytics/hotspots?days=30`:

**Algorithm:**
1. Query all SOS events from last N days
2. Group by grid cells (round lat to 2 decimal, lng to 2 decimal)
3. Count per cell
4. Sort descending
5. Return top 5-10 with: `latitude`, `longitude`, `count`, `suggestedLabel` (reverse geocode or area name)

**Response:** `[ { "latitude": 19.04, "longitude": 73.02, "count": 12, "suggestedLabel": "Vashi Station Area" } ]`

Dashboard shows these as colored markers on the map or a table with "Suggested ambulance positioning."

### 2.8 ETA Calculation Enhancement

In `SosService.getTracking()`:
- If ambulance has coordinates and SOS has coordinates:
  - Calculate `estimatedMinutesArrival` using Haversine distance / average speed (40 km/h in city)
  - Or optionally call OSRM server-side for actual drive time
- Return this in `TrackingDto.estimatedMinutesArrival`

---

## PART 3 — HOSPITAL DASHBOARD ENHANCEMENTS

---

The dashboard must feel like a **live command center**, not a generic CRUD admin panel.

### 3.1 Dashboard Home – Live Pulse

- Stat cards should have subtle entrance animations (slide up + fade, staggered)
- Active SOS count card: if count > 0, show amber pulse ring animation
- "Available Ambulances" card: show ratio visually (e.g. mini progress bar under the number)
- Auto-refresh every 15s with a subtle "Last updated: Xs ago" indicator

### 3.2 SOS Detail Page – Full Command View

When viewing an active SOS:

**Embed a live map** (not just text coordinates):
- Poll `GET /api/sos-events/{id}/tracking` every 8s
- Show ambulance marker moving on embedded map
- Show route polyline from ambulance to destination (compute client-side or from location history)
- Show ETA countdown: "Arriving in ~X min"

**Patient medical context card:**
- Blood group, allergies, conditions (from enhanced SOS DTO)
- Emergency contacts with click-to-call

**Live triage panel:**
- Poll `GET /api/triage/records?sosEventId={id}` and `GET /api/triage/medications?sosEventId={id}` every 15s
- Show latest vitals with colored indicators (green/amber/red based on ranges)
- Show medications list
- Label: "In-Transit Medical Records" – this is a key differentiator

### 3.3 Auto-Dispatch UX Flow

When a new SOS appears:
1. Toast notification: "🚨 New SOS Alert! Patient: [Name] – [Criticality]" with sound icon
2. SOS detail page: large, prominent "Find & Assign Nearest Ambulance" button
3. Show loading state while dispatching
4. On success: show assigned driver, ambulance, and ETA. Button changes to "Ambulance Assigned ✓"
5. On failure (no ambulance): show error message with "Retry" button

### 3.4 Notifications Page – Real-Time Badge

- Unread count badge on sidebar and topbar bell icon
- New notifications auto-appear (poll every 15s)

### 3.5 Analytics Enhancements

- **Hotspot map:** Show `GET /api/analytics/hotspots` data as colored circles on a map
- Label: "Emergency Hotspots – Suggested Ambulance Positioning"
- This demonstrates the Smart Resource Allocation feature to judges

### 3.6 Visual Polish

- Sortable table headers (click to sort by column)
- Hover effects on all interactive elements
- Empty states with illustrations/icons
- Smooth sidebar collapse animation
- Use consistent Lucide icons everywhere
- Status timeline component on SOS detail (already exists, ensure it's polished)

---

## PART 4 — USER APP ENHANCEMENTS

---

### 4.1 OSRM Route on Tracking Screen

The user app should also show the **actual road route** (not just straight line) from ambulance to patient:
- Call OSRM API from the app: `GET https://router.project-osrm.org/route/v1/driving/{ambLng},{ambLat};{patientLng},{patientLat}?overview=full&geometries=geojson`
- Draw blue polyline on the map
- Recalculate every 30s when ambulance position changes

### 4.2 Medical Context Reassurance

On the SOS confirmation screen, show:
- "Your medical profile has been shared with the ambulance team"
- Blood group badge, allergies (if set)
- "Emergency contacts will be notified" (if contacts exist)

### 4.3 Destination Hospital Info

On the tracking screen, show a card:
- "Destination: MGM Hospital, Vashi" (from `hospitalName` in SOS)
- Hospital address
- This reassures the patient about where they're being taken

### 4.4 Post-Case Feedback (Optional but Impressive)

After case completion, show a simple feedback screen:
- "How was your experience?" – 1-5 star rating
- Optional comment
- "Submit" or "Skip" → navigate home
- Store locally (or add a simple endpoint) – shows product maturity

---

## PART 5 — CROSS-APP STATUS SYNCHRONIZATION

---

### 5.1 Complete Status Flow with All Stakeholders

| Status | Trigger | User App | Driver App | Dashboard |
|--------|---------|----------|------------|-----------|
| CREATED | User taps SOS | "Searching for ambulance..." + loading animation | — | New SOS in list, notification toast |
| DISPATCHING | Dashboard clicks "Find Ambulance" | "Finding nearest ambulance..." | — | Loading indicator |
| AMBULANCE_ASSIGNED | Backend assigns | "Ambulance assigned! ETA X min" + driver info + map | Incoming request card on home | SOS updated: ambulance, driver shown |
| DRIVER_ENROUTE_TO_PATIENT | Driver taps "Start Navigation" | Ambulance moving on map, ETA countdown | Route to patient, GPS broadcasting | Ambulance moving on map |
| REACHED_PATIENT | Driver taps "Reached" | "Ambulance has arrived!" | Enable triage/medication | Status update |
| PICKED_UP | Driver taps "Pick Up" | "Heading to hospital" | — | "Patient picked up" |
| ENROUTE_TO_HOSPITAL | Driver taps "Head to Hospital" | Route to hospital shown | Navigation to hospital | "En route to hospital" |
| ARRIVED_AT_HOSPITAL | Driver taps "Arrived" | "Arrived at hospital" | Complete button enabled | "Ambulance arrived" |
| COMPLETED | Driver completes | "Case completed" → home | Summary → home | Archived, ambulance AVAILABLE |
| CANCELLED | User cancels | Confirm → home | Case removed if pending | Status red |

### 5.2 Cascading Dispatch Visibility

When driver rejects:
- User sees: (no change, still "Searching...")
- Dashboard sees: "Driver [X] rejected. Reassigning..." → then "Ambulance [Y] assigned"
- New driver sees: incoming request
- If all reject: Dashboard sees "No ambulance available" error, user sees "We're working on finding an ambulance"

### 5.3 Polling Strategy

| App | Endpoint | Interval | Condition |
|-----|----------|----------|-----------|
| User | `GET /api/sos-events/{id}/tracking` | 5-8s | SOS active |
| User | `GET /api/sos-events/my/active` | On app open / resume | Check for active SOS |
| Driver | `GET /api/dispatch/pending-requests` | 8s | AVAILABLE, no active case |
| Driver | `GET /api/sos-events/{id}` | 10s | During active case (for status sync) |
| Dashboard | `GET /api/dashboard/summary` + `active-sos` | 15s | Always |
| Dashboard | `GET /api/sos-events/{id}/tracking` | 8s | Viewing SOS detail |
| Dashboard | Triage records + medications | 15s | Viewing active SOS detail |
| All | `GET /api/notifications/unread-count` | 30s | Always |

### 5.4 GPS Broadcasting Chain

```
Driver app (every 5s)
   ↓ PATCH /api/ambulances/{id}/location
   ↓ POST /api/locations (trail record)
   ↓
Backend DB: ambulances.current_latitude/longitude updated
   ↓
User app polls GET /api/sos-events/{id}/tracking
   → reads ambulanceLatitude, ambulanceLongitude from ambulance entity
   → draws marker on map
   ↓
Dashboard polls GET /api/map/overview OR GET /api/sos-events/{id}/tracking
   → same ambulance position
   → draws marker on map
```

---

## PART 6 — SEED DATA FOR REALISTIC DEMO

---

Replace existing seed files in `seed/` directory with MGM Hospital Navi Mumbai data.

### 6.1 Hospitals (3 MGM branches in Navi Mumbai)

| Branch | Address | Latitude | Longitude |
|--------|---------|----------|-----------|
| MGM Hospital Vashi | Plot 7, Sector 1, Vashi, Navi Mumbai | 19.0771 | 73.0013 |
| MGM Hospital Kamothe | Sector 21, Kamothe, Navi Mumbai | 19.0178 | 73.0987 |
| MGM Hospital CBD Belapur | Sector 8, CBD Belapur, Navi Mumbai | 19.0235 | 73.0388 |

### 6.2 Users (5 patients in Navi Mumbai area)

| Email | Name | Phone |
|-------|------|-------|
| patient1@test.com | Rahul Sharma | 9876543210 |
| patient2@test.com | Priya Patel | 9876543211 |
| patient3@test.com | Amit Joshi | 9876543217 |
| patient4@test.com | Sneha Reddy | 9876543218 |
| patient5@test.com | Karan Mehta | 9876543219 |

### 6.3 Drivers (4 across branches)

| Email | Name | Branch | License |
|-------|------|--------|---------|
| driver1@test.com | Vikram Singh | MGM Vashi | MH43-2020-12345 |
| driver2@test.com | Anil Kumar | MGM Kamothe | MH43-2019-67890 |
| driver3@test.com | Suresh Patil | MGM Vashi | MH43-2021-54321 |
| driver4@test.com | Ravi Chauhan | MGM CBD Belapur | MH43-2022-11111 |

### 6.4 Staff & Doctors

| Email | Role | Branch | Specialization |
|-------|------|--------|---------------|
| staff@hospital.com | HOSPITAL_STAFF | MGM Vashi | — |
| doctor1@test.com | DOCTOR | MGM Vashi | Emergency Medicine |
| doctor2@test.com | DOCTOR | MGM Kamothe | Trauma Surgery |
| doctor3@test.com | DOCTOR | MGM CBD Belapur | Cardiology |

### 6.5 Ambulances (6 across branches)

| Registration | Branch | Status | Location (near) | Lat | Lng |
|---|---|---|---|---|---|
| MH-43-AB-1001 | MGM Vashi | AVAILABLE | Vashi Station | 19.0760 | 72.9988 |
| MH-43-AB-1002 | MGM Vashi | AVAILABLE | Sanpada | 19.0630 | 73.0120 |
| MH-43-CD-2001 | MGM Kamothe | AVAILABLE | Kamothe Station | 19.0200 | 73.0960 |
| MH-43-CD-2002 | MGM Kamothe | AVAILABLE | Kharghar | 19.0345 | 73.0720 |
| MH-43-EF-3001 | MGM CBD Belapur | AVAILABLE | CBD Belapur Station | 19.0220 | 73.0400 |
| MH-43-EF-3002 | MGM CBD Belapur | AVAILABLE | Nerul | 19.0330 | 73.0165 |

### 6.6 Medical Profiles

| Patient | Blood Group | Allergies | Conditions |
|---------|------------|-----------|------------|
| Rahul | B+ | Penicillin | Asthma |
| Priya | O- | None | Diabetes Type 2 |
| Amit | A+ | Sulfa drugs | Hypertension |
| Sneha | AB+ | Aspirin | None |
| Karan | O+ | None | None |

### 6.7 Emergency Contacts (1-2 per patient)

### 6.8 Historical SOS Events (12+ completed, spread over 30 days)

Variety of:
- Criticalities: 3 LOW, 4 MEDIUM, 3 HIGH, 2 CRITICAL
- Symptoms: chest pain, road accident, burn injury, allergic reaction, seizure, fracture, breathlessness, diabetic emergency, head injury, food poisoning, snake bite, fall from height
- Assigned across all 3 hospitals, all ambulances, all drivers
- Include triage records (realistic vitals) and medications for each
- Include location_updates trails (5-10 points per case simulating ambulance movement)

### 6.9 Active SOS Events for Demo

| Patient | Status | Purpose |
|---------|--------|---------|
| patient3@test.com (Amit) | CREATED | Demo: full dispatch flow from scratch |
| patient1@test.com (Rahul) | DRIVER_ENROUTE_TO_PATIENT | Demo: live tracking in progress |

Keep 4+ ambulances AVAILABLE so fresh dispatch demos work.

### 6.10 Notifications (mix of read/unread across all recipient types)

### 6.11 Password for all accounts: `password123`

---

## PART 7 — DEMO GUIDE (Step-by-Step)

---

### Prerequisites
1. Docker: `docker compose -f docker-compose.raksha-db.yml up -d`
2. Backend: `cd backend && mvn spring-boot:run`
3. Seed data: `./scripts/seed-all.sh`
4. Dashboard: `cd hospital-dashboard && npm run dev`
5. User app: running on emulator/device 1
6. Driver app: running on emulator/device 2

### Demo Flow 1: Complete Emergency Lifecycle (THE STAR DEMO – 5 min)

Show all 3 screens simultaneously (laptop + 2 phones or emulators).

**Step 1 – Patient triggers SOS (User App)**
- Login: `patient1@test.com` / `password123`
- Tap SOS button (show the pulse animation)
- Location auto-captured → SOS created
- Add: "Severe chest pain, difficulty breathing", Criticality: CRITICAL
- Screen: "Searching for ambulance..."
- Point out: "Medical profile and emergency contacts automatically shared"

**Step 2 – Hospital receives alert (Dashboard)**
- Login: `staff@hospital.com` / `password123`
- Show notification badge + toast: "New SOS Alert!"
- Click SOS → detail page shows: patient info, map location, criticality, medical profile
- Point out: "Hospital sees everything instantly – name, location, blood group, allergies"

**Step 3 – Smart dispatch (Dashboard)**
- Click "Find & Assign Nearest Ambulance"
- System finds nearest MGM ambulance → assigns + notifies driver
- Point out: "Algorithm picks the closest ambulance across all MGM branches. If nearest branch is busy, it goes to the next branch automatically."

**Step 4 – Driver accepts (Driver App)**
- Login: `driver1@test.com` / `password123`
- Incoming request: map with route, distance, ETA, patient info
- Show the 60-second countdown timer
- Tap "Accept"
- Point out: "If driver rejects, the next nearest driver is automatically notified"

**Step 5 – Live tracking (ALL 3 SCREENS)**
- Driver taps "Start Navigation" → OSRM route appears, GPS broadcasting starts
- **User App:** ambulance marker moving on map, ETA counting down
- **Dashboard:** same ambulance moving, status "Driver En Route"
- **Driver App:** navigating along route
- Point out: "All three stakeholders see the SAME live data. Zero information gaps."

**Step 6 – Pickup & triage**
- Driver: "Reached Patient" → User: "Ambulance has arrived!"
- Driver: "Pick Up Patient"
- Driver enters vitals: HR 110, BP 150/95, SpO2 92%, Temp 37.5°C, Notes: "Patient conscious, diaphoretic"
- **Dashboard:** vitals appear in real-time on SOS detail
- Point out: "Hospital can prepare before the patient arrives. Doctor can see vitals live."

**Step 7 – Transport**
- Driver: "Head to Hospital" → route recalculates to MGM Vashi
- Driver adds medication: "Aspirin 300mg sublingual, Nitroglycerin spray"
- Dashboard shows medication

**Step 8 – Arrival & completion**
- Driver: "Arrived at Hospital" → "Complete Case"
- Summary shown on driver app
- User app: "Case completed" → back to home
- Dashboard: ambulance back to AVAILABLE, analytics updated
- Point out: "Full digital trail of the emergency – from SOS to completion"

### Demo Flow 2: Cascading Dispatch (30s)

- "What if the nearest ambulance rejects?"
- Show: driver rejects → system auto-finds next nearest → new driver gets request
- "Works across branches too – if Vashi is fully occupied, Belapur's ambulance gets dispatched"

### Demo Flow 3: Patient History & Medical Context (30s)

- User App: Profile → Medical profile, Emergency contacts
- Dashboard: Patients → Search "Rahul" → Full SOS history with triage records

### Demo Flow 4: Analytics & Resource Allocation (30s)

- Dashboard: Analytics → Response time charts, emergency volume trends, severity breakdown
- Dashboard: Hotspot map → "These are high-frequency emergency zones. We suggest positioning ambulances here."

### Demo Flow 5: Notifications Across All Apps (15s)

- Show notification badges and lists on all 3 apps
- "Every status change creates targeted notifications"

### Talking Points for Judges

1. **One-tap SOS** – Zero friction. Auto-captures location, auto-sends medical context.
2. **Smart cascading dispatch** – Nearest ambulance algorithm with cross-branch fallback. If driver rejects, next nearest is auto-notified.
3. **Real-time 3-way sync** – Patient, driver, and hospital see identical live data. No phone calls to coordinate.
4. **In-transit triage** – Vitals and medications recorded BEFORE hospital arrival. Hospital prepares in advance. This saves critical minutes.
5. **OSRM route navigation** – Actual road routes for drivers, visible on all apps.
6. **Smart resource allocation** – Data-driven ambulance positioning based on emergency hotspots.
7. **Built for hospital chains** – Manages multiple branches with shared ambulance fleet and cross-branch dispatch.
8. **Complete digital trail** – Every emergency fully documented: timestamps, locations, vitals, medications, outcomes.
9. **Scalable architecture** – Spring Boot, PostgreSQL, JWT, role-based access. Ready for production scale.
10. **Open source maps** – No API key costs. OpenStreetMap + OSRM. Fully free infrastructure.

---

## PART 8 — QUALITY CHECKLIST

---

### Driver App
- [ ] Login validates DRIVER role
- [ ] Home: status toggle, pending requests, active case banner
- [ ] Request screen: map with OSRM route, countdown timer, accept/reject
- [ ] Active case: full-screen map, OSRM route, GPS every 5s, status buttons
- [ ] Cascading status: ASSIGNED → ENROUTE → REACHED → PICKED_UP → ENROUTE_HOSPITAL → ARRIVED → COMPLETE
- [ ] Triage: form with normal-range hints, color indicators, previous records
- [ ] Medications: add + list previous
- [ ] Completion: animated summary, ambulance/driver auto-AVAILABLE
- [ ] History, Profile, Notifications all functional

### User App
- [ ] SOS button with pulse animation and haptic
- [ ] OSRM route polyline on tracking map (not straight line)
- [ ] Medical context shown on confirmation screen
- [ ] Destination hospital info shown
- [ ] Status timeline with human-readable labels
- [ ] Cancel SOS when CREATED/DISPATCHING
- [ ] Call driver button

### Hospital Dashboard
- [ ] Live map with ambulance tracking on SOS detail
- [ ] Triage records and medications visible in real-time
- [ ] Medical context (blood group, allergies) on SOS detail
- [ ] Hotspot analysis on analytics page
- [ ] New SOS toast notification
- [ ] "Find Ambulance" button with loading + success state

### Backend
- [ ] Cascading dispatch: nearest branch first, cross-branch fallback
- [ ] Reject cascade: auto-reassign to next nearest
- [ ] Auto-assign nearest hospital on SOS create
- [ ] Notifications on every status change
- [ ] Ambulance + driver → AVAILABLE on completion
- [ ] Medical context attached to SOS DTO
- [ ] Driver history + active case endpoints
- [ ] Hotspot analysis endpoint

### Cross-App
- [ ] GPS broadcasting → ambulance moves on user app + dashboard
- [ ] Status changes propagate to all 3 apps via polling
- [ ] Notifications appear correctly for each role
- [ ] Consistent status colors across all apps

### Data
- [ ] Seed data: 3 MGM Navi Mumbai hospitals, 6 ambulances, 4 drivers, 5 patients
- [ ] 12+ historical SOS with triage + medications + location trails
- [ ] 2 active SOS for demo flows
- [ ] All passwords: password123

---

## PART 9 — FINAL INSTRUCTION

---

Build the Driver App and apply all backend/dashboard/user-app upgrades as a **complete, production-ready MVP for MGM Hospital Navi Mumbai**.

**Be creative:** This must NOT look generic. Add micro-animations (entrance, press, pulse). Use card shadows and elevation thoughtfully. Make the ambulance marker unmistakable. Make charts in analytics visually striking. The triage form should feel medical-grade. The SOS button should feel urgent. The dispatch flow should feel instant.

**Be precise:** Every API call must match the backend exactly. Status flows must cascade correctly. GPS must update the ambulance position across all apps. Notifications must target the right recipients. The cascading dispatch (reject → next driver → cross-branch) must work flawlessly.

**Be thorough:** Handle edge cases:
- No GPS → "Enable location" with settings button
- No ambulance available → clear error with retry
- Driver rejects → auto-cascade to next
- All drivers busy → error to dashboard
- Network offline → "Connection lost" banner
- Empty states → meaningful messages with icons
- Token expired → refresh or redirect to login

**Be a startup:** This MVP must convince judges that this is a real, fundable product. The polish, the flow, the data – everything should tell the story of "we solve a life-saving problem, and we've built it end-to-end."

Build accordingly.
