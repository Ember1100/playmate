import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../data/im_model.dart';
import '../data/im_repository.dart';
import '../data/websocket_service.dart';

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

  /// 进入群聊时乐观清零未读数
  void clearGroupUnread(String groupId) {
    state.whenData((list) {
      state = AsyncData(list.map((g) {
        if (g.id != groupId) return g;
        return GroupSession(
          id: g.id,
          name: g.name,
          avatarUrl: g.avatarUrl,
          lastMessage: g.lastMessage,
          lastMessageAt: g.lastMessageAt,
          unreadCount: 0,
          memberCount: g.memberCount,
        );
      }).toList());
    });
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
    final current = state.valueOrNull ?? [];
    if (current.any((m) => m.id == msg.id)) return;
    state = AsyncData([...current, msg]);
  }

  /// 用服务端确认消息替换 temp 消息；若 temp 已丢失则直接追加
  void replaceTempOrAdd(GroupMessage msg) {
    final current = state.valueOrNull ?? [];
    // 已有相同真实 ID → 去重
    if (current.any((m) => m.id == msg.id)) return;
    // 找最近一条 temp 且内容相同的消息（同一发送操作）
    final tempIdx = current.lastIndexWhere(
      (m) => m.id.startsWith('temp_') && m.content == msg.content,
    );
    if (tempIdx != -1) {
      final updated = List<GroupMessage>.from(current);
      updated[tempIdx] = msg;
      state = AsyncData(updated);
    } else {
      state = AsyncData([...current, msg]);
    }
  }
}

final groupChatProvider =
    AsyncNotifierProviderFamily<GroupChatNotifier, List<GroupMessage>, String>(
  GroupChatNotifier.new,
);

// ── 全局 WS 连接 + 消息分发器 ─────────────────────────────────────────────────────
//
// 在 PmBottomNav 中 watch，确保用户登录后立即建立 WS 连接并实时刷新未读数。
// WebSocketService 内部有防重连守卫，多次 connect 调用相同 token 不会重建连接。

final wsHandlerProvider = Provider<void>((ref) {
  final wsService    = ref.read(wsServiceProvider);
  final tokenStorage = ref.read(tokenStorageProvider);

  // 异步连接（fire-and-forget；WebSocketService 内部防重连）
  tokenStorage.getAccessToken().then((token) {
    if (token != null) wsService.connect(token);
  });

  // 监听消息，实时更新各 provider 以驱动角标重绘
  final sub = wsService.messages.listen((data) {
    switch (data['type'] as String?) {
      case 'new_message':
        ref.read(conversationsProvider.notifier).refresh();
      case 'new_group_message':
        ref.read(groupSessionsProvider.notifier).refresh();
      case 'new_notification':
        ref.read(notificationsProvider.notifier).refresh();
    }
  });

  ref.onDispose(sub.cancel);
});

// ── Total unread count (for bottom nav badge) ─────────────────────────────────

/// 汇总所有未读数：DM + 群聊 + 通知
final totalUnreadCountProvider = Provider<int>((ref) {
  final dmUnread = ref.watch(conversationsProvider).valueOrNull
          ?.fold(0, (sum, c) => sum + c.unreadCount) ??
      0;
  final groupUnread = ref.watch(groupSessionsProvider).valueOrNull
          ?.fold(0, (sum, g) => sum + g.unreadCount) ??
      0;
  final notifUnread = ref.watch(notificationsProvider).valueOrNull
          ?.where((n) => !n.isRead)
          .length ??
      0;
  return dmUnread + groupUnread + notifUnread;
});

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
