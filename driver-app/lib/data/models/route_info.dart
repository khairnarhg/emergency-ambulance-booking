import 'package:latlong2/latlong.dart';

class RouteInfo {
  final List<LatLng> polylinePoints;
  final double durationSeconds;
  final double distanceMeters;

  const RouteInfo({
    required this.polylinePoints,
    required this.durationSeconds,
    required this.distanceMeters,
  });

  String get formattedDuration {
    final minutes = (durationSeconds / 60).ceil();
    if (minutes < 60) return '$minutes min';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toInt()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
}
