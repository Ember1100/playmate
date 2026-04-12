import 'package:flutter/material.dart';
import '../../../../shared/widgets/pm_image.dart';
import '../../../../shared/widgets/pm_swipe_back.dart';

/// 搭子用户详情页
class BuddyUserDetailScreen extends StatefulWidget {
  const BuddyUserDetailScreen({super.key, this.userId});
  final String? userId;

  @override
  State<BuddyUserDetailScreen> createState() => _BuddyUserDetailScreenState();
}

class _BuddyUserDetailScreenState extends State<BuddyUserDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTab = 1; // 默认选中"遛宠搭子陪伴"

  static const _tabs = ['养宠实用干货', '遛宠搭子陪伴', '宠物顾问咨询', '用户评价'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: _tabs.length, vsync: this, initialIndex: _selectedTab);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PmSwipeBack(
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8EC),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            _buildAppBar(context),
            SliverToBoxAdapter(child: _buildProfileHeader()),
            SliverToBoxAdapter(child: _buildBio()),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                tabController: _tabController,
                tabs: _tabs,
                onTap: (i) => setState(() => _selectedTab = i),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPlaceholderTab('养宠实用干货'),
              _buildServiceTab(),
              _buildPlaceholderTab('宠物顾问咨询'),
              _buildReviewTab(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomActions(context),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: false,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Color(0xFF2C2C2A)),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.more_horiz_rounded,
                size: 20, color: Color(0xFF2C2C2A)),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ),
      ],
    );
  }

  // ── 个人信息头部 ───────────────────────────────────────────────────────────

  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PmImage(
              'https://picsum.photos/seed/user_ya/200/200',
              width: 86,
              height: 86,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 名字
                const Text(
                  '阿雅',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2C2C2A),
                  ),
                ),
                const SizedBox(height: 6),
                // 标签行
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _InfoChip(
                      label: '顺应搭子',
                      color: const Color(0xFF5DCAA5),
                      textColor: Colors.white,
                    ),
                    _InfoChip(
                      label: '实名认证',
                      icon: Icons.verified_user_outlined,
                      color: const Color(0xFFFFF0DC),
                      textColor: const Color(0xFFFF7A00),
                      borderColor: const Color(0xFFFF7A00),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 信用分
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFF7A00), size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      '信用分：',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF888780)),
                    ),
                    const Text(
                      '920',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF7A00),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7A00),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '极佳',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
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

  // ── 个人简介 ───────────────────────────────────────────────────────────────

  Widget _buildBio() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 引语
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Text('"', style: TextStyle(fontSize: 20, color: Color(0xFFFF7A00), height: 1)),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '用专业与爱心，守护毛孩子的健康成长',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2C2C2A),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 标题
          _SectionTitle(title: '遛宠搭子'),
          const SizedBox(height: 8),
          // 简介文字
          const Text(
            '宠物陪伴师，宠龄5年，熟悉各类宠物习性，特别是犬类。'
            '每周5~7年，熟悉各类宠物习性，特别是犬类，以及猫咪行为学。'
            '因此立志成为一名专业的宠物服务者，作为特定宠物陪伴师，我带着与各种性格的孩子打磨，'
            '能够敏锐把握宠物的情绪和需求，提供专业、贴心的服务。',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF555555),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          // 擅长领域
          _BioBlock(
            label: '擅长领域',
            items: const [
              '宠物训练、家庭护理、宠物行为评估',
            ],
          ),
          const SizedBox(height: 8),
          // 服务方式
          _BioBlock(
            label: '服务方式',
            items: const [
              '帮孩子散步、分享养宠经验、宠物社交不尴尬',
            ],
          ),
          const SizedBox(height: 8),
          // 服务承诺
          _BioBlock(
            label: '服务承诺',
            items: const [
              '专业照料·科学喂养·安全第一',
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab：遛宠搭子陪伴 ─────────────────────────────────────────────────────

  Widget _buildServiceTab() {
    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        // 大图
        PmImage(
          'https://picsum.photos/seed/golden/800/400',
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
        const SizedBox(height: 12),
        // 核心服务内容
        _ServiceCard(
          icon: Icons.pets_rounded,
          iconColor: const Color(0xFF5DCAA5),
          title: '核心服务内容',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _BulletItem(
                  '遛宠陪伴：每日定时遛弯，科学运动，快乐社交'),
              _BulletItem(
                  '生活协助：上门喂食换水，清洁环境、梳毛护理'),
              _BulletItem(
                  '专属定制：根据宠物性格定制专属陪伴方案'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 套餐
        _ServiceCard(
          icon: Icons.local_offer_outlined,
          iconColor: const Color(0xFFFF7A00),
          title: '超值体验套餐',
          child: Row(
            children: const [
              Expanded(
                  child: _PackageCard(
                      label: '体验单次', price: '¥19.9', desc: '单次遛狗')),
              SizedBox(width: 8),
              Expanded(
                  child: _PackageCard(
                      label: '周套餐', price: '¥80', desc: '每周5次')),
              SizedBox(width: 8),
              Expanded(
                  child: _PackageCard(
                      label: '月套餐', price: '¥300', desc: '每月20次')),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 用户评价摘要
        _ServiceCard(
          icon: Icons.format_quote_rounded,
          iconColor: const Color(0xFFFF7A00),
          title: '用户好评',
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '"非常专业，狗狗很喜欢她，推荐！"',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2C2C2A),
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0E0E0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded,
                          size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '宠主小李',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF888780)),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        5,
                        (_) => const Icon(Icons.star_rounded,
                            size: 12, color: Color(0xFFFF7A00)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // 服务安全保障
        _ServiceCard(
          icon: Icons.security_rounded,
          iconColor: const Color(0xFF5DCAA5),
          title: '服务安全保障',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GuaranteeItem(
                  icon: Icons.verified_rounded,
                  color: const Color(0xFF5DCAA5),
                  text: '实名认证·全程视频反馈·100% 履约承诺'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 本月服务日程
        _ServiceCard(
          icon: Icons.calendar_month_rounded,
          iconColor: const Color(0xFFFF7A00),
          title: '本月服务日程',
          child: _buildCalendar(),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildCalendar() {
    // 模拟本月日历，31天
    const statusMap = {
      1: 1, 2: 1, 3: 0, 4: 0, 5: 2, 6: 0, 7: 2,
      8: 1, 9: 0, 10: 0, 11: 2, 12: 2, 13: 0, 14: 2,
      15: 1, 16: 0, 17: 0, 18: 0, 19: 2, 20: 2, 21: 2,
      22: 1, 23: 0, 24: 0, 25: 2, 26: 2, 27: 0, 28: 2,
      29: 0, 30: 2, 31: 1,
    }; // 0=可约 1=已满 2=已预约

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 4,
        childAspectRatio: 0.8,
      ),
      itemCount: 31,
      itemBuilder: (_, i) {
        final day = i + 1;
        final status = statusMap[day] ?? 0;
        return _CalendarCell(day: day, status: status);
      },
    );
  }

  // ── Tab：用户评价 ─────────────────────────────────────────────────────────

  Widget _buildReviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        4,
        (i) => _ReviewCard(
          name: ['宠主小李', '铲屎官小王', '狗主人阿豪', '猫咪妈妈'][i],
          rating: [5, 5, 4, 5][i],
          comment: [
            '非常专业，狗狗很喜欢她！每次遛完都很开心，强烈推荐！',
            '服务很贴心，每次都准时，还会发照片给我们，很放心。',
            '整体不错，专业度高，就是偶尔会迟到一点点，但服务质量很好。',
            '我家猫咪超喜欢阿雅，而且每次都整理得干干净净再走！',
          ][i],
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty_rounded,
              size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('$title 内容即将上线',
              style: const TextStyle(color: Color(0xFF888780), fontSize: 14)),
        ],
      ),
    );
  }

  // ── 底部操作栏 ─────────────────────────────────────────────────────────────

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          // 私信按钮
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF7A00),
                side: const BorderSide(color: Color(0xFFFF7A00)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('私信',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          // 发起邀约按钮
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {},
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
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
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
  _TabBarDelegate({
    required this.tabController,
    required this.tabs,
    required this.onTap,
  });

  final TabController tabController;
  final List<String> tabs;
  final ValueChanged<int> onTap;

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
        labelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        tabs: tabs.map((t) => Tab(text: t)).toList(),
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        dividerColor: const Color(0xFFEEEEEE),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C2C2A),
          ),
        ),
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
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFFF7A00),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map((item) => Text(item,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF555555),
                        height: 1.5)))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C2C2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFFFF7A00),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF555555), height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.label,
    required this.price,
    required this.desc,
  });
  final String label;
  final String price;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD8A8)),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888780),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(price,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFF7A00),
              )),
          const SizedBox(height: 4),
          Text(desc,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF888780))),
        ],
      ),
    );
  }
}

