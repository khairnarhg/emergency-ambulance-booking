class AppConstants {
  AppConstants._();

  static const String baseUrl = 'http://10.0.2.2:8080/api';
  static const String osrmBaseUrl = 'https://router.project-osrm.org';

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';

  static const Duration pollInterval = Duration(seconds: 8);
  static const Duration gpsBroadcastInterval = Duration(seconds: 5);
  static const Duration routeRecalcInterval = Duration(seconds: 30);
  static const int requestTimeoutSeconds = 60;

  static const double averageSpeedKmh = 40.0;
}
