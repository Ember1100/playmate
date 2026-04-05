import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_model.dart';

class AuthRepository {
  const AuthRepository(this._client, this._storage);

  final ApiClient _client;
  final TokenStorage _storage;

  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final resp = await _client.post<Map<String, dynamic>>('/auth/register',
          data: {'username': username, 'email': email, 'password': password});
      final auth = AuthResponse.fromJson(resp['data'] as Map<String, dynamic>);
      await _storage.saveTokens(
          accessToken: auth.accessToken, refreshToken: auth.refreshToken);
      return auth;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await _client.post<Map<String, dynamic>>('/auth/login',
          data: {'email': email, 'password': password});
      final auth = AuthResponse.fromJson(resp['data'] as Map<String, dynamic>);
      await _storage.saveTokens(
          accessToken: auth.accessToken, refreshToken: auth.refreshToken);
      return auth;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 开发环境快速登录（phone = 手机号，password = DEV_PASSWORD）
  Future<AuthResponse> devLogin({
    required String phone,
    required String password,
    String? username,
  }) async {
    try {
      final resp = await _client.post<Map<String, dynamic>>(
        '/auth/dev/login',
        data: {'phone': phone, 'password': password, if (username != null) 'username': username},
      );
      final auth = AuthResponse.fromJson(resp['data'] as Map<String, dynamic>);
      await _storage.saveTokens(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
      );
      return auth;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } catch (_) {}
    await _storage.clear();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getAccessToken();
    return token != null;
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final resp = await _client.get<Map<String, dynamic>>('/users/me');
      return UserModel.fromJson(resp['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});
