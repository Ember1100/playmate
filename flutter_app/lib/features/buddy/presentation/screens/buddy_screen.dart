import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';

/// 搭子 Tab 首页
class BuddyScreen extends StatelessWidget {
  const BuddyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('搭子'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _QuickEntryRow(entries: [
            _Entry(icon: Icons.recommend_rounded,    label: '推荐搭子', path: '/buddy/candidates'),
            _Entry(icon: Icons.mail_outline_rounded, label: '邀约管理', path: '/buddy/invitations'),
            _Entry(icon: Icons.work_outline_rounded, label: '职业阵地', path: '/buddy/career'),
          ]),
          const SizedBox(height: 24),
          const _SectionHeader(title: '推荐搭子'),
          const SizedBox(height: 12),
          // 占位列表
          ...List.generate(
            5,
            (i) => const _BuddyCardPlaceholder(),
          ),
        ],
      ),
    );
  }
}

class _QuickEntryRow extends StatelessWidget {
  const _QuickEntryRow({required this.entries});
  final List<_Entry> entries;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: entries
          .map(
            (e) => Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.card),
                onTap: () => context.push(e.path),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(e.icon, color: AppColors.primary, size: 28),
                      const SizedBox(height: 6),
                      Text(e.label,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ),
          )
          .expand((w) => [w, const SizedBox(width: 10)])
          .toList()
        ..removeLast(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary));
  }
}

class _BuddyCardPlaceholder extends StatelessWidget {
  const _BuddyCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryLight,
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('加载中...', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('—', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.tag),
              ),
              minimumSize: Size.zero,
            ),
            child: const Text('打招呼', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _Entry {
  const _Entry({required this.icon, required this.label, required this.path});
  final IconData icon;
  final String   label;
  final String   path;
}
