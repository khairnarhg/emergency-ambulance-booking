import type { SosStatus, Criticality, AmbulanceStatus, StaffStatus } from '../types/index.ts';

export function sosStatusColor(status: SosStatus): string {
  switch (status) {
    case 'CREATED':
    case 'DISPATCHING':
      return 'bg-amber-100 text-amber-800';
    case 'AMBULANCE_ASSIGNED':
    case 'DRIVER_ENROUTE_TO_PATIENT':
      return 'bg-blue-100 text-blue-800';
    case 'REACHED_PATIENT':
    case 'PICKED_UP':
    case 'ENROUTE_TO_HOSPITAL':
      return 'bg-indigo-100 text-indigo-800';
    case 'ARRIVED_AT_HOSPITAL':
    case 'COMPLETED':
      return 'bg-green-100 text-green-800';
    case 'CANCELLED':
      return 'bg-red-100 text-red-800';
    default:
      return 'bg-gray-100 text-gray-800';
  }
}

export function sosStatusLabel(status: SosStatus): string {
  return status.replace(/_/g, ' ');
}

export function criticalityColor(crit: Criticality): string {
  switch (crit) {
    case 'LOW':
      return 'bg-gray-100 text-gray-700';
    case 'MEDIUM':
      return 'bg-yellow-100 text-yellow-800';
    case 'HIGH':
      return 'bg-orange-100 text-orange-800';
    case 'CRITICAL':
      return 'bg-red-100 text-red-800';
    default:
      return 'bg-gray-100 text-gray-700';
  }
}

export function ambulanceStatusColor(status: AmbulanceStatus): string {
  switch (status) {
    case 'AVAILABLE':
      return 'bg-green-100 text-green-800';
    case 'DISPATCHED':
      return 'bg-blue-100 text-blue-800';
    case 'MAINTENANCE':
      return 'bg-yellow-100 text-yellow-800';
    case 'OFFLINE':
      return 'bg-gray-100 text-gray-600';
    default:
      return 'bg-gray-100 text-gray-600';
  }
}

export function staffStatusColor(status: StaffStatus): string {
  switch (status) {
    case 'AVAILABLE':
      return 'bg-green-100 text-green-800';
    case 'BUSY':
      return 'bg-blue-100 text-blue-800';
    case 'OFFLINE':
      return 'bg-gray-100 text-gray-600';
    default:
      return 'bg-gray-100 text-gray-600';
  }
}

const SOS_STATUS_ORDER: SosStatus[] = [
  'CREATED',
  'DISPATCHING',
  'AMBULANCE_ASSIGNED',
  'DRIVER_ENROUTE_TO_PATIENT',
  'REACHED_PATIENT',
  'PICKED_UP',
  'ENROUTE_TO_HOSPITAL',
  'ARRIVED_AT_HOSPITAL',
  'COMPLETED',
];

export function getSosTimeline(currentStatus: SosStatus) {
  if (currentStatus === 'CANCELLED') {
    return SOS_STATUS_ORDER.map((s) => ({ status: s, reached: false, active: false }));
  }
  const idx = SOS_STATUS_ORDER.indexOf(currentStatus);
  return SOS_STATUS_ORDER.map((s, i) => ({
    status: s,
    reached: i <= idx,
    active: i === idx,
  }));
}

export function getApiErrorMessage(err: unknown): string {
  if (typeof err === 'object' && err !== null) {
    const e = err as Record<string, unknown>;
    if (e.response && typeof e.response === 'object') {
      const resp = e.response as Record<string, unknown>;
      if (resp.data && typeof resp.data === 'object') {
        const data = resp.data as Record<string, unknown>;
        if (data.error && typeof data.error === 'object') {
          const apiErr = data.error as Record<string, unknown>;
          if (typeof apiErr.message === 'string') return apiErr.message;
        }
        if (typeof data.message === 'string') return data.message;
      }
    }
    if (e.message && typeof e.message === 'string') return e.message;
  }
  return 'An unexpected error occurred. Please try again.';
}
