import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:driver_app/core/constants/app_constants.dart';

class ApiClient {
  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isRefreshing = false;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.accessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;
            try {
              final refreshed = await _refreshToken();
              if (refreshed) {
                final token = await _storage.read(
                  key: AppConstants.accessTokenKey,
                );
                error.requestOptions.headers['Authorization'] =
                    'Bearer $token';
                final response = await dio.fetch(error.requestOptions);
                _isRefreshing = false;
                return handler.resolve(response);
              }
            } catch (_) {
              await _clearTokens();
            }
            _isRefreshing = false;
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _storage.read(
      key: AppConstants.refreshTokenKey,
    );
    if (refreshToken == null) return false;

    try {
      final response = await Dio(
        BaseOptions(baseUrl: AppConstants.baseUrl),
      ).post('/auth/refresh', data: {'refreshToken': refreshToken});

      final data = response.data as Map<String, dynamic>;
      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: data['accessToken'] as String,
      );
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _clearTokens() async {
    await _storage.deleteAll();
  }
}
