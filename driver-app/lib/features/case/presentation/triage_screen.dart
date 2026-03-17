import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:driver_app/core/theme/app_theme.dart';
import 'package:driver_app/core/utils/format_date.dart';
import 'package:driver_app/data/api/triage_api.dart';
import 'package:driver_app/data/models/triage_record.dart';
import 'package:driver_app/providers/auth_provider.dart';

class TriageScreen extends ConsumerStatefulWidget {
  final int sosId;

  const TriageScreen({super.key, required this.sosId});

  @override
  ConsumerState<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends ConsumerState<TriageScreen> {
  final _heartRateController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _temperatureController = TextEditingController();
  final _notesController = TextEditingController();

  List<TriageRecord> _previousRecords = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final api = TriageApi(ref.read(apiClientProvider));
      _previousRecords = await api.getRecords(widget.sosId);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveVitals() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final api = TriageApi(ref.read(apiClientProvider));
      final record = TriageRecord(
        sosEventId: widget.sosId,
        heartRate: int.tryParse(_heartRateController.text),
        systolicBp: int.tryParse(_systolicController.text),
        diastolicBp: int.tryParse(_diastolicController.text),
        spo2: int.tryParse(_spo2Controller.text),
        temperature: double.tryParse(_temperatureController.text),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await api.createRecord(record);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vitals recorded'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save vitals'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _heartRateController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _spo2Controller.dispose();
    _temperatureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Triage - Enter Vitals'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildVitalField(
                  controller: _heartRateController,
                  label: 'Heart Rate',
                  unit: 'bpm',
                  hint: 'Normal: 60-100',
                  normalMin: 60,
                  normalMax: 100,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildVitalField(
                        controller: _systolicController,
                        label: 'Systolic BP',
                        unit: 'mmHg',
                        hint: 'Normal: 90-120',
                        normalMin: 90,
                        normalMax: 120,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildVitalField(
                        controller: _diastolicController,
                        label: 'Diastolic BP',
                        unit: 'mmHg',
                        hint: 'Normal: 60-80',
                        normalMin: 60,
                        normalMax: 80,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildVitalField(
                  controller: _spo2Controller,
                  label: 'SpO2',
                  unit: '%',
                  hint: 'Normal: 95-100',
                  normalMin: 95,
                  normalMax: 100,
                ),
                const SizedBox(height: 14),
                _buildVitalField(
                  controller: _temperatureController,
                  label: 'Temperature',
                  unit: '°C',
                  hint: 'Normal: 36.1-37.2',
                  normalMin: 36.1,
                  normalMax: 37.2,
                  isDecimal: true,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Additional observations...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveVitals,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: const Text(
                      'Save Vitals',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                if (_previousRecords.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  const Text(
                    'Previous Records',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._previousRecords.map(_buildRecordCard),
                ],
              ],
            ),
    );
  }

  Widget _buildVitalField({
    required TextEditingController controller,
    required String label,
    required String unit,
    required String hint,
    required num normalMin,
    required num normalMax,
    bool isDecimal = false,
  }) {
    return StatefulBuilder(
      builder: (context, setFieldState) {
        Color indicatorColor = Colors.grey.shade300;
        final text = controller.text;
        if (text.isNotEmpty) {
          final val =
              isDecimal ? double.tryParse(text) : int.tryParse(text);
          if (val != null) {
            if (val >= normalMin && val <= normalMax) {
              indicatorColor = AppColors.success;
            } else {
              final lowBorderline = normalMin * 0.85;
              final highBorderline = normalMax * 1.15;
              if (val >= lowBorderline && val <= highBorderline) {
                indicatorColor = AppColors.warning;
              } else {
                indicatorColor = AppColors.error;
              }
            }
          }
        }

        return TextFormField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          onChanged: (_) => setFieldState(() {}),
          decoration: InputDecoration(
            labelText: label,
            helperText: hint,
            suffixText: unit,
            suffixIcon: Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecordCard(TriageRecord record) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatDateTime(record.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (record.heartRate != null)
                  _buildVitalChip('HR', '${record.heartRate} bpm'),
                if (record.systolicBp != null)
                  _buildVitalChip(
                    'BP',
                    '${record.systolicBp}/${record.diastolicBp ?? "-"}',
                  ),
                if (record.spo2 != null)
                  _buildVitalChip('SpO2', '${record.spo2}%'),
                if (record.temperature != null)
                  _buildVitalChip('Temp', '${record.temperature}°C'),
              ],
            ),
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                record.notes!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVitalChip(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
