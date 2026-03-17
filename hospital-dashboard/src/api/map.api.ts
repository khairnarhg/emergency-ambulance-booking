import apiClient from './client.ts';
import type { MapOverview } from '../types/index.ts';

export const getMapOverview = (hospitalId?: number) =>
  apiClient.get<MapOverview>('/api/map/overview', {
    params: hospitalId ? { hospitalId } : undefined,
  });
