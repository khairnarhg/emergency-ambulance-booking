import 'package:driver_app/core/network/api_client.dart';
import 'package:driver_app/data/models/auth_response.dart';

class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  Future<AuthResponse> login(String email, String password) async {
    final response = await _client.dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _client.dio.post('/auth/logout');
  }

  Future<AuthResponse> refresh(String refreshToken) async {
    final response = await _client.dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
