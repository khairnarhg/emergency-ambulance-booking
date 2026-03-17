import apiClient from './client.ts';
import type { PatientSearchResult, PatientHistory } from '../types/index.ts';

export const listPatients = () =>
  apiClient.get<PatientSearchResult[]>('/api/patients');

export const searchPatients = (q: string) =>
  apiClient.get<PatientSearchResult[]>('/api/patients/search', { params: { q } });

export const getPatientHistory = (userId: number) =>
  apiClient.get<PatientHistory>(`/api/patients/${userId}/history`);
