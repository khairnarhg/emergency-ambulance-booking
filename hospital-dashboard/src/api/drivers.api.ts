import apiClient from './client.ts';
import type { Driver } from '../types/index.ts';

export const listDrivers = (hospitalId?: number) =>
  apiClient.get<Driver[]>('/api/drivers', {
    params: hospitalId ? { hospitalId } : undefined,
  });
