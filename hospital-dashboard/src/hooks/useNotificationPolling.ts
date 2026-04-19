import { useEffect, useCallback } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { useAuthStore } from '../store/authStore.ts';
import { useNotificationStore } from '../store/notificationStore.ts';
import { useHospitalStore } from '../store/hospitalStore.ts';
import { getUnreadCount } from '../api/notifications.api.ts';
import { useStompSubscription } from './useStompSubscription.ts';
import type { Notification } from '../types/index.ts';

export function useNotificationPolling() {
  const accessToken = useAuthStore((s) => s.accessToken);
  const setUnreadCount = useNotificationStore((s) => s.setUnreadCount);
  const hospitalId = useHospitalStore((s) => s.hospitalId);
  const queryClient = useQueryClient();

  useEffect(() => {
    if (!accessToken) return;

    const poll = () => {
      getUnreadCount()
        .then((res) => setUnreadCount(typeof res.data === 'number' ? res.data : 0))
        .catch(() => {});
    };

    poll();
    const interval = setInterval(poll, 60000);
    return () => clearInterval(interval);
  }, [accessToken, setUnreadCount]);

  const onNotification = useCallback(
    (notification: Notification) => {
      setUnreadCount(useNotificationStore.getState().unreadCount + 1);
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
      toast(notification.title, { icon: '🔔' });
    },
    [setUnreadCount, queryClient],
  );

  useStompSubscription<Notification>(
    hospitalId ? `/topic/notifications/hospital/${hospitalId}` : null,
    onNotification,
  );
}
