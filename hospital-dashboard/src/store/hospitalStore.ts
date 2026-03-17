import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { Hospital } from '../types/index.ts';

interface HospitalState {
  hospital: Hospital | null;
  hospitalId: number | null;
  setHospital: (hospital: Hospital) => void;
  clear: () => void;
}

export const useHospitalStore = create<HospitalState>()(
  persist(
    (set) => ({
      hospital: null,
      hospitalId: null,
      setHospital: (hospital) =>
        set({ hospital, hospitalId: hospital.id }),
      clear: () => set({ hospital: null, hospitalId: null }),
    }),
    { name: 'raksha-hospital' }
  )
);
