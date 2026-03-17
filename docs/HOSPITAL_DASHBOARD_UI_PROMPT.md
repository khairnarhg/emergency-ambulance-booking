# Hospital Dashboard UI – Full Build Prompt

**Use this document as the complete specification for building the RakshaPoorvak Hospital Dashboard.** Follow every instruction exactly. No deviations unless explicitly marked optional.

---

## 1. Project Context & References

- **Project:** RakshaPoorvak – Emergency Ambulance Dispatch & Triage System
- **Component:** Hospital Dashboard (web app for hospital emergency command center)
- **Backend:** Spring Boot API at `http://localhost:8080` (configurable via `VITE_API_URL`)
- **Read before building:**
  - `docs/PRD.md` – Product requirements, especially Section 7 (Hospital Dashboard)
  - `docs/BACKEND_TECHNICAL_SPEC.md` – API architecture
  - `docs/POSTMAN_API_REFERENCE.md` – Exact endpoints, headers, request/response formats
  - `docs/CODING_RULES.md` – React/TypeScript rules
  - `docs/PROJECT_STRUCTURE.md` – Hospital Dashboard folder structure

---

## 2. Tech Stack (Mandatory)

- **React 18+** with TypeScript (strict mode)
- **Vite** – build tool
- **Axios** – HTTP client (single configured instance, interceptors for auth and 401)
- **TailwindCSS** – styling only; no other CSS framework
- **React Router** – routing
- **Zustand** – state management (auth, notifications, shared UI state)
- **React Query (TanStack Query)** – server state, caching, pagination
- **React Leaflet** – maps (OpenStreetMap tiles)
- **Lucide React** or **Heroicons** – icons (use consistently throughout)
- **date-fns** – date/time formatting
- **No** `any` types; define interfaces for all API responses and props

---

## 3. Design System (Mandatory)

### 3.1 Theme
- **Light theme only** – clean, modern, professional
- This theme will be reused for mobile apps; keep tokens (colors, spacing, typography) in a single `theme.ts` or Tailwind config
- **Primary color:** Soft blue (e.g. `#2563eb` or similar) – use for primary actions, links, active states
- **Background:** Off-white / light gray (`#f8fafc`, `#f1f5f9`)
- **Card/panel background:** White with subtle shadow
- **Text:** Dark gray for primary text, medium gray for secondary
- **Status colors:**
  - `CREATED` / `DISPATCHING` – amber/yellow
  - `AMBULANCE_ASSIGNED` / `DRIVER_ENROUTE_TO_PATIENT` – blue
  - `REACHED_PATIENT` / `PICKED_UP` / `ENROUTE_TO_HOSPITAL` – indigo
  - `ARRIVED_AT_HOSPITAL` / `COMPLETED` – green
  - `CANCELLED` – red
  - Criticality: LOW (gray), MEDIUM (yellow), HIGH (orange), CRITICAL (red)

### 3.2 Typography
- Use a clear sans-serif (e.g. Inter, DM Sans, or system-ui)
- Hierarchy: `text-2xl` for page titles, `text-lg` for section titles, `text-base` for body, `text-sm` for secondary

### 3.3 Spacing & Layout
- Base spacing unit: 4px (Tailwind default)
- Card padding: `p-4` or `p-6`
- Section gaps: `space-y-4` or `space-y-6`
- Sidebar width: 256px (collapsed: 72px or hide)
- Topbar height: 64px

### 3.4 Components
- Buttons: primary (filled), secondary (outline), ghost, danger
- Inputs: consistent border, focus ring, error state
- Tables: striped or alternating row background, hover highlight
- Cards: white background, rounded corners (`rounded-lg`), `shadow-sm`
- Modals: centered overlay, slide-in or fade-in animation
- Badges: rounded-full or rounded-md, status-based colors

---

## 4. Layout Structure (Mandatory)

