import apiClient from './client.ts';

export const findAmbulance = (sosId: number) =>
  apiClient.post(`/api/dispatch/${sosId}/find-ambulance`);
