import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../data/api/auth_api.dart';
import '../data/models/auth_response.dart';
import '../data/models/user.dart';

// Current user state
class AuthState {
  final UserSummary? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserSummary? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApi _authApi;
  final FlutterSecureStorage _storage;

  AuthNotifier(this._authApi, this._storage) : super(const AuthState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      final id = await _storage.read(key: AppConstants.userIdKey);
      final email = await _storage.read(key: AppConstants.userEmailKey);
      final name = await _storage.read(key: AppConstants.userNameKey);
      final phone = await _storage.read(key: AppConstants.userPhoneKey);
      if (id != null && email != null && name != null) {
        state = AuthState(
          isAuthenticated: true,
          user: UserSummary(
            id: int.tryParse(id) ?? 0,
            email: email,
            fullName: name,
            phone: phone,
            roles: const ['USER'],
          ),
        );
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authApi.login(email, password);
      await _saveAuth(response);
      state = AuthState(
        isAuthenticated: true,
        user: response.user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authApi.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      await _saveAuth(response);
      state = AuthState(
        isAuthenticated: true,
        user: response.user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authApi.logout();
    await _storage.deleteAll();
    state = const AuthState();
  }

  Future<void> _saveAuth(AuthResponse response) async {
    await _storage.write(
        key: AppConstants.accessTokenKey, value: response.accessToken);
    await _storage.write(
        key: AppConstants.refreshTokenKey, value: response.refreshToken);
    await _storage.write(
        key: AppConstants.userIdKey, value: response.user.id.toString());
    await _storage.write(
        key: AppConstants.userEmailKey, value: response.user.email);
    await _storage.write(
        key: AppConstants.userNameKey, value: response.user.fullName);
    if (response.user.phone != null) {
      await _storage.write(
          key: AppConstants.userPhoneKey, value: response.user.phone!);
    }
  }

  String _extractError(dynamic e) {
    return e.toString().replaceAll('Exception: ', '');
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authApiProvider),
    const FlutterSecureStorage(),
  );
});

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});

final currentUserProvider = Provider<UserSummary?>((ref) {
  return ref.watch(authNotifierProvider).user;
});
