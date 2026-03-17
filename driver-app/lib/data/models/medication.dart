class Medication {
  final int? id;
  final int sosEventId;
  final String name;
  final String? dosage;
  final String? notes;
  final String? createdAt;

  const Medication({
    this.id,
    required this.sosEventId,
    required this.name,
    this.dosage,
    this.notes,
    this.createdAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as int?,
      sosEventId: json['sosEventId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sosEventId': sosEventId,
      'name': name,
      if (dosage != null) 'dosage': dosage,
      if (notes != null) 'notes': notes,
    };
  }
}
