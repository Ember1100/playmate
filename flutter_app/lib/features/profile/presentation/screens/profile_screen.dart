import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../auth/providers/auth_provider.dart';

/// 我的 Tab 首页
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/profile/settings'),
          ),
        ],
      ),
      body: ListView(
        children: [
          _ProfileHeader(user: user),
          const SizedBox(height: 12),
          _StatsRow(),
          const SizedBox(height: 12),
          _MenuSection(title: '我的内容', items: [
            _MenuItem(icon: Icons.bookmark_outline_rounded, label: '我的收藏', path: '/profile/collects'),
            _MenuItem(icon: Icons.note_alt_outlined,        label: '学习笔记', path: '/profile/notes'),
          ]),
          _MenuSection(title: '成长中心', items: [
            _MenuItem(icon: Icons.star_outline_rounded,  label: '会员中心', path: '/profile/member'),
            _MenuItem(icon: Icons.trending_up_rounded,   label: '成长报告', path: '/profile/growth-report'),
          ]),
          _MenuSection(title: '其他', items: [
            _MenuItem(icon: Icons.notifications_outlined, label: '消息通知', path: '/profile/notifications'),
            _MenuItem(icon: Icons.feedback_outlined,      label: '需求反馈', path: '/profile/feedback'),
            _MenuItem(icon: Icons.settings_outlined,      label: '设置',     path: '/profile/settings'),
          ]),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('退出登录'),
                    content: const Text('确认退出当前账号？'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('取消')),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('退出',
                              style: TextStyle(color: AppColors.error))),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await ref.read(authNotifierProvider.notifier).logout();
                }
              },
              style: OutlinedButton.styleFrom(
                side:        const BorderSide(color: AppColors.error),
                foregroundColor: AppColors.error,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button)),
              ),
              child: const Text('退出登录'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── 头部 ──────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final initial = (user?.username as String?)?.isNotEmpty == true
        ? (user!.username as String).substring(0, 1).toUpperCase()
        : '?';

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: user?.avatarUrl != null
                ? NetworkImage(user!.avatarUrl as String) as ImageProvider
                : null,
            child: user?.avatarUrl == null
                ? Text(initial,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.username as String? ?? '未登录',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.bio as String? ?? '这个人很懒，什么都没写~',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// ── 数据概览 ──────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _Stat(label: '成长值', value: '--'),
          _VertDivider(),
          _Stat(label: '积分',   value: '--'),
          _VertDivider(),
          _Stat(label: '信用分', value: '750'),
          _VertDivider(),
          _Stat(label: '收藏',   value: '--'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 0.5, height: 32, color: AppColors.border);
}

// ── 菜单 ──────────────────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});
  final String          title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(title,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          ...items.map((item) => ListTile(
                leading:  Icon(item.icon, color: AppColors.primary, size: 22),
                title:    Text(item.label, style: const TextStyle(fontSize: 15)),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary, size: 20),
                dense:    true,
                onTap:    () => context.push(item.path),
              )),
        ],
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final String   label;
  final String   path;
}
