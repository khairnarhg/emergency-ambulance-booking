import { createBrowserRouter, RouterProvider } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Toaster } from 'react-hot-toast';
import { routes } from './routes/index.tsx';
import { useNotificationPolling } from './hooks/useNotificationPolling.ts';

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

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
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
