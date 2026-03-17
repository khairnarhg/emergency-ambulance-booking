import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { listSosEvents } from '../api/sos.api.ts';
import { useHospitalId } from '../hooks/useHospital.ts';
import DataTable from '../components/common/DataTable.tsx';
import Badge from '../components/common/Badge.tsx';
import { sosStatusColor, sosStatusLabel, criticalityColor } from '../utils/parseStatus.ts';
import { formatDateTime } from '../utils/formatDate.ts';
import type { Column } from '../components/common/DataTable.tsx';
import type { SosEvent, SosStatus } from '../types/index.ts';

const STATUS_OPTIONS: (SosStatus | '')[] = [
  '',
  'CREATED',
  'DISPATCHING',
  'AMBULANCE_ASSIGNED',
  'DRIVER_ENROUTE_TO_PATIENT',
  'REACHED_PATIENT',
  'PICKED_UP',
  'ENROUTE_TO_HOSPITAL',
  'ARRIVED_AT_HOSPITAL',
  'COMPLETED',
  'CANCELLED',
];

export default function SosMonitorPage() {
  const hospitalId = useHospitalId();
  const navigate = useNavigate();
  const [page, setPage] = useState(0);
  const [statusFilter, setStatusFilter] = useState<string>('');
  const size = 20;

  const { data, isLoading } = useQuery({
    queryKey: ['sos-events', hospitalId, statusFilter, page, size],
    queryFn: () =>
      listSosEvents({
        hospitalId,
        status: statusFilter || undefined,
        page,
        size,
      }),
    select: (res) => res.data,
    refetchInterval: 30000,
  });

  const columns: Column<SosEvent>[] = [
    { header: 'ID', accessor: (r) => `#${r.id}` },
    { header: 'Patient', accessor: 'userName' },
    { header: 'Phone', accessor: 'userPhone' },
    {
      header: 'Status',
      accessor: (r) => (
        <Badge className={sosStatusColor(r.status)}>{sosStatusLabel(r.status)}</Badge>
      ),
    },
    {
      header: 'Criticality',
      accessor: (r) => <Badge className={criticalityColor(r.criticality)}>{r.criticality}</Badge>,
    },
    {
      header: 'Symptoms',
      accessor: (r) => (
        <span className="max-w-[180px] truncate block" title={r.symptoms}>
          {r.symptoms || '—'}
        </span>
      ),
    },
    { header: 'Created', accessor: (r) => formatDateTime(r.createdAt) },
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">SOS Monitor</h1>
        <select
          value={statusFilter}
          onChange={(e) => {
            setStatusFilter(e.target.value);
            setPage(0);
          }}
          className="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
        >
          {STATUS_OPTIONS.map((s) => (
            <option key={s} value={s}>
              {s ? sosStatusLabel(s as SosStatus) : 'All Statuses'}
            </option>
          ))}
        </select>
      </div>

      <DataTable
        columns={columns}
        data={data?.content ?? []}
        loading={isLoading}
        onRowClick={(row) => navigate(`/sos/${row.id}`)}
        emptyMessage="No SOS events found"
        pagination={{
          page,
          size,
          total: data?.totalElements ?? 0,
          onPageChange: setPage,
        }}
      />
    </div>
  );
}
