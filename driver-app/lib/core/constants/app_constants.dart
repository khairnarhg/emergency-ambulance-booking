class AppConstants {
  AppConstants._();

  // Using ADB reverse: adb reverse tcp:8080 tcp:8080
  static const String baseUrl = 'http://127.0.0.1:8080/api';
  static const String wsBaseUrl = 'http://127.0.0.1:8080/ws';
  static const String osrmBaseUrl = 'https://router.project-osrm.org';

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';

  static const Duration pollInterval = Duration(seconds: 30);
  static const Duration notificationPollInterval = Duration(seconds: 60);
  static const Duration gpsBroadcastInterval = Duration(seconds: 5);
  static const Duration routeRecalcInterval = Duration(seconds: 30);
  static const int requestTimeoutSeconds = 60;

  static const double averageSpeedKmh = 40.0;
}
