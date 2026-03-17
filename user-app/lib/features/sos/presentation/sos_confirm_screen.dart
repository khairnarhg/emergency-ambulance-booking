import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../data/api/sos_api.dart';
import '../../../data/api/user_api.dart';
import '../../../data/models/user.dart';
import '../../../providers/sos_provider.dart';

final _confirmMedicalProfileProvider =
    FutureProvider<MedicalProfile?>((ref) async {
  return ref.read(userApiProvider).getMedicalProfile();
});

final _confirmEmergencyContactsProvider =
    FutureProvider<List<EmergencyContact>>((ref) async {
  return ref.read(userApiProvider).getEmergencyContacts();
});

class SosConfirmScreen extends ConsumerStatefulWidget {
  final int sosId;

  const SosConfirmScreen({super.key, required this.sosId});

  @override
  ConsumerState<SosConfirmScreen> createState() => _SosConfirmScreenState();
}

class _SosConfirmScreenState extends ConsumerState<SosConfirmScreen>
    with SingleTickerProviderStateMixin {
  final _symptomsCtrl = TextEditingController();
  String? _selectedCriticality;
  bool _isUpdating = false;
  late AnimationController _checkCtrl;
  late Animation<double> _checkScale;

  final _criticalities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScale = CurvedAnimation(
      parent: _checkCtrl,
      curve: Curves.elasticOut,
    );
    _checkCtrl.forward();
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _symptomsCtrl.dispose();
    super.dispose();
  }

  Color _criticalityColor(String c) {
    switch (c) {
      case 'LOW':
        return AppColors.criticalityLow;
      case 'MEDIUM':
        return AppColors.criticalityMedium;
      case 'HIGH':
        return AppColors.criticalityHigh;
      case 'CRITICAL':
        return AppColors.criticalityCritical;
      default:
        return AppColors.textTertiary;
    }
  }

  Future<void> _update() async {
    setState(() => _isUpdating = true);
    try {
      final api = ref.read(sosApiProvider);
      final updated = await api.updateSos(
        id: widget.sosId,
        symptoms: _symptomsCtrl.text.trim().isNotEmpty
            ? _symptomsCtrl.text.trim()
            : null,
        criticality: _selectedCriticality,
      );
      ref.read(activeSosProvider.notifier).setActiveSos(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
    if (mounted) {
      context.go('/sos/${widget.sosId}/tracking');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // Success animation
                ScaleTransition(
                  scale: _checkScale,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 64,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'SOS Sent!',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.success,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Help is on the way. Add more details to help the paramedics prepare.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // SOS ID chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(15),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.accent.withAlpha(51)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tag, size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        'SOS #${widget.sosId}',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Medical context reassurance
                _MedicalContextCard(ref: ref),
                const SizedBox(height: 24),

                // Symptoms
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'What happened? (optional)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _symptomsCtrl,
                  maxLines: 3,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. Chest pain, difficulty breathing, severe bleeding...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Criticality
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Severity level (optional)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  children: _criticalities.map((c) {
                    final isSelected = _selectedCriticality == c;
                    final color = _criticalityColor(c);
                    return FilterChip(
                      label: Text(c),
                      selected: isSelected,
                      onSelected: (_) => setState(
                        () => _selectedCriticality = isSelected ? null : c,
                      ),
                      selectedColor: color.withAlpha(40),
                      checkmarkColor: color,
                      labelStyle: TextStyle(
                        color: isSelected ? color : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? color
                            : AppColors.divider,
                      ),
                      backgroundColor: AppColors.surface,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isUpdating ? null : _update,
                  child: _isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('View Tracking'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      context.go('/sos/${widget.sosId}/tracking'),
                  child: const Text('Skip and track →'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MedicalContextCard extends StatelessWidget {
  final WidgetRef ref;

  const _MedicalContextCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    final medicalAsync = ref.watch(_confirmMedicalProfileProvider);
    final contactsAsync = ref.watch(_confirmEmergencyContactsProvider);

    final profile = medicalAsync.valueOrNull;
    final contacts = contactsAsync.valueOrNull ?? [];

    final hasBloodGroup =
        profile?.bloodGroup != null && profile!.bloodGroup!.isNotEmpty;
    final hasAllergies =
        profile?.allergies != null && profile!.allergies!.isNotEmpty;
    final hasContacts = contacts.isNotEmpty;

    if (!hasBloodGroup && !hasAllergies && !hasContacts) {
      return const SizedBox.shrink();
    }

    return Card(
      color: AppColors.accent.withAlpha(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety_rounded,
                    size: 20, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your medical profile has been shared with the ambulance team',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            if (hasBloodGroup || hasAllergies) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (hasBloodGroup)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: AppColors.primary.withAlpha(60)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bloodtype_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            profile.bloodGroup ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  if (hasAllergies)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(20),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: AppColors.warning.withAlpha(60)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 14, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              profile.allergies ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            if (hasContacts) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.people_outline_rounded,
                      size: 16, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    'Emergency contacts will be notified',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
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
}
