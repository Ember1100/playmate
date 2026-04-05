import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({required this.code, required this.message});

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return ApiException(
        code: data['code'] as String? ?? 'ERROR',
        message: data['message'] as String,
      );
    }
    return ApiException(
      code: 'NETWORK_ERROR',
      message: _networkMessage(e.type),
    );
  }

  final String code;
  final String message;

  static String _networkMessage(DioExceptionType type) => switch (type) {
        DioExceptionType.connectionTimeout => '连接超时，请检查网络',
        DioExceptionType.receiveTimeout => '服务器响应超时',
        DioExceptionType.connectionError => '无法连接到服务器',
        _ => '网络请求失败',
      };

  @override
  String toString() => message;
}
