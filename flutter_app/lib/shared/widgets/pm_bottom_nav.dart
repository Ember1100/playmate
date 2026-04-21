import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../features/im/providers/im_provider.dart';

/// 底部导航 Shell（5 个 Tab：圈子 / 集市 / 搭子 / 趣玩 / 消息）
class PmBottomNav extends ConsumerWidget {
  const PmBottomNav({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    _TabItem(icon: Icons.forum_outlined,       activeIcon: Icons.forum_rounded,       label: '圈子'),
    _TabItem(icon: Icons.storefront_outlined,  activeIcon: Icons.storefront_rounded,  label: '集市'),
    _TabItem(icon: Icons.people_alt_outlined,  activeIcon: Icons.people_alt_rounded,  label: '搭子'),
    _TabItem(icon: Icons.celebration_outlined, activeIcon: Icons.celebration_rounded, label: '趣玩'),
    _TabItem(icon: Icons.chat_bubble_outline,  activeIcon: Icons.chat_bubble_rounded, label: '消息'),
  ];

  void _onTap(int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(wsHandlerProvider);
    final unreadCount = ref.watch(totalUnreadCountProvider);

    return Scaffold(
      body: shell,
      bottomNavigationBar: _buildNavBar(context, unreadCount),
    );
  }

  Widget _buildNavBar(BuildContext context, int unreadCount) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: 98 + bottomPadding,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Row(
          children: List.generate(
            _tabs.length,
            (i) => Expanded(child: _buildItem(i, i == 4 ? unreadCount : 0)),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index, int badge) {
    final selected = index == shell.currentIndex;
    final tab      = _tabs[index];
    final color    = selected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap:       () => _onTap(index),
      splashColor: AppColors.primaryLight,
      child: SizedBox(
        height: 98,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? tab.activeIcon : tab.icon, color: color, size: 26),
                if (badge > 0)
                  Positioned(
                    top:   -4,
                    right: -10,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color:        AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   9,
                          fontWeight: FontWeight.bold,
                          height:     1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                fontSize:   11.5,
                color:      color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.activeIcon, required this.label});
  final IconData icon;
  final IconData activeIcon;
  final String   label;
}
