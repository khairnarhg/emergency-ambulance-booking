# RakshaPoorvak Backend – Technical Specification

**Version:** 1.1  
**Last Updated:** April 2026

---

## Table of Contents

1. [Overview](#1-overview)
2. [Technology Stack](#2-technology-stack)
3. [Architecture](#3-architecture)
4. [Database Schema](#4-database-schema)
5. [API Endpoints Reference](#5-api-endpoints-reference)
6. [Authentication & Authorization](#6-authentication--authorization)
7. [Error Handling & Response Formats](#7-error-handling--response-formats)
8. [Environment & Configuration](#8-environment--configuration)
9. [Development Workflow](#9-development-workflow)
10. [Postman Testing](#10-postman-testing)

---

## 1. Overview

The RakshaPoorvak backend is a REST API that powers the Emergency Ambulance Dispatch & Triage System. It serves three clients:

- **User App (Flutter)** – Emergency patients
- **Driver App (Flutter)** – Ambulance drivers and paramedics
- **Hospital Dashboard (React)** – Hospital emergency command center

### Key Capabilities

- One-tap SOS with automatic medical context
- Smart ambulance allocation (nearest available)
- Doctor assignment (assign free doctor; notify user if none available)
- In-transit triage (vitals, medications)
- Real-time tracking (location updates, ETA)
- Analytics and dashboards
- JWT-based authentication

### Out of Scope (Current Phase)

- Video/phone calls between doctor, paramedic, and user

---

## 2. Technology Stack

| Component | Technology |
|-----------|------------|
| Framework | Spring Boot 3.2.5 |
| Language | Java 17 |
| Database | PostgreSQL 15+ |
| ORM | Spring Data JPA |
| Migrations | Flyway |
| Auth | JWT (JJWT 0.12.3) |
| Validation | Bean Validation (JSR-380) |
| Real-time | WebSocket (STOMP over SockJS) |
| DB Client | pgAdmin |

---

## 3. Architecture

### Layered Architecture

```
Controller → Service → Repository → Entity
     ↓           ↓
    DTO      DTO / Entity
```

### Package Structure

```
com.rakshapoorvak
├── config/           # Security, CORS, app config
├── controller/       # REST controllers (thin)
├── service/          # Business logic
├── repository/       # Spring Data JPA
├── model/
│   ├── entity/       # JPA entities
│   └── dto/          # Request/Response DTOs
├── mapper/           # Entity ↔ DTO mappers
├── exception/        # Custom exceptions, global handler
└── security/         # JWT filter, JwtUtil
```

### Naming Conventions

- **Tables:** `snake_case`, plural (e.g. `sos_events`, `ambulances`)
- **Columns:** `snake_case`
- **Indexes:** `idx_<table>_<column(s)>`
- **Foreign keys:** `fk_<table>_<ref_table>`

---

## 4. Database Schema

### Core Entities

| Table | Description |
|-------|-------------|
| `users` | Patients (User App); profile, phone, email |
| `drivers` | Ambulance drivers; linked to user, ambulance |
| `hospitals` | Hospitals with name, address, lat/lng |
| `doctors` | Doctors with hospital link, availability status |
| `ambulances` | Vehicles with registration, hospital, status |
| `sos_events` | SOS incidents; user, location, status, ambulance, doctor |
| `triage_records` | Vitals (HR, BP, SpO2) per SOS |
| `medications` | Medications administered per SOS |
| `location_updates` | Driver/ambulance location history |
| `emergency_contacts` | User emergency contacts |
| `medical_profiles` | User medical history (blood group, allergies, conditions) |
| `roles` | Role definitions (USER, DRIVER, HOSPITAL_STAFF, DOCTOR, ADMIN) |
| `notifications` | Notifications for user/hospital |
| `user_roles` | User-Role mapping |

### SOS Status Flow

```
CREATED → DISPATCHING → AMBULANCE_ASSIGNED → DRIVER_ENROUTE_TO_PATIENT
       → REACHED_PATIENT → PICKED_UP → ENROUTE_TO_HOSPITAL
       → ARRIVED_AT_HOSPITAL → COMPLETED
       → CANCELLED (optional, before ambulance assigned)
```

### Coordinates

- Uses `latitude` (DECIMAL) and `longitude` (DECIMAL) for OpenStreetMap compatibility.
- WGS84 standard.

---

## 5. API Endpoints Reference

### 5.1 Authentication (`/api/auth`)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/auth/register` | User registration | No |
| POST | `/api/auth/login` | Login | No |
| POST | `/api/auth/logout` | Logout | Yes |
| POST | `/api/auth/refresh` | Refresh JWT | No (refresh token) |
| GET | `/api/auth/me` | Current user | Yes |

### 5.2 Users – Profile & Medical

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/users/me` | Get profile | User |
| PATCH | `/api/users/me` | Update profile | User |
| GET | `/api/users/me/medical-profile` | Medical profile | User |
| PATCH | `/api/users/me/medical-profile` | Update medical profile | User |
| GET | `/api/users/me/emergency-contacts` | List emergency contacts | User |
| POST | `/api/users/me/emergency-contacts` | Add contact | User |
| PATCH | `/api/users/me/emergency-contacts/{id}` | Update contact | User |
| DELETE | `/api/users/me/emergency-contacts/{id}` | Remove contact | User |

### 5.3 SOS Events

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/sos-events` | Create SOS | User |
| PATCH | `/api/sos-events/{id}` | Update symptoms/criticality | User |
| GET | `/api/sos-events/{id}` | SOS details | All |
| GET | `/api/sos-events/my` | User's SOS list | User |
| GET | `/api/sos-events/my/active` | User's active SOS | User |
| GET | `/api/sos-events` | List SOS (filtered) | Hospital |
| GET | `/api/sos-events/active` | Active SOS | Hospital |
| PATCH | `/api/sos-events/{id}/status` | Update status | Driver |
| POST | `/api/sos-events/{id}/complete` | Complete SOS | Driver |
| DELETE | `/api/sos-events/{id}` | Cancel SOS | User |

### 5.4 Live Tracking & Map

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/sos-events/{id}/tracking` | Tracking info (location, ETA) | All |
| GET | `/api/sos-events/{id}/location-history` | Location trail | All |
| GET | `/api/sos-events/{id}/eta` | ETA | All |
| GET | `/api/ambulances/locations` | All ambulance locations | Hospital |
| GET | `/api/map/overview` | Map overview (ambulances, SOS, hospitals) | Hospital |

### 5.5 Location Broadcasting

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/locations` | Driver posts GPS update (with sosEventId, ambulanceId) | Driver |
| PATCH | `/api/ambulances/{id}/location` | Update ambulance current position | Driver |

### 5.6 Dispatch

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/dispatch/{sosId}/find-ambulance` | Find & assign nearest ambulance | Hospital |
| GET | `/api/dispatch/pending-requests` | Pending requests for driver | Driver |
| GET | `/api/dispatch/{sosId}/request-details` | Request details for driver | Driver |
| POST | `/api/dispatch/{sosId}/accept` | Driver accepts | Driver |
| POST | `/api/dispatch/{sosId}/reject` | Driver rejects | Driver |

### 5.7 Doctor Assignment

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/doctors` | List doctors | Hospital |
| GET | `/api/doctors/available` | Available doctors | Hospital |
| POST | `/api/sos-events/{sosId}/assign-doctor` | Assign doctor (or notify if none) | Hospital |
| DELETE | `/api/sos-events/{sosId}/doctor` | Unassign doctor | Hospital |
| PATCH | `/api/doctors/{id}/status` | Update doctor status | Hospital |
| PATCH | `/api/doctors/me/status` | Doctor updates own status | Doctor |

### 5.8 Ambulances

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/ambulances` | List ambulances | Hospital |
| GET | `/api/ambulances/{id}` | Ambulance details | All |
| GET | `/api/ambulances/{id}/location` | Current location | All |
| GET | `/api/drivers/me/ambulance` | Driver's ambulance | Driver |
| POST | `/api/ambulances` | Add ambulance | Hospital |
| PATCH | `/api/ambulances/{id}` | Update ambulance | Hospital |
| PATCH | `/api/ambulances/{id}/status` | Update status | Driver |

### 5.9 Drivers

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/drivers/me` | Driver profile | Driver |
| PATCH | `/api/drivers/me` | Update profile | Driver |
| GET | `/api/drivers` | List drivers | Hospital |
| POST | `/api/drivers` | Register driver | Hospital |
| PATCH | `/api/drivers/{id}` | Update driver | Hospital |

### 5.10 Triage (Vitals & Medications)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/triage/sos-events/{sosId}/records` | Add vitals | Driver |
| GET | `/api/triage/sos-events/{sosId}/records` | Triage records | Driver/Hospital |
| PATCH | `/api/triage/records/{id}` | Update record | Driver |
| POST | `/api/triage/sos-events/{sosId}/medications` | Add medication | Driver |
| GET | `/api/triage/sos-events/{sosId}/medications` | Medications | Driver/Hospital |
| PATCH | `/api/triage/medications/{id}` | Update medication | Driver |
| GET | `/api/sos-events/{sosId}/medical-summary` | Combined vitals + meds | Hospital |

### 5.11 Emergency History & Patients

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/users/me/emergency-history` | User's emergency history | User |
| GET | `/api/patients/{userId}/history` | Patient's full history | Hospital |
| GET | `/api/patients/search` | Search patients | Hospital |

### 5.12 Notifications

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/notifications` | List notifications | All |
| GET | `/api/notifications/unread-count` | Unread count | All |
| PATCH | `/api/notifications/{id}/read` | Mark read | All |
| PATCH | `/api/notifications/read-all` | Mark all read | All |

### 5.13 Dashboard & Analytics

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/dashboard/summary` | Dashboard summary | Hospital |
| GET | `/api/dashboard/active-sos` | Active SOS list | Hospital |
| GET | `/api/analytics/response-times` | Response time metrics | Hospital |
| GET | `/api/analytics/emergency-volume` | SOS volume | Hospital |
| GET | `/api/analytics/dashboard` | Combined analytics | Hospital |
| GET | `/api/analytics/by-severity` | By criticality | Hospital |
| GET | `/api/analytics/ambulance-utilization` | Ambulance usage | Hospital |

### 5.14 Hospitals

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/hospitals` | List hospitals | All |
| GET | `/api/hospitals/{id}` | Hospital details | All |
| GET | `/api/hospitals/me` | Current staff's hospital | Hospital |
| GET | `/api/hospitals/{id}/ambulances` | Hospital ambulances | Hospital |
| GET | `/api/hospitals/{id}/doctors` | Hospital doctors | Hospital |

### 5.15 Staff Management

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/staff/summary` | Staff counts by status | Hospital |
| GET | `/api/staff/doctors` | Doctors with status | Hospital |
| GET | `/api/staff/drivers` | Drivers with status | Hospital |
| POST | `/api/doctors` | Add doctor | Hospital |
| PATCH | `/api/doctors/{id}` | Update doctor | Hospital |

### 5.16 Health

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/health` | Health check | No |

---

## 5.17 WebSocket (Real-Time Communication)

The backend provides real-time updates via STOMP over WebSocket with SockJS fallback.

### Connection

| Setting | Value |
|---------|-------|
| Endpoint | `/ws` (native WebSocket) or `/ws` with SockJS |
| Protocol | STOMP |
| Auth | JWT passed via `Authorization` header in STOMP CONNECT frame |
| Topic Prefix | `/topic` |
| App Destination Prefix | `/app` |

### WebSocket Topics

| Topic | Payload | Purpose |
|-------|---------|---------|
| `/topic/sos/{sosId}/status` | `SosEventDto` | SOS status changes |
| `/topic/sos/{sosId}/location` | `{sosEventId, ambulanceId, latitude, longitude, timestamp}` | Real-time ambulance location |
| `/topic/dispatch/driver/{driverId}` | `SosEventDto` | New dispatch request to driver |
| `/topic/notifications/user/{userId}` | `NotificationDto` | Notifications for users |
| `/topic/notifications/driver/{driverId}` | `NotificationDto` | Notifications for drivers |
| `/topic/notifications/hospital/{hospitalId}` | `NotificationDto` | Notifications for hospital staff |
| `/topic/dashboard/{hospitalId}` | `{refresh: true}` | Dashboard refresh signal |

### Broadcast Service

`WebSocketBroadcastService` sends messages via `SimpMessagingTemplate`:

- `broadcastSosStatusChange(sosId, sosDto)` — Called on status updates
- `broadcastAmbulanceLocation(sosId, lat, lng, ambulanceId)` — Called on location updates
- `broadcastDispatchToDriver(driverId, sosDto)` — Called when driver assigned
- `broadcastNotificationToUser/Driver/Hospital()` — Called on notification creation
- `broadcastDashboardRefresh(hospitalId)` — Called on SOS changes

---

## 6. Authentication & Authorization

### JWT Flow

1. **Login:** `POST /api/auth/login` with `email` + `password`
2. Response: `accessToken`, `refreshToken`, `expiresIn`, `user`
3. **Authenticated requests:** `Authorization: Bearer <accessToken>`
4. **Refresh:** `POST /api/auth/refresh` with `refreshToken`

### Roles

| Role | Description | Access |
|------|-------------|--------|
| USER | Patient (User App) | Own profile, SOS, history, notifications |
| DRIVER | Ambulance driver | Dispatch, location, triage, assigned SOS |
| HOSPITAL_STAFF | Dashboard user | SOS, dispatch, doctors, analytics |
| DOCTOR | Doctor | Own status, assigned SOS view |
| ADMIN | System admin | All resources |

### Role-Based Access

- Controllers/methods use `@PreAuthorize("hasRole('...')")` or service-layer checks.
- 403 when role insufficient.

---

## 7. Error Handling & Response Formats

### Success Response

```json
{
  "data": { ... }
}
```

Or direct payload for simple endpoints.

### Error Response

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "SOS event not found",
    "timestamp": "2025-03-12T10:30:00Z"
  }
}
```

### HTTP Status Codes

| Code | Usage |
|------|--------|
| 200 | Success |
| 201 | Created |
| 400 | Bad request / validation |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not found |
| 409 | Conflict (e.g. duplicate) |
| 500 | Server error |

### Global Exception Handler

- `@ControllerAdvice` maps exceptions to HTTP status and error body.
- Logs errors with context; never exposes stack traces to clients.

---

## 8. Environment & Configuration

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DB_URL` | PostgreSQL JDBC URL | `jdbc:postgresql://localhost:5432/rakshapoorvak_dev` |
| `DB_USERNAME` | Database user | `rakshapoorvak` |
| `DB_PASSWORD` | Database password | `dev_password` |
| `JWT_SECRET` | JWT signing secret (min 256 bits) | (secure random) |
| `JWT_ACCESS_EXPIRATION` | Access token TTL (ms) | `86400000` |
| `JWT_REFRESH_EXPIRATION` | Refresh token TTL (ms) | `604800000` |

### Profiles

- `dev` – Development (default)
- `prod` – Production

### Database Client

- **pgAdmin** for connections, schema inspection, and query execution.

---

## 9. Development Workflow

### Setup

1. Run `./scripts/setup-environment.sh` to create DB and user.
2. Configure `application-dev.yml` or env vars.
3. Start backend: `cd backend && mvn spring-boot:run`
4. Migrations run automatically via Flyway.

### Seeding Data

```bash
./scripts/seed-all.sh
```

Runs all scripts in `seed/` in order.

---

## 10. Postman Testing

### Collection Structure

- Import base URL: `http://localhost:8080`
- Use environment variables: `baseUrl`, `accessToken`, `refreshToken`
- Pre-request script for auth: set `Authorization: Bearer {{accessToken}}`
- Test sequence: Login → Save token → Call protected endpoints

### Key Test Flows

1. **User flow:** Register → Login → Create SOS → Get tracking
2. **Driver flow:** Login → Get pending requests → Accept → Update status → Add triage
3. **Hospital flow:** Login → List SOS → Find ambulance → Assign doctor → Analytics

---

*This document is the single source of truth for the RakshaPoorvak backend API and architecture.*
