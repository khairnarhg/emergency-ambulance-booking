# RakshaPoorvak – Postman API Reference

Use this document to test the backend APIs in Postman. Base URL: **http://localhost:8080**

---

## Setup

1. **Environment variables** (optional, for Postman):
   - `baseUrl`: `http://localhost:8080`
   - `accessToken`: (set after login – use in Authorization header)

2. **Headers for protected endpoints:**
   ```
   Authorization: Bearer <accessToken>
   Content-Type: application/json
   ```

3. **Test credentials** (from seed data):

   | Role   | Email               | Password   |
   |--------|---------------------|------------|
   | Patient| patient1@test.com   | password123|
   | Driver | driver1@test.com    | password123|
   | Staff  | staff@hospital.com  | password123|
   | Doctor | doctor1@test.com    | password123|

---

## 1. Health (No Auth)

| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/health` | — | — |

---

## 2. Auth

### Login
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| POST | `http://localhost:8080/api/auth/login` | `Content-Type: application/json` | See below |

**Body (raw JSON):**
```json
{
  "email": "patient1@test.com",
  "password": "password123"
}
```

**Response:** `accessToken`, `refreshToken`, `expiresIn`, `user` → Copy `accessToken` for other requests.

---

### Register
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| POST | `http://localhost:8080/api/auth/register` | `Content-Type: application/json` | See below |

**Body (raw JSON):**
```json
{
  "email": "newuser@test.com",
  "password": "password123",
  "fullName": "New User",
  "phone": "9876543210",
  "roles": ["USER"]
}
```

---

### Refresh Token
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| POST | `http://localhost:8080/api/auth/refresh` | `Content-Type: application/json` | See below |

**Body (raw JSON):**
```json
{
  "refreshToken": "<paste_refresh_token_here>"
}
```

---

### Get Current User
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/auth/me` | `Authorization: Bearer <token>` | — |

---

### Logout
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| POST | `http://localhost:8080/api/auth/logout` | `Authorization: Bearer <token>` | — |

---

## 3. User (Auth: USER role)

### Get Profile
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/users/profile` | `Authorization: Bearer <token>` | — |

---

### Update Profile
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| PATCH | `http://localhost:8080/api/users/profile` | `Authorization: Bearer <token>`<br>`Content-Type: application/json` | See below |

**Body (raw JSON):**
```json
{
  "fullName": "Updated Name",
  "phone": "9999888877"
}
```

---

### Get Medical Profile
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/users/medical-profile` | `Authorization: Bearer <token>` | — |

---

### Update Medical Profile
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| PATCH | `http://localhost:8080/api/users/medical-profile` | `Authorization: Bearer <token>`<br>`Content-Type: application/json` | See below |

**Body (raw JSON):**
```json
{
  "bloodGroup": "O+",
  "allergies": "None",
  "conditions": "Hypertension",
  "notes": "On medication"
}
```

---

### List Emergency Contacts
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/users/emergency-contacts` | `Authorization: Bearer <token>` | — |

---

### Add Emergency Contact
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| POST | `http://localhost:8080/api/users/emergency-contacts` | `Authorization: Bearer <token>`<br>`Content-Type: application/json` | See below |

**Body (raw JSON):**
```json
{
  "name": "John Doe",
  "phone": "9123456789",
  "relationship": "Spouse"
}
```

---

### Update Emergency Contact
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| PUT | `http://localhost:8080/api/users/emergency-contacts/{id}` | `Authorization: Bearer <token>`<br>`Content-Type: application/json` | Same as Add |

---

### Delete Emergency Contact
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| DELETE | `http://localhost:8080/api/users/emergency-contacts/{id}` | `Authorization: Bearer <token>` | — |

---

## 4. SOS Events

### Create SOS (USER)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| POST | `http://localhost:8080/api/sos-events` | `Authorization: Bearer <token>`<br>`Content-Type: application/json` | See below |

**Body (raw JSON):**
```json
{
  "latitude": 19.0650,
  "longitude": 72.8450,
  "address": "Linking Road, Bandra",
  "symptoms": "Chest pain, shortness of breath",
  "criticality": "HIGH"
}
```
`criticality`: `LOW` \| `MEDIUM` \| `HIGH` \| `CRITICAL` (optional)

---

### Update SOS (symptoms/criticality) – USER
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| PATCH | `http://localhost:8080/api/sos-events/{id}` | `Authorization: Bearer <token>`<br>`Content-Type: application/json` | See below |

