import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

class UploadService {
  UploadService(this._client);

  final ApiClient _client;

  Future<String> uploadAvatar(File file) => _upload(file, 'avatar');
  Future<String> uploadPostImage(File file) => _upload(file, 'post');
  Future<String> uploadVoice(File file) => _upload(file, 'voice');

  Future<String> _upload(File file, String type) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
    final contentType = _extToContentType(ext);

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: DioMediaType.parse(contentType),
      ),
    });

    final resp = await _client.dio.post<Map<String, dynamic>>(
      '/upload/$type',
      data: formData,
    );

    final data = (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return data['url'] as String;
  }

  String _extToContentType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'm4a':
        return 'audio/m4a';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }
}

final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService(ref.watch(apiClientProvider));
});
