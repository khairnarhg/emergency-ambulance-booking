import apiClient from './client.ts';

export const findAmbulance = (sosId: number) =>
  apiClient.post(`/api/dispatch/${sosId}/find-ambulance`);

export const declineSos = (sosId: number) =>
  apiClient.post(`/api/dispatch/${sosId}/decline`);

export const escalateTimeout = (sosId: number) =>
  apiClient.post(`/api/dispatch/${sosId}/escalate-timeout`);

export const escalateDriverTimeout = (sosId: number) =>
  apiClient.post(`/api/dispatch/${sosId}/escalate-driver-timeout`);
