import { useRef } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useHospitalId } from '../hooks/useHospital.ts';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
} from 'recharts';
import { MapContainer, TileLayer, CircleMarker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import { getAnalyticsDashboard, getHotspots } from '../api/analytics.api.ts';
import Card from '../components/common/Card.tsx';
import type { EmergencyHotspot } from '../types/index.ts';

const PIE_COLORS = ['#6b7280', '#eab308', '#f97316', '#ef4444'];
const INDIA_CENTER: [number, number] = [20.59, 78.96];

function hotspotColor(count: number): string {
  if (count <= 3) return '#22c55e';
  if (count <= 7) return '#eab308';
  if (count <= 15) return '#f97316';
  return '#ef4444';
}

function hotspotRadius(count: number): number {
  return Math.max(8, Math.min(count * 2.5, 32));
}

function FitHotspotBounds({ hotspots }: { hotspots: EmergencyHotspot[] }) {
  const map = useMap();
  const fitted = useRef(false);

  if (!fitted.current && hotspots.length > 0) {
    const positions = hotspots.map((h) => [h.latitude, h.longitude] as [number, number]);
    map.fitBounds(L.latLngBounds(positions), { padding: [40, 40], maxZoom: 12 });
    fitted.current = true;
  }

  return null;
}

export default function AnalyticsPage() {
  const hospitalId = useHospitalId();

  const { data, isLoading } = useQuery({
    queryKey: ['analytics-dashboard', hospitalId],
    queryFn: () => getAnalyticsDashboard(hospitalId),
    select: (res) => res.data,
  });

  const { data: hotspots } = useQuery({
    queryKey: ['analytics-hotspots'],
    queryFn: () => getHotspots(30),
    select: (res) => (res.data ?? []) as EmergencyHotspot[],
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-20">
        <svg className="animate-spin h-8 w-8 text-primary-600" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
        </svg>
      </div>
    );
  }

  if (!data) {
    return <p className="text-gray-400 text-center py-20">No analytics data available</p>;
  }

  const severityData = Object.entries(data.bySeverity || {}).map(([name, value]) => ({ name, value }));
  const utilizationData = Object.entries(data.ambulanceUtilization || {}).map(([name, value]) => ({ name, value }));

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Analytics</h1>

      {/* Response Time Cards */}
      {data.responseTimes && (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[
            { label: 'Average', value: `${data.responseTimes.averageMinutes?.toFixed(1) ?? 'N/A'} min` },
            { label: 'Median', value: `${data.responseTimes.medianMinutes?.toFixed(1) ?? 'N/A'} min` },
            { label: 'Min', value: `${data.responseTimes.minMinutes?.toFixed(1) ?? 'N/A'} min` },
            { label: 'Max', value: `${data.responseTimes.maxMinutes?.toFixed(1) ?? 'N/A'} min` },
          ].map((item) => (
            <Card key={item.label} className="p-4">
              <p className="text-sm text-gray-500">{item.label} Response Time</p>
              <p className="text-xl font-bold text-gray-900 mt-1">{item.value}</p>
            </Card>
          ))}
        </div>
      )}

      {/* Emergency Volume */}
      {data.volume && data.volume.length > 0 && (
        <Card className="p-5">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Emergency Volume</h2>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={data.volume}>
              <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
              <XAxis dataKey="date" tick={{ fontSize: 12 }} />
              <YAxis allowDecimals={false} tick={{ fontSize: 12 }} />
              <Tooltip />
              <Bar dataKey="count" fill="#3b82f6" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </Card>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* By Severity */}
        {severityData.length > 0 && (
          <Card className="p-5">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">By Severity</h2>
            <ResponsiveContainer width="100%" height={250}>
              <PieChart>
                <Pie data={severityData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={80} label>
                  {severityData.map((_, i) => (
                    <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                  ))}
                </Pie>
                <Legend />
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </Card>
        )}

        {/* Ambulance Utilization */}
        {utilizationData.length > 0 && (
          <Card className="p-5">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Ambulance Utilization</h2>
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={utilizationData} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis type="number" tick={{ fontSize: 12 }} />
                <YAxis dataKey="name" type="category" tick={{ fontSize: 12 }} width={100} />
                <Tooltip />
                <Bar dataKey="value" fill="#6366f1" radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </Card>
        )}
      </div>

      {/* Emergency Hotspots */}
      {hotspots && hotspots.length > 0 && (
        <Card className="p-5 space-y-4">
          <div>
            <h2 className="text-lg font-semibold text-gray-900">
              Emergency Hotspots – Suggested Ambulance Positioning
            </h2>
            <p className="text-sm text-gray-500 mt-1">
              Based on emergency data from the last 30 days
            </p>
          </div>

          {/* Hotspot Map */}
          <div className="rounded-lg overflow-hidden border border-gray-200" style={{ height: 350 }}>
            <MapContainer
              center={INDIA_CENTER}
              zoom={5}
              className="w-full h-full"
              scrollWheelZoom
            >
              <TileLayer
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              />
              <FitHotspotBounds hotspots={hotspots} />

              {hotspots.map((h, i) => (
                <CircleMarker
                  key={i}
                  center={[h.latitude, h.longitude]}
                  radius={hotspotRadius(h.count)}
                  pathOptions={{
                    color: hotspotColor(h.count),
                    fillColor: hotspotColor(h.count),
                    fillOpacity: 0.5,
                    weight: 2,
                  }}
                >
                  <Popup>
                    <div className="text-sm">
                      <p className="font-semibold">{h.suggestedLabel}</p>
                      <p className="text-gray-600">{h.count} emergencies</p>
                    </div>
                  </Popup>
                </CircleMarker>
              ))}
            </MapContainer>
          </div>

          {/* Legend */}
          <div className="flex flex-wrap items-center gap-4 text-xs text-gray-500">
            <span className="flex items-center gap-1">
              <span className="w-3 h-3 rounded-full bg-green-500 inline-block" /> Low (1–3)
            </span>
            <span className="flex items-center gap-1">
              <span className="w-3 h-3 rounded-full bg-yellow-500 inline-block" /> Medium (4–7)
            </span>
            <span className="flex items-center gap-1">
              <span className="w-3 h-3 rounded-full bg-orange-500 inline-block" /> High (8–15)
            </span>
            <span className="flex items-center gap-1">
              <span className="w-3 h-3 rounded-full bg-red-500 inline-block" /> Critical (16+)
            </span>
          </div>

          {/* Hotspot Table */}
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Location</th>
                  <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Coordinates</th>
                  <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Emergencies</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {hotspots
                  .slice()
                  .sort((a, b) => b.count - a.count)
                  .map((h, i) => (
                    <tr key={i}>
                      <td className="px-4 py-2 text-sm font-medium text-gray-900">{h.suggestedLabel}</td>
                      <td className="px-4 py-2 text-sm text-gray-500">
                        {h.latitude.toFixed(4)}, {h.longitude.toFixed(4)}
                      </td>
                      <td className="px-4 py-2">
                        <span
                          className="inline-flex items-center justify-center min-w-[28px] px-2 py-0.5 rounded-full text-xs font-bold text-white"
                          style={{ backgroundColor: hotspotColor(h.count) }}
                        >
                          {h.count}
                        </span>
                      </td>
                    </tr>
                  ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}
    </div>
  );
}
