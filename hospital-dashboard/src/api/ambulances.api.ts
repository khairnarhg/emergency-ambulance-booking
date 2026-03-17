import apiClient from './client.ts';
import type { Ambulance } from '../types/index.ts';

export const listAmbulances = (hospitalId?: number) =>
  apiClient.get<Ambulance[]>('/api/ambulances', {
    params: hospitalId ? { hospitalId } : undefined,
  });

export const getAmbulance = (id: number) =>
  apiClient.get<Ambulance>(`/api/ambulances/${id}`);

export const getAmbulanceLocation = (id: number) =>
  apiClient.get(`/api/ambulances/${id}/location`);
