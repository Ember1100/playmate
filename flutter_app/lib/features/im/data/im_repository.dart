import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'im_model.dart';

class ImRepository {
  ImRepository(this._client);

  final ApiClient _client;

  Future<List<Conversation>> getConversations() async {
    final resp = await _client.get<Map<String, dynamic>>('/im/conversations');
    final data = resp['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Message>> getMessages(String conversationId,
      {int page = 1}) async {
    final resp = await _client.get<Map<String, dynamic>>(
      '/im/conversations/$conversationId/messages',
      params: {'page': page},
    );
    final pageData = resp['data'] as Map<String, dynamic>? ?? {};
    final items = pageData['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final resp = await _client.post<Map<String, dynamic>>(
      '/im/conversations/$conversationId/messages',
      data: {'type': 1, 'content': content},
    );
    return Message.fromJson(resp['data'] as Map<String, dynamic>);
  }

  Future<String> createConversation(String userId) async {
    final resp = await _client.post<Map<String, dynamic>>(
      '/im/conversations',
      data: {'target_user_id': userId},
    );
    final data = resp['data'] as Map<String, dynamic>;
    return data['id'] as String;
  }
}

final imRepositoryProvider = Provider<ImRepository>((ref) {
  return ImRepository(ref.watch(apiClientProvider));
});
