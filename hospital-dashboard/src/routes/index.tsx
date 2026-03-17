import { Navigate } from 'react-router-dom';
import { useAuthStore } from '../store/authStore.ts';
import Layout from '../components/layout/Layout.tsx';
import LoginPage from '../pages/Login.tsx';
import DashboardPage from '../pages/Dashboard.tsx';
import SosMonitorPage from '../pages/SosMonitor.tsx';
import SosDetailPage from '../pages/SosDetail.tsx';
import LiveMapPage from '../pages/LiveMap.tsx';
import AmbulancesPage from '../pages/Ambulances.tsx';
import StaffPage from '../pages/Staff.tsx';
import AnalyticsPage from '../pages/Analytics.tsx';
import NotificationsPage from '../pages/Notifications.tsx';
import PatientsPage from '../pages/Patients.tsx';

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const token = useAuthStore((s) => s.accessToken);
  if (!token) return <Navigate to="/login" replace />;
  return <>{children}</>;
}

function PublicRoute({ children }: { children: React.ReactNode }) {
  const token = useAuthStore((s) => s.accessToken);
  if (token) return <Navigate to="/" replace />;
  return <>{children}</>;
}

export const routes = [
  {
    path: '/login',
    element: (
      <PublicRoute>
        <LoginPage />
      </PublicRoute>
    ),
  },
  {
    path: '/',
    element: (
      <ProtectedRoute>
        <Layout />
      </ProtectedRoute>
    ),
    children: [
      { index: true, element: <DashboardPage /> },
      { path: 'sos', element: <SosMonitorPage /> },
      { path: 'sos/:id', element: <SosDetailPage /> },
      { path: 'map', element: <LiveMapPage /> },
      { path: 'ambulances', element: <AmbulancesPage /> },
      { path: 'staff', element: <StaffPage /> },
      { path: 'analytics', element: <AnalyticsPage /> },
      { path: 'notifications', element: <NotificationsPage /> },
      { path: 'patients', element: <PatientsPage /> },
    ],
  },
  {
    path: '*',
    element: <Navigate to="/" replace />,
  },
];
