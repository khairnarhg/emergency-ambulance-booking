import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:driver_app/core/theme/app_theme.dart';
import 'package:driver_app/core/constants/app_constants.dart';
import 'package:driver_app/core/network/osrm_client.dart';
import 'package:driver_app/core/utils/location_service.dart';
import 'package:driver_app/data/models/sos_event.dart';
import 'package:driver_app/data/models/route_info.dart';
import 'package:driver_app/data/api/ambulance_api.dart';
import 'package:driver_app/data/api/location_api.dart';
import 'package:driver_app/providers/auth_provider.dart';
import 'package:driver_app/providers/dispatch_provider.dart';
import 'package:driver_app/providers/driver_provider.dart';
import 'package:driver_app/shared/widgets/status_badge.dart';

class ActiveCaseScreen extends ConsumerStatefulWidget {
  final int sosId;

  const ActiveCaseScreen({super.key, required this.sosId});

  @override
  ConsumerState<ActiveCaseScreen> createState() => _ActiveCaseScreenState();
}

class _ActiveCaseScreenState extends ConsumerState<ActiveCaseScreen> {
  final MapController _mapController = MapController();
  final OsrmClient _osrmClient = OsrmClient();
  final LocationService _locationService = LocationService();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  SosEvent? _sos;
  RouteInfo? _routeInfo;
  Position? _driverPosition;
  Timer? _gpsTimer;
  Timer? _routeTimer;
  Timer? _refreshTimer;
  bool _isLoading = true;
  bool _isStatusUpdating = false;
  bool _gpsError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _locationService.requestPermission();
    _driverPosition = await _locationService.getCurrentPosition();
    if (_driverPosition == null) {
      setState(() => _gpsError = true);
    }

    await _loadSosData();
    setState(() => _isLoading = false);

