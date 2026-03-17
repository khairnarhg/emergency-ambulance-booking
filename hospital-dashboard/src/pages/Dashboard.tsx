import { useEffect, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { AlertTriangle, Truck, Clock, Stethoscope } from 'lucide-react';
import { getDashboardSummary, getDashboardActiveSos } from '../api/dashboard.api.ts';
import { useHospitalId } from '../hooks/useHospital.ts';
import StatCard from '../components/dashboard/StatCard.tsx';
import Card from '../components/common/Card.tsx';
import Badge from '../components/common/Badge.tsx';
import { sosStatusColor, sosStatusLabel, criticalityColor } from '../utils/parseStatus.ts';
import { formatTimeAgo } from '../utils/formatDate.ts';
import type { SosEvent } from '../types/index.ts';

export default function DashboardPage() {
  const hospitalId = useHospitalId();
  const navigate = useNavigate();

  const { data: summary, dataUpdatedAt: summaryUpdatedAt } = useQuery({
    queryKey: ['dashboard-summary', hospitalId],
    queryFn: () => getDashboardSummary(hospitalId),
    select: (res) => {
      const d = res.data as Record<string, unknown>;
      return {
        activeSosCount: d?.activeSosCount ?? d?.activeSos ?? 0,
        availableAmbulances: d?.availableAmbulances ?? 0,
        totalAmbulances: d?.totalAmbulances ?? 0,
        availableDoctors: d?.availableDoctors ?? 0,
        totalDoctors: d?.totalDoctors ?? 0,
        avgResponseTimeMinutes: d?.avgResponseTimeMinutes ?? 0,
      };
    },
    refetchInterval: 30000,
  });

  const { data: activeSos } = useQuery({
    queryKey: ['dashboard-active-sos', hospitalId],
    queryFn: () => getDashboardActiveSos(hospitalId),
    select: (res) => (res.data as SosEvent[]) ?? [],
    refetchInterval: 30000,
  });

  const [secondsAgo, setSecondsAgo] = useState(0);

  useEffect(() => {
    if (!summaryUpdatedAt) return;
    const tick = () => setSecondsAgo(Math.floor((Date.now() - summaryUpdatedAt) / 1000));
    tick();
    const interval = setInterval(tick, 1000);
    return () => clearInterval(interval);
  }, [summaryUpdatedAt]);

  const activeSosCount = (summary?.activeSosCount ?? 0) as number;
  const available = (summary?.availableAmbulances ?? 0) as number;
  const total = (summary?.totalAmbulances ?? 0) as number;
  const ambulancePercent = total > 0 ? Math.round((available / total) * 100) : 0;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Command Dashboard</h1>
        {summaryUpdatedAt > 0 && (
          <span className="text-xs text-gray-400">
            Last updated: {secondsAgo}s ago
          </span>
        )}
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="animate-slide-up-fade" style={{ animationDelay: '0ms' }}>
          <StatCard
            title="Active SOS"
            value={activeSosCount}
            icon={AlertTriangle}
            color="bg-amber-500"
            className={activeSosCount > 0 ? 'animate-amber-pulse ring-2 ring-amber-300' : ''}
          />
        </div>
        <div className="animate-slide-up-fade" style={{ animationDelay: '80ms' }}>
          <StatCard
            title="Available Ambulances"
            value={`${available} / ${total}`}
            icon={Truck}
            color="bg-blue-500"
          >
            <div className="mt-3">
              <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden">
                <div
                  className="h-full bg-blue-500 rounded-full transition-all duration-700 ease-out"
                  style={{ width: `${ambulancePercent}%` }}
                />
              </div>
              <p className="text-[11px] text-gray-400 mt-1">{ambulancePercent}% available</p>
            </div>
          </StatCard>
        </div>
        <div className="animate-slide-up-fade" style={{ animationDelay: '160ms' }}>
          <StatCard
            title="Avg Response Time"
            value={summary?.avgResponseTimeMinutes ? `${(summary.avgResponseTimeMinutes as number).toFixed(1)} min` : 'N/A'}
            icon={Clock}
            color="bg-green-500"
          />
        </div>
        <div className="animate-slide-up-fade" style={{ animationDelay: '240ms' }}>
          <StatCard
            title="Available Doctors"
            value={`${summary?.availableDoctors ?? 0} / ${summary?.totalDoctors ?? 0}`}
            icon={Stethoscope}
            color="bg-indigo-500"
          />
        </div>
      </div>

      <Card className="p-6 animate-slide-up-fade" style={{ animationDelay: '320ms' } as React.CSSProperties}>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-gray-900">Active Emergencies</h2>
          <button
            onClick={() => navigate('/sos')}
            className="text-sm text-primary-600 hover:text-primary-700 font-medium"
          >
            View All
          </button>
        </div>
        {!activeSos || activeSos.length === 0 ? (
          <p className="text-gray-400 text-sm py-6 text-center">No active emergencies</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">ID</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Patient</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Criticality</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Time</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {activeSos.slice(0, 10).map((sos: SosEvent) => (
                  <tr
                    key={sos.id}
                    onClick={() => navigate(`/sos/${sos.id}`)}
                    className="hover:bg-gray-50 cursor-pointer"
                  >
                    <td className="px-4 py-3 text-sm font-medium text-gray-900">#{sos.id}</td>
                    <td className="px-4 py-3 text-sm text-gray-700">{sos.userName}</td>
                    <td className="px-4 py-3">
                      <Badge className={sosStatusColor(sos.status)}>{sosStatusLabel(sos.status)}</Badge>
                    </td>
                    <td className="px-4 py-3">
                      <Badge className={criticalityColor(sos.criticality)}>{sos.criticality}</Badge>
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-500">{formatTimeAgo(sos.createdAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  );
}
