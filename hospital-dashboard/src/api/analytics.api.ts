import apiClient from './client.ts';
import type { ResponseTimeMetrics, EmergencyVolume, AnalyticsDashboard, EmergencyHotspot } from '../types/index.ts';

export const getResponseTimes = (hospitalId?: number, days = 30) =>
  apiClient.get<ResponseTimeMetrics>('/api/analytics/response-times', {
    params: { hospitalId: hospitalId ?? undefined, days },
  });

export const getEmergencyVolume = (hospitalId?: number, days = 30) =>
  apiClient.get<EmergencyVolume[]>('/api/analytics/emergency-volume', {
    params: { hospitalId: hospitalId ?? undefined, days },
  });

export const getAnalyticsDashboard = (hospitalId?: number, days = 30) =>
  apiClient.get<AnalyticsDashboard>('/api/analytics/dashboard', {
    params: { hospitalId: hospitalId ?? undefined, days },
  });

export const getHotspots = (days = 30) =>
  apiClient.get<EmergencyHotspot[]>('/api/analytics/hotspots', { params: { days } });
