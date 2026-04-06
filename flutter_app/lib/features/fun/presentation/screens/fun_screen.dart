import 'package:flutter/material.dart';

/// 趣玩 Tab（MVP 静态展示）
class FunScreen extends StatefulWidget {
  const FunScreen({super.key});

  @override
  State<FunScreen> createState() => _FunScreenState();
}

class _FunScreenState extends State<FunScreen> {
  int _selectedFilter = 0;

  static const _categories = [
    _Category(emoji: '🌴', label: '旅游'),
    _Category(emoji: '🤝', label: '交游'),
    _Category(emoji: '⚡', label: '轻运动'),
    _Category(emoji: '🎉', label: '娱乐'),
    _Category(emoji: '✨', label: '二次元'),
  ];

  static const _filters = ['亲子游', '周边游', '短途旅行', '文化体验'];

  static const _feed1 = [
    _ActivityItem(title: '上海迪士尼亲子一日游', subtitle: '4月15日 周六'),
    _ActivityItem(title: '苏州古镇慢生活体验', subtitle: '4月20日 周四'),
    _ActivityItem(title: '南京博物馆文化之旅', subtitle: '4月22日 周六'),
    _ActivityItem(title: '嘉兴南湖亲子露营', subtitle: '4月28日 周五'),
  ];

  static const _feed2 = [
    _ActivityItem(title: '周末爬山 · 天目山一日游', subtitle: '4月13日 周日'),
    _ActivityItem(title: '杭州西湖自行车环游', subtitle: '4月19日 周六'),
    _ActivityItem(title: '上海郊野公园徒步', subtitle: '4月26日 周六'),
    _ActivityItem(title: '苏州太湖周边游', subtitle: '5月3日 周六'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EF),
      body: ListView(
        children: [
          _buildHero(context),
          _buildCategoryRow(),
          const Divider(height: 1, color: Color(0xFFEEE0C0)),
          _buildFilterRow(),
          _buildFeedSection(title: '亲子家庭', items: _feed1),
          _buildFeedSection(title: '户外探索', items: _feed2),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final heroHeight = (screenWidth * 0.52).clamp(0.0, 220.0);

    return SizedBox(
      height: heroHeight,
      child: Stack(
        children: [
          // 占位背景（模拟图片）
          Container(
            color: const Color(0xFFFFE8C0),
          ),
          // 渐变遮罩（底部暗渐变）
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ),
          // 顶部 AI 标签
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8C0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'AI 生成图',
                style: TextStyle(fontSize: 11, color: Color(0xFF996600), fontWeight: FontWeight.w500),
              ),
            ),
          ),
          // 居中标题
          const Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '趣 玩',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                  ),
                ),
                SizedBox(height: 10),
                // 副标题胶囊
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFFFB703),
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    child: Text(
                      '探索精彩活动',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 底部三列
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _heroStat('10+ 活动'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB703),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '立即探索',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                _heroStat('本月更新'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
      ),
    );
  }

  Widget _buildCategoryRow() {
    return Container(
      color: const Color(0xFFFFF9EF),
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _categories.map((cat) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8C0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                cat.label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF444444)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF9EF), Color(0xFFFFF0D0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          // 三点装饰
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFFB703), shape: BoxShape.circle)),
              const SizedBox(width: 3),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFFB703), shape: BoxShape.circle)),
              const SizedBox(width: 3),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFFE8C0), shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(width: 10),
          // 筛选 pill 列表
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_filters.length, (i) {
                  final selected = _selectedFilter == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFFFB703) : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFFFB703)),
                      ),
                      child: Text(
                        _filters[i],
                        style: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : const Color(0xFF886600),
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedSection({required String title, required List<_ActivityItem> items}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧竖条标题
          Row(
            children: [
              Container(width: 4, height: 18, color: const Color(0xFFFFB703)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 横向滚动卡片
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: items.map((item) => _ActivityCard(item: item)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});
  final _ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片占位（aspect ratio 4:3）
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFE8C0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: const Center(
                child: Icon(Icons.image_outlined, color: Color(0xFFCCCCCC), size: 24),
              ),
            ),
          ),
          // 标题
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Category {
  const _Category({required this.emoji, required this.label});
  final String emoji;
  final String label;
}

class _ActivityItem {
  const _ActivityItem({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
}
