# 🚑 RakshaPoorvak

**Cloud-Based Emergency Ambulance Dispatch & Triage System**

RakshaPoorvak is a real-time emergency response platform designed to reduce ambulance response time, improve pre-hospital care, and enable hospitals to prepare before patient arrival. The system connects users (patients), ambulance drivers/paramedics, and hospital emergency departments through cloud-based synchronization, live tracking, and in-transit triage.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Problem Statement](#problem-statement)
- [System Architecture](#system-architecture)
- [Tech Stack](#tech-stack)
- [Core Functionalities](#core-functionalities)
- [End-to-End System Flow](#end-to-end-system-flow)
- [Application Features](#application-features)
- [Data Model](#data-model)
- [Non-Functional Requirements](#non-functional-requirements)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Documentation Index](#documentation-index)

---

## Overview

RakshaPoorvak consists of three primary applications that communicate through a centralized backend and real-time sync layer:

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Hospital Dashboard** | React + Vite | Web-based command center for emergency monitoring and dispatch |
| **User Mobile App** | Flutter (Android) | One-tap SOS, live tracking, emergency history for patients |
| **Driver Mobile App** | Flutter (Android) | Dispatch acceptance, navigation, triage entry for paramedics |
| **Backend** | Spring Boot | REST APIs, WebSocket, business logic, dispatch engine |
| **Database** | PostgreSQL | Persistent storage for users, SOS events, medical records |

**Target Deployment:** Future scope includes multi-hospital cloud deployment.

---

## Problem Statement

Existing ambulance booking systems suffer from:

- ❌ Manual dispatch delays
- ❌ No real-time triage support
- ❌ No hospital preparedness visibility
- ❌ No real-time coordination between ambulance and hospital
- ❌ No centralized monitoring dashboard

**RakshaPoorvak solves all of these.**

---

## System Architecture

```
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│   User App          │     │   Driver App        │     │   Hospital          │
│   (Flutter)         │     │   (Flutter)         │     │   Dashboard         │
│                     │     │                     │     │   (React + Vite)    │
└──────────┬──────────┘     └──────────┬──────────┘     └──────────┬──────────┘
           │                           │                           │
           │  REST / WebSocket         │  REST / WebSocket         │  REST / WebSocket
           │                           │                           │
           └───────────────────────────┼───────────────────────────┘
                                       │
                                       ▼
                           ┌───────────────────────┐
                           │   Spring Boot         │
                           │   Backend API         │
                           │   + WebSocket Server  │
                           └───────────┬───────────┘
                                       │
                                       ▼
                           ┌───────────────────────┐
                           │   PostgreSQL          │
                           │   Database            │
                           └───────────────────────┘
```

**Data Sync Flow:**
- Driver → Backend → User
- Driver → Backend → Hospital
- Hospital → Backend → Driver
- All systems update in real time (2–5 second sync interval)

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend (Web) | React 18+, Vite, TypeScript |
| Mobile (User & Driver) | Flutter, Dart |
| Backend | Spring Boot 3.x, Java 17+ |
| Database | PostgreSQL 15+ |
| Real-time | WebSocket (STOMP over WebSocket) |
| Auth | JWT (JSON Web Tokens) |
| Maps | Google Maps API / OpenStreetMap |
| Video/Audio | WebRTC (for doctor–paramedic calls) |

---

## Core Functionalities

### 1️⃣ One-Tap SOS Activation

**Purpose:** Enable users to instantly request emergency assistance with minimal interaction.

**Technical Flow:**
1. User presses SOS → App captures GPS, timestamp, user profile (name, age, blood group, emergency contact, known medical conditions)
2. Optional symptoms entered by user
3. SOS Event Object created and sent to backend
4. **Two parallel processes:**
   - **Process A:** Hospital dashboard notified → displays alert, location on map, patient info, symptoms
   - **Process B:** Backend finds nearest available ambulance → Driver receives notification (Accept/Reject)

**Example SOS Event:**
```json
{
  "sosId": "SOS102",
  "userId": "U12",
  "location": { "lat": 19.07, "lng": 72.87 },
  "symptoms": "Chest pain",
  "timestamp": "10:21:00",
  "status": "SEARCHING"
}
```

---

### 2️⃣ Smart Routing and Ambulance Allocation

**Purpose:** Ensure the fastest possible ambulance reaches the patient.

**Flow:**
- Driver accepts dispatch → Backend assigns ambulance to SOS case
- Route calculated using: traffic data, road closures, distance, ETA
- Route auto-recalculates if traffic changes
- User App, Hospital Dashboard, and Driver App all receive assignment updates

---

### 3️⃣ Real-Time Sync and Tracking

**Purpose:** All stakeholders have synchronized real-time information.

**Sync:** Every 2–5 seconds, Driver App sends GPS → Backend → User App + Hospital Dashboard

**Status Transitions:**
| Status | Description |
|--------|-------------|
| `SEARCHING` | SOS created, looking for ambulance |
| `AMBULANCE_ASSIGNED` | Driver accepted |
| `DRIVER_ENROUTE` | Driver heading to patient |
| `PATIENT_PICKED_UP` | Patient in ambulance |
| `ENROUTE_TO_HOSPITAL` | Heading to hospital |
| `ARRIVED` | Case closed |

---

### 4️⃣ Triage on the Go (Real-Time Medical Intervention)

**Purpose:** Enable early medical assessment before hospital arrival.

**Features:**
- Paramedic enters vitals: heart rate, BP, SpO2, breathing rate
- Notes and medications given
- **Real-time video/audio call** between doctor (hospital) and paramedic (ambulance)
- Doctor sees patient vitals + live location on dashboard
- Doctor guides treatment remotely

---

### 5️⃣ In-Transit Medical Records & Hospital Preparedness

**Purpose:** Ensure hospital is fully prepared before patient arrival.

**Data streamed to hospital:**
- Vitals, medications, doctor notes, ETA
- Hospital can prepare ICU, ER, call specialists
- Eliminates delays after arrival

---

## End-to-End System Flow

| Phase | Description |
|-------|-------------|
| **Phase 1: SOS Initiation** | User presses SOS → Location, profile, symptoms captured → Hospital notified + Nearest ambulance detected |
| **Phase 2: Ambulance Allocation** | Backend finds nearest ambulance → Driver notified → Driver accepts → Assignment confirmed → User + hospital notified |
| **Phase 3: Enroute to User** | Driver navigates → Location syncs continuously → User sees ambulance approaching |
| **Phase 4: Patient Pickup** | Driver reaches location → Paramedic begins triage → Vitals entered → Doctor may join video call → Hospital prepares |
| **Phase 5: Transport to Hospital** | Ambulance moves to hospital → Hospital receives live location, medical data, ETA |
| **Phase 6: Arrival and Handover** | Driver marks ARRIVED → Hospital receives patient → Data stored → Case closed |

---

## Application Features

### Hospital Dashboard (React)

| Feature | Description |
|---------|-------------|
| Emergency Monitoring | View all SOS cases, status, location on map |
| Dispatch Management | Assign doctor, view assigned ambulance, track live |
| Live Map | See all ambulances, active SOS locations |
| In-Transit Records | View vitals, medications, triage notes |
| Doctor/Paramedic Management | View online/offline/busy status, assign doctors |
| Notifications | New SOS alerts, ambulance arrival alerts |
| Analytics | Response times, case volume, ambulance usage |

### User Application (Flutter)

| Feature | Description |
|---------|-------------|
| SOS Activation | One-tap SOS button |
| Live Tracking | See ambulance location, ETA |
| Communication | Call paramedic, video call doctor |
| Emergency History | View past SOS events |
| Profile Management | Edit medical info, emergency contacts |

### Driver Application (Flutter)

| Feature | Description |
|---------|-------------|
| Dispatch Management | Accept SOS requests, view assigned case |
| Navigation | Optimized route to user, to hospital |
| Medical Input | Enter vitals, medications, notes |
| Communication | Video call doctor, call hospital |
| Status Updates | Mark Enroute, Picked up, Arrived |

---

## Data Model

Each SOS stores:

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

## Non-Functional Requirements

| Requirement | Target |
|-------------|--------|
| Latency | < 2 seconds update delay |
| Availability | 99% uptime |
| Security | JWT authentication |
| Scalability | Horizontal scaling support |

---

## Project Structure

See [PROJECT_STRUCTURE.md](./docs/PROJECT_STRUCTURE.md) for the recommended folder layout.

---

## Getting Started

1. **Prerequisites:** See [ENVIRONMENT_SETUP.md](./docs/ENVIRONMENT_SETUP.md) for required tools and installation steps on macOS.
2. **Database:** See [docs/db.md](./docs/db.md) for Docker PostgreSQL setup (Rancher Desktop). Start with `docker compose -f docker-compose.raksha-db.yml up -d`.
3. **Coding Standards:** AI agents and developers should follow [CODING_RULES.md](./docs/CODING_RULES.md) for consistency and quality.

---

## Documentation Index

| Document | Purpose |
|----------|---------|
| [README.md](./README.md) | This file – project overview and quick reference |
| [docs/PROJECT_STRUCTURE.md](./docs/PROJECT_STRUCTURE.md) | Recommended folder structure for all components |
| [docs/ENVIRONMENT_SETUP.md](./docs/ENVIRONMENT_SETUP.md) | Prerequisites, environment setup, and Mac installation |
| [docs/db.md](./docs/db.md) | PostgreSQL Docker setup (Rancher Desktop), pgAdmin connection |
| [docs/POSTMAN_API_REFERENCE.md](./docs/POSTMAN_API_REFERENCE.md) | API testing with Postman – URLs, headers, sample bodies |
| [docs/HOSPITAL_DASHBOARD_UI_PROMPT.md](./docs/HOSPITAL_DASHBOARD_UI_PROMPT.md) | Full prompt for building Hospital Dashboard UI |
| [docs/CODING_RULES.md](./docs/CODING_RULES.md) | Coding standards for AI agents and developers |
| [docs/PRD.md](./docs/PRD.md) | Full Product Requirements Document (reference) |

---

## Success Metrics

- ✅ Reduce ambulance response time
- ✅ Improve hospital preparedness
- ✅ Enable early triage and pre-hospital intervention

## Future Enhancements

- AI emergency prediction
- Wearable integration
- Multi-hospital support

---

*RakshaPoorvak – Saving lives through real-time coordination.*