    _subscribeToSosStatus();
    _startGpsBroadcast();
    _startRouteRecalc();
    _startPeriodicRefresh();
  }

  Future<void> _loadSosData() async {
    try {
      await ref.read(dispatchProvider.notifier).refreshActiveCase(widget.sosId);
      _sos = ref.read(dispatchProvider).activeCase;
      await _calculateRoute();
    } catch (_) {}
  }

  Future<void> _calculateRoute() async {
    if (_driverPosition == null || _sos == null) return;

    final driverLatLng =
        LatLng(_driverPosition!.latitude, _driverPosition!.longitude);

    LatLng? destination;
    final status = _sos!.status;

    if (status == 'AMBULANCE_ASSIGNED' ||
        status == 'DRIVER_ENROUTE_TO_PATIENT' ||
        status == 'REACHED_PATIENT') {
      if (_sos!.latitude != null && _sos!.longitude != null) {
        destination = LatLng(_sos!.latitude!, _sos!.longitude!);
      }
    } else if (status == 'PICKED_UP' ||
        status == 'ENROUTE_TO_HOSPITAL' ||
        status == 'ARRIVED_AT_HOSPITAL') {
      if (_sos!.hospitalLatitude != null && _sos!.hospitalLongitude != null) {
        destination =
            LatLng(_sos!.hospitalLatitude!, _sos!.hospitalLongitude!);
      }
    }

    if (destination != null) {
      _routeInfo = await _osrmClient.getRoute(driverLatLng, destination);
    }
    if (mounted) setState(() {});
  }

  void _startGpsBroadcast() {
    _gpsTimer = Timer.periodic(AppConstants.gpsBroadcastInterval, (_) async {
      final pos = await _locationService.getCurrentPosition();
      if (pos == null) {
        if (mounted) setState(() => _gpsError = true);
        return;
      }

      if (mounted) {
        setState(() {
          _driverPosition = pos;
          _gpsError = false;
        });
      }

      final driver = ref.read(driverProvider).driver;
      if (driver?.ambulanceId == null) return;

      final apiClient = ref.read(apiClientProvider);
      final ambulanceApi = AmbulanceApi(apiClient);
      final locationApi = LocationApi(apiClient);

      try {
        await ambulanceApi.updateLocation(
          driver!.ambulanceId!,
          pos.latitude,
          pos.longitude,
        );
        await locationApi.postLocation(
          ambulanceId: driver.ambulanceId!,
          sosEventId: widget.sosId,
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
      } catch (_) {}

      try {
        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          _mapController.camera.zoom,
        );
      } catch (_) {}
    });
  }

  void _startRouteRecalc() {
    _routeTimer = Timer.periodic(AppConstants.routeRecalcInterval, (_) {
      _calculateRoute();
    });
  }

  void _subscribeToSosStatus() {
    ref.read(dispatchProvider.notifier).subscribeToSosStatus(widget.sosId);
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        await ref
            .read(dispatchProvider.notifier)
            .refreshActiveCase(widget.sosId);
        final updated = ref.read(dispatchProvider).activeCase;
        if (updated != null && mounted) {
          setState(() => _sos = updated);
        }
      } catch (_) {}
    });
  }

  Future<void> _advanceStatus() async {
    if (_sos == null || _isStatusUpdating) return;

    final nextStatus = _getNextStatus(_sos!.status);
    if (nextStatus == null) return;

    if (nextStatus == 'COMPLETE') {
      final confirmed = await _showConfirmDialog();
      if (confirmed != true) return;
      setState(() => _isStatusUpdating = true);
      HapticFeedback.mediumImpact();
      final success = await ref
          .read(dispatchProvider.notifier)
          .completeCase(widget.sosId);
      if (mounted) {
        setState(() => _isStatusUpdating = false);
        if (success) {
          context.go('/case/${widget.sosId}/complete');
        }
      }
      return;
    }

    setState(() => _isStatusUpdating = true);
    HapticFeedback.mediumImpact();
    final updated = await ref
        .read(dispatchProvider.notifier)
        .updateStatus(widget.sosId, nextStatus);
    if (mounted) {
      setState(() {
        _isStatusUpdating = false;
        if (updated != null) _sos = updated;
      });
      await _calculateRoute();
    }
  }

  String? _getNextStatus(String current) {
    switch (current) {
      case 'AMBULANCE_ASSIGNED':
        return 'DRIVER_ENROUTE_TO_PATIENT';
      case 'DRIVER_ENROUTE_TO_PATIENT':
        return 'REACHED_PATIENT';
      case 'REACHED_PATIENT':
        return 'PICKED_UP';
      case 'PICKED_UP':
        return 'ENROUTE_TO_HOSPITAL';
      case 'ENROUTE_TO_HOSPITAL':
        return 'ARRIVED_AT_HOSPITAL';
      case 'ARRIVED_AT_HOSPITAL':
        return 'COMPLETE';
      default:
        return null;
    }
  }

  String _getActionButtonText(String status) {
    switch (status) {
      case 'AMBULANCE_ASSIGNED':
        return 'Start Navigation';
      case 'DRIVER_ENROUTE_TO_PATIENT':
        return "I've Reached the Patient";
      case 'REACHED_PATIENT':
        return 'Patient Picked Up';
      case 'PICKED_UP':
        return 'Heading to Hospital';
      case 'ENROUTE_TO_HOSPITAL':
        return 'Arrived at Hospital';
      case 'ARRIVED_AT_HOSPITAL':
        return 'Complete Case';
      default:
        return 'Next';
    }
  }

  Color _getActionButtonColor(String status) {
    switch (status) {
      case 'AMBULANCE_ASSIGNED':
      case 'DRIVER_ENROUTE_TO_PATIENT':
        return AppColors.accent;
      case 'REACHED_PATIENT':
      case 'PICKED_UP':
        return const Color(0xFF6366F1);
      case 'ENROUTE_TO_HOSPITAL':
      case 'ARRIVED_AT_HOSPITAL':
        return AppColors.success;
      default:
        return AppColors.accent;
    }
  }

  IconData _getActionButtonIcon(String status) {
    switch (status) {
      case 'AMBULANCE_ASSIGNED':
        return Icons.navigation;
      case 'DRIVER_ENROUTE_TO_PATIENT':
        return Icons.location_on;
      case 'REACHED_PATIENT':
        return Icons.person_add;
      case 'PICKED_UP':
        return Icons.local_hospital;
      case 'ENROUTE_TO_HOSPITAL':
        return Icons.check_circle;
      case 'ARRIVED_AT_HOSPITAL':
        return Icons.done_all;
      default:
        return Icons.arrow_forward;
    }
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Case'),
        content: Text(
          'Are you sure you want to complete this case?\n\n'
          'Patient: ${_sos?.userName ?? "Unknown"}\n'
          'Hospital: ${_sos?.hospitalName ?? "Unknown"}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _routeTimer?.cancel();
    _refreshTimer?.cancel();
    ref.read(dispatchProvider.notifier).unsubscribeFromSosStatus();
    _mapController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DispatchState>(dispatchProvider, (previous, next) {
      if (next.activeCase != null && next.activeCase!.id == widget.sosId) {
        if (_sos == null || _sos!.status != next.activeCase!.status) {
          setState(() => _sos = next.activeCase);
          _calculateRoute();
        }
      }
    });

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final sos = _sos;
    if (sos == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Case')),
        body: const Center(child: Text('Case not found')),
      );
    }

    final driverLatLng = _driverPosition != null
        ? LatLng(_driverPosition!.latitude, _driverPosition!.longitude)
        : null;
    final patientLatLng =
        sos.latitude != null && sos.longitude != null
            ? LatLng(sos.latitude!, sos.longitude!)
            : null;
    final hospitalLatLng =
        sos.hospitalLatitude != null && sos.hospitalLongitude != null
            ? LatLng(sos.hospitalLatitude!, sos.hospitalLongitude!)
            : null;

    final showHospital = sos.status == 'PICKED_UP' ||
        sos.status == 'ENROUTE_TO_HOSPITAL' ||
        sos.status == 'ARRIVED_AT_HOSPITAL';

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(driverLatLng, patientLatLng, hospitalLatLng, showHospital),
          _buildStatusBar(sos.status),
          if (_routeInfo != null) _buildEtaChip(),
          if (_gpsError) _buildGpsWarning(),
          _buildBottomSheet(sos),
        ],
      ),
    );
  }

  Widget _buildMap(
    LatLng? driver,
    LatLng? patient,
    LatLng? hospital,
    bool showHospital,
  ) {
    final center =
        driver ?? patient ?? const LatLng(19.076, 72.877);
    final markers = <Marker>[];

    if (driver != null) {
      markers.add(Marker(
        point: driver,
        width: 48,
        height: 48,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(Icons.local_shipping, color: Colors.white, size: 24),
        ),
      ));
    }

    if (patient != null) {
      markers.add(Marker(
        point: patient,
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 22),
        ),
      ));
    }

    if (showHospital && hospital != null) {
      markers.add(Marker(
        point: hospital,
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 3,
              ),
            ],
          ),
          child:
              const Icon(Icons.local_hospital, color: Colors.white, size: 22),
        ),
      ));
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.rakshapoorvak.driver_app',
        ),
        if (_routeInfo != null && _routeInfo!.polylinePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routeInfo!.polylinePoints,
                strokeWidth: 5,
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
              Polyline(
                points: _routeInfo!.polylinePoints,
                strokeWidth: 4,
                color: AppColors.accent,
              ),
            ],
          ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildStatusBar(String status) {
    final steps = [
      'ASSIGNED',
      'EN ROUTE',
      'REACHED',
      'PICKED UP',
      'TO HOSPITAL',
      'ARRIVED',
    ];
    final statusMap = {
      'AMBULANCE_ASSIGNED': 0,
      'DRIVER_ENROUTE_TO_PATIENT': 1,
      'REACHED_PATIENT': 2,
      'PICKED_UP': 3,
      'ENROUTE_TO_HOSPITAL': 4,
      'ARRIVED_AT_HOSPITAL': 5,
    };
    final currentStep = statusMap[status] ?? 0;

    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.white.withValues(alpha: 0.95),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            Expanded(
              child: Row(
                children: List.generate(steps.length, (i) {
                  final isCompleted = i <= currentStep;
                  final isCurrent = i == currentStep;
                  return Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppColors.forStatus(status)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          steps[i],
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight:
                                isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isCompleted
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtaChip() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer, size: 18, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                _routeInfo!.formattedDuration,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                width: 1,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: Colors.grey.shade300,
              ),
              const Icon(Icons.straighten, size: 18, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                _routeInfo!.formattedDistance,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGpsWarning() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.gps_off, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'GPS signal lost. Trying to reconnect...',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => _locationService.openLocationSettings(),
              child: const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet(SosEvent sos) {
    final canTriage = sos.status == 'REACHED_PATIENT' ||
        sos.status == 'PICKED_UP' ||
        sos.status == 'ENROUTE_TO_HOSPITAL';

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.3,
      minChildSize: 0.18,
      maxChildSize: 0.65,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isStatusUpdating ? null : _advanceStatus,
                  icon: _isStatusUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(_getActionButtonIcon(sos.status)),
                  label: Text(
                    _getActionButtonText(sos.status),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getActionButtonColor(sos.status),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildPatientInfoSection(sos),
              const SizedBox(height: 12),
              if (sos.hospitalName != null) _buildDestinationSection(sos),
              const SizedBox(height: 12),
              _buildMedicalContextSection(sos),
              const SizedBox(height: 12),
              _buildQuickActions(sos, canTriage),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatientInfoSection(SosEvent sos) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 20, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  sos.userName ?? 'Patient',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                CriticalityBadge(
                  criticality: sos.criticality ?? 'MEDIUM',
                ),
              ],
            ),
            if (sos.symptoms != null) ...[
              const SizedBox(height: 8),
              Text(
                sos.symptoms!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (sos.address != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      sos.address!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationSection(SosEvent sos) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_hospital,
                color: AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sos.hospitalName!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (sos.hospitalAddress != null)
                    Text(
                      sos.hospitalAddress!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalContextSection(SosEvent sos) {
    final hasData = sos.bloodGroup != null ||
        sos.allergies != null ||
        sos.medicalConditions != null;
    if (!hasData) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.medical_information, size: 18, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'Medical Info',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (sos.bloodGroup != null)
                  _buildMedChip('Blood: ${sos.bloodGroup!}', Colors.red),
                if (sos.allergies != null && sos.allergies!.isNotEmpty)
                  _buildMedChip('Allergies: ${sos.allergies!}', Colors.orange),
                if (sos.medicalConditions != null &&
                    sos.medicalConditions!.isNotEmpty)
                  _buildMedChip(sos.medicalConditions!, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color.withValues(alpha: 0.8),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQuickActions(SosEvent sos, bool canTriage) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildQuickActionChip(
          icon: Icons.monitor_heart,
          label: 'Vitals',
          enabled: canTriage,
          onTap: () => context.push('/case/${sos.id}/triage'),
        ),
        _buildQuickActionChip(
          icon: Icons.medication,
          label: 'Medications',
          enabled: canTriage,
          onTap: () => context.push('/case/${sos.id}/medications'),
        ),
        if (sos.userPhone != null)
          _buildQuickActionChip(
            icon: Icons.phone,
            label: 'Call Patient',
            enabled: true,
            onTap: () async {
              final uri = Uri(scheme: 'tel', path: sos.userPhone);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
      ],
    );
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: enabled ? onTap : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
