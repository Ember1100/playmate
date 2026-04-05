import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/im_provider.dart';

class ImScreen extends ConsumerWidget {
  const ImScreen({super.key});

  static const _avatarColors = [
    Color(0xFF7F77DD),
    Color(0xFF4ECDC4),
    Color(0xFFFF6B6B),
    Color(0xFFFFBE0B),
    Color(0xFF06D6A0),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('消息'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('编辑',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: conversationsAsync.when(
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
                    ref.read(conversationsProvider.notifier).refresh(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    '暂无消息，去发现玩伴吧',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(conversationsProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 72,
                endIndent: 16,
                color: AppColors.border,
              ),
              itemBuilder: (context, index) {
                final conv = conversations[index];
                final avatarColor = _avatarColors[index % _avatarColors.length];

                String timeStr = '';
                if (conv.lastMessageAt != null) {
                  final now = DateTime.now();
                  final diff = now.difference(conv.lastMessageAt!);
                  if (diff.inDays == 0) {
                    timeStr = DateFormat('HH:mm').format(conv.lastMessageAt!);
                  } else if (diff.inDays < 7) {
                    timeStr = DateFormat('MM-dd').format(conv.lastMessageAt!);
                  } else {
                    timeStr = DateFormat('MM-dd').format(conv.lastMessageAt!);
                  }
                }

                return InkWell(
                  onTap: () {
                    // 乐观清零未读红点
                    ref
                        .read(conversationsProvider.notifier)
                        .clearUnread(conv.id);
                    context.push(
                      '/im/${conv.id}',
                      extra: {
                        'username': conv.otherUsername,
                        'otherUserId': conv.otherUserId,
                      },
                    );
                  },
                  child: Container(
                    height: 72,
                    color: AppColors.surface,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: avatarColor,
                          backgroundImage: conv.otherAvatarUrl != null
                              ? NetworkImage(conv.otherAvatarUrl!)
                              : null,
                          child: conv.otherAvatarUrl == null
                              ? Text(
                                  conv.otherUsername
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                conv.otherUsername,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                conv.lastMessage ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Time + unread
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (conv.unreadCount > 0) ...[
                              const SizedBox(height: 4),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  conv.unreadCount > 99
                                      ? '99+'
                                      : '${conv.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