### 4.1 App Shell
```
┌─────────────────────────────────────────────────────────────┐
│  Topbar (logo, search, notifications bell, user menu)       │
├──────────────┬──────────────────────────────────────────────┤
│              │                                              │
│   Sidebar    │              Main Content Area               │
│   (nav)      │              (outlet for routes)             │
│              │                                              │
│   - Collapse │   - Full width/height                        │
│   - Animated │   - Scrollable if needed                     │
│              │                                              │
└──────────────┴──────────────────────────────────────────────┘
```

### 4.2 Sidebar
- **Items (with icons):**
  - Dashboard (home icon)
  - SOS Monitor (alert icon)
  - Live Map (map icon)
  - Ambulances (truck icon)
  - Staff (users icon) – doctors & drivers
  - Analytics (chart icon)
  - Notifications (bell icon)
- **Behavior:**
  - Collapsible with smooth CSS transition (e.g. 200ms ease)
  - Active route highlighted
  - Icons always visible; labels show when expanded
  - No nested menus for MVP

### 4.3 Topbar
- Logo + app name "RakshaPoorvak"
- Optional: global search (can be placeholder)
- Notifications dropdown (unread count badge)
- User dropdown: name, logout
- Responsive: sidebar can toggle to hamburger on smaller screens

---

## 5. Authentication Flow

### 5.1 Login Page (`/login`)
- Route: `/login` (public)
- Form: email, password
- API: `POST /api/auth/login` with `{ email, password }`
- On success: store `accessToken`, `refreshToken`, `user` in Zustand; redirect to `/`
- On error: show message below form
- "Remember me" optional

### 5.2 Protected Routes
- All routes except `/login` require auth
- If no token: redirect to `/login`
- Axios interceptor: add `Authorization: Bearer <accessToken>` to every request
- On 401: try `POST /api/auth/refresh` with `refreshToken`; on success update token and retry; on failure redirect to `/login`

### 5.3 Logout
- API: `POST /api/auth/logout` (optional; client clears tokens)
- Clear Zustand store; redirect to `/login`

---

## 6. Page-by-Page Implementation

### 6.1 Command Dashboard (`/`)
- **Purpose:** Overview of active emergencies, ambulances, quick stats
- **API calls:**
  - `GET /api/dashboard/summary?hospitalId={id}` – active SOS count, ambulance stats, response times
  - `GET /api/dashboard/active-sos?hospitalId={id}` – list of active SOS
- **Layout:**
  - Row of stat cards (e.g. Active SOS, Available Ambulances, Response Time Avg)
  - Table or list of active SOS (ID, patient, status, criticality, time) – max 10, link to detail
  - "View All" → SOS Monitor
- **Hospital ID:** From `GET /api/hospitals/my-hospital` after login; store in Zustand or pass via context

### 6.2 SOS Monitor (`/sos`)
- **Purpose:** View and manage all SOS cases
- **API:** `GET /api/sos-events?hospitalId={id}&status={status}&page={page}&size={size}`
  - `status` filter: CREATED, DISPATCHING, AMBULANCE_ASSIGNED, etc. (dropdown)
  - Pagination: page 0-based, size 10 or 20
- **Table columns:** ID, Patient Name, Phone, Status, Criticality, Symptoms (truncated), Created At, Actions
- **Actions per row:** View Detail, Find Ambulance (if status CREATED/DISPATCHING), Assign Doctor (if ambulance assigned)
- **Pagination:** Previous/Next, page numbers, "Showing X–Y of Z"
- **Click row or "View"** → SOS Detail page

### 6.3 SOS Detail (`/sos/:id`)
- **Purpose:** Full view of one SOS – patient info, location, status, triage, medications, actions
- **API calls:**
  - `GET /api/sos-events/{id}` – full SOS
  - `GET /api/sos-events/{id}/tracking` – ambulance location, ETA
  - `GET /api/triage/records?sosEventId={id}` – vitals
  - `GET /api/triage/medications?sosEventId={id}` – medications
