import apiClient from './client.ts';
import type { DashboardSummary, SosEvent } from '../types/index.ts';

export const getDashboardSummary = (hospitalId?: number) =>
  apiClient.get<DashboardSummary>('/api/dashboard/summary', {
    params: hospitalId ? { hospitalId } : undefined,
  });

export const getDashboardActiveSos = (hospitalId?: number) =>
  apiClient.get<SosEvent[]>('/api/dashboard/active-sos', {
    params: hospitalId ? { hospitalId } : undefined,
  });
