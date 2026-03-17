import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:driver_app/core/theme/app_theme.dart';
import 'package:driver_app/data/api/sos_api.dart';
import 'package:driver_app/data/api/triage_api.dart';
import 'package:driver_app/data/models/sos_event.dart';
import 'package:driver_app/core/utils/format_date.dart';
import 'package:driver_app/providers/auth_provider.dart';

class CaseCompleteScreen extends ConsumerStatefulWidget {
  final int sosId;

  const CaseCompleteScreen({super.key, required this.sosId});

  @override
  ConsumerState<CaseCompleteScreen> createState() =>
      _CaseCompleteScreenState();
}

class _CaseCompleteScreenState extends ConsumerState<CaseCompleteScreen>
    with SingleTickerProviderStateMixin {
  SosEvent? _sos;
  int _triageCount = 0;
  int _medicationCount = 0;
  bool _isLoading = true;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final sosApi = SosApi(apiClient);
      final triageApi = TriageApi(apiClient);

      _sos = await sosApi.getById(widget.sosId);
      final records = await triageApi.getRecords(widget.sosId);
      final meds = await triageApi.getMedications(widget.sosId);
      _triageCount = records.length;
      _medicationCount = meds.length;
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.3),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    const Text(
                      'Case Completed',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Great work! The patient has been delivered safely.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (_sos != null)
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            'Patient',
                            _sos!.userName ?? 'Unknown',
                          ),
                          _buildDivider(),
                          _buildSummaryRow(
                            'Hospital',
                            _sos!.hospitalName ?? 'Unknown',
                          ),
                          _buildDivider(),
                          _buildSummaryRow(
                            'Duration',
                            durationString(
                              _sos!.createdAt,
                              _sos!.completedAt ?? _sos!.updatedAt,
                            ),
                          ),
                          _buildDivider(),
                          _buildSummaryRow(
                            'Triage Records',
                            '$_triageCount',
                          ),
                          _buildDivider(),
                          _buildSummaryRow(
                            'Medications',
                            '$_medicationCount',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey.shade200, height: 1);
  }
}