- **Sections:**
  - Header: SOS ID, status badge, criticality badge
  - Patient: name, phone, location (lat/lng, address)
  - Status timeline (visual: CREATED → ... → COMPLETED)
  - Actions: Find Ambulance, Assign Doctor, Unassign Doctor (as applicable)
  - Tracking: ambulance location, driver name, ETA (if assigned)
  - Triage: table of vitals (HR, BP, SpO2, temp, notes, time)
  - Medications: table (name, dosage, notes, time)
- **Find Ambulance:** `POST /api/dispatch/{sosId}/find-ambulance` – show success toast or error (e.g. "No ambulance available")
- **Assign Doctor:** `POST /api/sos-events/{sosId}/assign-doctor` – handle "No doctor available" error; show toast

### 6.4 Live Map (`/map`)
- **Purpose:** Map with ambulances, active SOS locations, hospitals
- **API:** `GET /api/map/overview` – returns ambulances, SOS, hospitals with lat/lng
- **Map library:** React Leaflet, OpenStreetMap tiles
- **Markers:**
  - Ambulance: custom icon (e.g. truck), color by status (AVAILABLE=green, DISPATCHED=blue)
  - SOS/Patient: pin icon, color by criticality
  - Hospital: building icon
- **Popup on marker click:** ID, name, status/criticality, link to SOS detail if applicable
- **Behavior:** Smooth pan/zoom; fit bounds to show all markers on load; optional refresh button or auto-refresh every 30s
- **Fallback:** Center on India (e.g. 20.59, 78.96) if no data

### 6.5 Ambulances (`/ambulances`)
- **Purpose:** List ambulances for the hospital
- **API:** `GET /api/ambulances?hospitalId={id}`
- **Table:** Registration, Status, Current Location (lat/lng), Hospital, Last Updated
- **Pagination:** If backend returns many; otherwise simple table
- **Status badge:** color-coded

### 6.6 Staff (`/staff`)
- **Purpose:** Doctors and drivers (online, offline, busy)
- **API:**
  - `GET /api/doctors?hospitalId={id}`
  - `GET /api/drivers?hospitalId={id}`
- **Layout:** Two sections or tabs – Doctors, Drivers
- **Tables:** Name, Status, Hospital (if multi), Last Activity (if API provides)
- **Status badges:** AVAILABLE (green), BUSY (blue), OFFLINE (gray)

### 6.7 Analytics (`/analytics`)
- **Purpose:** Response times, emergency volume
- **API:**
  - `GET /api/analytics/response-times`
  - `GET /api/analytics/emergency-volume`
  - `GET /api/analytics/dashboard`
- **Charts:** Use a lightweight chart library (e.g. Recharts) – bar/line for volume over time, response time metrics
- **Layout:** Cards with chart + summary text

### 6.8 Notifications (`/notifications`)
- **Purpose:** List and manage notifications
- **API:**
  - `GET /api/notifications` – list
  - `GET /api/notifications/unread-count` – badge
  - `PATCH /api/notifications/{id}/read` – mark one read
  - `POST /api/notifications/read-all` – mark all read
- **List:** Title, body, read/unread, timestamp
- **Action:** Mark all as read button
- **Unread count** shown in topbar bell icon

### 6.9 Patient History (`/patients`)
- **Purpose:** Search patients and view history
- **API:**
  - `GET /api/patients/search?q={query}` – search by name/phone
  - `GET /api/patients/{userId}/history` – SOS history for a patient
- **Search bar** → results table (name, phone, last SOS date)
- **Click patient** → detail with history (list of past SOS with date, symptoms, outcome)
- **Pagination:** If search returns many results

---

## 7. API Integration (Exact Spec)

### 7.1 Base Configuration
- Base URL: `import.meta.env.VITE_API_URL || 'http://localhost:8080'`
- Create `src/api/client.ts` – Axios instance with `baseURL`, `timeout`, `headers: { 'Content-Type': 'application/json' }`
- Request interceptor: add `Authorization: Bearer ${accessToken}` from Zustand
- Response interceptor: on 401, attempt refresh → retry or redirect to login

