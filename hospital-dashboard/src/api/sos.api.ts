import apiClient from './client.ts';
import type { SosEvent, SosTracking, Page } from '../types/index.ts';

export const listSosEvents = (params: {
  hospitalId?: number;
  status?: string;
  page?: number;
  size?: number;
}) => apiClient.get<Page<SosEvent>>('/api/sos-events', { params });

export const getActiveSos = (hospitalId?: number) =>
  apiClient.get<SosEvent[]>('/api/sos-events/active', {
    params: hospitalId ? { hospitalId } : undefined,
  });

export const getSosEvent = (id: number) =>
  apiClient.get<SosEvent>(`/api/sos-events/${id}`);

export const getSosTracking = (id: number) =>
  apiClient.get<SosTracking>(`/api/sos-events/${id}/tracking`);

export const assignDoctor = (sosId: number) =>
  apiClient.post(`/api/sos-events/${sosId}/assign-doctor`);

export const unassignDoctor = (sosId: number) =>
  apiClient.delete(`/api/sos-events/${sosId}/doctor`);