**Body (raw JSON):**
```json
{
  "symptoms": "Updated symptoms",
  "criticality": "CRITICAL"
}
```

---

### Get SOS by ID
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/sos-events/{id}` | `Authorization: Bearer <token>` | — |

---

### Get My SOS List (USER)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/sos-events/my` | `Authorization: Bearer <token>` | — |

---

### Get My Active SOS (USER)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/sos-events/my/active` | `Authorization: Bearer <token>` | — |

---

### List SOS (Hospital)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/sos-events?hospitalId=1&status=CREATED&page=0&size=20` | `Authorization: Bearer <token>` | — |
Query params: `hospitalId`, `status`, `page`, `size` (all optional)

---

### Get Active SOS (Hospital)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/sos-events/active?hospitalId=1` | `Authorization: Bearer <token>` | — |

---

### Update Status (DRIVER)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| PATCH | `http://localhost:8080/api/sos-events/{id}/status` | `Authorization: Bearer <token>`<br>`Content-Type: application/json` | See below |

**Body (raw JSON):**
```json
{
  "status": "DRIVER_ENROUTE_TO_PATIENT"
}
```
Status values: `DRIVER_ENROUTE_TO_PATIENT`, `REACHED_PATIENT`, `PICKED_UP`, `ENROUTE_TO_HOSPITAL`, `ARRIVED_AT_HOSPITAL`

---

### Complete SOS (DRIVER)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| POST | `http://localhost:8080/api/sos-events/{id}/complete` | `Authorization: Bearer <token>` | — |

---

### Cancel SOS (USER)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| DELETE | `http://localhost:8080/api/sos-events/{id}` | `Authorization: Bearer <token>` | — |

---

### Get Tracking
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/sos-events/{id}/tracking` | `Authorization: Bearer <token>` | — |

---

### Assign Doctor (Hospital)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| POST | `http://localhost:8080/api/sos-events/{sosId}/assign-doctor` | `Authorization: Bearer <token>` | — |

---

### Unassign Doctor (Hospital)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| DELETE | `http://localhost:8080/api/sos-events/{sosId}/doctor` | `Authorization: Bearer <token>` | — |

---

## 5. Dispatch (DRIVER / HOSPITAL_STAFF)

### Find Ambulance (Hospital)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| POST | `http://localhost:8080/api/dispatch/{sosId}/find-ambulance` | `Authorization: Bearer <token>` | — |

---

### Get Pending Requests (Driver)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/dispatch/pending-requests` | `Authorization: Bearer <token>` | — |

---

### Get Request Details (Driver)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/dispatch/{sosId}/request-details` | `Authorization: Bearer <token>` | — |

---

### Accept (Driver)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| POST | `http://localhost:8080/api/dispatch/{sosId}/accept` | `Authorization: Bearer <token>` | — |

---

### Reject (Driver)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| POST | `http://localhost:8080/api/dispatch/{sosId}/reject` | `Authorization: Bearer <token>` | — |

---

## 6. Hospitals

### List Hospitals
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/hospitals` | `Authorization: Bearer <token>` | — |

---

### Get Hospital by ID
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/hospitals/{id}` | `Authorization: Bearer <token>` | — |

---

### Get My Hospital (Hospital Staff)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/hospitals/my-hospital` | `Authorization: Bearer <token>` | — |

---

## 7. Ambulances

### List Ambulances
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/ambulances?hospitalId=1` | `Authorization: Bearer <token>` | — |

---

### Get Ambulance by ID
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/ambulances/{id}` | `Authorization: Bearer <token>` | — |

---

### Get Ambulance Location
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/ambulances/{id}/location` | `Authorization: Bearer <token>` | — |

---

### Update Ambulance Location (Driver)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| PATCH | `http://localhost:8080/api/ambulances/{id}/location` | `Authorization: Bearer <token>`<br>`Content-Type: application/json` | See below |

**Body (raw JSON):**
```json
{
  "latitude": 19.07,
  "longitude": 72.88
}
```

---

### Update Ambulance Status (Driver)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| PATCH | `http://localhost:8080/api/ambulances/{id}/status` | `Authorization: Bearer <token>`<br>`Content-Type: application/json` | See below |

**Body (raw JSON):**
```json
{
  "status": "DISPATCHED"
}
```
Status: `AVAILABLE`, `DISPATCHED`, `MAINTENANCE`, `OFFLINE`

---

## 8. Drivers

### Get My Profile (Driver)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/drivers/me` | `Authorization: Bearer <token>` | — |

---

