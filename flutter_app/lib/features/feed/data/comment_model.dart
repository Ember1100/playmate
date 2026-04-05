import 'package:intl/intl.dart';

class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as String,
        postId: json['post_id'] as String,
        userId: json['user_id'] as String,
        username: json['username'] as String? ??
            (json['user_id'] as String).substring(0, 8),
        avatarUrl: json['avatar_url'] as String?,
        content: json['content'] as String,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String content;
  final DateTime createdAt;

  String get timeStr => DateFormat('MM-dd HH:mm').format(createdAt);
}
