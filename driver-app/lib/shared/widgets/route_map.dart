import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:driver_app/core/theme/app_theme.dart';

class RouteMap extends StatelessWidget {
  final LatLng? driverLocation;
  final LatLng? patientLocation;
  final LatLng? hospitalLocation;
  final List<LatLng> routePolyline;
  final bool showHospital;
  final MapController? mapController;

  const RouteMap({
    super.key,
    this.driverLocation,
    this.patientLocation,
    this.hospitalLocation,
    this.routePolyline = const [],
    this.showHospital = false,
    this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    final center = driverLocation ?? patientLocation ?? const LatLng(19.076, 72.877);
    final markers = <Marker>[];

    if (driverLocation != null) {
      markers.add(
        Marker(
          point: driverLocation!,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.local_shipping, color: Colors.white, size: 22),
          ),
        ),
      );
    }

    if (patientLocation != null) {
      markers.add(
        Marker(
          point: patientLocation!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ),
      );
    }

    if (showHospital && hospitalLocation != null) {
      markers.add(
        Marker(
          point: hospitalLocation!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.local_hospital, color: Colors.white, size: 20),
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.rakshapoorvak.driver_app',
        ),
        if (routePolyline.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePolyline,
                strokeWidth: 5,
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
              Polyline(
                points: routePolyline,
                strokeWidth: 4,
                color: AppColors.accent,
              ),
            ],
          ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
