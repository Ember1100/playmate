import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'feed_model.dart';

class FeedRepository {
  FeedRepository(this._client);

  final ApiClient _client;

  Future<List<Post>> getPosts({int page = 1, int limit = 20}) async {
    final resp = await _client.get<Map<String, dynamic>>(
      '/feed/posts',
      params: {'page': page, 'limit': limit},
    );
    final pageData = resp['data'] as Map<String, dynamic>? ?? {};
    final items = pageData['items'] as List<dynamic>? ?? [];
    return items.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Post> createPost(String content) async {
    final resp = await _client.post<Map<String, dynamic>>(
      '/feed/posts',
      data: {'content': content},
    );
    return Post.fromJson(resp['data'] as Map<String, dynamic>);
  }

  Future<void> toggleLike(String postId) async {
    await _client.post<dynamic>('/feed/posts/$postId/like');
  }
}

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.watch(apiClientProvider));
});
