class EmergencyContact {
  final int id;
  final int userId;
  final String name;
  final String phone;
  final String? relationship;

  const EmergencyContact({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.relationship,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as int,
      userId: json['userId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      relationship: json['relationship'] as String?,
    );
  }
}

class SosEvent {
  final int id;
  final int? userId;
  final String? userName;
  final String? userPhone;
  final int? hospitalId;
  final String? hospitalName;
  final String? hospitalAddress;
  final double? hospitalLatitude;
  final double? hospitalLongitude;
  final int? ambulanceId;
  final String? ambulanceRegistrationNumber;
  final int? driverId;
  final String? driverName;
  final int? doctorId;
  final String? doctorName;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String status;
  final String? symptoms;
  final String? criticality;
  final String? bloodGroup;
  final String? allergies;
  final String? medicalConditions;
  final List<EmergencyContact> emergencyContacts;
  final String? completedAt;
  final String? createdAt;
  final String? updatedAt;

  const SosEvent({
    required this.id,
    this.userId,
    this.userName,
    this.userPhone,
    this.hospitalId,
    this.hospitalName,
    this.hospitalAddress,
    this.hospitalLatitude,
    this.hospitalLongitude,
    this.ambulanceId,
    this.ambulanceRegistrationNumber,
    this.driverId,
    this.driverName,
    this.doctorId,
    this.doctorName,
    this.latitude,
    this.longitude,
    this.address,
    required this.status,
    this.symptoms,
    this.criticality,
    this.bloodGroup,
    this.allergies,
    this.medicalConditions,
    this.emergencyContacts = const [],
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory SosEvent.fromJson(Map<String, dynamic> json) {
    final contacts = json['emergencyContacts'] as List<dynamic>?;
    return SosEvent(
      id: json['id'] as int,
      userId: json['userId'] as int?,
      userName: json['userName'] as String?,
      userPhone: json['userPhone'] as String?,
      hospitalId: json['hospitalId'] as int?,
      hospitalName: json['hospitalName'] as String?,
      hospitalAddress: json['hospitalAddress'] as String?,
      hospitalLatitude: (json['hospitalLatitude'] as num?)?.toDouble(),
      hospitalLongitude: (json['hospitalLongitude'] as num?)?.toDouble(),
      ambulanceId: json['ambulanceId'] as int?,
      ambulanceRegistrationNumber:
          json['ambulanceRegistrationNumber'] as String?,
      driverId: json['driverId'] as int?,
      driverName: json['driverName'] as String?,
      doctorId: json['doctorId'] as int?,
      doctorName: json['doctorName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      status: json['status'] as String? ?? 'CREATED',
      symptoms: json['symptoms'] as String?,
      criticality: json['criticality'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      allergies: json['allergies'] as String?,
      medicalConditions: json['medicalConditions'] as String?,
      emergencyContacts: contacts
              ?.map(
                (c) =>
                    EmergencyContact.fromJson(c as Map<String, dynamic>),
              )
              .toList() ??
          [],
      completedAt: json['completedAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  bool get isActive {
    const activeStatuses = [
      'AMBULANCE_ASSIGNED',
      'DRIVER_ENROUTE_TO_PATIENT',
      'REACHED_PATIENT',
      'PICKED_UP',
      'ENROUTE_TO_HOSPITAL',
      'ARRIVED_AT_HOSPITAL',
    ];
    return activeStatuses.contains(status);
  }

  bool get isEnrouteToPatient =>
      status == 'AMBULANCE_ASSIGNED' ||
      status == 'DRIVER_ENROUTE_TO_PATIENT';

  bool get isWithPatient =>
      status == 'REACHED_PATIENT' ||
      status == 'PICKED_UP';

  bool get isEnrouteToHospital => status == 'ENROUTE_TO_HOSPITAL';
}
