import apiClient from './client.ts';
import type { Hospital } from '../types/index.ts';

export const listHospitals = () =>
  apiClient.get<Hospital[]>('/api/hospitals');

export const getHospital = (id: number) =>
  apiClient.get<Hospital>(`/api/hospitals/${id}`);

export const getMyHospital = () =>
  apiClient.get<Hospital>('/api/hospitals/my-hospital');
