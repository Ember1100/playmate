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

// ── Group sessions provider ───────────────────────────────────────────────────

class GroupSessionsNotifier extends AsyncNotifier<List<GroupSession>> {
  @override
  Future<List<GroupSession>> build() =>
      ref.read(imRepositoryProvider).getGroupSessions();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(imRepositoryProvider).getGroupSessions(),
    );
  }
}

final groupSessionsProvider =
    AsyncNotifierProvider<GroupSessionsNotifier, List<GroupSession>>(
  GroupSessionsNotifier.new,
);

// ── Notifications provider ────────────────────────────────────────────────────

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() =>
      ref.read(imRepositoryProvider).getNotifications();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(imRepositoryProvider).getNotifications(),
    );
  }

  void markRead(String id) {
    state.whenData((list) {
      state = AsyncData(list.map((n) {
        return n.id == id ? n.copyWith(isRead: true) : n;
      }).toList());
    });
    // fire-and-forget 通知后端
    ref.read(imRepositoryProvider).markNotificationRead(id);
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

// ── Group chat provider ───────────────────────────────────────────────────────

class GroupChatNotifier extends FamilyAsyncNotifier<List<GroupMessage>, String> {
  @override
  Future<List<GroupMessage>> build(String arg) =>
      ref.read(imRepositoryProvider).getGroupMessages(arg);

  void addMessage(GroupMessage msg) {
    state.whenData((list) {
      if (list.any((m) => m.id == msg.id)) return;
      state = AsyncData([...list, msg]);
    });
  }
}

final groupChatProvider =
    AsyncNotifierProviderFamily<GroupChatNotifier, List<GroupMessage>, String>(
  GroupChatNotifier.new,
);

// ── Messages list (read-only) ─────────────────────────────────────────────────

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
