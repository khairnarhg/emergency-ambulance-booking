class Driver {
  final int id;
  final int userId;
  final String? name;
  final String? email;
  final String? phone;
  final String? licenseNumber;
  final String status;
  final int? hospitalId;
  final String? hospitalName;
  final int? ambulanceId;
  final String? ambulanceRegistrationNumber;

  const Driver({
    required this.id,
    required this.userId,
    this.name,
    this.email,
    this.phone,
    this.licenseNumber,
    required this.status,
    this.hospitalId,
    this.hospitalName,
    this.ambulanceId,
    this.ambulanceRegistrationNumber,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as int,
      userId: json['userId'] as int? ?? 0,
      name: json['fullName'] as String? ?? json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      status: json['status'] as String? ?? 'OFFLINE',
      hospitalId: json['hospitalId'] as int?,
      hospitalName: json['hospitalName'] as String?,
      ambulanceId: json['ambulanceId'] as int?,
      ambulanceRegistrationNumber:
          json['ambulanceRegistrationNumber'] as String?,
    );
  }

  bool get isAvailable => status == 'AVAILABLE';
  bool get isOffline => status == 'OFFLINE';
  bool get isBusy => status == 'BUSY';
}
