// ──── Auth ────
export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: User;
}

export interface RefreshRequest {
  refreshToken: string;
}

// ──── User ────
export interface User {
  id: number;
  email: string;
  fullName: string;
  phone: string;
  roles: string[];
}

// ──── Hospital ────
export interface Hospital {
  id: number;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  phone: string;
}

// ──── SOS ────
export type SosStatus =
  | 'CREATED'
  | 'DISPATCHING'
  | 'AMBULANCE_ASSIGNED'
  | 'DRIVER_ENROUTE_TO_PATIENT'
  | 'REACHED_PATIENT'
  | 'PICKED_UP'
  | 'ENROUTE_TO_HOSPITAL'
  | 'ARRIVED_AT_HOSPITAL'
  | 'COMPLETED'
  | 'CANCELLED';

export type Criticality = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';

export interface EmergencyContact {
  id: number;
  name: string;
  phone: string;
  relationship: string;
}

export interface SosEvent {
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
  hospitalName: string | null;
  hospitalAddress: string | null;
  hospitalLatitude: number | null;
  hospitalLongitude: number | null;
  ambulanceRegistrationNumber: string | null;
  bloodGroup: string | null;
  allergies: string | null;
  medicalConditions: string | null;
  emergencyContacts: EmergencyContact[] | null;
  createdAt: string;
  updatedAt: string;
}

export interface LocationHistoryEntry {
  latitude: number;
  longitude: number;
  recordedAt: string;
}

export interface SosTracking {
  sosEventId: number;
  ambulanceLatitude: number | null;
  ambulanceLongitude: number | null;
  driverName: string | null;
  eta: string | null;
  status: SosStatus;
  ambulanceRegistrationNumber: string | null;
  hospitalName: string | null;
  hospitalAddress: string | null;
  estimatedMinutesArrival: number | null;
  driverPhone: string | null;
  locationHistory: LocationHistoryEntry[];
}

// ──── Ambulance ────
export type AmbulanceStatus = 'AVAILABLE' | 'DISPATCHED' | 'MAINTENANCE' | 'OFFLINE';

export interface Ambulance {
  id: number;
  registrationNumber: string;
  status: AmbulanceStatus;
  hospitalId: number;
  hospitalName: string;
  currentLatitude: number | null;
  currentLongitude: number | null;
  updatedAt: string;
}

// ──── Doctor ────
export type StaffStatus = 'AVAILABLE' | 'BUSY' | 'OFFLINE';

export interface Doctor {
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

// ──── Driver ────
export interface Driver {
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

// ──── Triage ────
export interface TriageRecord {
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

export interface Medication {
  id: number;
  sosEventId: number;
  name: string;
  dosage: string;
  notes: string;
  createdAt: string;
}

// ──── Notification ────
export interface Notification {
  id: number;
  title: string;
  body: string;
  isRead: boolean;
  createdAt: string;
}

// ──── Dashboard ────
export interface DashboardSummary {
  activeSosCount: number;
  availableAmbulances: number;
  totalAmbulances: number;
  availableDoctors: number;
  totalDoctors: number;
  avgResponseTimeMinutes: number;
}

// ──── Analytics ────
export interface ResponseTimeMetrics {
  averageMinutes: number;
  medianMinutes: number;
  minMinutes: number;
  maxMinutes: number;
}

export interface EmergencyVolume {
  date: string;
  count: number;
}

export interface AnalyticsDashboard {
  responseTimes: ResponseTimeMetrics;
  volume: EmergencyVolume[];
  bySeverity: Record<string, number>;
  ambulanceUtilization: Record<string, number>;
}

// ──── Hotspot ────
export interface EmergencyHotspot {
  latitude: number;
  longitude: number;
  count: number;
  suggestedLabel: string;
}

// ──── Map ────
export interface MapOverview {
  ambulances: Ambulance[];
  sosEvents: SosEvent[];
  hospitals: Hospital[];
}

// ──── Patient ────
export interface PatientSearchResult {
  userId: number;
  fullName: string;
  phone: string;
  email: string;
  lastSosDate: string | null;
}

export interface PatientHistory {
  userId: number;
  fullName: string;
  sosEvents: SosEvent[];
}

// ──── Pagination ────
export interface Page<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  number: number;
  size: number;
}

// ──── Error ────
export interface ApiError {
  error: {
    code: string;
    message: string;
    timestamp: string;
  };
}
