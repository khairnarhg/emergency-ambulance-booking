# Product Requirements Document (PRD)

**RakshaPoorvak – Real-Time Emergency Ambulance Dispatch & Triage Platform**

---

## 1. Product Overview

### 1.1 Product Name
RakshaPoorvak

### 1.2 Target Deployment
Future scope: Multi-hospital cloud deployment.

### 1.3 Product Objective
RakshaPoorvak is a real-time emergency response and ambulance coordination platform that connects:
- Emergency patients (User App)
- Ambulance drivers & paramedics (Driver App)
- Hospital emergency departments (Hospital Dashboard)

The system reduces emergency response time, enables live medical triage during transit, and ensures hospitals are fully prepared before patient arrival.

### 1.4 Problem Statement
Existing ambulance booking systems suffer from:
- Manual dispatch delays
- No real-time triage support
- No hospital preparedness visibility
- No real-time coordination between ambulance and hospital
- No centralized monitoring dashboard

RakshaPoorvak solves all of these.

---

## 2. Core Differentiating Features

### 2.1 One-Tap SOS with Automatic Medical Context (Implemented)
- Immediate emergency activation without manual input
- Automatically sends: GPS location, medical history, emergency contacts, user profile
- No typing required

### 2.2 Real-Time Triage System (Implemented)
- Paramedics record vitals (HR, BP, SpO2, temperature) in transit
- Medications administered are logged with timestamps
- Hospital staff view live triage data before patient arrival
- Pre-hospital medical documentation

### 2.3 Live Synchronization Across All Stakeholders (Implemented)
- User, ambulance, and hospital all see same live data via WebSocket
- Same ambulance location, ETA, medical records, status
- No information gaps
- Real-time status updates across all three applications

### 2.4 Smart Ambulance Allocation Engine (Implemented)
- Automatically selects nearest hospital (geo-based)
- Finds nearest available ambulance (same branch first, cross-branch fallback)
- Cascading dispatch: if driver rejects, next nearest is auto-assigned
- Minimizes response time

### 2.5 In-Transit Medical Records System (Implemented)
- All vitals and treatments logged digitally before hospital arrival
- Hospital staff can prepare in advance
- Complete digital trail of emergency response

### 2.6 Hospital Command Center Dashboard (Implemented)
- Centralized emergency control interface
- Track all ambulances on live map
- Assign doctors, monitor emergencies, view live triage
- Analytics: response times, emergency volume, hotspot analysis

### 2.7 Doctor Video Assistance (Future Scope)
- Video calls between doctor and paramedic
- Real-time medical guidance during transport
- *Not implemented in current version*

---

## 3. System Components

1. User Mobile Application (Flutter)
2. Driver Mobile Application (Flutter)
3. Hospital Management Dashboard (React + Vite)
4. Backend (Spring Boot)
5. Database (PostgreSQL)

---

## 4. End-to-End System Flow

| Step | Description |
|------|-------------|
| 1 | User presses SOS → System captures location, medical profile, timestamp → SOS created |
| 2 | Hospital notified instantly → Dashboard shows new emergency, user location, symptoms |
| 3 | Nearest ambulance detected → Dispatch engine finds nearest available ambulance → Driver receives request |
| 4 | Driver accepts request → Assignment confirmed → User sees ambulance assigned + ETA → Hospital sees ambulance assigned |
| 5 | Ambulance travels to patient → Location updated continuously → User and hospital see real-time tracking |
| 6 | Paramedic begins triage → Vitals entered → Doctor may join video call → Hospital receives live data |
| 7 | Ambulance transports patient → Hospital prepares |
| 8 | Arrival → Case closed → All data saved |

---

## 5. User Application – Feature Requirements

| # | Feature | Description | Status |
|---|---------|-------------|--------|
| 5.1 | Authentication | Login, Register, Logout | Implemented |
| 5.2 | SOS Activation | One tap SOS button, auto-capture location and user info | Implemented |
| 5.3 | SOS Confirmation Screen | Optional: symptoms, criticality level | Implemented |
| 5.4 | Live Ambulance Tracking | Ambulance location, driver name, ETA, live map updates (WebSocket) | Implemented |
| 5.5 | Communication | Call paramedic via phone | Implemented |
| 5.6 | Status Tracking | Full 10-step status flow from CREATED to COMPLETED | Implemented |
| 5.7 | Emergency History | View past emergencies (date, symptoms, outcome) | Implemented |
| 5.8 | Notifications | Real-time via WebSocket + polling fallback | Implemented |
| 5.9 | Profile Management | Edit profile, medical history, blood group, emergency contacts | Implemented |
| 5.10 | Video Call with Doctor | Video consultation during emergency | Future Scope |