### 7.2 API Modules
Create separate files under `src/api/`:
- `auth.api.ts` – login, logout, refresh, me
- `sos.api.ts` – list, get, active, tracking, assign-doctor, unassign-doctor
- `dispatch.api.ts` – find-ambulance
- `hospitals.api.ts` – list, get, my-hospital
- `ambulances.api.ts` – list, get, location
- `doctors.api.ts` – list
- `drivers.api.ts` – list
- `triage.api.ts` – records, medications
- `analytics.api.ts` – response-times, emergency-volume, dashboard
- `notifications.api.ts` – list, unread-count, mark-read, read-all
- `patients.api.ts` – search, history
- `map.api.ts` – overview, ambulances

### 7.3 Types
- Define `src/types/` – interfaces for every API response and request body
- Match backend DTOs: camelCase in JSON
- Example: `SosEvent`, `User`, `Hospital`, `Ambulance`, `TriageRecord`, `Medication`, `Notification`, etc.

### 7.4 Error Handling
- Backend error format: `{ error: { code, message, timestamp } }`
- Display `message` in toast or inline error
- Never expose stack traces
- Network errors: "Connection failed. Please try again."

---

## 8. State Management

### 8.1 Zustand Stores
- `authStore`: `{ user, accessToken, refreshToken, setAuth, logout }`
- `notificationStore`: `{ unreadCount, setUnreadCount }` – sync with API
- `hospitalStore`: `{ hospitalId, hospital, setHospital }` – from my-hospital after login

### 8.2 React Query
- Use for all server data: SOS list, detail, ambulances, doctors, drivers, analytics, notifications, patients
- `staleTime`, `cacheTime` – e.g. 30s for live data (SOS, map), 5min for static (hospitals)
- Pagination: `keepPreviousData` for SOS list
- Invalidations: after assign-doctor, find-ambulance → invalidate SOS queries

---

## 9. Maps (React Leaflet + OpenStreetMap)

### 9.1 Setup
- `react-leaflet`, `leaflet` – add Leaflet CSS in `index.html` or main CSS
- Tile URL: `https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png`
- Container: `min-height: 400px` or fill viewport

### 9.2 Markers
- Use `Marker`, `Popup` from react-leaflet
- Custom icons: `L.divIcon` or `L.icon` with custom HTML/SVG for ambulance, SOS, hospital
- Clustering: consider `react-leaflet-cluster` if many markers

### 9.3 Smooth UX
- Debounce or throttle re-renders if data updates frequently
- Fit bounds to markers on load
- Avoid unnecessary re-mounts (use `key` wisely)

---

## 10. Tables & Pagination

### 10.1 Table Component
- Reusable `DataTable` in `src/components/common/DataTable/`
- Props: `columns`, `data`, `pagination`, `loading`, `onRowClick`, `actions`
- Empty state: "No data" message
- Loading: skeleton or spinner

### 10.2 Pagination
- Props: `page`, `size`, `total`, `onPageChange`, `onSizeChange`
- UI: Previous, 1 2 3 … Next, "Show 10 / 20 / 50"
- Backend: `page` 0-based, `size` default 20

---

## 11. Animations

- **Sidebar:** `transform: translateX()` or `width` transition, 200–300ms ease
- **Modals:** fade-in overlay, scale/slide-in content
- **Page transitions:** optional fade (e.g. 150ms)
- **Lists:** optional stagger on mount (low priority)
- Use CSS transitions or `framer-motion` (if added) – keep lightweight

---

## 12. Icons

- Use one library consistently (Lucide React or Heroicons)
- Map: `Map`, `MapPin`, `Truck`, `Building`, `AlertCircle`, `User`, `Bell`, `LogOut`, `Home`, `Users`, `BarChart3`, etc.
- Same icon set for sidebar, topbar, buttons, status indicators

---

## 13. Accessibility & Responsiveness

