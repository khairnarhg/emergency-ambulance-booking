import apiClient from './client.ts';
import type { Doctor } from '../types/index.ts';

export const listDoctors = (hospitalId?: number) =>
  apiClient.get<Doctor[]>('/api/doctors', {
    params: hospitalId ? { hospitalId } : undefined,
  });

export const getDoctor = (id: number) =>
  apiClient.get<Doctor>(`/api/doctors/${id}`);
