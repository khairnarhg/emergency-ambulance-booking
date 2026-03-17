class TriageRecord {
  final int? id;
  final int sosEventId;
  final int? heartRate;
  final int? systolicBp;
  final int? diastolicBp;
  final int? spo2;
  final double? temperature;
  final String? notes;
  final String? createdAt;

  const TriageRecord({
    this.id,
    required this.sosEventId,
    this.heartRate,
    this.systolicBp,
    this.diastolicBp,
    this.spo2,
    this.temperature,
    this.notes,
    this.createdAt,
  });

  factory TriageRecord.fromJson(Map<String, dynamic> json) {
    return TriageRecord(
      id: json['id'] as int?,
      sosEventId: json['sosEventId'] as int? ?? 0,
      heartRate: json['heartRate'] as int?,
      systolicBp: json['systolicBp'] as int?,
      diastolicBp: json['diastolicBp'] as int?,
      spo2: json['spo2'] as int?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sosEventId': sosEventId,
      if (heartRate != null) 'heartRate': heartRate,
      if (systolicBp != null) 'systolicBp': systolicBp,
      if (diastolicBp != null) 'diastolicBp': diastolicBp,
      if (spo2 != null) 'spo2': spo2,
      if (temperature != null) 'temperature': temperature,
      if (notes != null) 'notes': notes,
    };
  }
}
