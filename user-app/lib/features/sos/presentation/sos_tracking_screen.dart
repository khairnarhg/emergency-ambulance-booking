import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format_date.dart';
import '../../../data/api/sos_api.dart';
import '../../../providers/sos_provider.dart';
import '../../../shared/widgets/map_tracking_widget.dart';
import '../../../shared/widgets/status_badge.dart';

class SosTrackingScreen extends ConsumerStatefulWidget {
  final int sosId;

  const SosTrackingScreen({super.key, required this.sosId});

  @override
  ConsumerState<SosTrackingScreen> createState() =>
      _SosTrackingScreenState();
}

class _SosTrackingScreenState extends ConsumerState<SosTrackingScreen> {
  bool _showCancelConfirm = false;

  Future<void> _callDriver(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _cancelSos() async {
    try {
      final api = ref.read(sosApiProvider);
      await api.cancelSos(widget.sosId);
      ref.read(activeSosProvider.notifier).clearActiveSos();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sosAsync = ref.watch(sosEventProvider(widget.sosId));
    final trackingAsync = ref.watch(trackingProvider(widget.sosId));

    // Prefer the real-time tracking status (updated via WebSocket) over
    // the initially-fetched SOS event status.
    final liveStatus =
        trackingAsync.valueOrNull?.status;

    return sosAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Tracking')),
        body: Center(child: Text(extractErrorMessage(e))),
      ),
      data: (sos) {
        final currentStatus = liveStatus ?? sos.status;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Custom app bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => context.go('/home'),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          shape: const CircleBorder(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Tracking',
                              style:
                                  Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'SOS #${widget.sosId}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: currentStatus),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      children: [
                        // Map
                        trackingAsync.when(
                          loading: () => Container(
                            height: 280,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (e, _) => MapTrackingWidget(
                            sosEvent: sos,
                            tracking: null,
                          ),
                          data: (tracking) => MapTrackingWidget(
                            sosEvent: sos,
                            tracking: tracking,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Status timeline
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: SosStatusTimeline(
                                currentStatus: currentStatus),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ETA card
                        trackingAsync.maybeWhen(
                          data: (tracking) {
                            if (tracking == null) return const SizedBox();
                            final eta =
                                tracking.estimatedMinutesArrival;
                            return _EtaCard(eta: eta);
                          },
                          orElse: () => const SizedBox(),
                        ),

                        // Hospital destination card
                        if (sos.hospitalName != null) ...[
                          const SizedBox(height: 12),
                          _HospitalDestinationCard(
                            hospitalName: sos.hospitalName!,
                            hospitalAddress: sos.hospitalAddress,
                          ),
                        ],

                        // Driver info card
                        if (sos.driverName != null) ...[
                          const SizedBox(height: 12),
                          _DriverCard(
                            driverName: sos.driverName!,
                            driverPhone:
                                trackingAsync.valueOrNull?.driverPhone,
                            ambulanceReg:
                                sos.ambulanceRegistrationNumber,
                            hospitalName: sos.hospitalName,
                            onCall: (phone) => _callDriver(phone),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // SOS info card
                        _SosInfoCard(sos: sos),
                        const SizedBox(height: 16),

                        // Cancel button
                        if (sos.isCancellable)
                          _showCancelConfirm
                              ? Card(
                                  color: AppColors.error.withAlpha(15),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Cancel this SOS request?',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  color: AppColors.error),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'This will cancel the ambulance dispatch.',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () => setState(
                                                  () =>
                                                      _showCancelConfirm =
                                                          false,
                                                ),
                                                child: const Text(
                                                    'Keep SOS'),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                style: ElevatedButton
                                                    .styleFrom(
                                                  backgroundColor:
                                                      AppColors.error,
                                                ),
                                                onPressed: _cancelSos,
                                                child: const Text(
                                                    'Yes, Cancel'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : OutlinedButton.icon(
                                  onPressed: () => setState(
                                    () => _showCancelConfirm = true,
                                  ),
                                  icon: const Icon(Icons.cancel_outlined,
                                      color: AppColors.error),
                                  label: const Text('Cancel SOS',
                                      style:
                                          TextStyle(color: AppColors.error)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: AppColors.error),
                                  ),
                                ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EtaCard extends StatelessWidget {
  final int? eta;

  const _EtaCard({this.eta});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(26),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.timer_outlined,
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
                    'Estimated Arrival',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    eta != null ? '$eta minutes' : 'Calculating...',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final String driverName;
  final String? driverPhone;
  final String? ambulanceReg;
  final String? hospitalName;
  final void Function(String) onCall;

  const _DriverCard({
    required this.driverName,
    this.driverPhone,
    this.ambulanceReg,
    this.hospitalName,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline,
                    color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Ambulance Team',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 20),
            _InfoRow(
              icon: Icons.person_rounded,
              label: 'Driver',
              value: driverName,
            ),
            if (ambulanceReg != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.directions_car_rounded,
                label: 'Ambulance',
                value: ambulanceReg!,
              ),
            ],
            if (hospitalName != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.local_hospital_rounded,
                label: 'Destination',
                value: hospitalName!,
              ),
            ],
            if (driverPhone != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => onCall(driverPhone!),
                icon: const Icon(Icons.phone, size: 18),
                label: Text('Call Driver ($driverPhone)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HospitalDestinationCard extends StatelessWidget {
  final String hospitalName;
  final String? hospitalAddress;

  const _HospitalDestinationCard({
    required this.hospitalName,
    this.hospitalAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(26),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
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
                    'Destination',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hospitalName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (hospitalAddress != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      hospitalAddress!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SosInfoCard extends StatelessWidget {
  final dynamic sos;

  const _SosInfoCard({required this.sos});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'SOS Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 20),
            if (sos.symptoms != null)
              _InfoRow(
                icon: Icons.medical_services_outlined,
                label: 'Symptoms',
                value: sos.symptoms,
              ),
            if (sos.symptoms != null) const SizedBox(height: 8),
            if (sos.criticality != null)
              _InfoRow(
                icon: Icons.priority_high_rounded,
                label: 'Severity',
                value: sos.criticality,
              ),
            if (sos.criticality != null) const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.access_time_rounded,
              label: 'Requested',
              value: formatDateTime(sos.createdAt),
            ),
            if (sos.address != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: sos.address,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
