class TrackingInfo {
  final int sosEventId;
  final String status;
  final double? ambulanceLatitude;
  final double? ambulanceLongitude;
  final String? driverName;
  final String? driverPhone;
  final String? ambulanceRegistrationNumber;
  final String? hospitalName;
  final String? hospitalAddress;
  final int? estimatedMinutesArrival;
  final List<LocationPoint> locationHistory;

  const TrackingInfo({
    required this.sosEventId,
    required this.status,
    this.ambulanceLatitude,
    this.ambulanceLongitude,
    this.driverName,
    this.driverPhone,
    this.ambulanceRegistrationNumber,
    this.hospitalName,
    this.hospitalAddress,
    this.estimatedMinutesArrival,
    required this.locationHistory,
  });

  factory TrackingInfo.fromJson(Map<String, dynamic> json) => TrackingInfo(
        sosEventId: (json['sosEventId'] as num).toInt(),
        status: json['status'] as String,
        ambulanceLatitude: json['ambulanceLatitude'] != null
            ? double.parse(json['ambulanceLatitude'].toString())
            : null,
        ambulanceLongitude: json['ambulanceLongitude'] != null
            ? double.parse(json['ambulanceLongitude'].toString())
            : null,
        driverName: json['driverName'] as String?,
        driverPhone: json['driverPhone'] as String?,
        ambulanceRegistrationNumber:
            json['ambulanceRegistrationNumber'] as String?,
        hospitalName: json['hospitalName'] as String?,
        hospitalAddress: json['hospitalAddress'] as String?,
        estimatedMinutesArrival: json['estimatedMinutesArrival'] != null
            ? (json['estimatedMinutesArrival'] as num).toInt()
            : null,
        locationHistory: json['locationHistory'] != null
            ? (json['locationHistory'] as List)
                .map((e) => LocationPoint.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
      );

  bool get hasAmbulanceLocation =>
      ambulanceLatitude != null && ambulanceLongitude != null;
}

class LocationPoint {
  final double latitude;
  final double longitude;
  final String? recordedAt;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    this.recordedAt,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) => LocationPoint(
        latitude: double.parse(json['latitude'].toString()),
        longitude: double.parse(json['longitude'].toString()),
        recordedAt: json['recordedAt'] as String?,
      );
}
