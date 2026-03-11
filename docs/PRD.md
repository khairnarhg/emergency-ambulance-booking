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

### 2.1 One-Tap SOS with Automatic Medical Context
- Immediate emergency activation without manual input
- Automatically sends: GPS location, medical history, emergency contacts, user profile
- No typing required

### 2.2 Real-Time Triage and Doctor Video Assistance
- Doctors can join video calls with paramedics inside ambulance
- View patient vitals live
- Guide treatment before hospital arrival
- Pre-hospital medical intervention

### 2.3 Live Synchronization Across All Stakeholders
- User, ambulance, and hospital all see same live data
- Same ambulance location, ETA, medical records, status
- No information gaps

### 2.4 Smart Ambulance Allocation Engine
- Automatically selects nearest ambulance
- Best route considering traffic
- Available paramedic resources
- Minimizes response time

### 2.5 In-Transit Medical Records System
- All vitals and treatments logged digitally before hospital arrival
- Hospital staff can prepare in advance

### 2.6 Hospital Command Center Dashboard
- Centralized emergency control interface
- Track all ambulances, assign doctors, monitor emergencies, view live triage

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

| # | Feature | Description |
|---|---------|-------------|
| 5.1 | Authentication | Login, Register, Logout |
| 5.2 | SOS Activation | One tap SOS button, auto-capture location and user info |
| 5.3 | SOS Confirmation Screen | Optional: symptoms, criticality level |
| 5.4 | Live Ambulance Tracking | Ambulance location, driver name, ETA, live map updates |
| 5.5 | Communication | Call paramedic, join video call with doctor |
| 5.6 | Status Tracking | Searching, Assigned, Enroute, Arriving, Completed |
| 5.7 | Emergency History | View past emergencies (date, symptoms, outcome) |
| 5.8 | Notifications | Ambulance assigned, ambulance arriving |
| 5.9 | Profile Management | Edit medical history, blood group, emergency contact |

---

## 6. Driver Application – Feature Requirements

| # | Feature | Description |
|---|---------|-------------|
| 6.1 | Authentication | Driver login, Logout |
| 6.2 | Dispatch Request Reception | Receive SOS request, display location and distance, Accept/Reject |
| 6.3 | Navigation System | Optimized route, auto-updates |
| 6.4 | Live Location Broadcasting | Driver GPS sent continuously |
| 6.5 | Patient Pickup Status | Update: Enroute, Reached patient, Picked up, Enroute to hospital, Arrived |
| 6.6 | Triage Entry | Heart rate, BP, SpO2, notes |
| 6.7 | Medication Entry | Enter medications given |
| 6.8 | Doctor Communication | Video call doctor, audio call doctor |
| 6.9 | Case Completion | Driver closes case |

---

## 7. Hospital Dashboard – Feature Requirements

| # | Feature | Description |
|---|---------|-------------|
| 7.1 | Login | Hospital staff login |
| 7.2 | Command Dashboard | View active SOS, ambulances, response times |
| 7.3 | SOS Monitoring | View all SOS cases (location, user info, symptoms) |
| 7.4 | Dispatch Tracking | Track ambulance live |
| 7.5 | Map Monitoring | View all ambulances on map |
| 7.6 | Doctor Assignment | Assign doctor to SOS case |
| 7.7 | Video Call Monitoring | See which doctors are live |
| 7.8 | In-Transit Medical Records | View vitals, medications |
| 7.9 | Staff Management | View doctors, paramedics (online, offline, busy) |
| 7.10 | Notifications | New SOS, ambulance arrival alerts |
| 7.11 | Patient History | View all past records |
| 7.12 | Analytics | Response times, emergency volume |

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

| Feature | User App | Driver App | Hospital Dashboard |
|---------|----------|------------|---------------------|
| SOS trigger | YES | NO | View only |
| Ambulance tracking | YES | YES | YES |
| Doctor video call | YES | YES | YES |
| Medical record entry | NO | YES | View |
| Doctor assignment | NO | NO | YES |
| Dispatch acceptance | NO | YES | Monitor |
| Analytics | NO | NO | YES |

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

- AI emergency prediction
- Wearable integration
- Multi-hospital support
