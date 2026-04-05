import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'comment_model.dart';

class CommentRepository {
  const CommentRepository(this._client);
  final ApiClient _client;

  Future<List<Comment>> getComments(String postId, {int page = 1}) async {
    final resp = await _client.get<Map<String, dynamic>>(
      '/feed/posts/$postId/comments',
      params: {'page': page, 'limit': 50},
    );
    final data = resp['data'] as Map<String, dynamic>? ?? {};
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Comment> createComment(String postId, String content) async {
    final resp = await _client.post<Map<String, dynamic>>(
      '/feed/posts/$postId/comments',
      data: {'content': content},
    );
    return Comment.fromJson(resp['data'] as Map<String, dynamic>);
  }
}

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(ref.watch(apiClientProvider));
});
