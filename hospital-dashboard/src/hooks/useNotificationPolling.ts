import { useEffect } from 'react';
import { useAuthStore } from '../store/authStore.ts';
import { useNotificationStore } from '../store/notificationStore.ts';
import { getUnreadCount } from '../api/notifications.api.ts';

export function useNotificationPolling() {
  const accessToken = useAuthStore((s) => s.accessToken);
  const setUnreadCount = useNotificationStore((s) => s.setUnreadCount);

  useEffect(() => {
    if (!accessToken) return;

    const poll = () => {
      getUnreadCount()
        .then((res) => setUnreadCount(typeof res.data === 'number' ? res.data : 0))
        .catch(() => {});
    };

    poll();
    const interval = setInterval(poll, 30000);
    return () => clearInterval(interval);
  }, [accessToken, setUnreadCount]);
}
