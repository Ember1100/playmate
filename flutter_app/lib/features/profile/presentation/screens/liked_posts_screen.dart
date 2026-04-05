import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../feed/data/feed_model.dart';
import '../../../feed/presentation/widgets/comment_sheet.dart';
import '../../../feed/providers/feed_provider.dart';

final likedPostsProvider =
    AsyncNotifierProvider<LikedPostsNotifier, List<Post>>(
        LikedPostsNotifier.new);

class LikedPostsNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() => _fetch();

  Future<List<Post>> _fetch() async {
    final client = ref.read(apiClientProvider);
    final resp = await client
        .get<Map<String, dynamic>>('/feed/posts/liked', params: {'limit': 50});
    final data = resp['data'] as Map<String, dynamic>? ?? {};
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  void incrementCommentCount(String postId) {
    state.whenData((posts) {
      state = AsyncData(posts.map((p) {
        if (p.id != postId) return p;
        return p.copyWith(commentCount: p.commentCount + 1);
      }).toList());
    });
  }

  void toggleLike(String postId) {
    state.whenData((posts) {
      state = AsyncData(posts.map((p) {
        if (p.id != postId) return p;
        return p.copyWith(
          isLiked: !p.isLiked,
          likeCount: p.isLiked ? p.likeCount - 1 : p.likeCount + 1,
        );
      }).toList());
    });
  }
}

class LikedPostsScreen extends ConsumerWidget {
  const LikedPostsScreen({super.key});

  static const _colors = [
    Color(0xFF7F77DD),
    Color(0xFF4ECDC4),
    Color(0xFFFF6B6B),
    Color(0xFFFFBE0B),
    Color(0xFF06D6A0),
  ];

  Color _colorFor(String id) {
    final code = id.codeUnits.fold(0, (a, b) => a + b);
    return _colors[code % _colors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(likedPostsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('我的点赞'),
      ),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('加载失败',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.read(likedPostsProvider.notifier).refresh(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('还没有点赞任何动态',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(likedPostsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: posts.length,
              itemBuilder: (context, i) {
                final post = posts[i];
                return _LikedPostCard(
                  post: post,
                  color: _colorFor(post.userId),
                  onLike: () async {
                    ref
                        .read(likedPostsProvider.notifier)
                        .toggleLike(post.id);
                    await ref
                        .read(feedProvider.notifier)
                        .toggleLike(post.id);
                  },
                  onComment: () =>
                      showCommentSheet(context, post.id, post.commentCount),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _LikedPostCard extends StatelessWidget {
  const _LikedPostCard({
    required this.post,
    required this.color,
    required this.onLike,
    required this.onComment,
  });

  final Post post;
  final Color color;
  final VoidCallback onLike;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('MM-dd HH:mm').format(post.createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color,
                child: Text(
                  post.username.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.username,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    Text(timeStr,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(post.content,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textPrimary, height: 1.5),
              maxLines: 4,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                child: Row(
                  children: [
                    Icon(
                      post.isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: post.isLiked ? Colors.red : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text('${post.likeCount}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: onComment,
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${post.commentCount}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
