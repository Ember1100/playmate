import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';

/// 圈子 Tab 首页
class CircleScreen extends StatelessWidget {
  const CircleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('圈子'),
          actions: [
            IconButton(
              icon: const Icon(Icons.group_outlined),
              onPressed: () => context.push('/circle/groups'),
              tooltip: '社群',
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () {},
              tooltip: '发话题',
            ),
          ],
          bottom: const TabBar(
            labelColor:         AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor:     AppColors.primary,
            indicatorWeight:    2.5,
            labelStyle:         TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle: TextStyle(fontSize: 14),
            tabs: [
              Tab(text: '热门'),
              Tab(text: '关注'),
              Tab(text: '成长'),
              Tab(text: '职场'),
            ],
          ),
        ),
        body: TabBarView(
          children: List.generate(4, (_) => _TopicListPlaceholder()),
        ),
      ),
    );
  }
}

class _TopicListPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => const _TopicCardPlaceholder(),
    );
  }
}

class _TopicCardPlaceholder extends StatelessWidget {
  const _TopicCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border:       Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户行
          Row(children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('用户名', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  Text('1小时前', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:        AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.tag),
              ),
              child: const Text('热门',
                  style: TextStyle(color: AppColors.primary, fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 10),
          const Text('话题标题加载中...',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 6),
          const Text('话题内容摘要...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          // 操作栏
          const Row(children: [
            _ActionBtn(icon: Icons.favorite_border_rounded, label: '点赞'),
            SizedBox(width: 20),
            _ActionBtn(icon: Icons.chat_bubble_outline_rounded, label: '评论'),
          ]),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label});
  final IconData icon;
  final String   label;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
    ]);
  }
}
