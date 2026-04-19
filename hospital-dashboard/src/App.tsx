import { useEffect } from 'react';
import { createBrowserRouter, RouterProvider } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Toaster } from 'react-hot-toast';
import { routes } from './routes/index.tsx';
import { useNotificationPolling } from './hooks/useNotificationPolling.ts';
import { useAuthStore } from './store/authStore.ts';
import { useWebSocketStore } from './store/websocketStore.ts';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

const router = createBrowserRouter(routes);

function NotificationPoller() {
  useNotificationPolling();
  return null;
}

function WebSocketConnector() {
  const token = useAuthStore((s) => s.accessToken);
  const connect = useWebSocketStore((s) => s.connect);
  const disconnect = useWebSocketStore((s) => s.disconnect);

  useEffect(() => {
    if (token) connect();
    else disconnect();
    return () => disconnect();
  }, [token, connect, disconnect]);

  return null;
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <WebSocketConnector />
      <NotificationPoller />
      <RouterProvider router={router} />
      <Toaster
        position="top-right"
        toastOptions={{
          duration: 4000,
          style: { fontSize: '14px' },
        }}
      />
    </QueryClientProvider>
  );
}
