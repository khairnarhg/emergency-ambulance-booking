import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:driver_app/core/theme/app_theme.dart';
import 'package:driver_app/core/constants/app_constants.dart';
import 'package:driver_app/core/utils/haversine.dart';
import 'package:driver_app/core/utils/location_service.dart';
import 'package:driver_app/core/utils/format_date.dart';
import 'package:driver_app/providers/driver_provider.dart';
import 'package:driver_app/providers/dispatch_provider.dart';
import 'package:driver_app/providers/notification_provider.dart';
import 'package:driver_app/shared/widgets/status_badge.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _pollTimer;
  final LocationService _locationService = LocationService();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _locationService.requestPermission();
    _currentPosition = await _locationService.getCurrentPosition();
    ref.read(driverProvider.notifier).loadDriver();
    ref.read(dispatchProvider.notifier).loadActiveCase();
    ref.read(dispatchProvider.notifier).loadPendingRequests();
    ref.read(notificationProvider.notifier).loadUnreadCount();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(AppConstants.pollInterval, (_) {
      final driverState = ref.read(driverProvider);
      final dispatchState = ref.read(dispatchProvider);
      if (driverState.driver?.isAvailable == true &&
          dispatchState.activeCase == null) {
        ref.read(dispatchProvider.notifier).loadPendingRequests();
      }
      ref.read(notificationProvider.notifier).loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverProvider);
    final dispatchState = ref.watch(dispatchProvider);
    final notifState = ref.watch(notificationProvider);
    final driver = driverState.driver;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'RakshaPoorvak',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/notifications'),
              ),
              if (notifState.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      notifState.unreadCount > 9
                          ? '9+'
                          : '${notifState.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(driverProvider.notifier).loadDriver();
          await ref.read(dispatchProvider.notifier).loadActiveCase();
          await ref.read(dispatchProvider.notifier).loadPendingRequests();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDriverCard(driver),
            const SizedBox(height: 16),
            _buildStatusToggle(driver),
            const SizedBox(height: 16),
            if (dispatchState.activeCase != null)
              _buildActiveCaseBanner(dispatchState.activeCase!),
            if (driver?.isAvailable == true) ...[
              const SizedBox(height: 16),
              _buildPendingRequestsSection(dispatchState),
            ],
            if (driver?.isOffline == true) ...[
              const SizedBox(height: 40),
              _buildOfflineMessage(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard(dynamic driver) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.accent,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver?.name ?? 'Driver',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (driver?.ambulanceRegistrationNumber != null)
                    Text(
                      driver!.ambulanceRegistrationNumber!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (driver?.hospitalName != null)
                    Text(
                      driver!.hospitalName!,
                      style: const TextStyle(
                        fontSize: 13,
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

  Widget _buildStatusToggle(dynamic driver) {
    final isAvailable = driver?.isAvailable == true;
    final isBusy = driver?.isBusy == true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBusy
                          ? 'On Active Case'
                          : isAvailable
                              ? 'Online'
                              : 'Offline',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isBusy
                            ? AppColors.warning
                            : isAvailable
                                ? AppColors.success
                                : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBusy
                          ? 'Complete your case to go offline'
                          : isAvailable
                              ? 'Receiving dispatch requests'
                              : 'Go online to receive requests',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                IgnorePointer(
                  ignoring: isBusy,
                  child: Opacity(
                    opacity: isBusy ? 0.5 : 1.0,
                    child: Switch(
                      value: isAvailable || isBusy,
                      onChanged: (_) async {
                        final newStatus =
                            isAvailable ? 'OFFLINE' : 'AVAILABLE';
                        await ref
                            .read(driverProvider.notifier)
                            .updateStatus(newStatus);
                      },
                      activeTrackColor: AppColors.success.withValues(alpha: 0.5),
                      activeThumbColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCaseBanner(dynamic activeCase) {
    return GestureDetector(
      onTap: () => context.push('/case/${activeCase.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_shipping,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Case #${activeCase.id}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Patient: ${activeCase.userName ?? "Unknown"}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequestsSection(dynamic dispatchState) {
    final requests = dispatchState.pendingRequests;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pending Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (requests.isEmpty)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No pending requests',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...requests.map((sos) => _buildRequestCard(sos)),
      ],
    );
  }

  Widget _buildRequestCard(dynamic sos) {
    double? distanceKm;
    if (_currentPosition != null &&
        sos.latitude != null &&
        sos.longitude != null) {
      distanceKm = haversineDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        sos.latitude!,
        sos.longitude!,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/request/${sos.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CriticalityBadge(
                      criticality: sos.criticality ?? 'MEDIUM',
                    ),
                    const Spacer(),
                    Text(
                      timeAgo(sos.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  sos.userName ?? 'Patient',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (sos.symptoms != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    sos.symptoms!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (distanceKm != null) ...[
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineMessage() {
    return Column(
      children: [
        Icon(Icons.bedtime_outlined, size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(
          'You are offline',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Go online to receive dispatch requests',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
        ),
      ],
    );
  }
}
