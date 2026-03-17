import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { listDoctors } from '../api/doctors.api.ts';
import { listDrivers } from '../api/drivers.api.ts';
import { useHospitalId } from '../hooks/useHospital.ts';
import DataTable from '../components/common/DataTable.tsx';
import Badge from '../components/common/Badge.tsx';
import { staffStatusColor } from '../utils/parseStatus.ts';
import type { Column } from '../components/common/DataTable.tsx';
import type { Doctor, Driver } from '../types/index.ts';

export default function StaffPage() {
  const hospitalId = useHospitalId();
  const [tab, setTab] = useState<'doctors' | 'drivers'>('doctors');

  const { data: doctors, isLoading: loadingDoctors } = useQuery({
    queryKey: ['doctors', hospitalId],
    queryFn: () => listDoctors(hospitalId),
    select: (res) => res.data,
  });

  const { data: drivers, isLoading: loadingDrivers } = useQuery({
    queryKey: ['drivers', hospitalId],
    queryFn: () => listDrivers(hospitalId),
    select: (res) => res.data,
  });

  const doctorCols: Column<Doctor>[] = [
    { header: 'Name', accessor: 'fullName' },
    { header: 'Email', accessor: 'email' },
    { header: 'Phone', accessor: 'phone' },
    { header: 'Specialization', accessor: 'specialization' },
    {
      header: 'Status',
      accessor: (r) => <Badge className={staffStatusColor(r.status)}>{r.status}</Badge>,
    },
  ];

  const driverCols: Column<Driver>[] = [
    { header: 'Name', accessor: 'fullName' },
    { header: 'Email', accessor: 'email' },
    { header: 'Phone', accessor: 'phone' },
    { header: 'License', accessor: 'licenseNumber' },
    {
      header: 'Status',
      accessor: (r) => <Badge className={staffStatusColor(r.status)}>{r.status}</Badge>,
    },
  ];

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold text-gray-900">Staff Management</h1>
      <div className="flex gap-1 bg-gray-100 rounded-lg p-1 w-fit">
        <button
          onClick={() => setTab('doctors')}
          className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
            tab === 'doctors' ? 'bg-white shadow text-gray-900' : 'text-gray-500 hover:text-gray-700'
          }`}
        >
          Doctors ({doctors?.length ?? 0})
        </button>
        <button
          onClick={() => setTab('drivers')}
          className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
            tab === 'drivers' ? 'bg-white shadow text-gray-900' : 'text-gray-500 hover:text-gray-700'
          }`}
        >
          Drivers ({drivers?.length ?? 0})
        </button>
      </div>

      {tab === 'doctors' ? (
        <DataTable columns={doctorCols} data={doctors ?? []} loading={loadingDoctors} emptyMessage="No doctors found" />
      ) : (
        <DataTable columns={driverCols} data={drivers ?? []} loading={loadingDrivers} emptyMessage="No drivers found" />
      )}
    </div>
  );
}
