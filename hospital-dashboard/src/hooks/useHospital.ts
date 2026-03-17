import { useHospitalStore } from '../store/hospitalStore.ts';

export function useHospitalId(): number | undefined {
  return useHospitalStore((s) => s.hospitalId) ?? undefined;
}
