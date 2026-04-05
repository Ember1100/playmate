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

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String,
        otherUserId: json['other_user_id'] as String? ?? '',
        otherUsername: json['other_username'] as String? ?? '未知用户',
        otherAvatarUrl: json['other_avatar_url'] as String?,
        lastMessage: json['last_message'] as String?,
        lastMessageAt: json['last_message_at'] != null
            ? DateTime.tryParse(json['last_message_at'] as String)
            : null,
        unreadCount: json['unread_count'] as int? ?? 0,
      );

  final String id;
  final String otherUserId;
  final String otherUsername;
  final String? otherAvatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
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
        type: json['type'] as int? ?? 1,
        content: json['content'] as String?,
        mediaUrl: json['media_url'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
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
