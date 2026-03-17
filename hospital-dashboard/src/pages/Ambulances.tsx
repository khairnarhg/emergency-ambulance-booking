import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { RefreshCw } from 'lucide-react';
import { listAmbulances } from '../api/ambulances.api.ts';
import { useHospitalId } from '../hooks/useHospital.ts';
import { useLocationNames, getLocationDisplay } from '../hooks/useLocationNames.ts';
import DataTable from '../components/common/DataTable.tsx';
import Badge from '../components/common/Badge.tsx';
import Button from '../components/common/Button.tsx';
import { ambulanceStatusColor } from '../utils/parseStatus.ts';
import { formatDateTime } from '../utils/formatDate.ts';
import type { Column } from '../components/common/DataTable.tsx';
import type { Ambulance } from '../types/index.ts';

export default function AmbulancesPage() {
  const hospitalId = useHospitalId();
  const [refreshKey, setRefreshKey] = useState(0);

  const { data, isLoading, refetch } = useQuery({
    queryKey: ['ambulances', hospitalId],
    queryFn: () => listAmbulances(hospitalId),
    select: (res) => res.data,
    refetchInterval: 15000,
  });

  const ambulances = data ?? [];
  const coords = ambulances
    .filter((a): a is Ambulance & { currentLatitude: number; currentLongitude: number } =>
      a.currentLatitude != null && a.currentLongitude != null
    )
    .map((a) => ({ lat: a.currentLatitude, lng: a.currentLongitude }));
  const locationNames = useLocationNames(coords, refreshKey);

  const handleRefresh = () => {
    setRefreshKey((k) => k + 1);
    void refetch();
  };

  const columns: Column<Ambulance>[] = [
    { header: 'Registration', accessor: 'registrationNumber' },
    {
      header: 'Status',
      accessor: (r) => <Badge className={ambulanceStatusColor(r.status)}>{r.status}</Badge>,
    },
    {
      header: 'Location',
      accessor: (r) =>
        getLocationDisplay(r.currentLatitude, r.currentLongitude, locationNames),
    },
    { header: 'Hospital', accessor: 'hospitalName' },
    { header: 'Updated', accessor: (r) => formatDateTime(r.updatedAt) },
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Ambulances</h1>
        <Button
          variant="secondary"
          onClick={handleRefresh}
          disabled={isLoading}
          className="shrink-0"
        >
          <RefreshCw
            size={16}
            className={`mr-1.5 ${isLoading ? 'animate-spin' : ''}`}
          />
          Refresh
        </Button>
      </div>
      <DataTable
        columns={columns}
        data={ambulances}
        loading={isLoading}
        emptyMessage="No ambulances found"
      />
    </div>
  );
}
