# Hospital Dashboard – Technical Documentation

**RakshaPoorvak Hospital Dashboard**
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
7. [Styling & Design System](#7-styling--design-system)
8. [Type Definitions](#8-type-definitions)
9. [State Management (Zustand)](#9-state-management-zustand)
10. [API Layer](#10-api-layer)
11. [Routing & Authentication](#11-routing--authentication)
12. [Pages – Detailed Reference](#12-pages--detailed-reference)
13. [Reusable Components](#13-reusable-components)
14. [Hooks](#14-hooks)
15. [Utility Functions](#15-utility-functions)
16. [Data Flow & Query Patterns](#16-data-flow--query-patterns)
17. [Error Handling](#17-error-handling)
18. [Test Credentials](#18-test-credentials)
19. [Common Tasks for New Developers](#19-common-tasks-for-new-developers)

---

## 1. Overview

The Hospital Dashboard is a **React web application** that serves as the real-time emergency command center for hospital staff. It is one of three client applications (alongside User App and Driver App) that communicate with the RakshaPoorvak Spring Boot backend.

### What This Dashboard Does

- **Monitor SOS emergencies** in real time (list, detail, status tracking)
- **Dispatch ambulances** to patients (find nearest ambulance)
- **Assign doctors** to active SOS cases
- **Track ambulances** on a live map (OpenStreetMap)
- **View triage data** — vitals and medications recorded by paramedics in transit
- **Manage staff** — see doctors and drivers with availability status
- **View analytics** — response times, emergency volume, severity breakdown
- **Handle notifications** — unread count, mark as read
- **Search patients** and view their emergency history

### How It Connects to the System

```
Hospital Dashboard (this app)
        │
        │  REST API (Axios, HTTP polling)
        ▼
  Spring Boot Backend (port 8080)
        │
        ▼
  PostgreSQL Database
```

The dashboard uses **HTTP polling** (React Query refetch intervals) instead of WebSocket for real-time updates. Typical polling intervals are 10–30 seconds depending on the data type.

---

## 2. Tech Stack & Dependencies

### Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `react` | ^19.2.4 | UI framework |
| `react-dom` | ^19.2.4 | DOM rendering |
| `react-router-dom` | ^7.13.1 | Client-side routing (9 routes + login) |
| `axios` | ^1.13.6 | HTTP client with interceptors |
| `zustand` | ^5.0.11 | Lightweight state management (3 stores) |
| `@tanstack/react-query` | ^5.90.21 | Server state, caching, polling |
| `react-leaflet` | ^5.0.0 | React wrapper for Leaflet maps |
| `leaflet` | ^1.9.4 | Mapping library (OpenStreetMap tiles) |
| `lucide-react` | ^0.577.0 | Icon library (used throughout) |
| `recharts` | ^3.8.0 | Charts (bar, pie) for analytics |
| `date-fns` | ^4.1.0 | Date formatting (`formatDateTime`, `formatTimeAgo`) |
| `react-hot-toast` | ^2.6.0 | Toast notifications |
| `react-is` | ^19.2.4 | Peer dependency for recharts |

### Dev Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `vite` | ^8.0.0 | Build tool and dev server |
| `@vitejs/plugin-react` | ^6.0.0 | React fast refresh for Vite |
| `tailwindcss` | ^4.2.1 | Utility-first CSS framework |
| `@tailwindcss/vite` | ^4.2.1 | Tailwind integration with Vite |
| `typescript` | ~5.9.3 | TypeScript compiler |
| `@types/leaflet` | ^1.9.21 | Leaflet type definitions |
| `eslint` | ^9.39.4 | Linting |

### NPM Scripts

```bash
npm run dev       # Start dev server (port 5173)
npm run build     # TypeScript check + Vite production build
npm run preview   # Preview production build locally
npm run lint      # Run ESLint
```

---

## 3. Project Structure

```
hospital-dashboard/
├── index.html                    # HTML entry point (includes Leaflet CSS CDN)
├── package.json                  # Dependencies and scripts
├── vite.config.ts                # Vite config (proxy, plugins)
├── tsconfig.json                 # TypeScript project references
├── tsconfig.app.json             # App TypeScript config (strict, no unused vars)
├── tsconfig.node.json            # Node TypeScript config (for vite.config.ts)
├── .env.example                  # Example environment variables
│
└── src/
    ├── main.tsx                  # React app bootstrap (mount to #root)
    ├── App.tsx                   # Root component (QueryClient, Router, Toaster)
    │
    ├── api/                      # API layer (Axios client + modules)
    │   ├── client.ts             # Axios instance with auth interceptors
    │   ├── auth.api.ts           # Login, logout, refresh, me
    │   ├── sos.api.ts            # SOS CRUD, tracking, assign/unassign doctor
    │   ├── dispatch.api.ts       # Find ambulance
    │   ├── dashboard.api.ts      # Summary, active SOS
    │   ├── hospitals.api.ts      # List, get, my-hospital
    │   ├── ambulances.api.ts     # List, get, location
    │   ├── doctors.api.ts        # List, get
    │   ├── drivers.api.ts        # List
    │   ├── triage.api.ts         # Triage records, medications
    │   ├── analytics.api.ts      # Response times, volume, dashboard
    │   ├── notifications.api.ts  # List, unread count, mark read
    │   ├── patients.api.ts       # Search, history
    │   └── map.api.ts            # Map overview
    │
    ├── components/               # React components
    │   ├── common/               # Reusable UI components
    │   │   ├── Badge.tsx         # Status/criticality badges
    │   │   ├── Button.tsx        # Primary/secondary/ghost/danger buttons
    │   │   ├── Card.tsx          # White card container
    │   │   ├── DataTable.tsx     # Generic table with pagination
    │   │   ├── Input.tsx         # Form input with label/error
    │   │   └── Modal.tsx         # Overlay modal dialog
    │   ├── layout/               # App shell components
    │   │   ├── Layout.tsx        # Sidebar + Topbar + Outlet wrapper
    │   │   ├── Sidebar.tsx       # Collapsible navigation sidebar
    │   │   └── Topbar.tsx        # Header with logo, notifications, user menu
    │   ├── dashboard/
    │   │   └── StatCard.tsx      # Metric card (icon + value)
    │   └── sos/
    │       └── StatusTimeline.tsx # Visual SOS status progress indicator
    │
    ├── pages/                    # Route-level page components
    │   ├── Login.tsx             # /login
    │   ├── Dashboard.tsx         # / (command dashboard)
    │   ├── SosMonitor.tsx        # /sos (paginated SOS list)
    │   ├── SosDetail.tsx         # /sos/:id (full SOS view + actions)
    │   ├── LiveMap.tsx           # /map (Leaflet map with markers)
    │   ├── Ambulances.tsx        # /ambulances (ambulance list)
    │   ├── Staff.tsx             # /staff (doctors + drivers tabs)
    │   ├── Analytics.tsx         # /analytics (charts + metrics)
    │   ├── Notifications.tsx     # /notifications (notification list)
    │   └── Patients.tsx          # /patients (search + history)
    │
    ├── hooks/                    # Custom React hooks
    │   ├── useAuth.ts            # Auth state + hospital auto-fetch
    │   ├── useHospital.ts        # Hospital ID accessor
    │   └── useNotificationPolling.ts  # Background notification count polling
    │
    ├── store/                    # Zustand state stores
    │   ├── authStore.ts          # User, tokens (persisted)
    │   ├── hospitalStore.ts      # Current hospital (persisted)
    │   └── notificationStore.ts  # Unread count (not persisted)
    │
    ├── types/
    │   └── index.ts              # All TypeScript interfaces and types
    │
    ├── utils/
    │   ├── formatDate.ts         # Date formatting helpers
    │   └── parseStatus.ts        # Status colors, labels, timeline, error parsing
    │
    ├── routes/
    │   └── index.tsx             # Route definitions with auth guards
    │
    └── styles/
        └── index.css             # Tailwind imports + custom theme tokens
```

---

## 4. Getting Started

### Prerequisites

- **Node.js** 20+ and **npm** 10+
- **Backend** running at `http://localhost:8080` (Spring Boot)
- **Database** seeded with test data (`./scripts/seed-all.sh`)

### Installation

```bash
cd hospital-dashboard
npm install --legacy-peer-deps
```

> **Note:** `--legacy-peer-deps` is required due to a version conflict between `@tailwindcss/vite` (requires Vite 5–7) and the installed Vite 8. This does not affect functionality.

### Running the Dev Server

```bash
npm run dev
```

Opens at **http://localhost:5173**. The Vite dev server proxies all `/api` requests to `http://localhost:8080`.

### Building for Production

```bash
npm run build
```

Outputs to `dist/`. To preview:

```bash
npm run preview
```

### Environment Variables

Create a `.env.local` file (or use Vite proxy in dev):

```
VITE_API_URL=http://localhost:8080
```

If running the Vite dev server with the proxy config, this variable is optional in development.

---

## 5. Architecture

### High-Level Data Flow

```
User Interaction
      │
      ▼
┌─────────────┐    React Query     ┌──────────────┐    Axios      ┌──────────────┐
│   Pages     │ ◄───────────────── │  API Layer   │ ◄──────────── │   Backend    │
│ (components)│ ──────────────────►│ (src/api/)   │ ────────────► │   (8080)     │
└─────────────┘    cache + poll    └──────────────┘  JWT Bearer   └──────────────┘
      │
      ▼
┌─────────────┐
│   Zustand   │  (auth, hospital, notifications)
│   Stores    │  Persisted to localStorage
└─────────────┘
```

### Key Architectural Decisions

| Decision | Details |
|----------|---------|
| **Polling over WebSocket** | React Query `refetchInterval` (10–30s) instead of WebSocket push. WebSocket is Phase 2. |
| **Zustand for client state** | Auth tokens, hospital context, notification count. Persisted via `zustand/middleware/persist`. |
| **React Query for server state** | All API data fetched/cached via `useQuery`. Mutations invalidate relevant queries. |
| **No `any` types** | Strict TypeScript throughout. All API responses have defined interfaces. |
| **Thin pages, reusable components** | Pages compose common components (DataTable, Badge, Card, etc.) |

### Component Hierarchy

```
App
├── QueryClientProvider (React Query)
├── NotificationPoller (background polling hook)
├── RouterProvider
│   ├── /login → LoginPage
│   └── / → Layout (ProtectedRoute)
│       ├── Topbar
│       ├── Sidebar
│       └── <Outlet> → Page Components
└── Toaster (react-hot-toast)
```

---

## 6. Configuration

### Vite Configuration (`vite.config.ts`)

```typescript
export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
})
```

- **Dev server port:** 5173
- **API proxy:** All `/api/*` requests forwarded to `http://localhost:8080`
- **Plugins:** React (fast refresh) + Tailwind CSS

### TypeScript Configuration (`tsconfig.app.json`)

- **Target:** ES2023
- **Strict mode:** Enabled
- **No unused locals/params:** Disabled (to reduce friction during development)
- **JSX:** `react-jsx` (automatic runtime)
- **Module resolution:** `bundler`

---

## 7. Styling & Design System

### Tailwind CSS Theme (`src/styles/index.css`)

```css
@import "tailwindcss";

@theme {
  --font-sans: "Inter", ui-sans-serif, system-ui, sans-serif;
  --color-primary-50: #eff6ff;
  --color-primary-100: #dbeafe;
  --color-primary-200: #bfdbfe;
  --color-primary-300: #93c5fd;
  --color-primary-400: #60a5fa;
  --color-primary-500: #3b82f6;
  --color-primary-600: #2563eb;   ← Primary action color
  --color-primary-700: #1d4ed8;
  --color-primary-800: #1e40af;
  --color-primary-900: #1e3a8a;
}
```

### Design Tokens

| Token | Value | Usage |
|-------|-------|-------|
| Primary | `#2563eb` (blue-600) | Buttons, links, active states, highlights |
| Background | `#f8fafc` (slate-50) | Page background |
| Card background | `#ffffff` | Cards, panels, modals |
| Primary text | `#111827` (gray-900) | Headings, body text |
| Secondary text | `#6b7280` (gray-500) | Labels, timestamps, descriptions |
| Font | Inter | Headers, body (falls back to system-ui) |

### Status Color Mapping

| Context | Value | Tailwind Classes |
|---------|-------|-----------------|
| **SOS Status** | CREATED / DISPATCHING | `bg-amber-100 text-amber-800` |
| | AMBULANCE_ASSIGNED / DRIVER_ENROUTE_TO_PATIENT | `bg-blue-100 text-blue-800` |
| | REACHED_PATIENT / PICKED_UP / ENROUTE_TO_HOSPITAL | `bg-indigo-100 text-indigo-800` |
| | ARRIVED_AT_HOSPITAL / COMPLETED | `bg-green-100 text-green-800` |
| | CANCELLED | `bg-red-100 text-red-800` |
| **Criticality** | LOW | `bg-gray-100 text-gray-700` |
| | MEDIUM | `bg-yellow-100 text-yellow-800` |
| | HIGH | `bg-orange-100 text-orange-800` |
| | CRITICAL | `bg-red-100 text-red-800` |
| **Ambulance** | AVAILABLE | `bg-green-100 text-green-800` |
| | DISPATCHED | `bg-blue-100 text-blue-800` |
| | MAINTENANCE | `bg-yellow-100 text-yellow-800` |
| | OFFLINE | `bg-gray-100 text-gray-600` |
| **Staff** | AVAILABLE | `bg-green-100 text-green-800` |
| | BUSY | `bg-blue-100 text-blue-800` |
| | OFFLINE | `bg-gray-100 text-gray-600` |

### Layout Dimensions

| Element | Dimension |
|---------|-----------|
| Topbar height | 64px (h-16) |
| Sidebar expanded | 256px (w-64) |
| Sidebar collapsed | 72px (w-[72px]) |
| Card padding | p-4 or p-6 |
| Page padding | p-6 |
| Sidebar transition | 200ms ease-in-out |

---

## 8. Type Definitions

All types are centralized in `src/types/index.ts`. Below is the complete reference.

### Auth Types

```typescript
interface LoginRequest {
  email: string;
  password: string;
}

interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: User;
}

interface RefreshRequest {
  refreshToken: string;
}
```

### User

```typescript
interface User {
  id: number;
  email: string;
  fullName: string;
  phone: string;
  roles: string[];     // e.g., ["HOSPITAL_STAFF"]
}
```

### Hospital

```typescript
interface Hospital {
  id: number;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  phone: string;
}
```

### SOS Event

```typescript
type SosStatus =
  | 'CREATED' | 'DISPATCHING' | 'AMBULANCE_ASSIGNED'
  | 'DRIVER_ENROUTE_TO_PATIENT' | 'REACHED_PATIENT' | 'PICKED_UP'
  | 'ENROUTE_TO_HOSPITAL' | 'ARRIVED_AT_HOSPITAL' | 'COMPLETED' | 'CANCELLED';

type Criticality = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';

interface SosEvent {
  id: number;
  userId: number;
  userName: string;
  userPhone: string;
  latitude: number;
  longitude: number;
  address: string;
  symptoms: string;
  criticality: Criticality;
  status: SosStatus;
  ambulanceId: number | null;
  driverId: number | null;
  driverName: string | null;
  doctorId: number | null;
  doctorName: string | null;
  hospitalId: number | null;
  createdAt: string;           // ISO 8601
  updatedAt: string;           // ISO 8601
}

interface SosTracking {
  sosEventId: number;
  ambulanceLatitude: number | null;
  ambulanceLongitude: number | null;
  driverName: string | null;
  eta: string | null;
  status: SosStatus;
}
```

### Ambulance

```typescript
type AmbulanceStatus = 'AVAILABLE' | 'DISPATCHED' | 'MAINTENANCE' | 'OFFLINE';

interface Ambulance {
  id: number;
  registrationNumber: string;
  status: AmbulanceStatus;
  hospitalId: number;
  hospitalName: string;
  latitude: number | null;
  longitude: number | null;
  updatedAt: string;
}
```

### Doctor & Driver

```typescript
type StaffStatus = 'AVAILABLE' | 'BUSY' | 'OFFLINE';

interface Doctor {
  id: number;
  userId: number;
  fullName: string;
  email: string;
  phone: string;
  specialization: string;
  status: StaffStatus;
  hospitalId: number;
  hospitalName: string;
}

interface Driver {
  id: number;
  userId: number;
  fullName: string;
  email: string;
  phone: string;
  licenseNumber: string;
  status: StaffStatus;
  ambulanceId: number | null;
  hospitalId: number;
  hospitalName: string;
}
```

### Triage

```typescript
interface TriageRecord {
  id: number;
  sosEventId: number;
  heartRate: number | null;
  systolicBp: number | null;
  diastolicBp: number | null;
  spo2: number | null;
  temperature: number | null;
  notes: string;
  createdAt: string;
}

interface Medication {
  id: number;
  sosEventId: number;
  name: string;
  dosage: string;
  notes: string;
  createdAt: string;
}
```

### Dashboard & Analytics

```typescript
interface DashboardSummary {
  activeSosCount: number;
  availableAmbulances: number;
  totalAmbulances: number;
  availableDoctors: number;
  totalDoctors: number;
  avgResponseTimeMinutes: number;
}

interface ResponseTimeMetrics {
  averageMinutes: number;
  medianMinutes: number;
  minMinutes: number;
  maxMinutes: number;
}

interface EmergencyVolume {
  date: string;
  count: number;
}

interface AnalyticsDashboard {
  responseTimes: ResponseTimeMetrics;
  volume: EmergencyVolume[];
  bySeverity: Record<string, number>;
  ambulanceUtilization: Record<string, number>;
}
```

### Other Types

```typescript
interface Notification {
  id: number;
  title: string;
  body: string;
  read: boolean;
  createdAt: string;
}

interface MapOverview {
  ambulances: Ambulance[];
  sosEvents: SosEvent[];
  hospitals: Hospital[];
}

interface PatientSearchResult {
  userId: number;
  fullName: string;
  phone: string;
  email: string;
  lastSosDate: string | null;
}

interface PatientHistory {
  userId: number;
  fullName: string;
  sosEvents: SosEvent[];
}

interface Page<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  number: number;        // current page (0-indexed)
  size: number;
}

interface ApiError {
  error: {
    code: string;
    message: string;
    timestamp: string;
  };
}
```

---

## 9. State Management (Zustand)

Three Zustand stores manage client-side state.

### authStore (`src/store/authStore.ts`)

| Field | Type | Description |
|-------|------|-------------|
| `user` | `User \| null` | Logged-in user object |
| `accessToken` | `string \| null` | JWT access token |
| `refreshToken` | `string \| null` | JWT refresh token |

| Method | Signature | Description |
|--------|-----------|-------------|
| `setAuth` | `(user, accessToken, refreshToken) => void` | Set all auth fields (on login) |
| `setAccessToken` | `(token: string) => void` | Update access token (on refresh) |
| `logout` | `() => void` | Clear all auth fields |

- **Persistence:** `localStorage` key `raksha-auth`

### hospitalStore (`src/store/hospitalStore.ts`)

| Field | Type | Description |
|-------|------|-------------|
| `hospital` | `Hospital \| null` | Full hospital object |
| `hospitalId` | `number \| null` | Hospital ID (convenience) |

| Method | Signature | Description |
|--------|-----------|-------------|
| `setHospital` | `(hospital: Hospital) => void` | Set hospital and extract ID |
| `clear` | `() => void` | Clear hospital state |

- **Persistence:** `localStorage` key `raksha-hospital`

### notificationStore (`src/store/notificationStore.ts`)

| Field | Type | Description |
|-------|------|-------------|
| `unreadCount` | `number` | Unread notification count |

| Method | Signature | Description |
|--------|-----------|-------------|
| `setUnreadCount` | `(count: number) => void` | Update unread count |

- **No persistence** (refreshed on each session via polling)

---

## 10. API Layer

### API Client (`src/api/client.ts`)

The Axios client is the single HTTP interface to the backend.

**Configuration:**

| Setting | Value |
|---------|-------|
| Base URL | `import.meta.env.VITE_API_URL` or `http://localhost:8080` |
| Timeout | 15,000ms (15 seconds) |
| Content-Type | `application/json` |

**Request Interceptor:**
- Reads `accessToken` from `authStore` and adds `Authorization: Bearer <token>` header.

**Response Interceptor (401 handling):**
1. On 401 response, reads `refreshToken` from `authStore`.
2. Calls `POST /api/auth/refresh` with the refresh token.
3. On success: updates `accessToken` in store, retries the original request.
4. On failure: calls `logout()`, redirects to `/login`.
5. Uses `_retry` flag to prevent infinite refresh loops.

### API Module Reference

All API modules are in `src/api/`. Each exports functions that return Axios promises.

#### Auth (`auth.api.ts`)

| Function | Method | Endpoint | Parameters | Returns |
|----------|--------|----------|------------|---------|
| `login` | POST | `/api/auth/login` | `{ email, password }` | `LoginResponse` |
| `logout` | POST | `/api/auth/logout` | — | — |
| `refreshToken` | POST | `/api/auth/refresh` | `{ refreshToken }` | `LoginResponse` |
| `getMe` | GET | `/api/auth/me` | — | `User` |

#### Dashboard (`dashboard.api.ts`)

| Function | Method | Endpoint | Query Params | Returns |
|----------|--------|----------|-------------|---------|
| `getDashboardSummary` | GET | `/api/dashboard/summary` | `hospitalId?` | `DashboardSummary` |
| `getDashboardActiveSos` | GET | `/api/dashboard/active-sos` | `hospitalId?` | `SosEvent[]` |

#### SOS (`sos.api.ts`)

| Function | Method | Endpoint | Parameters | Returns |
|----------|--------|----------|------------|---------|
| `listSosEvents` | GET | `/api/sos-events` | `hospitalId?, status?, page?, size?` | `Page<SosEvent>` |
| `getActiveSos` | GET | `/api/sos-events/active` | `hospitalId?` | `SosEvent[]` |
| `getSosEvent` | GET | `/api/sos-events/{id}` | path: `id` | `SosEvent` |
| `getSosTracking` | GET | `/api/sos-events/{id}/tracking` | path: `id` | `SosTracking` |
| `assignDoctor` | POST | `/api/sos-events/{sosId}/assign-doctor` | path: `sosId` | — |
| `unassignDoctor` | DELETE | `/api/sos-events/{sosId}/doctor` | path: `sosId` | — |

#### Dispatch (`dispatch.api.ts`)

| Function | Method | Endpoint | Parameters | Returns |
|----------|--------|----------|------------|---------|
| `findAmbulance` | POST | `/api/dispatch/{sosId}/find-ambulance` | path: `sosId` | — |

#### Hospitals (`hospitals.api.ts`)

| Function | Method | Endpoint | Parameters | Returns |
|----------|--------|----------|------------|---------|
| `listHospitals` | GET | `/api/hospitals` | — | `Hospital[]` |
| `getHospital` | GET | `/api/hospitals/{id}` | path: `id` | `Hospital` |
| `getMyHospital` | GET | `/api/hospitals/my-hospital` | — | `Hospital` |

#### Ambulances (`ambulances.api.ts`)

| Function | Method | Endpoint | Parameters | Returns |
|----------|--------|----------|------------|---------|
| `listAmbulances` | GET | `/api/ambulances` | `hospitalId?` | `Ambulance[]` |
| `getAmbulance` | GET | `/api/ambulances/{id}` | path: `id` | `Ambulance` |
| `getAmbulanceLocation` | GET | `/api/ambulances/{id}/location` | path: `id` | — |

#### Doctors (`doctors.api.ts`)

| Function | Method | Endpoint | Parameters | Returns |
|----------|--------|----------|------------|---------|
| `listDoctors` | GET | `/api/doctors` | `hospitalId?` | `Doctor[]` |
| `getDoctor` | GET | `/api/doctors/{id}` | path: `id` | `Doctor` |

#### Drivers (`drivers.api.ts`)

| Function | Method | Endpoint | Parameters | Returns |
|----------|--------|----------|------------|---------|
| `listDrivers` | GET | `/api/drivers` | `hospitalId?` | `Driver[]` |

#### Triage (`triage.api.ts`)

| Function | Method | Endpoint | Parameters | Returns |
|----------|--------|----------|------------|---------|
| `listTriageRecords` | GET | `/api/triage/records` | `sosEventId` | `TriageRecord[]` |
| `listMedications` | GET | `/api/triage/medications` | `sosEventId` | `Medication[]` |

#### Analytics (`analytics.api.ts`)

| Function | Method | Endpoint | Parameters | Returns |
|----------|--------|----------|------------|---------|
| `getResponseTimes` | GET | `/api/analytics/response-times` | — | `ResponseTimeMetrics` |
| `getEmergencyVolume` | GET | `/api/analytics/emergency-volume` | — | `EmergencyVolume[]` |
| `getAnalyticsDashboard` | GET | `/api/analytics/dashboard` | — | `AnalyticsDashboard` |

#### Notifications (`notifications.api.ts`)

| Function | Method | Endpoint | Parameters | Returns |
|----------|--------|----------|------------|---------|
| `listNotifications` | GET | `/api/notifications` | — | `Notification[]` |
| `getUnreadCount` | GET | `/api/notifications/unread-count` | — | `number` |
| `markRead` | PATCH | `/api/notifications/{id}/read` | path: `id` | — |
| `markAllRead` | POST | `/api/notifications/read-all` | — | — |

#### Patients (`patients.api.ts`)

| Function | Method | Endpoint | Parameters | Returns |
|----------|--------|----------|------------|---------|
| `searchPatients` | GET | `/api/patients/search` | `q` (query string) | `PatientSearchResult[]` |
| `getPatientHistory` | GET | `/api/patients/{userId}/history` | path: `userId` | `PatientHistory` |

#### Map (`map.api.ts`)

| Function | Method | Endpoint | Parameters | Returns |
|----------|--------|----------|------------|---------|
| `getMapOverview` | GET | `/api/map/overview` | — | `MapOverview` |

---

## 11. Routing & Authentication

### Route Map (`src/routes/index.tsx`)

| Path | Component | Auth | Description |
|------|-----------|------|-------------|
| `/login` | `LoginPage` | Public (redirects to `/` if logged in) | Email/password login form |
| `/` | `DashboardPage` | Protected | Command dashboard with stats + active SOS |
| `/sos` | `SosMonitorPage` | Protected | Paginated SOS list with status filter |
| `/sos/:id` | `SosDetailPage` | Protected | Full SOS detail + actions |
| `/map` | `LiveMapPage` | Protected | Interactive map with markers |
| `/ambulances` | `AmbulancesPage` | Protected | Ambulance list |
| `/staff` | `StaffPage` | Protected | Doctors + drivers (tabbed) |
| `/analytics` | `AnalyticsPage` | Protected | Charts + metrics |
| `/notifications` | `NotificationsPage` | Protected | Notification list |
| `/patients` | `PatientsPage` | Protected | Patient search + history |
| `*` | — | — | Redirects to `/` |

### Auth Guards

- **`ProtectedRoute`** — Checks `accessToken` in `authStore`. If null, redirects to `/login`.
- **`PublicRoute`** — If already authenticated, redirects to `/`.

### Login Flow

1. User submits email + password on `/login`.
2. `POST /api/auth/login` → receives `{ accessToken, refreshToken, user }`.
3. `authStore.setAuth(user, accessToken, refreshToken)` stores to Zustand (persisted to localStorage).
4. Navigate to `/`.
5. On first protected route load, `useAuth` hook fetches `GET /api/hospitals/my-hospital` and stores in `hospitalStore`.

### Token Refresh Flow

1. Any API request returns 401.
2. Response interceptor reads `refreshToken` from `authStore`.
3. Calls `POST /api/auth/refresh` with `{ refreshToken }`.
4. On success: updates `accessToken`, retries original request.
5. On failure: calls `logout()`, redirects to `/login`.

---

## 12. Pages – Detailed Reference

### 12.1 Login (`/login`)

**File:** `src/pages/Login.tsx`

**State:** `email`, `password`, `error`, `loading`

**API:** `login({ email, password })` → `POST /api/auth/login`

**Behavior:**
- Centered card with RakshaPoorvak branding
- On success: stores tokens + redirects to `/`
- On error: shows error message in red box below form
- Button shows spinner while loading

---

### 12.2 Command Dashboard (`/`)

**File:** `src/pages/Dashboard.tsx`

**API Calls:**

| Query Key | Endpoint | Refetch Interval |
|-----------|----------|-----------------|
| `['dashboard-summary', hospitalId]` | `GET /api/dashboard/summary` | 30s |
| `['dashboard-active-sos', hospitalId]` | `GET /api/dashboard/active-sos` | 30s |

**Layout:**
1. **4 Stat Cards** (grid):
   - Active SOS (amber icon)
   - Available Ambulances (e.g., "3 / 5") (blue icon)
   - Avg Response Time (e.g., "4.2 min") (green icon)
   - Available Doctors (e.g., "2 / 4") (indigo icon)
2. **Active Emergencies Table** (max 10 rows):
   - Columns: ID, Patient, Status, Criticality, Time
   - Click row → `/sos/{id}`
   - "View All" → `/sos`

---

### 12.3 SOS Monitor (`/sos`)

**File:** `src/pages/SosMonitor.tsx`

**State:** `page` (0-indexed), `statusFilter`, `size` (20)

**API Calls:**

| Query Key | Endpoint | Refetch Interval |
|-----------|----------|-----------------|
| `['sos-events', hospitalId, statusFilter, page, size]` | `GET /api/sos-events` | 30s |

**Features:**
- **Status filter dropdown** with all 10 SOS status values + "All Statuses"
- **Paginated DataTable** with columns: ID, Patient, Phone, Status, Criticality, Symptoms (truncated), Created
- Click row → `/sos/{id}`
- Page resets to 0 when filter changes

---

### 12.4 SOS Detail (`/sos/:id`)

**File:** `src/pages/SosDetail.tsx`

**Route Params:** `id` (SOS event ID, extracted via `useParams`)

**API Calls:**

| Query Key | Endpoint | Refetch | Condition |
|-----------|----------|---------|-----------|
| `['sos-event', sosId]` | `GET /api/sos-events/{id}` | 15s | Always |
| `['sos-tracking', sosId]` | `GET /api/sos-events/{id}/tracking` | 10s | Only if `ambulanceId` is set |
| `['triage-records', sosId]` | `GET /api/triage/records?sosEventId={id}` | 15s | Always |
| `['medications', sosId]` | `GET /api/triage/medications?sosEventId={id}` | 15s | Always |

**Actions (buttons):**

| Action | API Call | Shown When |
|--------|---------|------------|
| Find Ambulance | `POST /api/dispatch/{sosId}/find-ambulance` | Status is CREATED or DISPATCHING |
| Assign Doctor | `POST /api/sos-events/{sosId}/assign-doctor` | Ambulance assigned, no doctor, not completed/cancelled |
| Unassign Doctor | `DELETE /api/sos-events/{sosId}/doctor` | Doctor assigned, not completed/cancelled |

**Sections:**
1. **Header** — SOS ID + status badge + criticality badge + back button
2. **Status Timeline** — Visual progress (StatusTimeline component)
3. **Patient Info** — Name, phone, GPS coordinates, address, symptoms, created time
4. **Tracking & Actions** — Driver name, ETA, ambulance location, assigned doctor, action buttons
5. **Triage Records** — Table: Time, HR, BP, SpO2, Temp, Notes
6. **Medications** — Table: Time, Name, Dosage, Notes

All actions show toast notifications on success/error and invalidate relevant queries.

---

### 12.5 Live Map (`/map`)

**File:** `src/pages/LiveMap.tsx`

**API Calls:**

| Query Key | Endpoint | Refetch Interval |
|-----------|----------|-----------------|
| `['map-overview']` | `GET /api/map/overview` | 30s |

**Map Configuration:**
- **Library:** React Leaflet with OpenStreetMap tiles
- **Default center:** India (lat 20.59, lng 78.96), zoom 5
- **Auto-fit bounds** to all markers on data load (max zoom 14, padding 40px)

**Marker Types:**

| Type | Icon | Color Logic |
|------|------|-------------|
| Ambulance | Circle with "A" | Green (AVAILABLE), Blue (DISPATCHED) |
| SOS/Patient | Circle with "S" | Red (CRITICAL), Orange (HIGH), Yellow (MEDIUM), Gray (LOW) |
| Hospital | Circle with "H" | Indigo |

**Popup Content:**
- Ambulance: registration number + status badge
- SOS: ID, patient name, status + criticality badges, link to detail
- Hospital: name + address

**Controls:** Refresh button (manual refetch)

**Legend:** Color key shown below map

---

### 12.6 Ambulances (`/ambulances`)

**File:** `src/pages/Ambulances.tsx`

**API:** `['ambulances', hospitalId]` → `GET /api/ambulances?hospitalId={id}` (refetch: 30s)

**Table Columns:** Registration, Status (badge), Location (lat/lng or "—"), Hospital, Updated

---

### 12.7 Staff (`/staff`)

**File:** `src/pages/Staff.tsx`

**State:** `tab` — `'doctors'` or `'drivers'`

**API Calls:**
- `['doctors', hospitalId]` → `GET /api/doctors?hospitalId={id}`
- `['drivers', hospitalId]` → `GET /api/drivers?hospitalId={id}`

**Doctors Table:** Name, Email, Phone, Specialization, Status (badge)

**Drivers Table:** Name, Email, Phone, License, Status (badge)

**Tab UI:** Toggle buttons with active count displayed

---

### 12.8 Analytics (`/analytics`)

**File:** `src/pages/Analytics.tsx`

**API:** `['analytics-dashboard']` → `GET /api/analytics/dashboard`

**Sections:**
1. **Response Time Cards** (4 cards): Average, Median, Min, Max (in minutes)
2. **Emergency Volume** — Vertical bar chart (Recharts) by date
3. **By Severity** — Pie chart with colors: Gray (LOW), Yellow (MEDIUM), Orange (HIGH), Red (CRITICAL)
4. **Ambulance Utilization** — Horizontal bar chart by ambulance

---

### 12.9 Notifications (`/notifications`)

**File:** `src/pages/Notifications.tsx`

**API:** `['notifications']` → `GET /api/notifications`

**Actions:**
- Mark individual: `PATCH /api/notifications/{id}/read`
- Mark all: `POST /api/notifications/read-all`

**UI:**
- Unread items have blue left border + bold title
- Each item shows title, body, time ago
- "Mark All Read" button at top
- Empty state with Bell icon

---

### 12.10 Patients (`/patients`)

**File:** `src/pages/Patients.tsx`

**State:** `query` (input), `searchTerm` (submitted), `selectedPatient` (userId)

**API Calls:**
- `['patient-search', searchTerm]` → `GET /api/patients/search?q={term}` (enabled when term >= 2 chars)
- `['patient-history', selectedPatient]` → `GET /api/patients/{userId}/history` (enabled when patient selected)

**Layout:** 3-column grid (1/3 search results, 2/3 history)
- Left: Search form + patient cards (name, phone, last SOS date)
- Right: Selected patient's SOS history (click SOS → `/sos/{id}`)

---

## 13. Reusable Components

### Button (`src/components/common/Button.tsx`)

```typescript
interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger';  // default: 'primary'
  loading?: boolean;                                         // shows spinner
}
```

| Variant | Appearance |
|---------|-----------|
| `primary` | Blue filled, white text |
| `secondary` | White with gray border |
| `ghost` | Transparent, gray text |
| `danger` | Red filled, white text |

### Card (`src/components/common/Card.tsx`)

```typescript
interface CardProps {
  children: React.ReactNode;
  className?: string;      // merged with defaults
}
```

White background, rounded-lg, shadow-sm, gray-100 border.

### Badge (`src/components/common/Badge.tsx`)

```typescript
interface BadgeProps {
  children: React.ReactNode;
  className?: string;      // default: 'bg-gray-100 text-gray-700'
}
```

Inline pill (rounded-full) with customizable Tailwind classes. Typically used with color functions from `parseStatus.ts`.

### Input (`src/components/common/Input.tsx`)

```typescript
interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;     // rendered above input
  error?: string;     // rendered below input in red
}
```

### Modal (`src/components/common/Modal.tsx`)

```typescript
interface ModalProps {
  open: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
}
```

Renders a centered overlay with dark backdrop. Prevents body scroll when open.

### DataTable (`src/components/common/DataTable.tsx`)

```typescript
interface Column<T> {
  header: string;
  accessor: keyof T | ((row: T) => React.ReactNode);
  className?: string;
}

interface DataTableProps<T> {
  columns: Column<T>[];
  data: T[];
  loading?: boolean;
  onRowClick?: (row: T) => void;
  emptyMessage?: string;       // default: "No data available"
  pagination?: {
    page: number;              // 0-indexed
    size: number;
    total: number;
    onPageChange: (page: number) => void;
  };
}
```

Generic table supporting:
- Function or property accessors for cell rendering
- Optional row click handler (adds cursor-pointer + hover)
- Optional pagination controls (Previous / page buttons / Next + "Showing X–Y of Z")
- Loading state (centered spinner)
- Empty state message

### StatCard (`src/components/dashboard/StatCard.tsx`)

```typescript
interface StatCardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  color: string;           // e.g., 'bg-amber-500'
}
```

### StatusTimeline (`src/components/sos/StatusTimeline.tsx`)

```typescript
interface StatusTimelineProps {
  currentStatus: SosStatus;
}
```

Shows 9 numbered circles connected by lines representing the SOS status flow:
- **Completed steps:** Green with checkmark
- **Current step:** Primary blue with ring
- **Future steps:** Gray

### Layout, Sidebar, Topbar

See [Section 3 (Project Structure)](#3-project-structure) for file locations. The Layout component manages the sidebar collapsed/expanded state and renders Sidebar + Topbar + `<Outlet />`.

**Sidebar Navigation Items:**

| Label | Route | Icon |
|-------|-------|------|
| Dashboard | `/` | Home |
| SOS Monitor | `/sos` | AlertTriangle |
| Live Map | `/map` | Map |
| Ambulances | `/ambulances` | Truck |
| Staff | `/staff` | Users |
| Analytics | `/analytics` | BarChart3 |
| Notifications | `/notifications` | Bell |
| Patients | `/patients` | UserSearch |

---

## 14. Hooks

### `useAuth()` (`src/hooks/useAuth.ts`)

```typescript
function useAuth(): {
  user: User | null;
  isAuthenticated: boolean;
  logout: () => void;
  hospital: Hospital | null;
}
```

On mount: if authenticated but hospital not loaded, fetches `GET /api/hospitals/my-hospital` and stores in `hospitalStore`.

### `useHospitalId()` (`src/hooks/useHospital.ts`)

```typescript
function useHospitalId(): number | undefined
```

Returns the hospital ID from the hospital store.

### `useNotificationPolling()` (`src/hooks/useNotificationPolling.ts`)

```typescript
function useNotificationPolling(): void
```

When authenticated:
- Immediately fetches `GET /api/notifications/unread-count`
- Sets up 30-second polling interval
- Updates `notificationStore.unreadCount`
- Cleans up interval on unmount

This hook runs in `App.tsx` via the `<NotificationPoller />` component.

---

## 15. Utility Functions

### `formatDate.ts` (`src/utils/formatDate.ts`)

| Function | Input | Output | Example |
|----------|-------|--------|---------|
| `formatDateTime(iso)` | ISO 8601 string | `"dd MMM yyyy, HH:mm"` | `"25 Dec 2024, 14:30"` |
| `formatTimeAgo(iso)` | ISO 8601 string | Relative time | `"2 hours ago"` |
| `formatTime(iso)` | ISO 8601 string | `"HH:mm"` | `"14:30"` |

All functions gracefully handle parse errors by returning the input string.

### `parseStatus.ts` (`src/utils/parseStatus.ts`)

| Function | Input | Output |
|----------|-------|--------|
| `sosStatusColor(status)` | `SosStatus` | Tailwind class string for badge |
| `sosStatusLabel(status)` | `SosStatus` | Human-readable label (underscores → spaces) |
| `criticalityColor(crit)` | `Criticality` | Tailwind class string for badge |
| `ambulanceStatusColor(status)` | `AmbulanceStatus` | Tailwind class string for badge |
| `staffStatusColor(status)` | `StaffStatus` | Tailwind class string for badge |
| `getSosTimeline(currentStatus)` | `SosStatus` | `Array<{ status, reached, active }>` |
| `getApiErrorMessage(err)` | `unknown` | Human-readable error message string |

**`getApiErrorMessage`** tries to extract error message from:
1. `err.response.data.error.message` (backend error format)
2. `err.response.data.message` (generic)
3. `err.message` (Axios error)
4. Falls back to `"An unexpected error occurred. Please try again."`

---

## 16. Data Flow & Query Patterns

### React Query Configuration

```typescript
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,                    // Retry failed queries once
      refetchOnWindowFocus: false,  // Don't refetch on tab switch
    },
  },
});
```

### Query Key Patterns

All query keys follow the pattern `[resource, ...filters]`:

| Query Key | API | Refetch | Page |
|-----------|-----|---------|------|
| `['dashboard-summary', hospitalId]` | `GET /api/dashboard/summary` | 30s | Dashboard |
| `['dashboard-active-sos', hospitalId]` | `GET /api/dashboard/active-sos` | 30s | Dashboard |
| `['sos-events', hospitalId, status, page, size]` | `GET /api/sos-events` | 30s | SOS Monitor |
| `['sos-event', sosId]` | `GET /api/sos-events/{id}` | 15s | SOS Detail |
| `['sos-tracking', sosId]` | `GET /api/sos-events/{id}/tracking` | 10s | SOS Detail |
| `['triage-records', sosId]` | `GET /api/triage/records` | 15s | SOS Detail |
| `['medications', sosId]` | `GET /api/triage/medications` | 15s | SOS Detail |
| `['map-overview']` | `GET /api/map/overview` | 30s | Live Map |
| `['ambulances', hospitalId]` | `GET /api/ambulances` | 30s | Ambulances |
| `['doctors', hospitalId]` | `GET /api/doctors` | — | Staff |
| `['drivers', hospitalId]` | `GET /api/drivers` | — | Staff |
| `['analytics-dashboard']` | `GET /api/analytics/dashboard` | — | Analytics |
| `['notifications']` | `GET /api/notifications` | — | Notifications |
| `['patient-search', term]` | `GET /api/patients/search` | — | Patients |
| `['patient-history', userId]` | `GET /api/patients/{userId}/history` | — | Patients |

### Mutation → Invalidation Pattern

After actions on the SOS Detail page (find ambulance, assign/unassign doctor):

```typescript
const invalidate = () => {
  queryClient.invalidateQueries({ queryKey: ['sos-event', sosId] });
  queryClient.invalidateQueries({ queryKey: ['sos-tracking', sosId] });
};
```

After notification actions (mark read, mark all read):

```typescript
queryClient.invalidateQueries({ queryKey: ['notifications'] });
```

---

## 17. Error Handling

### API Errors

The backend returns errors in this format:

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "SOS event not found",
    "timestamp": "2025-03-12T10:30:00Z"
  }
}
```

The `getApiErrorMessage(err)` utility extracts the `message` field.

### Error Display

- **Login page:** Red error box below the form
- **SOS Detail actions:** Toast notification via `react-hot-toast`
- **Network errors:** Fallback message: "An unexpected error occurred. Please try again."

### Toast Configuration

```typescript
<Toaster
  position="top-right"
  toastOptions={{
    duration: 4000,        // 4 seconds
    style: { fontSize: '14px' },
  }}
/>
```

---

## 18. Test Credentials

From seed data (`./scripts/seed-all.sh`):

| Role | Email | Password | Use Case |
|------|-------|----------|----------|
| Hospital Staff | `staff@hospital.com` | `password123` | Dashboard login (primary) |
| Doctor | `doctor1@test.com` | `password123` | Doctor role testing |
| Patient | `patient1@test.com` | `password123` | User app testing |
| Driver | `driver1@test.com` | `password123` | Driver app testing |

---

## 19. Common Tasks for New Developers

### Adding a New Page

1. Create a page component in `src/pages/NewPage.tsx`.
2. Add the route in `src/routes/index.tsx` inside the `children` array of the Layout route.
3. Add a nav item in `src/components/layout/Sidebar.tsx` in the `navItems` array.
4. Create any needed API functions in `src/api/`.
5. Add types to `src/types/index.ts`.

### Adding a New API Endpoint

1. Add the TypeScript interface for request/response in `src/types/index.ts`.
2. Add the API function in the appropriate `src/api/*.api.ts` file.
3. Use `useQuery` (for reads) or direct calls (for mutations) in your page/component.
4. After mutations, invalidate relevant queries.

### Adding a New Zustand Store

1. Create `src/store/newStore.ts`.
2. Define the interface and create the store with `create<T>()`.
3. Add `persist(...)` wrapper if the state should survive page refreshes.
4. Import and use via `useNewStore((s) => s.field)` in components.

### Modifying Status Colors

Edit `src/utils/parseStatus.ts`. Each status type has its own color function that returns Tailwind class strings. The Badge component accepts these as `className`.

### Running the Full System Locally

```bash
# 1. Start the database
docker compose -f docker-compose.raksha-db.yml up -d

# 2. Seed test data
./scripts/seed-all.sh

# 3. Start the backend
cd backend && mvn spring-boot:run

# 4. Start the dashboard
cd hospital-dashboard && npm run dev

# 5. Open http://localhost:5173 and login as staff@hospital.com / password123
```

### Understanding the Polling System

The dashboard does **not** use WebSocket. Instead:
- React Query's `refetchInterval` polls the backend at set intervals (10–30s).
- The `useNotificationPolling` hook polls unread count every 30s via `setInterval`.
- To change polling frequency, modify the `refetchInterval` value in the relevant `useQuery` call.

### Key Files to Understand First

For a new developer, read these files in order:
1. `src/types/index.ts` — All data shapes
2. `src/api/client.ts` — How API calls are authenticated
3. `src/store/authStore.ts` — How login state is managed
4. `src/routes/index.tsx` — How routes and auth guards work
5. `src/components/layout/Layout.tsx` — How the app shell works
6. `src/pages/Dashboard.tsx` — Example of a page using React Query
7. `src/pages/SosDetail.tsx` — Example of a page with mutations and multiple queries

---

*This document is the complete technical reference for the RakshaPoorvak Hospital Dashboard. Keep it updated as the codebase evolves.*
