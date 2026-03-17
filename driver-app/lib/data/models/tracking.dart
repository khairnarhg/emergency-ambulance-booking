class LocationHistory {
  final double latitude;
  final double longitude;
  final String? recordedAt;

  const LocationHistory({
    required this.latitude,
    required this.longitude,
    this.recordedAt,
  });

  factory LocationHistory.fromJson(Map<String, dynamic> json) {
    return LocationHistory(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      recordedAt: json['recordedAt'] as String?,
    );
  }
}

class Tracking {
  final int sosEventId;
  final String? status;
  final double? ambulanceLatitude;
  final double? ambulanceLongitude;
  final String? driverName;
  final String? driverPhone;
  final String? ambulanceRegistrationNumber;
  final String? hospitalName;
  final String? hospitalAddress;
  final int? estimatedMinutesArrival;
  final List<LocationHistory> locationHistory;

  const Tracking({
    required this.sosEventId,
    this.status,
    this.ambulanceLatitude,
    this.ambulanceLongitude,
    this.driverName,
    this.driverPhone,
    this.ambulanceRegistrationNumber,
    this.hospitalName,
    this.hospitalAddress,
    this.estimatedMinutesArrival,
    this.locationHistory = const [],
  });

  factory Tracking.fromJson(Map<String, dynamic> json) {
    final history = json['locationHistory'] as List<dynamic>?;
    return Tracking(
      sosEventId: json['sosEventId'] as int,
      status: json['status'] as String?,
      ambulanceLatitude: (json['ambulanceLatitude'] as num?)?.toDouble(),
      ambulanceLongitude: (json['ambulanceLongitude'] as num?)?.toDouble(),
      driverName: json['driverName'] as String?,
      driverPhone: json['driverPhone'] as String?,
      ambulanceRegistrationNumber:
          json['ambulanceRegistrationNumber'] as String?,
      hospitalName: json['hospitalName'] as String?,
      hospitalAddress: json['hospitalAddress'] as String?,
      estimatedMinutesArrival: json['estimatedMinutesArrival'] as int?,
      locationHistory: history
              ?.map(
                (h) =>
                    LocationHistory.fromJson(h as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}
