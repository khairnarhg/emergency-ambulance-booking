import { useState, useEffect, useRef } from 'react';
import { reverseGeocode } from '../utils/geocode.ts';

type Coord = { lat: number; lng: number };

const key = (c: Coord) => `${c.lat.toFixed(6)},${c.lng.toFixed(6)}`;

export function getLocationDisplay(
  lat: number | null,
  lng: number | null,
  names: Record<string, string>
): string {
  if (lat == null || lng == null) return '—';
  const k = `${lat.toFixed(6)},${lng.toFixed(6)}`;
  return names[k] ?? `${lat.toFixed(4)}, ${lng.toFixed(4)}`;
}

/**
 * Fetches location names for coordinates sequentially (Nominatim: 1 req/sec).
 * refreshKey: increment to re-fetch all (e.g. when user clicks refresh).
 */
export function useLocationNames(
  coords: Coord[],
  refreshKey: number
): Record<string, string> {
  const [names, setNames] = useState<Record<string, string>>({});
  const cacheRef = useRef<Record<string, string>>({});

  const coordKey = coords.map((c) => key(c)).sort().join('|');
  useEffect(() => {
    const unique = Array.from(
      new Map(coords.map((c) => [key(c), c])).values()
    );
    if (unique.length === 0) {
      setNames({});
      return;
    }

    // Clear cache on manual refresh
    if (refreshKey > 0) {
      cacheRef.current = {};
    }

    let cancelled = false;

    const fetchAll = async () => {
      const results: Record<string, string> = { ...cacheRef.current };
      for (const c of unique) {
        if (cancelled) return;
        const k = key(c);
        try {
          const addr = await reverseGeocode(c.lat, c.lng);
          if (cancelled) return;
          results[k] = addr;
          cacheRef.current[k] = addr;
          setNames({ ...cacheRef.current });
        } catch {
          results[k] = `${c.lat.toFixed(4)}, ${c.lng.toFixed(4)}`;
          cacheRef.current[k] = results[k];
          setNames({ ...cacheRef.current });
        }
        await new Promise((r) => setTimeout(r, 1100));
      }
    };

    void fetchAll();
    return () => {
      cancelled = true;
    };
  }, [coordKey, refreshKey]);

  return names;
}
