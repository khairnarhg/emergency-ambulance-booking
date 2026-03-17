import { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import {
  ArrowLeft,
  MapPin,
  Phone,
  User,
  Truck,
  Stethoscope,
  Heart,
  AlertCircle,
  CheckCircle2,
  Shield,
  Navigation,
  Clock,
} from 'lucide-react';
import toast from 'react-hot-toast';
import { MapContainer, TileLayer, Marker, Popup, Polyline, useMap } from 'react-leaflet';
import L from 'leaflet';
import { getSosEvent, getSosTracking, assignDoctor, unassignDoctor } from '../api/sos.api.ts';
import { findAmbulance } from '../api/dispatch.api.ts';
import { listTriageRecords, listMedications } from '../api/triage.api.ts';
import Card from '../components/common/Card.tsx';
import Badge from '../components/common/Badge.tsx';
import Button from '../components/common/Button.tsx';
import StatusTimeline from '../components/sos/StatusTimeline.tsx';
import { sosStatusColor, sosStatusLabel, criticalityColor, getApiErrorMessage } from '../utils/parseStatus.ts';
import { formatDateTime, formatTime } from '../utils/formatDate.ts';
import type { SosTracking as SosTrackingType } from '../types/index.ts';

// ── Map icons ──
function createIcon(color: string, label: string) {
  return L.divIcon({
    className: '',
    html: `<div style="background:${color};color:#fff;width:28px;height:28px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:bold;border:2px solid #fff;box-shadow:0 1px 4px rgba(0,0,0,.3)">${label}</div>`,
    iconSize: [28, 28],
    iconAnchor: [14, 14],
  });
}

const patientIcon = createIcon('#ef4444', 'P');
const ambulanceIcon = createIcon('#3b82f6', 'A');
const hospitalIcon = createIcon('#7c3aed', 'H');

interface OsrmRoute {
  geometry: { coordinates: [number, number][] };
  duration: number;
  distance: number;
}

interface OsrmResponse {
  routes: OsrmRoute[];
}

function FitBoundsOnce({ positions }: { positions: [number, number][] }) {
  const map = useMap();
  const fitted = useRef(false);

  if (!fitted.current && positions.length > 0) {
    map.fitBounds(L.latLngBounds(positions), { padding: [40, 40], maxZoom: 15 });
    fitted.current = true;
  }

  return null;
}

export default function SosDetailPage() {
  const { id } = useParams<{ id: string }>();
  const sosId = Number(id);
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const [dispatching, setDispatching] = useState(false);
  const [dispatchError, setDispatchError] = useState<string | null>(null);
  const [routeCoords, setRouteCoords] = useState<[number, number][]>([]);
  const [routeEtaMin, setRouteEtaMin] = useState<number | null>(null);

  const { data: sos, isLoading } = useQuery({
    queryKey: ['sos-event', sosId],
    queryFn: () => getSosEvent(sosId),
    select: (res) => res.data,
    refetchInterval: 15000,
  });

  const { data: tracking } = useQuery({
    queryKey: ['sos-tracking', sosId],
    queryFn: () => getSosTracking(sosId),
    select: (res) => res.data as SosTrackingType,
    refetchInterval: 8000,
    enabled: !!sos && sos.ambulanceId !== null,
  });

  const { data: triageRecords } = useQuery({
    queryKey: ['triage-records', sosId],
    queryFn: () => listTriageRecords(sosId),
    select: (res) => res.data,
    refetchInterval: 15000,
  });

  const { data: medications } = useQuery({
    queryKey: ['medications', sosId],
    queryFn: () => listMedications(sosId),
    select: (res) => res.data,
    refetchInterval: 15000,
  });

  // ── Route fetch ──
  const isAfterPickup = sos
    ? ['PICKED_UP', 'ENROUTE_TO_HOSPITAL'].includes(sos.status)
    : false;
  const destLat = isAfterPickup ? sos?.hospitalLatitude : sos?.latitude;
  const destLng = isAfterPickup ? sos?.hospitalLongitude : sos?.longitude;

  useEffect(() => {
    const ambLat = tracking?.ambulanceLatitude;
    const ambLng = tracking?.ambulanceLongitude;

    if (ambLat == null || ambLng == null || destLat == null || destLng == null) {
      setRouteCoords([]);
      return;
    }

    const controller = new AbortController();

    fetch(
      `https://router.project-osrm.org/route/v1/driving/${ambLng},${ambLat};${destLng},${destLat}?overview=full&geometries=geojson`,
      { signal: controller.signal },
    )
      .then((r) => r.json() as Promise<OsrmResponse>)
      .then((data) => {
        if (data.routes?.[0]) {
          const coords = data.routes[0].geometry.coordinates.map(
            ([lng, lat]) => [lat, lng] as [number, number],
          );
          setRouteCoords(coords);
          setRouteEtaMin(Math.round(data.routes[0].duration / 60));
        }
      })
      .catch(() => {});

    return () => controller.abort();
  }, [tracking?.ambulanceLatitude, tracking?.ambulanceLongitude, destLat, destLng]);

  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ['sos-event', sosId] });
    queryClient.invalidateQueries({ queryKey: ['sos-tracking', sosId] });
  };

  const handleFindAmbulance = async () => {
    setDispatching(true);
    setDispatchError(null);
    try {
      await findAmbulance(sosId);
      toast.success('Ambulance assigned successfully');
      invalidate();
    } catch (err) {
      const msg = getApiErrorMessage(err);
      setDispatchError(msg);
      toast.error(msg);
    } finally {
      setDispatching(false);
    }
  };

  const handleAssignDoctor = async () => {
    try {
      await assignDoctor(sosId);
      toast.success('Doctor assigned successfully');
      invalidate();
    } catch (err) {
      toast.error(getApiErrorMessage(err));
    }
  };

  const handleUnassignDoctor = async () => {
    try {
      await unassignDoctor(sosId);
      toast.success('Doctor unassigned');
      invalidate();
    } catch (err) {
      toast.error(getApiErrorMessage(err));
    }
  };

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

  if (!sos) {
    return <p className="text-center text-gray-400 py-20">SOS event not found</p>;
  }

  const canFindAmbulance = sos.status === 'CREATED' || sos.status === 'DISPATCHING';
  const canAssignDoctor = sos.ambulanceId !== null && sos.doctorId === null && sos.status !== 'COMPLETED' && sos.status !== 'CANCELLED';
  const canUnassignDoctor = sos.doctorId !== null && sos.status !== 'COMPLETED' && sos.status !== 'CANCELLED';

  const ambulanceAssigned = sos.ambulanceId !== null && !canFindAmbulance;
  const etaMinutes = tracking?.estimatedMinutesArrival ?? routeEtaMin;

  const hasMedicalContext = sos.bloodGroup || sos.allergies || sos.medicalConditions;
  const hasEmergencyContacts = sos.emergencyContacts && sos.emergencyContacts.length > 0;

  // Build map marker positions
  const mapPositions: [number, number][] = [[sos.latitude, sos.longitude]];
  if (tracking?.ambulanceLatitude != null && tracking?.ambulanceLongitude != null) {
    mapPositions.push([tracking.ambulanceLatitude, tracking.ambulanceLongitude]);
  }
  if (sos.hospitalLatitude != null && sos.hospitalLongitude != null) {
    mapPositions.push([sos.hospitalLatitude, sos.hospitalLongitude]);
  }

  const showMap =
    tracking?.ambulanceLatitude != null ||
    sos.hospitalLatitude != null ||
    sos.status !== 'CREATED';

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <button onClick={() => navigate(-1)} className="p-2 rounded-lg hover:bg-gray-100">
          <ArrowLeft size={20} />
        </button>
        <div className="flex items-center gap-3">
          <h1 className="text-2xl font-bold text-gray-900">SOS #{sos.id}</h1>
          <Badge className={sosStatusColor(sos.status)}>{sosStatusLabel(sos.status)}</Badge>
          <Badge className={criticalityColor(sos.criticality)}>{sos.criticality}</Badge>
        </div>
      </div>

      {/* Status Timeline */}
      <Card className="p-4">
        <StatusTimeline currentStatus={sos.status} />
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* ── Left Column ── */}
        <div className="space-y-6">
          {/* Patient Info */}
          <Card className="p-5 space-y-3">
            <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
              <User size={18} /> Patient Info
            </h2>
            <div className="space-y-2 text-sm">
              <InfoRow label="Name" value={sos.userName} />
              <InfoRow label="Phone">
                <span className="font-medium flex items-center gap-1"><Phone size={14} />{sos.userPhone}</span>
              </InfoRow>
              <InfoRow label="Location">
                <span className="font-medium flex items-center gap-1"><MapPin size={14} />{sos.latitude.toFixed(4)}, {sos.longitude.toFixed(4)}</span>
              </InfoRow>
              {sos.address && <InfoRow label="Address" value={sos.address} />}
              <InfoRow label="Symptoms" value={sos.symptoms || '—'} />
              <InfoRow label="Created" value={formatDateTime(sos.createdAt)} />
            </div>
          </Card>

          {/* Medical Context */}
          {(hasMedicalContext || hasEmergencyContacts) && (
            <Card className="p-5 space-y-4">
              <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
                <Heart size={18} className="text-red-500" /> Medical Context
              </h2>
              {hasMedicalContext && (
                <div className="space-y-2 text-sm">
                  {sos.bloodGroup && (
                    <div className="flex items-center gap-2">
                      <span className="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-red-50 text-red-600 font-bold text-sm">
                        {sos.bloodGroup}
                      </span>
                      <span className="text-gray-500">Blood Group</span>
                    </div>
                  )}
                  {sos.allergies && (
                    <div>
                      <p className="text-gray-500 mb-1">Allergies</p>
                      <p className="font-medium text-amber-700 bg-amber-50 rounded-md px-3 py-1.5">{sos.allergies}</p>
                    </div>
                  )}
                  {sos.medicalConditions && (
                    <div>
                      <p className="text-gray-500 mb-1">Medical Conditions</p>
                      <p className="font-medium text-gray-700 bg-gray-50 rounded-md px-3 py-1.5">{sos.medicalConditions}</p>
                    </div>
                  )}
                </div>
              )}
              {hasEmergencyContacts && (
                <div>
                  <p className="text-sm text-gray-500 mb-2 flex items-center gap-1">
                    <Shield size={14} /> Emergency Contacts
                  </p>
                  <div className="space-y-2">
                    {sos.emergencyContacts!.map((c) => (
                      <div key={c.id} className="flex items-center justify-between bg-gray-50 rounded-lg px-3 py-2">
                        <div>
                          <p className="text-sm font-medium text-gray-900">{c.name}</p>
                          <p className="text-xs text-gray-500">{c.relationship}</p>
                        </div>
                        <a
                          href={`tel:${c.phone}`}
                          className="inline-flex items-center gap-1.5 text-sm font-medium text-primary-600 hover:text-primary-700"
                        >
                          <Phone size={14} /> {c.phone}
                        </a>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </Card>
          )}
        </div>

        {/* ── Right Column: Tracking & Actions ── */}
        <Card className="p-5 space-y-4 self-start">
          <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
            <Truck size={18} /> Tracking & Actions
          </h2>

          {/* Dispatch area */}
          {canFindAmbulance && (
            <div className="space-y-3">
              <Button
                onClick={handleFindAmbulance}
                loading={dispatching}
                className="w-full py-3 text-base"
              >
                <Navigation size={18} />
                {dispatching ? 'Finding nearest ambulance…' : 'Find & Assign Nearest Ambulance'}
              </Button>
              {dispatchError && (
                <div className="flex items-center gap-2 text-sm text-red-600 bg-red-50 rounded-lg p-3">
                  <AlertCircle size={16} className="shrink-0" />
                  <span className="flex-1">{dispatchError}</span>
                  <button onClick={handleFindAmbulance} className="underline font-medium shrink-0">
                    Retry
                  </button>
                </div>
              )}
            </div>
          )}

          {/* Ambulance assigned success */}
          {ambulanceAssigned && (
            <div className="bg-green-50 border border-green-200 rounded-lg p-4 space-y-2">
              <div className="flex items-center gap-2 text-green-700 font-semibold">
                <CheckCircle2 size={18} /> Ambulance Assigned
              </div>
              {sos.driverName && (
                <InfoRow label="Driver" value={sos.driverName} />
              )}
              {(sos.ambulanceRegistrationNumber ?? tracking?.ambulanceRegistrationNumber) && (
                <InfoRow label="Ambulance" value={sos.ambulanceRegistrationNumber ?? tracking?.ambulanceRegistrationNumber ?? ''} />
              )}
              {tracking?.driverPhone && (
                <InfoRow label="Driver Phone">
                  <a href={`tel:${tracking.driverPhone}`} className="font-medium text-primary-600 flex items-center gap-1">
                    <Phone size={14} /> {tracking.driverPhone}
                  </a>
                </InfoRow>
              )}
              {etaMinutes != null && etaMinutes > 0 && (
                <div className="flex items-center gap-2 text-sm font-medium text-blue-700 bg-blue-50 rounded-md px-3 py-2 mt-1">
                  <Clock size={16} />
                  Arriving in ~{etaMinutes} min
                </div>
              )}
            </div>
          )}

          {/* Tracking coords */}
          {tracking && !ambulanceAssigned && (
            <div className="space-y-2 text-sm">
              {tracking.driverName && <InfoRow label="Driver" value={tracking.driverName} />}
              {tracking.eta && <InfoRow label="ETA" value={tracking.eta} />}
              {tracking.ambulanceLatitude != null && tracking.ambulanceLongitude != null && (
                <InfoRow label="Ambulance Location" value={`${tracking.ambulanceLatitude.toFixed(4)}, ${tracking.ambulanceLongitude.toFixed(4)}`} />
              )}
            </div>
          )}

          {/* Ambulance + ETA for assigned non-success state */}
          {tracking && ambulanceAssigned && tracking.ambulanceLatitude != null && tracking.ambulanceLongitude != null && (
            <div className="space-y-2 text-sm">
              <InfoRow label="Ambulance Location" value={`${tracking.ambulanceLatitude.toFixed(4)}, ${tracking.ambulanceLongitude.toFixed(4)}`} />
            </div>
          )}

          {/* Hospital info */}
          {sos.hospitalName && (
            <div className="space-y-2 text-sm border-t border-gray-100 pt-3">
              <InfoRow label="Hospital" value={sos.hospitalName} />
              {sos.hospitalAddress && <InfoRow label="Address" value={sos.hospitalAddress} />}
            </div>
          )}

          {/* Doctor */}
          {sos.doctorName && (
            <div className="flex items-center gap-2 text-sm border-t border-gray-100 pt-3">
              <Stethoscope size={16} className="text-indigo-600" />
              <span className="text-gray-500">Doctor:</span>
              <span className="font-medium">{sos.doctorName}</span>
            </div>
          )}

          {/* Action buttons */}
          <div className="flex flex-wrap gap-2 pt-2 border-t border-gray-100">
            {canAssignDoctor && (
              <Button variant="secondary" onClick={handleAssignDoctor}>Assign Doctor</Button>
            )}
            {canUnassignDoctor && (
              <Button variant="danger" onClick={handleUnassignDoctor}>Unassign Doctor</Button>
            )}
          </div>
        </Card>
      </div>

      {/* ── Live Map ── */}
      {showMap && (
        <Card className="p-5 space-y-3">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
              <MapPin size={18} /> Live Tracking Map
            </h2>
            {etaMinutes != null && etaMinutes > 0 && (
              <span className="text-sm font-medium text-blue-700 bg-blue-50 rounded-full px-3 py-1">
                Arriving in ~{etaMinutes} min
              </span>
            )}
          </div>

          <div className="rounded-lg overflow-hidden border border-gray-200" style={{ height: 400 }}>
            <MapContainer
              center={[sos.latitude, sos.longitude]}
              zoom={13}
              className="w-full h-full"
              scrollWheelZoom
            >
              <TileLayer
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              />
              <FitBoundsOnce positions={mapPositions} />

              {/* Patient marker */}
              <Marker position={[sos.latitude, sos.longitude]} icon={patientIcon}>
                <Popup>
                  <div className="text-sm">
                    <p className="font-semibold">Patient: {sos.userName}</p>
                    <p className="text-gray-500">{sos.address}</p>
                  </div>
                </Popup>
              </Marker>

              {/* Ambulance marker */}
              {tracking?.ambulanceLatitude != null && tracking?.ambulanceLongitude != null && (
                <Marker position={[tracking.ambulanceLatitude, tracking.ambulanceLongitude]} icon={ambulanceIcon}>
                  <Popup>
                    <div className="text-sm">
                      <p className="font-semibold">Ambulance</p>
                      {(sos.ambulanceRegistrationNumber ?? tracking.ambulanceRegistrationNumber) && (
                        <p>{sos.ambulanceRegistrationNumber ?? tracking.ambulanceRegistrationNumber}</p>
                      )}
                      {tracking.driverName && <p>Driver: {tracking.driverName}</p>}
                    </div>
                  </Popup>
                </Marker>
              )}

              {/* Hospital marker */}
              {sos.hospitalLatitude != null && sos.hospitalLongitude != null && (
                <Marker position={[sos.hospitalLatitude, sos.hospitalLongitude]} icon={hospitalIcon}>
                  <Popup>
                    <div className="text-sm">
                      <p className="font-semibold">{sos.hospitalName ?? 'Hospital'}</p>
                      {sos.hospitalAddress && <p className="text-gray-500">{sos.hospitalAddress}</p>}
                    </div>
                  </Popup>
                </Marker>
              )}

              {/* Route polyline */}
              {routeCoords.length > 1 && (
                <Polyline positions={routeCoords} pathOptions={{ color: '#3b82f6', weight: 4, opacity: 0.7 }} />
              )}
            </MapContainer>
          </div>

          {/* Map legend */}
          <div className="flex flex-wrap items-center gap-4 text-xs text-gray-500">
            <span className="flex items-center gap-1">
              <span className="w-3 h-3 rounded-full bg-red-500 inline-block" /> Patient
            </span>
            <span className="flex items-center gap-1">
              <span className="w-3 h-3 rounded-full bg-blue-500 inline-block" /> Ambulance
            </span>
            <span className="flex items-center gap-1">
              <span className="w-3 h-3 rounded-full bg-purple-600 inline-block" /> Hospital
            </span>
            {routeCoords.length > 1 && (
              <span className="flex items-center gap-1">
                <span className="w-6 h-0.5 bg-blue-500 inline-block rounded" /> Route
              </span>
            )}
          </div>
        </Card>
      )}

      {/* Triage Records */}
      <Card className="p-5">
        <h2 className="text-lg font-semibold text-gray-900 mb-3">Triage Records</h2>
        {!triageRecords || triageRecords.length === 0 ? (
          <p className="text-gray-400 text-sm">No triage records yet</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Time</th>
                  <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">HR</th>
                  <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">BP</th>
                  <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">SpO2</th>
                  <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Temp</th>
                  <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Notes</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {triageRecords.map((rec) => (
                  <tr key={rec.id}>
                    <td className="px-4 py-2 text-sm text-gray-700">{formatTime(rec.createdAt)}</td>
                    <td className="px-4 py-2 text-sm text-gray-700">{rec.heartRate ?? '—'}</td>
                    <td className="px-4 py-2 text-sm text-gray-700">
                      {rec.systolicBp && rec.diastolicBp ? `${rec.systolicBp}/${rec.diastolicBp}` : '—'}
                    </td>
                    <td className="px-4 py-2 text-sm text-gray-700">{rec.spo2 != null ? `${rec.spo2}%` : '—'}</td>
                    <td className="px-4 py-2 text-sm text-gray-700">{rec.temperature != null ? `${rec.temperature}°C` : '—'}</td>
                    <td className="px-4 py-2 text-sm text-gray-500">{rec.notes || '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* Medications */}
      <Card className="p-5">
        <h2 className="text-lg font-semibold text-gray-900 mb-3">Medications</h2>
        {!medications || medications.length === 0 ? (
          <p className="text-gray-400 text-sm">No medications recorded</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Time</th>
                  <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
                  <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Dosage</th>
                  <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Notes</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {medications.map((med) => (
                  <tr key={med.id}>
                    <td className="px-4 py-2 text-sm text-gray-700">{formatTime(med.createdAt)}</td>
                    <td className="px-4 py-2 text-sm font-medium text-gray-900">{med.name}</td>
                    <td className="px-4 py-2 text-sm text-gray-700">{med.dosage}</td>
                    <td className="px-4 py-2 text-sm text-gray-500">{med.notes || '—'}</td>
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

// ── Small helper components ──

function InfoRow({ label, value, children }: { label: string; value?: string; children?: React.ReactNode }) {
  return (
    <div className="flex justify-between text-sm">
      <span className="text-gray-500">{label}</span>
      {children ?? <span className="font-medium text-right max-w-[220px]">{value}</span>}
    </div>
  );
}
