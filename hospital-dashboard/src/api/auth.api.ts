import apiClient from './client.ts';
import type { LoginRequest, LoginResponse, User } from '../types/index.ts';

export const login = (data: LoginRequest) =>
  apiClient.post<LoginResponse>('/api/auth/login', data);

export const logout = () =>
  apiClient.post('/api/auth/logout');

export const refreshToken = (token: string) =>
  apiClient.post<LoginResponse>('/api/auth/refresh', { refreshToken: token });

export const getMe = () =>
  apiClient.get<User>('/api/auth/me');
