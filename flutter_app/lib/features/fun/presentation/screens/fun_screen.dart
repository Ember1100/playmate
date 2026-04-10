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
    _Category(emoji: '🏆', label: '我参与'),
    _Category(emoji: '🛍️', label: '好物团'),
    _Category(emoji: '🗺️', label: '全年线'),
    _Category(emoji: '✈️', label: '国际线'),
    _Category(emoji: '🎨', label: '定制游'),
  ];

  static const _filters = ['探游', '交游', '轻运动', '娱乐', '二次元'];

  // TODO: replace with API call to GET /api/v1/fun/activities
  static const _feed1 = [
    _ActivityItem(
      title: '红色教育基地参观研学',
      subtitle: '4月15日 周二',
      imageId: 1048,
    ),
    _ActivityItem(
      title: '延安精神传承营（3天）',
      subtitle: '4月20日 周日',
      imageId: 1059,
    ),
    _ActivityItem(
      title: '南京博物馆文化之旅',
      subtitle: '4月22日 周二',
      imageId: 1069,
    ),
    _ActivityItem(
      title: '井冈山红色研学游',
      subtitle: '4月28日 周一',
      imageId: 1074,
    ),
  ];

  static const _feed2 = [
    _ActivityItem(
      title: '周末汉服同城聚会',
      subtitle: '4月13日 周日',
      imageId: 1011,
    ),
    _ActivityItem(
      title: '古城小巷摄影交流',
      subtitle: '4月19日 周六',
      imageId: 1016,
    ),
    _ActivityItem(
      title: '周末咖啡读书会',
      subtitle: '4月26日 周六',
      imageId: 1021,
    ),
    _ActivityItem(
      title: '城市徒步 · 外滩夜走',
      subtitle: '5月3日 周六',
      imageId: 1026,
    ),
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
          _buildFeedSection(title: '红色旅游', items: _feed1),
          _buildFeedSection(title: '同城聚会', items: _feed2),
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
          // Hero 背景图
          Image.network(
            'https://picsum.photos/id/1036/1200/600',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(color: const Color(0xFFFFE8C0));
            },
            errorBuilder: (_, e, s) =>
                Container(color: const Color(0xFFFFE8C0)),
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
          // 图片（aspect ratio 4:3）
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.network(
                'https://picsum.photos/id/${item.imageId}/280/210',
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(color: const Color(0xFFFFE8C0));
                },
                errorBuilder: (_, e, s) =>
                    Container(color: const Color(0xFFFFE8C0)),
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
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF999999)),
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
  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.imageId,
  });
  final String title;
  final String subtitle;
  final int imageId;
}
