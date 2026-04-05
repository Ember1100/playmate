import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../feed/data/feed_model.dart';
import 'liked_posts_screen.dart';

// ── 我的动态 provider ─────────────────────────────────────────────────────────

final myPostsProvider =
    AsyncNotifierProvider<MyPostsNotifier, List<Post>>(MyPostsNotifier.new);

class MyPostsNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() => _fetch();

  Future<List<Post>> _fetch() async {
    final client = ref.read(apiClientProvider);
    final resp = await client.get<Map<String, dynamic>>(
      '/feed/posts/mine',
      params: {'limit': 30},
    );
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
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: AppColors.primary,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => context.push('/profile/edit'),
                  ),
                  const SizedBox(width: 4),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 52, 56, 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 38,
                              backgroundColor: Colors.white,
                              backgroundImage: user?.avatarUrl != null
                                  ? NetworkImage(user!.avatarUrl!)
                                  : null,
                              child: user?.avatarUrl == null
                                  ? Text(
                                      user?.username.isNotEmpty == true
                                          ? user!.username[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    user?.username ?? '未登录',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    user?.bio ?? '这个人很懒，什么都没留下',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 数据栏 + 退出
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      _StatColumn(label: '关注', value: '0'),
                      const SizedBox(width: 24),
                      _StatColumn(label: '粉丝', value: '0'),
                      const SizedBox(width: 24),
                      _StatColumn(label: '玩伴', value: '0'),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          await ref
                              .read(authNotifierProvider.notifier)
                              .logout();
                          if (context.mounted) context.go('/login');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            '退出登录',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Tab 栏
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  const TabBar(
                    tabs: [Tab(text: '动态'), Tab(text: '赞过')],
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorWeight: 3,
                    dividerColor: AppColors.border,
                    labelStyle: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ];
          },
          body: const TabBarView(
            children: [
              _MyPostsTab(),
              _LikedTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 数据列 ────────────────────────────────────────────────────────────────────

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── SliverPersistentHeader delegate ──────────────────────────────────────────

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _SliverTabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate old) => false;
}

// ── 动态 Tab ──────────────────────────────────────────────────────────────────

class _MyPostsTab extends ConsumerWidget {
  const _MyPostsTab();

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
    final postsAsync = ref.watch(myPostsProvider);

    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('加载失败',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.read(myPostsProvider.notifier).refresh(),
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
                Icon(Icons.article_outlined,
                    size: 64, color: AppColors.textSecondary),
                SizedBox(height: 16),
                Text('暂无动态，快去发布吧',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 15)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(myPostsProvider.notifier).refresh(),
          child: GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 0.68,
            ),
            itemCount: posts.length,
            itemBuilder: (context, i) {
              final post = posts[i];
              return _PostGridCard(
                post: post,
                color: _colorFor(post.userId),
              );
            },
          ),
        );
      },
    );
  }
}

// ── 赞过 Tab ─────────────────────────────────────────────────────────────────

class _LikedTab extends ConsumerWidget {
  const _LikedTab();

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

    return postsAsync.when(
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
                Text('还没有点赞任何内容',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 15)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(likedPostsProvider.notifier).refresh(),
          child: GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 0.68,
            ),
            itemCount: posts.length,
            itemBuilder: (context, i) {
              final post = posts[i];
              return _PostGridCard(
                post: post,
                color: _colorFor(post.userId),
              );
            },
          ),
        );
      },
    );
  }
}

// ── 赞过卡片（XHS 风格）──────────────────────────────────────────────────────

class _PostGridCard extends StatelessWidget {
  const _PostGridCard({required this.post, required this.color});
  final Post post;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasImage = post.mediaUrls.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 上半：图片 or 文字色块
          Expanded(
            flex: 6,
            child: hasImage
                ? Image.network(
                    post.mediaUrls.first,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stack) =>
                        _TextPreview(content: post.content, color: color),
                  )
                : _TextPreview(content: post.content, color: color),
          ),
          // 下半：标题 + 用户信息
          Expanded(
            flex: 3,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        height: 1.4),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 9,
                        backgroundColor: color,
                        child: Text(
                          post.username.isNotEmpty
                              ? post.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.username,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.favorite,
                          size: 12, color: Colors.red),
                      const SizedBox(width: 2),
                      Text(
                        '${post.likeCount}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextPreview extends StatelessWidget {
  const _TextPreview({required this.content, required this.color});
  final String content;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.all(12),
      alignment: Alignment.topLeft,
      child: Text(
        content,
        style: TextStyle(
          fontSize: 13,
          color: color,
          height: 1.55,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 7,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
