import 'user.dart';

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserSummary user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresIn: (json['expiresIn'] as num).toInt(),
        user: UserSummary.fromJson(json['user'] as Map<String, dynamic>),
      );
}
