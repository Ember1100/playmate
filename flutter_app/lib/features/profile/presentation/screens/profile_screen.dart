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
      backgroundColor: AppColors.warmBg,
      body: SafeArea(
        child: ListView(
          children: [
            // 顶部 header
            _buildHeader(context),
            // 用户信息区
            _buildUserInfo(user),
            const SizedBox(height: 24),
            // 成长统计卡
            _buildStatsCard(),
            const SizedBox(height: 12),
            // 兴趣标签云
            _buildTagCloud(),
            const SizedBox(height: 12),
            // 成长宣言
            _buildMotto(),
            const SizedBox(height: 12),
            // 功能中心
            _buildFunctionCenter(context),
            const SizedBox(height: 16),
            // 我参与的活动
            _buildActivities(),
            const SizedBox(height: 16),
            // 退出登录
            _buildLogout(context, ref),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const SizedBox(width: 36), // 占位（无返回按钮）
            const Expanded(
              child: Center(
                child: Text(
                  '我的',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/profile/settings'),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.warmBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(dynamic user) {
    final username = user?.username as String? ?? '玩伴用户';
    final initial = username.isNotEmpty ? username.substring(0, 1).toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 16),
      child: Row(
        children: [
          // 头像
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFFFD166),
            backgroundImage: user?.avatarUrl != null
                ? NetworkImage(user!.avatarUrl as String) as ImageProvider
                : null,
            child: user?.avatarUrl == null
                ? Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'ID: ${user?.id?.toString().substring(0, 8) ?? "00000000"}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB703),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Lv.5',
                        style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withValues(alpha: 0.07),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatItem(value: '--', label: '成长值'),
          Container(width: 0.5, height: 36, color: const Color(0xFFEEEEEE)),
          _StatItem(value: '--', label: '积分'),
          Container(width: 0.5, height: 36, color: const Color(0xFFEEEEEE)),
          _StatItem(value: '--', label: '收藏数'),
        ],
      ),
    );
  }

  Widget _buildTagCloud() {
    const tags = ['爬山', '摄影', '读书', '游戏', '旅行'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warmBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              tag,
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMotto() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        '✨ 每一天都是新的开始，用行动书写属于自己的精彩人生',
        style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
      ),
    );
  }

  Widget _buildFunctionCenter(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withValues(alpha: 0.07),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              '功能中心',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF222222)),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          // 菜单项
          _FuncItem(
            icon: Icons.notifications_outlined,
            label: '消息通知',
            badge: '2',
            onTap: () => context.push('/profile/notifications'),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 56),
          _FuncItem(
            icon: Icons.bookmark_outline_rounded,
            label: '收藏列表',
            onTap: () => context.push('/profile/collects'),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 56),
          _FuncItem(
            icon: Icons.people_alt_outlined,
            label: '搭子管理',
            onTap: () => context.push('/buddy'),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 56),
          _FuncItem(
            icon: Icons.workspace_premium_outlined,
            label: '会员中心',
            onTap: () => context.push('/profile/member'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivities() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withValues(alpha: 0.07),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              '我参与的活动',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF222222)),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _ActivityItem(label: '红色教育基地参观', status: '进行中', statusColor: const Color(0xFF4CAF50)),
          const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 16),
          _ActivityItem(label: '古城小巷摄影', status: '已完成', statusColor: const Color(0xFF999999)),
          const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 16),
          _ActivityItem(label: '周末咖啡读书会', status: '已报名', statusColor: const Color(0xFFFFB703)),
        ],
      ),
    );
  }

  Widget _buildLogout(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: const Icon(Icons.logout_rounded, color: Color(0xFFE88888)),
        title: const Text(
          '退出登录',
          style: TextStyle(color: Color(0xFFE88888), fontSize: 15),
        ),
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('退出登录'),
              content: const Text('确认退出当前账号？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    '退出',
                    style: TextStyle(color: Color(0xFFE24B4A)),
                  ),
                ),
              ],
            ),
          );
          if (confirm == true && context.mounted) {
            await ref.read(authNotifierProvider.notifier).logout();
          }
        },
      ),
    );
  }
}

// ── 子组件 ────────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }
}

class _FuncItem extends StatelessWidget {
  const _FuncItem({
    required this.icon,
    required this.label,
    this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              // 图标容器
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.warmBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF222222)),
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE24B4A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCCCCCC), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.label,
    required this.status,
    required this.statusColor,
  });

  final String label;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
