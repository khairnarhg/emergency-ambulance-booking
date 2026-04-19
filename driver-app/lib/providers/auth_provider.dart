import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:driver_app/core/constants/app_constants.dart';
import 'package:driver_app/core/network/api_client.dart';
import 'package:driver_app/core/network/websocket_service.dart';
import 'package:driver_app/data/api/auth_api.dart';
import 'package:driver_app/data/models/auth_response.dart';
import 'package:driver_app/data/models/user.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.read(apiClientProvider));
});

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApi _authApi;
  final WebSocketService _wsService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier(this._authApi, this._wsService) : super(const AuthState());

  Future<void> checkAuth() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      state = state.copyWith(status: AuthStatus.authenticated);
      _wsService.connect();
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final AuthResponse response = await _authApi.login(email, password);

      if (!response.user.isDriver) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage:
              'Access denied. This app is for MGM ambulance drivers only.',
        );
        return;
      }

      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: response.accessToken,
      );
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: response.refreshToken,
      );
      await _storage.write(
        key: AppConstants.userIdKey,
        value: response.user.id.toString(),
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.user,
      );

      _wsService.connect();
    } catch (e) {
      String message = 'Login failed. Please try again.';
      if (e.toString().contains('401')) {
        message = 'Invalid email or password.';
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        message = 'Network error. Check your connection.';
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      );
    }
  }

  Future<void> logout() async {
    _wsService.disconnect();
    try {
      await _authApi.logout();
    } catch (_) {}
    await _storage.deleteAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authApiProvider),
    ref.read(websocketServiceProvider),
  );
});
