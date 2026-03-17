import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:driver_app/core/constants/app_constants.dart';
import 'package:driver_app/data/models/route_info.dart';

class OsrmClient {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.osrmBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<RouteInfo?> getRoute(LatLng start, LatLng end) async {
    try {
      final response = await _dio.get(
        '/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson',
      );

      final data = response.data as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes[0] as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;
      final durationSeconds = (route['duration'] as num).toDouble();
      final distanceMeters = (route['distance'] as num).toDouble();

      final polylinePoints = coordinates.map((coord) {
        final c = coord as List<dynamic>;
        return LatLng(
          (c[1] as num).toDouble(),
          (c[0] as num).toDouble(),
        );
      }).toList();

      return RouteInfo(
        polylinePoints: polylinePoints,
        durationSeconds: durationSeconds,
        distanceMeters: distanceMeters,
      );
    } catch (_) {
      return null;
    }
  }
}