class _GuaranteeItem extends StatelessWidget {
  const _GuaranteeItem({
    required this.icon,
    required this.color,
    required this.text,
  });
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF555555), height: 1.5)),
        ),
      ],
    );
  }
}

// 日历单元格
class _CalendarCell extends StatelessWidget {
  const _CalendarCell({required this.day, required this.status});
  final int day;
  final int status; // 0=可约 1=已满 2=已预约

  @override
  Widget build(BuildContext context) {
    final colors = [
      [const Color(0xFFE8F8F2), const Color(0xFF5DCAA5)],  // 可约：绿
      [const Color(0xFFFFEEEE), const Color(0xFFE24B4A)],  // 已满：红
      [const Color(0xFFFFF0DC), const Color(0xFFFF7A00)],  // 已预约：橙
    ];
    final labels = ['可约', '已满', '已预约'];

    return Column(
      children: [
        Text(
          '$day',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors[status][1],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: colors[status][0],
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            labels[status],
            style: TextStyle(
              fontSize: 9,
              color: colors[status][1],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// 评价卡片
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.name,
    required this.rating,
    required this.comment,
  });
  final String name;
  final int rating;
  final String comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(blurRadius: 6, color: Color(0x0A000000), offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8E6E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    size: 20, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C2C2A))),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 13,
                          color: const Color(0xFFFF7A00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(comment,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF555555), height: 1.6)),
        ],
      ),
    );
  }
}
