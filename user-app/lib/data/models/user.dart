class UserSummary {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final List<String> roles;

  const UserSummary({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.roles,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    List<String> roleList = [];
    if (rolesRaw is List) {
      roleList = rolesRaw.map((e) => e.toString()).toList();
    } else if (rolesRaw is Set) {
      roleList = rolesRaw.map((e) => e.toString()).toList();
    }
    return UserSummary(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String?,
      roles: roleList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'roles': roles,
      };
}

class UserProfile {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final List<String> roles;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.roles,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    List<String> roleList = [];
    if (rolesRaw is List) {
      roleList = rolesRaw.map((e) => e.toString()).toList();
    }
    return UserProfile(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String?,
      roles: roleList,
    );
  }
}

class MedicalProfile {
  final int? id;
  final int? userId;
  final String? bloodGroup;
  final String? allergies;
  final String? conditions;
  final String? notes;

  const MedicalProfile({
    this.id,
    this.userId,
    this.bloodGroup,
    this.allergies,
    this.conditions,
    this.notes,
  });

  factory MedicalProfile.fromJson(Map<String, dynamic> json) => MedicalProfile(
        id: json['id'] != null ? (json['id'] as num).toInt() : null,
        userId: json['userId'] != null ? (json['userId'] as num).toInt() : null,
        bloodGroup: json['bloodGroup'] as String?,
        allergies: json['allergies'] as String?,
        conditions: json['conditions'] as String?,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (bloodGroup != null) 'bloodGroup': bloodGroup,
        if (allergies != null) 'allergies': allergies,
        if (conditions != null) 'conditions': conditions,
        if (notes != null) 'notes': notes,
      };
}

class EmergencyContact {
  final int? id;
  final int? userId;
  final String name;
  final String phone;
  final String? relationship;

  const EmergencyContact({
    this.id,
    this.userId,
    required this.name,
    required this.phone,
    this.relationship,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        id: json['id'] != null ? (json['id'] as num).toInt() : null,
        userId: json['userId'] != null ? (json['userId'] as num).toInt() : null,
        name: json['name'] as String,
        phone: json['phone'] as String,
        relationship: json['relationship'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        if (relationship != null) 'relationship': relationship,
      };
}
