import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/im_model.dart';
import '../data/im_repository.dart';

// Conversations list
class ConversationsNotifier extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() async {
    return ref.read(imRepositoryProvider).getConversations();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(imRepositoryProvider).getConversations(),
    );
  }

  /// 乐观清零某会话的未读数（进入聊天时立即调用）
  void clearUnread(String conversationId) {
    state.whenData((list) {
      state = AsyncData(list.map((c) {
        if (c.id != conversationId) return c;
        return Conversation(
          id: c.id,
          otherUserId: c.otherUserId,
          otherUsername: c.otherUsername,
          otherAvatarUrl: c.otherAvatarUrl,
          lastMessage: c.lastMessage,
          lastMessageAt: c.lastMessageAt,
          unreadCount: 0,
        );
      }).toList());
    });
  }
}

final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<Conversation>>(
  ConversationsNotifier.new,
);

// Messages list (read-only)
final messagesProvider =
    FutureProvider.family<List<Message>, String>((ref, conversationId) async {
  return ref.read(imRepositoryProvider).getMessages(conversationId);
});

// Chat notifier (manages messages for a specific conversation)
class ChatNotifier extends FamilyAsyncNotifier<List<Message>, String> {
  @override
  Future<List<Message>> build(String arg) async {
    return ref.read(imRepositoryProvider).getMessages(arg);
  }

  Future<void> sendMessage(String content) async {
    final conversationId = arg;
    // Optimistic update with temporary message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final current = state.valueOrNull ?? [];
    final tempMessage = Message(
      id: tempId,
      conversationId: conversationId,
      senderId: 'me',
      type: 1,
      content: content,
      createdAt: DateTime.now(),
      isRecalled: false,
    );
    state = AsyncData([...current, tempMessage]);

    try {
      final sent = await ref.read(imRepositoryProvider).sendMessage(
            conversationId: conversationId,
            content: content,
          );
      // Replace temp with real
      final updated = (state.valueOrNull ?? [])
          .map((m) => m.id == tempId ? sent : m)
          .toList();
      state = AsyncData(updated);
    } catch (e) {
      // Remove temp on failure
      final rollback =
          (state.valueOrNull ?? []).where((m) => m.id != tempId).toList();
      state = AsyncData(rollback);
      rethrow;
    }
  }

  void addMessage(Message message) {
    final current = state.valueOrNull ?? [];
    // Avoid duplicates
    if (current.any((m) => m.id == message.id)) return;
    state = AsyncData([...current, message]);
  }
}

final chatNotifierProvider =
    AsyncNotifierProviderFamily<ChatNotifier, List<Message>, String>(
  ChatNotifier.new,
);
