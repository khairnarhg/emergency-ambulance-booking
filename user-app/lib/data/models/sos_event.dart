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
  final double latitude;
  final double longitude;
  final String? address;
  final String status;
  final String? symptoms;
  final String? criticality;
  final String? bloodGroup;
  final String? allergies;
  final String? medicalConditions;
  final List<SosEmergencyContact>? emergencyContacts;
  final String? completedAt;
  final String createdAt;
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
    required this.latitude,
    required this.longitude,
    this.address,
    required this.status,
    this.symptoms,
    this.criticality,
    this.bloodGroup,
    this.allergies,
    this.medicalConditions,
    this.emergencyContacts,
    this.completedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory SosEvent.fromJson(Map<String, dynamic> json) => SosEvent(
        id: (json['id'] as num).toInt(),
        userId: json['userId'] != null ? (json['userId'] as num).toInt() : null,
        userName: json['userName'] as String?,
        userPhone: json['userPhone'] as String?,
        hospitalId: json['hospitalId'] != null
            ? (json['hospitalId'] as num).toInt()
            : null,
        hospitalName: json['hospitalName'] as String?,
        hospitalAddress: json['hospitalAddress'] as String?,
        hospitalLatitude: json['hospitalLatitude'] != null
            ? double.parse(json['hospitalLatitude'].toString())
            : null,
        hospitalLongitude: json['hospitalLongitude'] != null
            ? double.parse(json['hospitalLongitude'].toString())
            : null,
        ambulanceId: json['ambulanceId'] != null
            ? (json['ambulanceId'] as num).toInt()
            : null,
        ambulanceRegistrationNumber:
            json['ambulanceRegistrationNumber'] as String?,
        driverId: json['driverId'] != null
            ? (json['driverId'] as num).toInt()
            : null,
        driverName: json['driverName'] as String?,
        doctorId:
            json['doctorId'] != null ? (json['doctorId'] as num).toInt() : null,
        doctorName: json['doctorName'] as String?,
        latitude: double.parse(json['latitude'].toString()),
        longitude: double.parse(json['longitude'].toString()),
        address: json['address'] as String?,
        status: json['status'] as String,
        symptoms: json['symptoms'] as String?,
        criticality: json['criticality'] as String?,
        bloodGroup: json['bloodGroup'] as String?,
        allergies: json['allergies'] as String?,
        medicalConditions: json['medicalConditions'] as String?,
        emergencyContacts: json['emergencyContacts'] != null
            ? (json['emergencyContacts'] as List)
                .map((e) =>
                    SosEmergencyContact.fromJson(e as Map<String, dynamic>))
                .toList()
            : null,
        completedAt: json['completedAt'] as String?,
        createdAt: json['createdAt'] as String,
        updatedAt: json['updatedAt'] as String?,
      );

  bool get isActive {
    const activeStatuses = [
      'CREATED',
      'DISPATCHING',
      'AMBULANCE_ASSIGNED',
      'DRIVER_ENROUTE_TO_PATIENT',
      'REACHED_PATIENT',
      'PICKED_UP',
      'ENROUTE_TO_HOSPITAL',
      'ARRIVED_AT_HOSPITAL',
    ];
    return activeStatuses.contains(status);
  }

  bool get isCancellable =>
      status == 'CREATED' || status == 'DISPATCHING';
}

class SosEmergencyContact {
  final int? id;
  final String name;
  final String phone;
  final String? relationship;

  const SosEmergencyContact({
    this.id,
    required this.name,
    required this.phone,
    this.relationship,
  });

  factory SosEmergencyContact.fromJson(Map<String, dynamic> json) =>
      SosEmergencyContact(
        id: json['id'] != null ? (json['id'] as num).toInt() : null,
        name: json['name'] as String,
        phone: json['phone'] as String,
        relationship: json['relationship'] as String?,
      );
}
