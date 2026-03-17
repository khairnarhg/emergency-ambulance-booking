import apiClient from './client.ts';
import type { Notification } from '../types/index.ts';

export const listNotifications = () =>
  apiClient.get<Notification[]>('/api/notifications');

export const getUnreadCount = () =>
  apiClient.get<number>('/api/notifications/unread-count');

export const markRead = (id: number) =>
  apiClient.patch(`/api/notifications/${id}/read`);

export const markAllRead = () =>
  apiClient.post('/api/notifications/read-all');
