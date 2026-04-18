class Conversation {
  const Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUsername,
    this.otherAvatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // 兼容两种后端格式：扁平字段 vs other_user 嵌套对象
    final otherUser = json['other_user'] as Map<String, dynamic>?;
    return Conversation(
      id: json['id'] as String,
      otherUserId: otherUser?['id'] as String? ?? json['other_user_id'] as String? ?? '',
      otherUsername: otherUser?['username'] as String? ?? json['other_username'] as String? ?? '未知用户',
      otherAvatarUrl: otherUser?['avatar_url'] as String? ?? json['other_avatar_url'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'] as String)?.toLocal()
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  final String id;
  final String otherUserId;
  final String otherUsername;
  final String? otherAvatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
}

// ── 群聊会话（搭子局 / 社群）────────────────────────────────────────────────

class GroupSession {
  const GroupSession({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    required this.memberCount,
  });

  factory GroupSession.fromJson(Map<String, dynamic> json) => GroupSession(
        id: json['id'] as String,
        name: json['name'] as String? ?? '群聊',
        avatarUrl: json['avatar_url'] as String?,
        lastMessage: json['last_message'] as String?,
        lastMessageAt: json['last_message_at'] != null
            ? DateTime.tryParse(json['last_message_at'] as String)?.toLocal()
            : null,
        unreadCount: json['unread_count'] as int? ?? 0,
        memberCount: json['member_count'] as int? ?? 0,
      );

  final String id;
  final String name;
  final String? avatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final int memberCount;

  static final mockList = <GroupSession>[
    GroupSession(
      id: 'mock-group-1',
      name: '🏃 晨跑搭子局',
      lastMessage: '小赵：明早六点操场见！',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 15)),
      unreadCount: 3,
      memberCount: 8,
    ),
    GroupSession(
      id: 'mock-group-2',
      name: '🏔️ 周末爬山队',
      lastMessage: '路线已发群里，记得带水',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 4)),
      unreadCount: 1,
      memberCount: 12,
    ),
  ];
}

// ── 群聊消息 ──────────────────────────────────────────────────────────────────

class GroupMessage {
  const GroupMessage({
    required this.id,
    required this.groupId,
    this.senderId,
    required this.senderUsername,
    this.senderAvatarUrl,
    required this.type,
    this.content,
    this.mediaUrl,
    required this.isRecalled,
    required this.createdAt,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) => GroupMessage(
        id: json['id'] as String,
        groupId: json['group_id'] as String,
        senderId: json['sender_id'] as String?,
        senderUsername: json['sender_username'] as String? ?? '系统',
        senderAvatarUrl: json['sender_avatar_url'] as String?,
        type: json['msg_type'] as int? ?? json['type'] as int? ?? 1,
        content: json['content'] as String?,
        mediaUrl: json['media_url'] as String?,
        isRecalled: json['is_recalled'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      );

  final String id;
  final String groupId;
  final String? senderId;
  final String senderUsername;
  final String? senderAvatarUrl;
  final int type;
  final String? content;
  final String? mediaUrl;
  final bool isRecalled;
  final DateTime createdAt;

  /// type=99 表示系统通知消息（进群/退群等）
  bool get isSystemMsg => type == 99;
}

// ── 通知 ──────────────────────────────────────────────────────────────────────

enum NotificationType { system, buddyRequest, invitation, interaction }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.relatedId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        type: switch (json['type'] as String? ?? '') {
          'buddy_request' => NotificationType.buddyRequest,
          'invitation'    => NotificationType.invitation,
          'interaction'   => NotificationType.interaction,
          _               => NotificationType.system,
        },
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
        relatedId: json['related_id'] as String?,
      );

  final String id;
  final NotificationType type;
  final String title;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final String? relatedId;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id, type: type, title: title, content: content,
        isRead: isRead ?? this.isRead, createdAt: createdAt, relatedId: relatedId,
      );

  static final mockList = <AppNotification>[
    AppNotification(
      id: 'mock-notif-sys-1',
      type: NotificationType.system,
      title: '平台公告',
      content: '搭伴新功能「搭子局」正式上线！快去约起来吧 🎉',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    AppNotification(
      id: 'mock-notif-buddy-1',
      type: NotificationType.buddyRequest,
      title: '新的搭子申请',
      content: '陈思远 想和你成为搭子，备注：喜欢跑步，一起约？',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      relatedId: 'mock-request-1',
    ),
    AppNotification(
      id: 'mock-notif-interact-1',
      type: NotificationType.interaction,
      title: '点赞了你的话题',
      content: '小赵 赞了你发布的话题「最近发现一条绝美骑行路线」',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      relatedId: 'mock-topic-1',
    ),
  ];
}

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    this.content,
    this.mediaUrl,
    required this.createdAt,
    required this.isRecalled,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        senderId: json['sender_id'] as String,
        type: json['msg_type'] as int? ?? json['type'] as int? ?? 1,
        content: json['content'] as String?,
        mediaUrl: json['media_url'] as String?,
        createdAt: (DateTime.tryParse(json['created_at'] as String? ?? '')
                    ?.toLocal()) ??
            DateTime.now(),
        isRecalled: json['is_recalled'] as bool? ?? false,
      );

  final String id;
  final String conversationId;
  final String senderId;
  final int type;
  final String? content;
  final String? mediaUrl;
  final DateTime createdAt;
  final bool isRecalled;
}
