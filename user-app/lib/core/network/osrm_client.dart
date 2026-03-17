import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class OsrmClient {
  final Dio _dio = Dio();

  Future<OsrmRouteResult?> getRoute(LatLng from, LatLng to) async {
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
          '?overview=full&geometries=geojson';
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final routes = response.data['routes'] as List;
        if (routes.isNotEmpty) {
          final route = routes[0];
          final coords = (route['geometry']['coordinates'] as List)
              .map((c) => LatLng((c as List)[1].toDouble(), c[0].toDouble()))
              .toList();
          return OsrmRouteResult(
            points: coords,
            durationSeconds: (route['duration'] as num).toDouble(),
            distanceMeters: (route['distance'] as num).toDouble(),
          );
        }
      }
    } catch (_) {}
    return null;
  }
}

class OsrmRouteResult {
  final List<LatLng> points;
  final double durationSeconds;
  final double distanceMeters;

  OsrmRouteResult({
    required this.points,
    required this.durationSeconds,
    required this.distanceMeters,
  });
}