- Semantic HTML: `nav`, `main`, `header`, `button`, `input` with labels
- Focus states for keyboard navigation
- Responsive: sidebar collapses to hamburger on small screens; tables scroll horizontally if needed
- Minimum width for dashboard: ~1024px for comfortable use (document in README)

---

## 14. File Structure (Match PROJECT_STRUCTURE.md)

```
hospital-dashboard/
├── package.json
├── vite.config.ts
├── tsconfig.json
├── index.html
├── .env.example          # VITE_API_URL=http://localhost:8080
├── tailwind.config.js
├── postcss.config.js
└── src/
    ├── main.tsx
    ├── App.tsx
    ├── vite-env.d.ts
    ├── api/
    │   ├── client.ts
    │   ├── auth.api.ts
    │   ├── sos.api.ts
    │   ├── dispatch.api.ts
    │   ├── hospitals.api.ts
    │   ├── ambulances.api.ts
    │   ├── doctors.api.ts
    │   ├── drivers.api.ts
    │   ├── triage.api.ts
    │   ├── analytics.api.ts
    │   ├── notifications.api.ts
    │   ├── patients.api.ts
    │   └── map.api.ts
    ├── components/
    │   ├── common/
    │   │   ├── Button/
    │   │   ├── Card/
    │   │   ├── Modal/
    │   │   ├── DataTable/
    │   │   ├── Badge/
    │   │   ├── Input/
    │   │   └── ...
    │   ├── layout/
    │   │   ├── Sidebar/
    │   │   ├── Topbar/
    │   │   └── Layout/
    │   ├── dashboard/
    │   │   └── StatCard, ActiveSosList, ...
    │   ├── sos/
    │   │   └── SosTable, SosDetail, StatusTimeline, ...
    │   ├── map/
    │   │   └── LiveMap, MapMarkers, ...
    │   ├── staff/
    │   │   └── DoctorsTable, DriversTable
    │   ├── analytics/
    │   │   └── ResponseTimeChart, VolumeChart
    │   └── notifications/
    │       └── NotificationList
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
    ├── hooks/
    │   ├── useAuth.ts
    │   ├── useHospital.ts
    │   └── ...
    ├── store/
    │   ├── authStore.ts
    │   ├── hospitalStore.ts
    │   └── notificationStore.ts
    ├── types/
    │   └── index.ts
    ├── utils/
    │   ├── formatDate.ts
    │   ├── parseStatus.ts
    │   └── ...
    ├── routes/
    │   └── index.tsx
    └── styles/
        └── index.css
```

---

## 15. Out of Scope (Do Not Build)

- Video/phone call monitoring (PRD 7.7) – skip entirely
- WebSocket real-time push – use polling (React Query refetch) for now
- Dark theme – light only
- Multi-language – English only
- User/Driver app features – dashboard only

---

## 16. Quality Checklist

- [ ] All API calls use the correct endpoints, methods, and headers from POSTMAN_API_REFERENCE.md
- [ ] No `any`; all types defined
- [ ] Tables have pagination where backend supports it
- [ ] Maps use OpenStreetMap and show ambulances, SOS, hospitals with distinct markers
- [ ] Sidebar has smooth collapse animation
- [ ] 401 triggers refresh or redirect to login
- [ ] Error messages shown for failed API calls
- [ ] Loading states for async operations
- [ ] Empty states when no data
- [ ] Light theme, consistent with design system
- [ ] Reusable components; no duplicated UI patterns
- [ ] Code split by feature; no single file > 200 lines where avoidable

---

## 17. Test Credentials

- **Staff:** `staff@hospital.com` / `password123` – use for dashboard testing
- **Doctor:** `doctor1@test.com` / `password123` – if role-specific views differ later

---

## 18. Final Instruction

Build the Hospital Dashboard as a **complete, production-ready, one-stop command center**. Every feature listed must be implemented and wired to the backend. The result should feel finished, with no placeholder "TODO" or "Coming soon" sections. Prioritize correctness, consistency, and smooth UX over extra polish.
