import apiClient from './client.ts';
import type { TriageRecord, Medication } from '../types/index.ts';

export const listTriageRecords = (sosEventId: number) =>
  apiClient.get<TriageRecord[]>('/api/triage/records', {
    params: { sosEventId },
  });

export const listMedications = (sosEventId: number) =>
  apiClient.get<Medication[]>('/api/triage/medications', {
    params: { sosEventId },
  });
