/**
 * Reverse geocoding via OpenStreetMap Nominatim (free, no API key).
 * Usage policy: max 1 request/second, provide User-Agent.
 */

const NOMINATIM_URL = 'https://nominatim.openstreetmap.org/reverse';
const USER_AGENT = 'RakshaPoorvak-Hospital-Dashboard/1.0';

export async function reverseGeocode(lat: number, lon: number): Promise<string> {
  const params = new URLSearchParams({
    lat: String(lat),
    lon: String(lon),
    format: 'json',
  });
  const res = await fetch(`${NOMINATIM_URL}?${params}`, {
    headers: { 'User-Agent': USER_AGENT },
  });
  if (!res.ok) throw new Error('Geocoding failed');
  const data = (await res.json()) as { display_name?: string; address?: Record<string, string> };
  if (data.display_name) return data.display_name;
  const addr = data.address;
  if (addr) {
    const parts = [addr.road, addr.suburb, addr.city, addr.state, addr.country].filter(Boolean);
    return parts.join(', ') || `${lat.toFixed(4)}, ${lon.toFixed(4)}`;
  }
  return `${lat.toFixed(4)}, ${lon.toFixed(4)}`;
}
