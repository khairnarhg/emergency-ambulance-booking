import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format_date.dart';
import '../../../providers/sos_provider.dart';
import '../../../shared/widgets/status_badge.dart';

class SosDetailScreen extends ConsumerWidget {
  final int sosId;

  const SosDetailScreen({super.key, required this.sosId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosAsync = ref.watch(sosEventProvider(sosId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('SOS #$sosId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: sosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(extractErrorMessage(e)),
        ),
        data: (sos) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Status card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SOS #${sos.id}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            StatusBadge(status: sos.status),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SosStatusTimeline(currentStatus: sos.status),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Incident Details',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Divider(height: 20),
                        _Row(
                          label: 'Date',
                          value: formatDateTime(sos.createdAt),
                        ),
                        if (sos.symptoms != null) ...[
                          const SizedBox(height: 12),
                          _Row(
                            label: 'Symptoms',
                            value: sos.symptoms!,
                          ),
                        ],
                        if (sos.criticality != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  'Severity',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600),
                                ),
                              ),
                              CriticalityBadge(
                                  criticality: sos.criticality!),
                            ],
                          ),
                        ],
                        if (sos.address != null) ...[
                          const SizedBox(height: 12),
                          _Row(
                            label: 'Location',
                            value: sos.address!,
                          ),
                        ],
                        if (sos.completedAt != null) ...[
                          const SizedBox(height: 12),
                          _Row(
                            label: 'Completed',
                            value: formatDateTime(sos.completedAt),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Team card
                if (sos.driverName != null || sos.hospitalName != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Response Team',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Divider(height: 20),
                          if (sos.driverName != null)
                            _Row(
                              label: 'Driver',
                              value: sos.driverName!,
                            ),
                          if (sos.ambulanceRegistrationNumber != null) ...[
                            const SizedBox(height: 12),
                            _Row(
                              label: 'Ambulance',
                              value: sos.ambulanceRegistrationNumber!,
                            ),
                          ],
                          if (sos.hospitalName != null) ...[
                            const SizedBox(height: 12),
                            _Row(
                              label: 'Hospital',
                              value: sos.hospitalName!,
                            ),
                          ],
                          if (sos.doctorName != null) ...[
                            const SizedBox(height: 12),
                            _Row(
                              label: 'Doctor',
                              value: sos.doctorName!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Track button (if active)
                if (sos.isActive)
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.go('/sos/${sos.id}/tracking'),
                    icon: const Icon(Icons.track_changes_rounded),
                    label: const Text('View Live Tracking'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
