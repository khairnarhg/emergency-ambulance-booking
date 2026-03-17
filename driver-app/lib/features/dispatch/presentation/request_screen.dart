import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:driver_app/core/theme/app_theme.dart';
import 'package:driver_app/core/constants/app_constants.dart';
import 'package:driver_app/core/network/osrm_client.dart';
import 'package:driver_app/core/utils/location_service.dart';
import 'package:driver_app/data/models/sos_event.dart';
import 'package:driver_app/data/models/route_info.dart';
import 'package:driver_app/providers/dispatch_provider.dart';
import 'package:driver_app/shared/widgets/route_map.dart';
import 'package:geolocator/geolocator.dart';

class RequestScreen extends ConsumerStatefulWidget {
  final int sosId;

  const RequestScreen({super.key, required this.sosId});

  @override
  ConsumerState<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends ConsumerState<RequestScreen>
    with SingleTickerProviderStateMixin {
  SosEvent? _sosEvent;
  RouteInfo? _routeInfo;
  Position? _driverPosition;
  int _countdown = AppConstants.requestTimeoutSeconds;
  Timer? _countdownTimer;
  bool _isLoading = true;
  bool _isActioning = false;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  final OsrmClient _osrmClient = OsrmClient();
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _driverPosition = await _locationService.getCurrentPosition();
      final api = ref.read(dispatchApiProvider);
      _sosEvent = await api.getRequestDetails(widget.sosId);

      if (_driverPosition != null &&
          _sosEvent?.latitude != null &&
          _sosEvent?.longitude != null) {
        _routeInfo = await _osrmClient.getRoute(
          LatLng(_driverPosition!.latitude, _driverPosition!.longitude),
          LatLng(_sosEvent!.latitude!, _sosEvent!.longitude!),
        );
      }

      setState(() => _isLoading = false);
      _slideController.forward();
      _startCountdown();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load request details')),
        );
        context.go('/home');
      }
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        timer.cancel();
        _rejectRequest();
      }
    });
  }

  Future<void> _acceptRequest() async {
    if (_isActioning) return;
    setState(() => _isActioning = true);
    HapticFeedback.mediumImpact();
    final success =
        await ref.read(dispatchProvider.notifier).acceptRequest(widget.sosId);
    if (mounted) {
      if (success) {
        context.go('/case/${widget.sosId}');
      } else {
        setState(() => _isActioning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to accept request')),
        );
      }
    }
  }

  Future<void> _rejectRequest() async {
    if (_isActioning) return;
    setState(() => _isActioning = true);
    await ref.read(dispatchProvider.notifier).rejectRequest(widget.sosId);
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final sos = _sosEvent;
    if (sos == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Request not found')),
      );
    }

    final criticalityColor =
        AppColors.forCriticality(sos.criticality ?? 'MEDIUM');

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 12,
              left: 16,
              right: 16,
            ),
            color: criticalityColor,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.go('/home'),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(sos.criticality ?? "MEDIUM").toUpperCase()} EMERGENCY',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                _buildCountdownIndicator(),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: RouteMap(
              driverLocation: _driverPosition != null
                  ? LatLng(
                      _driverPosition!.latitude,
                      _driverPosition!.longitude,
                    )
                  : null,
              patientLocation: sos.latitude != null && sos.longitude != null
                  ? LatLng(sos.latitude!, sos.longitude!)
                  : null,
              routePolyline: _routeInfo?.polylinePoints ?? [],
            ),
          ),
          SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sos.userName ?? 'Patient',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (sos.symptoms != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      sos.symptoms!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_routeInfo != null) ...[
                        _buildInfoChip(
                          Icons.straighten,
                          _routeInfo!.formattedDistance,
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          Icons.timer,
                          _routeInfo!.formattedDuration,
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (sos.hospitalName != null)
                        Expanded(
                          child: _buildInfoChip(
                            Icons.local_hospital,
                            sos.hospitalName!,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _isActioning ? null : _rejectRequest,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Reject',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isActioning ? null : _acceptRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isActioning
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Accept',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownIndicator() {
    final fraction = _countdown / AppConstants.requestTimeoutSeconds;
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: fraction,
            strokeWidth: 3,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
          Text(
            '$_countdown',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
