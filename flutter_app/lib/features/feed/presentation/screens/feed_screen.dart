import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../shared/widgets/pm_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/upload_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../im/data/im_repository.dart';
import '../../data/feed_model.dart';
import '../../presentation/widgets/comment_sheet.dart';
import '../../providers/feed_provider.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  static const _avatarColors = [
    Color(0xFF7F77DD),
    Color(0xFF4ECDC4),
    Color(0xFFFF6B6B),
    Color(0xFFFFBE0B),
    Color(0xFF06D6A0),
  ];

  Color _colorForUserId(String userId) {
    final code = userId.codeUnits.fold(0, (a, b) => a + b);
    return _avatarColors[code % _avatarColors.length];
  }

  void _showCreatePostSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CreatePostSheet(
        onPost: (content, mediaUrls) async {
          try {
            await ref
                .read(feedProvider.notifier)
                .createPost(content, mediaUrls: mediaUrls);
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('发布失败，请重试')),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('动态'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showCreatePostSheet(context, ref),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('加载失败',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.read(feedProvider.notifier).refresh(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (posts) {
          return RefreshIndicator(
            onRefresh: () => ref.read(feedProvider.notifier).refresh(),
            child: posts.isEmpty
                ? const CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        child: Center(
                          child: Text(
                            '暂无动态，快去发布吧',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return _PostCard(
                        post: post,
                        avatarColor: _colorForUserId(post.userId),
                        onLike: () =>
                            ref.read(feedProvider.notifier).toggleLike(post.id),
                        onChat: currentUser?.id != post.userId
                            ? () async {
                                try {
                                  final convId = await ref
                                      .read(imRepositoryProvider)
                                      .createConversation(post.userId);
                                  if (context.mounted) {
                                    context.push(
                                      '/im/$convId',
                                      extra: {'username': post.username},
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('发起私聊失败，请重试')),
                                    );
                                  }
                                }
                              }
                            : null,
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({
    required this.post,
    required this.avatarColor,
    required this.onLike,
    this.onChat,
  });

  final Post post;
  final Color avatarColor;
  final VoidCallback onLike;
  final VoidCallback? onChat;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _expanded = false;

  void _showImagePreview(BuildContext context, List<String> urls, int initial) {
    final controller = PageController(initialPage: initial);
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              PageView.builder(
                controller: controller,
                itemCount: urls.length,
                itemBuilder: (ctx, index) => InteractiveViewer(
                  child: Center(
                    child: PmImage(
                      urls[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              if (urls.length > 1)
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      urls.length,
                      (i) => AnimatedBuilder(
                        animation: controller,
                        builder: (_, __) {
                          final page = controller.hasClients
                              ? (controller.page?.round() ?? initial)
                              : initial;
                          return Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: page == i
                                  ? Colors.white
                                  : Colors.white38,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 48,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
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
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: widget.avatarColor,
                backgroundImage: post.avatarUrl != null
                    ? PmImageProvider(post.avatarUrl!)
                    : null,
                child: post.avatarUrl == null
                    ? Text(
                        post.username.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.username,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          // Content
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              post.content,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
              maxLines: _expanded ? null : 4,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
          if (!_expanded && post.content.length > 100) ...[
            GestureDetector(
              onTap: () => setState(() => _expanded = true),
              child: const Text(
                '展开',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          // Images
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: post.mediaUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _showImagePreview(context, post.mediaUrls, index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: PmImage(post.mediaUrls[index], width: 180, height: 180, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Actions
          Row(
            children: [
              _ActionButton(
                icon: post.isLiked
                    ? Icons.favorite
                    : Icons.favorite_border,
                label: '${post.likeCount}',
                color: post.isLiked ? Colors.red : AppColors.textSecondary,
                onTap: widget.onLike,
              ),
              const SizedBox(width: 20),
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: '${post.commentCount}',
                color: AppColors.textSecondary,
                onTap: () => showCommentSheet(context, post.id, post.commentCount),
              ),
              const Spacer(),
              if (widget.onChat != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz,
                      color: AppColors.textSecondary, size: 20),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'chat') widget.onChat!();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'chat',
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 18),
                          SizedBox(width: 10),
                          Text('私聊 TA'),
                        ],
                      ),
                    ),
                  ],
                )
              else
                const Icon(Icons.more_horiz, color: AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }
}

class _CreatePostSheet extends ConsumerStatefulWidget {
  const _CreatePostSheet({required this.onPost});

  final Future<void> Function(String content, List<String> mediaUrls) onPost;

  @override
  ConsumerState<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<_CreatePostSheet> {
  final _controller = TextEditingController();
  bool _isPosting = false;
  final List<XFile> _pickedImages = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final results = await picker.pickMultiImage(imageQuality: 80);
    if (results.isNotEmpty && mounted) {
      setState(() {
        final remaining = 9 - _pickedImages.length;
        _pickedImages.addAll(results.take(remaining));
      });
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _pickedImages.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      // 上传图片
      final uploadService = ref.read(uploadServiceProvider);
      final mediaUrls = <String>[];
      for (final xfile in _pickedImages) {
        final url = await uploadService.uploadPostImage(File(xfile.path));
        mediaUrls.add(url);
      }
      await widget.onPost(text, mediaUrls);
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                const Text(
                  '发布动态',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _isPosting ? null : _submit,
                  icon: _isPosting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('发布'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 文本输入
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '分享你的想法...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),

            // 已选图片预览
            if (_pickedImages.isNotEmpty) ...[
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _pickedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final img = _pickedImages[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(img.path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _pickedImages.removeAt(index)),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 12),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],

            // 底部工具栏
            Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.image_outlined,
                      color: AppColors.textSecondary, size: 24),
                  onPressed: _pickedImages.length < 9 ? _pickImages : null,
                  tooltip: '添加图片',
                ),
                const SizedBox(width: 4),
                Text(
                  '${_pickedImages.length}/9',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
