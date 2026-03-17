import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/authStore.ts';
import { useHospitalStore } from '../store/hospitalStore.ts';
import { login } from '../api/auth.api.ts';
import { getMyHospital } from '../api/hospitals.api.ts';
import { getApiErrorMessage } from '../utils/parseStatus.ts';
import Button from '../components/common/Button.tsx';
import Input from '../components/common/Input.tsx';

const DASHBOARD_ROLES = ['HOSPITAL_STAFF', 'ADMIN', 'DOCTOR'];

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const setAuth = useAuthStore((s) => s.setAuth);
  const clearAuth = useAuthStore((s) => s.clear);
  const setHospital = useHospitalStore((s) => s.setHospital);
  const clearHospital = useHospitalStore((s) => s.clear);
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const { data } = await login({ email, password });
      const hasDashboardAccess = data.user.roles?.some((r: string) => DASHBOARD_ROLES.includes(r));
      if (!hasDashboardAccess) {
        clearAuth();
        setError('Access denied. This dashboard is for hospital staff, doctors, and administrators only.');
        return;
      }
      setAuth(data.user, data.accessToken, data.refreshToken);
      try {
        const { data: hospital } = await getMyHospital();
        setHospital(hospital);
      } catch {
        clearHospital();
      }
      navigate('/', { replace: true });
    } catch (err) {
      setError(getApiErrorMessage(err));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl shadow-lg border border-gray-100 w-full max-w-md p-8">
        <div className="text-center mb-8">
          <div className="w-12 h-12 bg-primary-600 rounded-xl flex items-center justify-center mx-auto mb-3">
            <span className="text-white font-bold text-xl">R</span>
          </div>
          <h1 className="text-2xl font-bold text-gray-900">RakshaPoorvak</h1>
          <p className="text-sm text-gray-500 mt-1">Hospital Dashboard</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            label="Email"
            type="email"
            placeholder="staff@hospital.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
          <Input
            label="Password"
            type="password"
            placeholder="Enter password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg px-4 py-3 text-sm text-red-700">
              {error}
            </div>
          )}
          <Button type="submit" loading={loading} className="w-full">
            Sign In
          </Button>
        </form>
      </div>
    </div>
  );
}
