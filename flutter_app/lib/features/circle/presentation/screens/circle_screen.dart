import 'package:flutter/material.dart';

/// 圈子 Tab 首页
class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key});

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTagIndex = 0;

  static const _tabLabels = ['推荐', '话题', '群聊'];
  static const _tags = ['热点', '关注', '自我成长', '认知升级', '情绪管理', '职场进阶'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8C0),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRecommendTab(),
                  const Center(child: Text('开发中...', style: TextStyle(color: Color(0xFF999999)))),
                  const Center(child: Text('开发中...', style: TextStyle(color: Color(0xFF999999)))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFB703).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: const [
          SizedBox(width: 14),
          Icon(Icons.search_rounded, color: Color(0xFF999999), size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '搜索群聊...',
              style: TextStyle(color: Color(0xFF999999), fontSize: 14),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.star_outline_rounded, color: Color(0xFFFFB703), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_tabLabels.length, (i) {
          return GestureDetector(
            onTap: () {
              _tabController.animateTo(i);
              setState(() {});
            },
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                final selected = _tabController.index == i;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selected ? const Color(0xFFFFB703) : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    _tabLabels[i],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? const Color(0xFF222222) : const Color(0xFF999999),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRecommendTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildPublishBar(),
        const SizedBox(height: 8),
        _buildPollBox(),
        const SizedBox(height: 16),
        _buildTagScrollRow(),
        const SizedBox(height: 16),
        _buildTopicCard(
          title: '在外打工，你有没有这样的孤独感？',
          description: '远离家乡，一个人在外漂，有时候孤独感突然就来了，你们有同感吗？',
          time: '2小时前',
        ),
        _buildTopicCard(
          title: '分享一下你是如何从职业迷茫走出来的',
          description: '25岁换了3份工作，终于找到自己想做的事，想跟大家分享一下我的经历...',
          time: '5小时前',
        ),
        _buildTopicCard(
          title: '周末去哪玩？推荐上海周边亲子好去处',
          description: '整理了几个上海周边适合带娃的地方，价格不贵，体验还不错～',
          time: '昨天',
        ),
      ],
    );
  }

  Widget _buildPublishBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB703),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('✏️', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text(
                    '发布话题',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.4)),
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📊', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text(
                    '发布投票›',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💬 今日观点交锋',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '年轻人是否应该为了梦想放弃稳定工作？',
            style: TextStyle(fontSize: 14, color: Color(0xFF444444)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5E1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFE8C0)),
                  ),
                  child: const Column(
                    children: [
                      Text('正方', style: TextStyle(fontSize: 12, color: Color(0xFFD36A00), fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('梦想无价，值得拼一把', style: TextStyle(fontSize: 11, color: Color(0xFFD36A00)), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: const Column(
                    children: [
                      Text('反方', style: TextStyle(fontSize: 12, color: Color(0xFF555555), fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('稳定才是幸福的基础', style: TextStyle(fontSize: 11, color: Color(0xFF555555)), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagScrollRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tags.length, (i) {
          final selected = _selectedTagIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedTagIndex = i),
            child: Container(
              margin: const EdgeInsets.only(right: 9),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFFB703) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: selected
                    ? null
                    : Border.all(color: const Color(0xFFFFE0B2)),
              ),
              child: Text(
                _tags[i],
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? Colors.white : const Color(0xFF666666),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTopicCard({
    required String title,
    required String description,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片占位
          Container(
            width: 102,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.image_outlined, color: Color(0xFFCCCCCC), size: 28),
            ),
          ),
          const SizedBox(width: 12),
          // 内容
          Expanded(
            child: SizedBox(
              height: 82,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF222222),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF777777),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF999999),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB703),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          '热议',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
