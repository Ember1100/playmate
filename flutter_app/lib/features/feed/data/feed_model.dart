class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    required this.mediaUrls,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    this.isLiked = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final userId = json['user_id'] as String;
    return Post(
        id: json['id'] as String,
        userId: userId,
        username: json['username'] as String? ?? userId.substring(0, 8),
        avatarUrl: json['avatar_url'] as String?,
        content: json['content'] as String,
        mediaUrls: (json['media_urls'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        likeCount: json['like_count'] as int? ?? 0,
        commentCount: json['comment_count'] as int? ?? 0,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        isLiked: json['is_liked'] as bool? ?? false,
    );
  }

  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String content;
  final List<String> mediaUrls;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final bool isLiked;

  Post copyWith({
    String? id,
    String? userId,
    String? username,
    String? avatarUrl,
    String? content,
    List<String>? mediaUrls,
    int? likeCount,
    int? commentCount,
    DateTime? createdAt,
    bool? isLiked,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

class CreatePostRequest {
  const CreatePostRequest({required this.content});

  final String content;

  Map<String, dynamic> toJson() => {'content': content};
}
