import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/pm_image.dart';
import '../../../../shared/widgets/pm_swipe_back.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../im/data/im_repository.dart';
import '../../../im/providers/im_provider.dart';
import '../../data/user_detail_model.dart';
import '../../providers/user_detail_provider.dart';

/// 用户详情页 — 1:1 保留原视觉结构，接真实数据
/// - 他人：底部「私信 + 发起邀约」
/// - 自己：底部「编辑资料」
class BuddyUserDetailScreen extends ConsumerStatefulWidget {
  const BuddyUserDetailScreen({
    super.key,
    required this.userId,
    this.username,
    this.avatarUrl,
  });

  final String userId;
  final String? username;
  final String? avatarUrl;

  @override
  ConsumerState<BuddyUserDetailScreen> createState() =>
      _BuddyUserDetailScreenState();
}

class _BuddyUserDetailScreenState extends ConsumerState<BuddyUserDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _chatLoading = false;

  static const _tabs = ['个人简介', '职业档案'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isSelf =>
      ref.read(currentUserProvider)?.id == widget.userId;

  Future<void> _startChat(UserDetailModel detail) async {
    setState(() => _chatLoading = true);
    final router    = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final convId =
          await ref.read(imRepositoryProvider).createConversation(widget.userId);
      ref.invalidate(conversationsProvider);
      if (mounted) {
        router.push('/im/chat/$convId', extra: {
          'username':      detail.username,
          'otherAvatarUrl': detail.avatarUrl,
        });
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
            const SnackBar(content: Text('创建会话失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _chatLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(userDetailProvider(widget.userId));

    return PmSwipeBack(
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8EC),
        body: detailAsync.when(
          loading: () => _buildBody(null),
          error:   (e, _) => _buildError(e),
          data:    _buildBody,
        ),
        bottomNavigationBar: detailAsync.whenOrNull(
          data: (d) => _buildBottomActions(context, d),
        ) ?? _buildBottomActions(context, null),
      ),
    );
  }

  Widget _buildError(Object e) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 12),
          Text('加载失败，请重试',
              style: const TextStyle(color: Color(0xFF888888))),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => ref.invalidate(userDetailProvider(widget.userId)),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(UserDetailModel? detail) {
    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        _buildAppBar(context, detail),
        SliverToBoxAdapter(child: _buildProfileHeader(detail)),
        SliverToBoxAdapter(child: _buildQuoteSection(detail)),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            tabController: _tabController,
            tabs: _tabs,
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIntroTab(detail),
          _buildCareerTab(detail),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar(BuildContext context, UserDetailModel? detail) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: false,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Color(0xFF2C2C2A)),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle),
          child: _isSelf
              ? IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 20, color: Color(0xFF2C2C2A)),
                  onPressed: () async {
                    await context.push('/profile/edit');
                    ref.invalidate(userDetailProvider(widget.userId));
                  },
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                )
              : IconButton(
                  icon: const Icon(Icons.more_horiz_rounded,
                      size: 20, color: Color(0xFF2C2C2A)),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
        ),
      ],
    );
  }

  // ── 个人信息头部 ───────────────────────────────────────────────────────────

  Widget _buildProfileHeader(UserDetailModel? detail) {
    final username  = detail?.username  ?? widget.username ?? '搭伴用户';
    final avatarUrl = detail?.avatarUrl ?? widget.avatarUrl;
    final initial   = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: avatarUrl != null
                ? PmImage(avatarUrl, width: 86, height: 86, fit: BoxFit.cover)
                : Container(
                    width: 86, height: 86,
                    color: const Color(0xFFFF8C42),
                    child: Center(
                      child: Text(initial,
                          style: const TextStyle(
                              fontSize: 36,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C2C2A))),
                const SizedBox(height: 6),
                // 标签行：性别 / 城市 / 实名认证
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (detail?.genderLabel.isNotEmpty == true)
                      _InfoChip(
                        label: detail!.genderLabel,
                        color: detail.gender == 1
                            ? const Color(0xFFE3F0FF)
                            : const Color(0xFFFFE8F3),
                        textColor: detail.gender == 1
                            ? const Color(0xFF2196F3)
                            : const Color(0xFFE91E8C),
                      ),
                    if (detail?.city?.isNotEmpty == true)
                      _InfoChip(
                        label: detail!.city!,
                        icon: Icons.location_on_outlined,
                        color: const Color(0xFFF0F0F0),
                        textColor: const Color(0xFF666666),
                      ),
                    if (detail?.isVerified == true)
                      _InfoChip(
                        label: '实名认证',
                        icon: Icons.verified_user_outlined,
                        color: const Color(0xFFFFF0DC),
                        textColor: const Color(0xFFFF7A00),
                        borderColor: const Color(0xFFFF7A00),
                      ),
                    if (detail == null)
                      Container(
                        width: 80, height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // 信用分
                if (detail != null)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFF7A00), size: 16),
                      const SizedBox(width: 4),
                      const Text('信用分：',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF888780))),
                      Text('${detail.creditScore}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF7A00))),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7A00),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(detail.creditLabel,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  )
                else
                  Container(
                    width: 120, height: 18,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 引言区（bio）────────────────────────────────────────────────────────────

  Widget _buildQuoteSection(UserDetailModel? detail) {
    final bio = detail?.bio;
    if (bio == null || bio.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 1),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('"',
                style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFFFF7A00),
                    height: 1)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(bio,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2C2C2A),
                      fontStyle: FontStyle.italic,
                      height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1：个人简介 ────────────────────────────────────────────────────────

  Widget _buildIntroTab(UserDetailModel? detail) {
    if (detail == null) return const _LoadingPlaceholder();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(title: '兴趣爱好'),
              const SizedBox(height: 12),
              if (detail.tags.isEmpty)
                const Text('暂未设置兴趣标签',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF999999)))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: detail.tags
                      .map((tag) => _TagChip(label: tag))
                      .toList(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(title: '基本信息'),
              const SizedBox(height: 12),
              if (detail.genderLabel.isNotEmpty)
                _BioBlock(label: '性别', items: [detail.genderLabel]),
              if (detail.city?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                _BioBlock(label: '城市', items: [detail.city!]),
              ],
              if (detail.level > 0) ...[
                const SizedBox(height: 8),
                _BioBlock(label: '等级', items: ['Lv.${detail.level}']),
              ],
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  // ── Tab 2：职业档案 ────────────────────────────────────────────────────────

  Widget _buildCareerTab(UserDetailModel? detail) {
    if (detail == null) return const _LoadingPlaceholder();

    final career = detail.career;
    if (career == null || career.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline_rounded,
                size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              _isSelf ? '你还没有填写职业档案' : '该用户暂未公开职业档案',
              style: const TextStyle(
                  color: Color(0xFF888780), fontSize: 14),
            ),
            if (_isSelf) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.push('/profile/edit'),
                child: const Text('去填写',
                    style: TextStyle(color: Color(0xFFFF7A00))),
              ),
            ],
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(title: '职业信息'),
              const SizedBox(height: 12),
              if (career.jobTitle?.isNotEmpty == true)
                _BioBlock(label: '职位', items: [career.jobTitle!]),
              if (career.company?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                _BioBlock(label: '公司', items: [career.company!]),
              ],
              if (career.experience?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                _BioBlock(label: '经验', items: [career.experience!]),
              ],
              if (career.lookingFor?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                _BioBlock(label: '期望', items: [career.lookingFor!]),
              ],
            ],
          ),
        ),
        if (career.skills.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(title: '技能标签'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: career.skills
                      .map((s) => _TagChip(
                          label: s,
                          bgColor: const Color(0xFFE8F8F2),
                          textColor: const Color(0xFF5DCAA5)))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  // ── 底部操作栏 ─────────────────────────────────────────────────────────────

  Widget _buildBottomActions(BuildContext context, UserDetailModel? detail) {
    final padding = MediaQuery.of(context).padding.bottom;

    if (_isSelf) {
      return Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, padding + 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: ElevatedButton.icon(
          onPressed: () async {
            await context.push('/profile/edit');
            ref.invalidate(userDetailProvider(widget.userId));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7A00),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text('编辑资料',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, padding + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed:
                  (_chatLoading || detail == null) ? null : () => _startChat(detail),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF7A00),
                side: const BorderSide(color: Color(0xFFFF7A00)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: _chatLoading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFFFF7A00)))
                  : const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('私信',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: detail == null
                  ? null
                  : () {
                      // TODO: 发起邀约 sheet
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A00),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: const Text('发起邀约',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 固定 Tab 栏委托
// ─────────────────────────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate({
    required this.tabController,
    required this.tabs,
  });

  final TabController tabController;
  final List<String> tabs;

  @override
  double get minExtent => 46;
  @override
  double get maxExtent => 46;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      height: 46,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: const Color(0xFFFF7A00),
        unselectedLabelColor: const Color(0xFF888780),
        indicatorColor: const Color(0xFFFF7A00),
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        tabs: tabs.map((t) => Tab(text: t)).toList(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        dividerColor: const Color(0xFFEEEEEE),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// 小组件
// ─────────────────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.color,
    required this.textColor,
    this.icon,
    this.borderColor,
  });

  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: textColor,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    this.bgColor = const Color(0xFFFFF0DC),
    this.textColor = const Color(0xFFFF7A00),
  });

  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFFF7A00),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C2C2A))),
      ],
    );
  }
}

class _BioBlock extends StatelessWidget {
  const _BioBlock({required this.label, required this.items});
  final String label;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFF7A00)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFFF7A00),
                  fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(items.join('、'),
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF555555), height: 1.5)),
        ),
      ],
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
          color: Color(0xFFFF7A00), strokeWidth: 2),
    );
  }
}