---

## 6. Driver Application – Feature Requirements

| # | Feature | Description | Status |
|---|---------|-------------|--------|
| 6.1 | Authentication | Driver login, Logout (DRIVER role validation) | Implemented |
| 6.2 | Dispatch Request Reception | Real-time WebSocket notifications, accept/reject with 60s timer | Implemented |
| 6.3 | Navigation System | OSRM-powered route display, recalculates every 30s | Implemented |
| 6.4 | Live Location Broadcasting | GPS sent every 5 seconds to backend | Implemented |
| 6.5 | Patient Pickup Status | 6-step workflow: Assigned → Enroute → Reached → Picked Up → To Hospital → Arrived | Implemented |
| 6.6 | Triage Entry | Heart rate, BP, SpO2, temperature, notes with visual indicators | Implemented |
| 6.7 | Medication Entry | Enter medications with dosage and notes | Implemented |
| 6.8 | Doctor Communication | Call patient via phone | Implemented |
| 6.9 | Case Completion | Driver closes case, ambulance auto-available | Implemented |
| 6.10 | Video Call with Doctor | Video consultation during transport | Future Scope |

---

## 7. Hospital Dashboard – Feature Requirements

| # | Feature | Description | Status |
|---|---------|-------------|--------|
| 7.1 | Login | Hospital staff/doctor/admin login | Implemented |
| 7.2 | Command Dashboard | Active SOS count, ambulance availability, response times | Implemented |
| 7.3 | SOS Monitoring | Paginated SOS list with filters, real-time via WebSocket | Implemented |
| 7.4 | Dispatch Tracking | Live ambulance position on map, ETA, route visualization | Implemented |
| 7.5 | Map Monitoring | Interactive map with ambulances, SOS events, hospitals | Implemented |
| 7.6 | Doctor Assignment | Assign/unassign doctor to active SOS | Implemented |
| 7.7 | Smart Dispatch | One-click nearest ambulance assignment | Implemented |
| 7.8 | In-Transit Medical Records | Live triage records and medications view | Implemented |
| 7.9 | Staff Management | View doctors, drivers with availability status | Implemented |
| 7.10 | Notifications | Real-time via WebSocket + polling, unread badge | Implemented |
| 7.11 | Patient History | Search patients, view SOS history | Implemented |
| 7.12 | Analytics | Response times, volume trends, hotspot analysis | Implemented |
| 7.13 | Video Call Monitoring | Track active video calls | Future Scope |

---

## 8. Data Requirements

Each SOS must store:
- SOS ID
- User ID
- Location (lat, lng)
- Timestamp
- Ambulance ID
- Driver ID
- Doctor ID
- Status
- Symptoms
- Vitals (heart rate, BP, SpO2, etc.)
- Medications
- Notes

---

## 9. Functional Requirements Summary

| Feature | User App | Driver App | Hospital Dashboard | Status |
|---------|----------|------------|---------------------|--------|
| SOS trigger | YES | NO | View only | Implemented |
| Ambulance tracking | YES | YES | YES | Implemented |
| Doctor video call | Future | Future | Future | Future Scope |
| Medical record entry | NO | YES | View | Implemented |
| Doctor assignment | NO | NO | YES | Implemented |
| Dispatch acceptance | NO | YES | Monitor | Implemented |
| Analytics | NO | NO | YES | Implemented |
| WebSocket real-time | YES | YES | YES | Implemented |
| GPS broadcasting | NO | YES | View | Implemented |

---

## 10. Non-Functional Requirements

- **Latency:** < 2 seconds update delay
- **Availability:** 99% uptime
- **Security:** JWT authentication
- **Scalable architecture**

---

## 11. Success Metrics

- Reduce ambulance response time
- Improve hospital preparedness
- Enable early triage

---

## 12. Future Enhancements

- **Video/audio calls** — Doctor-paramedic-patient video consultation
- **AI emergency prediction** — Predict emergency hotspots and resource needs
- **Wearable integration** — Auto-trigger SOS from health wearables
- **Multi-hospital chain support** — Support multiple independent hospital chains
- **iOS builds** — Currently Android only
- **Push notifications** — FCM/APNs for background notifications
- **Dark theme** — User preference for dark mode
- **Multi-language support** — Internationalization
