import { useEffect } from 'react';
import { useAuthStore } from '../store/authStore.ts';
import { useHospitalStore } from '../store/hospitalStore.ts';
import { getMyHospital } from '../api/hospitals.api.ts';

export function useAuth() {
  const { user, accessToken, logout } = useAuthStore();
  const { hospital, setHospital } = useHospitalStore();

  useEffect(() => {
    if (accessToken && !hospital) {
      getMyHospital()
        .then((res) => setHospital(res.data))
        .catch(() => {
          // staff may not have hospital yet
        });
    }
  }, [accessToken, hospital, setHospital]);

  return { user, isAuthenticated: !!accessToken, logout, hospital };
}
