class AppConstants {
  // Base URLs
  static const String baseUrlEmulator = 'http://10.0.2.2:8080';
  static const String baseUrlDevice = 'http://localhost:8080';
  static const String baseUrl = baseUrlEmulator;

  // API paths
  static const String apiPrefix = '/api';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userNameKey = 'user_name';
  static const String userPhoneKey = 'user_phone';

  // Timeouts
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;

  // Polling
  static const int trackingPollIntervalSeconds = 7;
  static const int notificationPollIntervalSeconds = 30;

  // Map
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmUserAgent = 'com.rakshapoorvak.userapp';
  static const double defaultMapZoom = 15.0;
  static const double defaultLat = 19.0760; // Mumbai fallback
  static const double defaultLng = 72.8777;

  // SOS statuses
  static const String statusCreated = 'CREATED';
  static const String statusDispatching = 'DISPATCHING';
  static const String statusAmbulanceAssigned = 'AMBULANCE_ASSIGNED';
  static const String statusDriverEnroute = 'DRIVER_ENROUTE_TO_PATIENT';
  static const String statusReachedPatient = 'REACHED_PATIENT';
  static const String statusPickedUp = 'PICKED_UP';
  static const String statusEnrouteHospital = 'ENROUTE_TO_HOSPITAL';
  static const String statusArrivedHospital = 'ARRIVED_AT_HOSPITAL';
  static const String statusCompleted = 'COMPLETED';
  static const String statusCancelled = 'CANCELLED';

  // Criticality
  static const String criticalityLow = 'LOW';
  static const String criticalityMedium = 'MEDIUM';
  static const String criticalityHigh = 'HIGH';
  static const String criticalityCritical = 'CRITICAL';

  // Active statuses (polling needed)
  static const List<String> activeStatuses = [
    statusCreated,
    statusDispatching,
    statusAmbulanceAssigned,
    statusDriverEnroute,
    statusReachedPatient,
    statusPickedUp,
    statusEnrouteHospital,
    statusArrivedHospital,
  ];

  // Cancellable statuses
  static const List<String> cancellableStatuses = [
    statusCreated,
    statusDispatching,
  ];
}
