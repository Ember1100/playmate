import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/im/providers/im_provider.dart';

/// 底部导航 Shell（4 个 Tab：圈子 / 集市 / 搭子 / 趣玩）
/// 消息和我的移至右上角全局悬浮按钮。
class PmBottomNav extends ConsumerWidget {
  const PmBottomNav({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    _TabItem(icon: Icons.forum_outlined,       activeIcon: Icons.forum_rounded,       label: '圈子'),
    _TabItem(icon: Icons.storefront_outlined,  activeIcon: Icons.storefront_rounded,  label: '集市'),
    _TabItem(icon: Icons.people_alt_outlined,  activeIcon: Icons.people_alt_rounded,  label: '搭子'),
    _TabItem(icon: Icons.celebration_outlined, activeIcon: Icons.celebration_rounded, label: '趣玩'),
  ];

  void _onTap(int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(wsHandlerProvider);
    final unreadCount = ref.watch(totalUnreadCountProvider);
    final user        = ref.watch(currentUserProvider);
    final topPadding  = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        children: [
          shell,
          // ── 右上角全局按钮（消息铃铛 + 我的头像）─────────────────────────
          Positioned(
            top:   topPadding + 8,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 消息铃铛
                _GlobalBtn(
                  onTap: () => context.push('/im'),
                  badge: unreadCount,
                  child: const Icon(Icons.notifications_outlined, size: 20, color: Color(0xFF444444)),
                ),
                const SizedBox(width: 8),
                // 我的
                _GlobalBtn(
                  onTap: () => context.push('/profile'),
                  child: Text(
                    user != null && user.username.isNotEmpty
                        ? user.username.substring(0, 1).toUpperCase()
                        : '我',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444444),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavBar(context),
    );
  }

  Widget _buildNavBar(BuildContext context) {
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
            (i) => Expanded(child: _buildItem(i)),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index) {
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
            Icon(selected ? tab.activeIcon : tab.icon, color: color, size: 26),
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

// ── 右上角全局悬浮按钮 ─────────────────────────────────────────────────────────

class _GlobalBtn extends StatelessWidget {
  const _GlobalBtn({required this.onTap, required this.child, this.badge = 0});

  final VoidCallback onTap;
  final Widget       child;
  final int          badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: child,
          ),
          if (badge > 0)
            Positioned(
              top:   -3,
              right: -3,
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
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.activeIcon, required this.label});
  final IconData icon;
  final IconData activeIcon;
  final String   label;
}
