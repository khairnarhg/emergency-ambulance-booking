import { useQuery } from '@tanstack/react-query';
import { useHospitalId } from '../hooks/useHospital.ts';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import { useNavigate } from 'react-router-dom';
import { RefreshCw } from 'lucide-react';
import { getMapOverview } from '../api/map.api.ts';
import Badge from '../components/common/Badge.tsx';
import Button from '../components/common/Button.tsx';
import { sosStatusColor, sosStatusLabel, criticalityColor, ambulanceStatusColor } from '../utils/parseStatus.ts';
import type { AmbulanceStatus, SosStatus, Criticality, Hospital } from '../types/index.ts';

const INDIA_CENTER: [number, number] = [20.59, 78.96];

function createIcon(color: string, label: string) {
  return L.divIcon({
    className: '',
    html: `<div style="background:${color};color:#fff;width:28px;height:28px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:bold;border:2px solid #fff;box-shadow:0 1px 4px rgba(0,0,0,.3)">${label}</div>`,
    iconSize: [28, 28],
    iconAnchor: [14, 14],
  });
}

const ambulanceIcon = (status: string) =>
  createIcon(status === 'AVAILABLE' ? '#22c55e' : '#3b82f6', 'A');
const sosIcon = (crit: string) =>
  createIcon(crit === 'CRITICAL' ? '#ef4444' : crit === 'HIGH' ? '#f97316' : crit === 'MEDIUM' ? '#eab308' : '#6b7280', 'S');
const hospitalIcon = createIcon('#6366f1', 'H');

function FitBounds({ positions }: { positions: [number, number][] }) {
  const map = useMap();
  if (positions.length > 0) {
    const bounds = L.latLngBounds(positions.map(([lat, lng]) => [lat, lng]));
    map.fitBounds(bounds, { padding: [40, 40], maxZoom: 14 });
  }
  return null;
}

export default function LiveMapPage() {
  const navigate = useNavigate();
  const hospitalId = useHospitalId();

  const { data, refetch, isRefetching } = useQuery({
    queryKey: ['map-overview', hospitalId],
    queryFn: () => getMapOverview(hospitalId),
    select: (res) => res.data,
    refetchInterval: 30000,
  });

  const ambulances = data?.ambulances ?? [];
  const sosEvents = data?.sosEvents ?? [];
  const hospitals = data?.hospitals ?? [];

  const positions: [number, number][] = [];
  ambulances.forEach((a: { id: number; latitude?: number | null; longitude?: number | null }) => {
    if (a.latitude != null && a.longitude != null) positions.push([a.latitude, a.longitude]);
  });
  sosEvents.forEach((s: { latitude: number; longitude: number }) => positions.push([s.latitude, s.longitude]));
  hospitals.forEach((h: Hospital) => positions.push([h.latitude, h.longitude]));

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Live Map</h1>
        <Button variant="secondary" onClick={() => refetch()} loading={isRefetching}>
          <RefreshCw size={16} /> Refresh
        </Button>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-100 overflow-hidden" style={{ height: 'calc(100vh - 200px)', minHeight: 400 }}>
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
          {positions.length > 0 && <FitBounds positions={positions} />}

          {ambulances.map((a: { id: number; latitude?: number | null; longitude?: number | null; status?: string; registrationNumber?: string }) =>
            a.latitude != null && a.longitude != null ? (
              <Marker key={`amb-${a.id}`} position={[a.latitude, a.longitude]} icon={ambulanceIcon(a.status ?? 'AVAILABLE')}>
                <Popup>
                  <div className="text-sm space-y-1">
                    <p className="font-semibold">{a.registrationNumber}</p>
                    <Badge className={ambulanceStatusColor((a.status ?? 'AVAILABLE') as AmbulanceStatus)}>{a.status ?? 'AVAILABLE'}</Badge>
                  </div>
                </Popup>
              </Marker>
            ) : null
          )}

          {sosEvents.map((s: { id: number; latitude: number; longitude: number; criticality?: string; status?: string; userName?: string }) => (
            <Marker key={`sos-${s.id}`} position={[s.latitude, s.longitude]} icon={sosIcon(s.criticality ?? 'MEDIUM')}>
              <Popup>
                <div className="text-sm space-y-1">
                  <p className="font-semibold">SOS #{s.id}</p>
                  <p>{s.userName}</p>
                  <Badge className={sosStatusColor((s.status ?? 'CREATED') as SosStatus)}>{sosStatusLabel((s.status ?? 'CREATED') as SosStatus)}</Badge>
                  <Badge className={criticalityColor((s.criticality ?? 'MEDIUM') as Criticality)}>{s.criticality ?? 'MEDIUM'}</Badge>
                  <button
                    onClick={() => navigate(`/sos/${s.id}`)}
                    className="text-primary-600 text-xs underline block mt-1"
                  >
                    View Details
                  </button>
                </div>
              </Popup>
            </Marker>
          ))}

          {hospitals.map((h: Hospital) => (
            <Marker key={`hosp-${h.id}`} position={[h.latitude, h.longitude]} icon={hospitalIcon}>
              <Popup>
                <div className="text-sm space-y-1">
                  <p className="font-semibold">{h.name}</p>
                  <p className="text-gray-500">{h.address}</p>
                </div>
              </Popup>
            </Marker>
          ))}
        </MapContainer>
      </div>

      <div className="flex items-center gap-4 text-xs text-gray-500">
        <span className="flex items-center gap-1">
          <span className="w-3 h-3 rounded-full bg-green-500 inline-block" /> Ambulance (Available)
        </span>
        <span className="flex items-center gap-1">
          <span className="w-3 h-3 rounded-full bg-blue-500 inline-block" /> Ambulance (Dispatched)
        </span>
        <span className="flex items-center gap-1">
          <span className="w-3 h-3 rounded-full bg-red-500 inline-block" /> SOS (Critical)
        </span>
        <span className="flex items-center gap-1">
          <span className="w-3 h-3 rounded-full bg-indigo-500 inline-block" /> Hospital
        </span>
      </div>
    </div>
  );
}
