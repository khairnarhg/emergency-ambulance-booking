import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Bell, CheckCheck } from 'lucide-react';
import { listNotifications, markRead, markAllRead } from '../api/notifications.api.ts';
import { useNotificationStore } from '../store/notificationStore.ts';
import Card from '../components/common/Card.tsx';
import Button from '../components/common/Button.tsx';
import { formatTimeAgo } from '../utils/formatDate.ts';
import type { Notification } from '../types/index.ts';

export default function NotificationsPage() {
  const queryClient = useQueryClient();
  const setUnreadCount = useNotificationStore((s) => s.setUnreadCount);

  const { data: notifications, isLoading } = useQuery({
    queryKey: ['notifications'],
    queryFn: () => listNotifications(),
    select: (res) => res.data,
  });

  const handleMarkRead = async (id: number) => {
    await markRead(id);
    queryClient.invalidateQueries({ queryKey: ['notifications'] });
    queryClient.invalidateQueries({ queryKey: ['notifications-unread'] });
    setUnreadCount(Math.max(0, useNotificationStore.getState().unreadCount - 1));
  };

  const handleMarkAllRead = async () => {
    await markAllRead();
    queryClient.invalidateQueries({ queryKey: ['notifications'] });
    setUnreadCount(0);
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-20">
        <svg className="animate-spin h-8 w-8 text-primary-600" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
        </svg>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Notifications</h1>
        <Button variant="secondary" onClick={handleMarkAllRead}>
          <CheckCheck size={16} /> Mark All Read
        </Button>
      </div>

      {!notifications || notifications.length === 0 ? (
        <Card className="p-12 text-center">
          <Bell size={40} className="text-gray-300 mx-auto mb-3" />
          <p className="text-gray-400">No notifications</p>
        </Card>
      ) : (
        <div className="space-y-2">
          {notifications.map((n: Notification) => (
            <Card
              key={n.id}
              className={`p-4 flex items-start justify-between gap-4 ${
                !n.isRead ? 'border-l-4 border-l-primary-500' : ''
              }`}
            >
              <div className="flex-1 min-w-0">
                <p className={`text-sm ${n.isRead ? 'text-gray-600' : 'text-gray-900 font-medium'}`}>
                  {n.title}
                </p>
                <p className="text-sm text-gray-500 mt-0.5">{n.body}</p>
                <p className="text-xs text-gray-400 mt-1">{formatTimeAgo(n.createdAt)}</p>
              </div>
              {!n.isRead && (
                <button
                  onClick={() => handleMarkRead(n.id)}
                  className="text-xs text-primary-600 hover:text-primary-700 shrink-0"
                >
                  Mark read
                </button>
              )}
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
