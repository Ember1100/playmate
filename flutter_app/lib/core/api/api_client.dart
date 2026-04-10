import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl: '${AppConstants.baseUrl}${AppConstants.apiPrefix}',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token 过期，尝试刷新
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            // 重试原请求
            final token = await _storage.getAccessToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
          await _storage.clear();
        }
        handler.next(error);
      },
    ));
  }

  late final Dio _dio;
  final TokenStorage _storage;

  Dio get dio => _dio;

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;
      final resp = await Dio().post(
        '${AppConstants.baseUrl}${AppConstants.apiPrefix}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = resp.data['data'];
      await _storage.saveAccessToken(data['access_token'] as String);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? params}) async {
    final resp = await _dio.get(path, queryParameters: params);
    return resp.data as T;
  }

  Future<T> post<T>(String path, {dynamic data}) async {
    final resp = await _dio.post(path, data: data);
    return resp.data as T;
  }

  Future<T> put<T>(String path, {dynamic data}) async {
    final resp = await _dio.put(path, data: data);
    return resp.data as T;
  }

  Future<T> delete<T>(String path) async {
    final resp = await _dio.delete(path);
    return resp.data as T;
  }
}

// Providers
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(storage);
});
