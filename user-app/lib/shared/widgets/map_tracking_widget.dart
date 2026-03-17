import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/osrm_client.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/tracking.dart';
import '../../data/models/sos_event.dart';

class MapTrackingWidget extends StatefulWidget {
  final SosEvent sosEvent;
  final TrackingInfo? tracking;
  final double height;

  const MapTrackingWidget({
    super.key,
    required this.sosEvent,
    this.tracking,
    this.height = 320,
  });

  @override
  State<MapTrackingWidget> createState() => _MapTrackingWidgetState();
}

class _MapTrackingWidgetState extends State<MapTrackingWidget> {
  final MapController _mapController = MapController();
  final OsrmClient _osrmClient = OsrmClient();
  LatLng? _prevAmbulanceLoc;

  List<LatLng>? _routePoints;
  double? _routeEtaSeconds;
  double? _routeDistanceMeters;
  Timer? _routeRefreshTimer;
  bool _fetchingRoute = false;

  LatLng get patientLatLng =>
      LatLng(widget.sosEvent.latitude, widget.sosEvent.longitude);

  LatLng? get ambulanceLatLng {
    final t = widget.tracking;
    if (t == null || !t.hasAmbulanceLocation) return null;
    return LatLng(t.ambulanceLatitude!, t.ambulanceLongitude!);
  }

  LatLng? get hospitalLatLng {
    final sos = widget.sosEvent;
    if (sos.hospitalLatitude != null && sos.hospitalLongitude != null) {
      return LatLng(sos.hospitalLatitude!, sos.hospitalLongitude!);
    }
    return null;
  }

  bool get _isEnrouteToHospital =>
      widget.sosEvent.status == AppConstants.statusEnrouteHospital ||
      widget.sosEvent.status == AppConstants.statusPickedUp;

  LatLng get _routeDestination {
    if (_isEnrouteToHospital && hospitalLatLng != null) {
      return hospitalLatLng!;
    }
    return patientLatLng;
  }

  @override
  void initState() {
    super.initState();
    _routeRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshRoute(),
    );
  }

  @override
  void dispose() {
    _routeRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapTrackingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newAmbulance = ambulanceLatLng;
    if (newAmbulance != null && newAmbulance != _prevAmbulanceLoc) {
      _prevAmbulanceLoc = newAmbulance;
      _fetchRoute(newAmbulance, _routeDestination);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds();
      });
    }
  }

  void _refreshRoute() {
    final amb = ambulanceLatLng;
    if (amb != null) {
      _fetchRoute(amb, _routeDestination);
    }
  }

  Future<void> _fetchRoute(LatLng from, LatLng to) async {
    if (_fetchingRoute) return;
    _fetchingRoute = true;
    final result = await _osrmClient.getRoute(from, to);
    _fetchingRoute = false;
    if (!mounted) return;
    setState(() {
      if (result != null) {
        _routePoints = result.points;
        _routeEtaSeconds = result.durationSeconds;
        _routeDistanceMeters = result.distanceMeters;
      } else {
        _routePoints = [from, to];
        _routeEtaSeconds = null;
        _routeDistanceMeters = null;
      }
    });
  }

  void _fitBounds() {
    final amb = ambulanceLatLng;
    final points = <LatLng>[patientLatLng];
    if (amb != null) points.add(amb);
    if (_isEnrouteToHospital && hospitalLatLng != null) {
      points.add(hospitalLatLng!);
    }

    if (points.length > 1) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
      );
    } else {
      _mapController.move(patientLatLng, AppConstants.defaultMapZoom);
    }
  }

  String _formatEta(double seconds) {
    final mins = (seconds / 60).round();
    if (mins < 1) return '< 1 min';
    if (mins == 1) return '1 min';
    return '$mins min';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final amb = ambulanceLatLng;
    final routePolyline = _routePoints ?? (amb != null ? [amb, patientLatLng] : null);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: patientLatLng,
                initialZoom: AppConstants.defaultMapZoom,
                onMapReady: () => WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _fitBounds(),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConstants.osmTileUrl,
                  userAgentPackageName: AppConstants.osmUserAgent,
                ),

                if (routePolyline != null && amb != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePolyline,
                        color: AppColors.accent,
                        strokeWidth: 5,
                      ),
                    ],
                  ),

                MarkerLayer(
                  markers: [
                    Marker(
                      point: patientLatLng,
                      width: 48,
                      height: 56,
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(77),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_pin_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          CustomPaint(
                            size: const Size(12, 10),
                            painter: _PinTailPainter(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    if (amb != null)
                      Marker(
                        point: amb,
                        width: 52,
                        height: 52,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22C55E).withAlpha(102),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_taxi_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    if (_isEnrouteToHospital && hospitalLatLng != null)
                      Marker(
                        point: hospitalLatLng!,
                        width: 48,
                        height: 56,
                        child: Column(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withAlpha(77),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.local_hospital_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            CustomPaint(
                              size: const Size(12, 10),
                              painter:
                                  _PinTailPainter(color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // ETA / distance floating chip
            if (amb != null && (_routeEtaSeconds != null || _routeDistanceMeters != null))
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_car_rounded,
                            size: 16, color: AppColors.accent),
                        const SizedBox(width: 6),
                        if (_routeEtaSeconds != null)
                          Text(
                            _formatEta(_routeEtaSeconds!),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        if (_routeEtaSeconds != null &&
                            _routeDistanceMeters != null)
                          Text(
                            '  ·  ',
                            style: TextStyle(color: AppColors.textTertiary),
                          ),
                        if (_routeDistanceMeters != null)
                          Text(
                            _formatDistance(_routeDistanceMeters!),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;

  _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
