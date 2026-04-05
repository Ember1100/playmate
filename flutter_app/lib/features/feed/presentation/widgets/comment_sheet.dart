import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/comment_model.dart';
import '../../data/comment_repository.dart';
import '../../providers/feed_provider.dart';
import '../../../profile/presentation/screens/liked_posts_screen.dart';

// Provider: 每个 postId 独立的评论列表
final commentsProvider = FutureProvider.autoDispose
    .family<List<Comment>, String>((ref, postId) async {
  return ref.read(commentRepositoryProvider).getComments(postId);
});

void showCommentSheet(BuildContext context, String postId, int commentCount) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _CommentSheet(postId: postId, initialCount: commentCount),
  );
}

class _CommentSheet extends ConsumerStatefulWidget {
  const _CommentSheet({required this.postId, required this.initialCount});
  final String postId;
  final int initialCount;

  @override
  ConsumerState<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<_CommentSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref.read(commentRepositoryProvider).createComment(widget.postId, text);
      _controller.clear();
      ref.invalidate(commentsProvider(widget.postId));
      ref.read(feedProvider.notifier).incrementCommentCount(widget.postId);
      ref.read(likedPostsProvider.notifier).incrementCommentCount(widget.postId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评论失败，请重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Text('评论',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(width: 6),
                commentsAsync.when(
                  data: (list) => Text('${list.length}',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // 评论列表
          Expanded(
            child: commentsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('加载失败',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
              data: (comments) {
                if (comments.isEmpty) {
                  return const Center(
                    child: Text('暂无评论，来说点什么吧',
                        style:
                            TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: comments.length,
                  itemBuilder: (_, i) => _CommentItem(comment: comments[i]),
                );
              },
            ),
          ),

          // 输入栏
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: '说点什么...',
                      hintStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submitting ? null : _submit,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _submitting
                          ? AppColors.border
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _submitting
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  const _CommentItem({required this.comment});
  final Comment comment;

  static const _colors = [
    Color(0xFF7F77DD),
    Color(0xFF4ECDC4),
    Color(0xFFFF6B6B),
    Color(0xFFFFBE0B),
    Color(0xFF06D6A0),
  ];

  @override
  Widget build(BuildContext context) {
    final code = comment.userId.codeUnits.fold(0, (a, b) => a + b);
    final color = _colors[code % _colors.length];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color,
            child: Text(
              comment.username.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.username,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const Spacer(),
                    Text(comment.timeStr,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
