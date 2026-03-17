import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: '${AppConstants.baseUrl}${AppConstants.apiPrefix}',
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
      contentType: 'application/json',
      responseType: ResponseType.json,
    ));

    _dio.interceptors.add(_AuthInterceptor(_dio, _storage));
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      error: true,
    ));
  }

  Dio get dio => _dio;
}

class _AuthInterceptor extends QueuedInterceptorsWrapper {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  bool _isRefreshing = false;

  _AuthInterceptor(this._dio, this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken =
            await _storage.read(key: AppConstants.refreshTokenKey);
        if (refreshToken == null) {
          await _clearAndRedirect();
          handler.next(err);
          return;
        }

        final refreshDio = Dio(BaseOptions(
          baseUrl: '${AppConstants.baseUrl}${AppConstants.apiPrefix}',
        ));
        final response = await refreshDio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        final newToken = response.data['accessToken'] as String?;
        final newRefresh = response.data['refreshToken'] as String?;
        if (newToken != null) {
          await _storage.write(
              key: AppConstants.accessTokenKey, value: newToken);
          if (newRefresh != null) {
            await _storage.write(
                key: AppConstants.refreshTokenKey, value: newRefresh);
          }

          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await _dio.fetch(opts);
          handler.resolve(retryResponse);
          return;
        }
      } catch (_) {
        await _clearAndRedirect();
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }

  Future<void> _clearAndRedirect() async {
    await _storage.deleteAll();
  }
}

String extractErrorMessage(dynamic error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final errorObj = data['error'];
      if (errorObj is Map) {
        return errorObj['message']?.toString() ?? 'Something went wrong';
      }
      return data['message']?.toString() ?? 'Something went wrong';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your network.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Connection failed. Please check your internet.';
    }
  }
  return 'Something went wrong. Please try again.';
}