### Update My Profile (Driver)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| PATCH | `http://localhost:8080/api/drivers/me` | `Authorization: Bearer <token>`<br>`Content-Type: application/json` | See below |

**Body (raw JSON):**
```json
{
  "status": "AVAILABLE"
}
```
Status: `AVAILABLE`, `BUSY`, `OFFLINE`

---

### List Drivers (Hospital)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/drivers?hospitalId=1` | `Authorization: Bearer <token>` | — |

---

## 9. Triage (DRIVER)

### Add Triage Record
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| POST | `http://localhost:8080/api/triage/records` | `Authorization: Bearer <token>`<br>`Content-Type: application/json` | See below |

**Body (raw JSON):**
```json
{
  "sosEventId": 1,
  "heartRate": 72,
  "systolicBp": 120,
  "diastolicBp": 80,
  "spo2": 98,
  "temperature": 36.5,
  "notes": "Stable"
}
```

---

### List Triage Records
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/triage/records?sosEventId=1` | `Authorization: Bearer <token>` | — |

---

### Add Medication
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| POST | `http://localhost:8080/api/triage/medications` | `Authorization: Bearer <token>`<br>`Content-Type: application/json` | See below |

**Body (raw JSON):**
```json
{
  "sosEventId": 1,
  "name": "Paracetamol",
  "dosage": "500mg",
  "notes": "For fever"
}
```

---

### List Medications
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/triage/medications?sosEventId=1` | `Authorization: Bearer <token>` | — |

---

## 10. Location (DRIVER)

### Post Location Update
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| POST | `http://localhost:8080/api/locations` | `Authorization: Bearer <token>`<br>`Content-Type: application/json` | See below |

**Body (raw JSON):**
```json
{
  "latitude": 19.07,
  "longitude": 72.88,
  "sosEventId": 1,
  "ambulanceId": 1
}
```

---

## 11. Dashboard (Hospital)

### Get Summary
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/dashboard/summary?hospitalId=1` | `Authorization: Bearer <token>` | — |

---

### Get Active SOS
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/dashboard/active-sos?hospitalId=1` | `Authorization: Bearer <token>` | — |

---

## 12. Analytics (Hospital)

### Response Times
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/analytics/response-times` | `Authorization: Bearer <token>` | — |

---

### Emergency Volume
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/analytics/emergency-volume` | `Authorization: Bearer <token>` | — |

---

### Dashboard
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/analytics/dashboard` | `Authorization: Bearer <token>` | — |

---

## 13. Doctors

### Get Me (Doctor)
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/doctors/me` | `Authorization: Bearer <token>` | — |

---

### List Doctors
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/doctors?hospitalId=1` | `Authorization: Bearer <token>` | — |

---

### Get Doctor by ID
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/doctors/{id}` | `Authorization: Bearer <token>` | — |

---

## 14. Map

### Ambulance Locations
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/map/ambulances` | `Authorization: Bearer <token>` | — |

---

### Map Overview
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/map/overview` | `Authorization: Bearer <token>` | — |

---

## 15. Notifications

### List Notifications
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/notifications` | `Authorization: Bearer <token>` | — |

---

### Unread Count
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/notifications/unread-count` | `Authorization: Bearer <token>` | — |

---

### Mark Read
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| PATCH | `http://localhost:8080/api/notifications/{id}/read` | `Authorization: Bearer <token>` | — |

---

### Mark All Read
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| POST | `http://localhost:8080/api/notifications/read-all` | `Authorization: Bearer <token>` | — |

---

## 16. Patients (Hospital)

### Search
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/patients/search?q=rahul` | `Authorization: Bearer <token>` | — |

---

### Patient History
| Method | URL | Headers | Body |
|--------|-----|---------|------|
| GET | `http://localhost:8080/api/patients/{userId}/history` | `Authorization: Bearer <token>` | — |

---

## Suggested Test Flow

1. **Login** as `staff@hospital.com` → copy `accessToken`
2. **List hospitals** → note `hospitalId` (e.g. 1)
3. **Login** as `patient1@test.com` → create SOS
4. **Login** as `staff@hospital.com` → find ambulance for that SOS
5. **Login** as `driver1@test.com` → get pending requests → accept
6. **Post location** as driver, **add triage record**, **add medication**
7. **Update status** → `DRIVER_ENROUTE_TO_PATIENT` → `REACHED_PATIENT` → `PICKED_UP` → `ENROUTE_TO_HOSPITAL` → `ARRIVED_AT_HOSPITAL`
8. **Complete** SOS as driver
9. **Assign doctor** (as staff) before/during transit
