import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../data/api/user_api.dart';
import '../../../data/models/user.dart';

final _medicalProfileProvider = FutureProvider<MedicalProfile?>((ref) async {
  return ref.read(userApiProvider).getMedicalProfile();
});

class MedicalProfileScreen extends ConsumerStatefulWidget {
  const MedicalProfileScreen({super.key});

  @override
  ConsumerState<MedicalProfileScreen> createState() =>
      _MedicalProfileScreenState();
}

class _MedicalProfileScreenState
    extends ConsumerState<MedicalProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bloodGroupCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isSaving = false;
  bool _isEditing = false;

  void _populate(MedicalProfile? profile) {
    if (profile != null) {
      _bloodGroupCtrl.text = profile.bloodGroup ?? '';
      _allergiesCtrl.text = profile.allergies ?? '';
      _conditionsCtrl.text = profile.conditions ?? '';
      _notesCtrl.text = profile.notes ?? '';
    }
  }

  @override
  void dispose() {
    _bloodGroupCtrl.dispose();
    _allergiesCtrl.dispose();
    _conditionsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(userApiProvider).updateMedicalProfile(
            MedicalProfile(
              bloodGroup: _bloodGroupCtrl.text.trim().isNotEmpty
                  ? _bloodGroupCtrl.text.trim()
                  : null,
              allergies: _allergiesCtrl.text.trim().isNotEmpty
                  ? _allergiesCtrl.text.trim()
                  : null,
              conditions: _conditionsCtrl.text.trim().isNotEmpty
                  ? _conditionsCtrl.text.trim()
                  : null,
              notes: _notesCtrl.text.trim().isNotEmpty
                  ? _notesCtrl.text.trim()
                  : null,
            ),
          );
      ref.invalidate(_medicalProfileProvider);
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Medical profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  static const _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(_medicalProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medical Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(extractErrorMessage(e))),
        data: (profile) {
          if (!_isEditing && profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.medical_information_outlined,
                      size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text(
                    'No medical profile yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your medical info to help paramedics',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Medical Info'),
                  ),
                ],
              ),
            );
          }

          if (!_isEditing) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.health_and_safety_rounded,
                              color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Medical Information',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _InfoTile(
                        icon: Icons.bloodtype_rounded,
                        label: 'Blood Group',
                        value: profile?.bloodGroup,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      _InfoTile(
                        icon: Icons.warning_amber_rounded,
                        label: 'Allergies',
                        value: profile?.allergies,
                        color: AppColors.warning,
                      ),
                      const SizedBox(height: 16),
                      _InfoTile(
                        icon: Icons.sick_rounded,
                        label: 'Medical Conditions',
                        value: profile?.conditions,
                        color: const Color(0xFF6366F1),
                      ),
                      const SizedBox(height: 16),
                      _InfoTile(
                        icon: Icons.notes_rounded,
                        label: 'Notes',
                        value: profile?.notes,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Edit mode – populate once
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_bloodGroupCtrl.text.isEmpty) _populate(profile);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Blood group dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _bloodGroups.contains(_bloodGroupCtrl.text)
                        ? _bloodGroupCtrl.text
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Blood Group',
                      prefixIcon: Icon(Icons.bloodtype_rounded),
                    ),
                    items: _bloodGroups
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _bloodGroupCtrl.text = v;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _allergiesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Allergies',
                      hintText: 'e.g. Penicillin, Peanuts',
                      prefixIcon: Icon(Icons.warning_amber_rounded),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _conditionsCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Medical Conditions',
                      hintText: 'e.g. Diabetes, Hypertension',
                      prefixIcon: Icon(Icons.sick_rounded),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes',
                      hintText: 'Any other important medical info',
                      prefixIcon: Icon(Icons.notes_rounded),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Medical Profile'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                value?.isNotEmpty == true ? value! : 'Not specified',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: value?.isNotEmpty == true
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
