import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/pm_image.dart';

/// 搭子 Tab 首页
class BuddyScreen extends StatefulWidget {
  const BuddyScreen({super.key});

  @override
  State<BuddyScreen> createState() => _BuddyScreenState();
}

class _BuddyScreenState extends State<BuddyScreen> {
  static const _tags = ['旅行户外', '娱乐搭子', '游戏搭子', '脱单搭子'];

  // 搭子局 分类
  static const _categories = ['生活', '学习', '兴趣', '游戏', '自定义'];
  int _catIndex = 0;

  // 每个一级分类对应的子标签
  static const _subTags = {
    '生活': ['饭搭子', '探店搭子', '遛宠搭子', '观影搭子', '健身搭子', '更多...'],
    '学习': ['考研搭子', '刷题搭子', '图书馆搭子', '语言搭子', '更多...'],
    '兴趣': ['摄影搭子', '手工搭子', '读书搭子', '音乐搭子', '更多...'],
    '游戏': ['手游搭子', '桌游搭子', '剧本杀搭子', 'Steam搭子', '更多...'],
    '自定义': ['我发起的', '我参与的'],
  };
  int _subTagIndex = -1; // -1 = 未选子标签 → 显示搭子局；>=0 → 显示搭子人物

  // 顶层 Tab：0=搭子局  1=搭子
  int _topTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EF),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── 原有头部：标题栏 + 横幅 + 搜索 + 分类卡片 + 标签 ──
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildBanner()),
            SliverToBoxAdapter(child: _buildSearchBar(context)),
            SliverToBoxAdapter(child: _buildCategoryGrid(context)),
            // ── 搭子局 / 搭子 两层切换区域 ──
            SliverToBoxAdapter(child: _buildTopTabBar()),
            SliverToBoxAdapter(child: _buildCategoryTabs()),
            SliverToBoxAdapter(child: _buildSubTagRow()),
            // 内容区
            _topTab == 0
                ? (_subTagIndex < 0
                    ? _buildGatherListSliver()
                    : _buildSubTagBuddyGridSliver())
                : _buildBuddyFeedGridSliver(),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ── 原有：标题栏 ──────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                '俱乐部兴趣活动',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 原有：横幅 ────────────────────────────────────────────────────────────
  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      height: 148,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE8C0), Color(0xFFFFD166), Color(0xFFFFB703)],
                  begin: Alignment(-0.7, -0.7),
                  end: Alignment(1, 1),
                ),
              ),
            ),
          ),
          Positioned(left: 28, top: 12, child: _CloudShape(width: 72, height: 36)),
          Positioned(left: 96, top: 24, child: _CloudShape(width: 56, height: 28, opacity: 0.9)),
          Positioned(right: 80, top: 8, child: _CloudShape(width: 64, height: 32)),
          const Positioned(
            left: 16, top: 0, bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('周末不宅', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF333333), letterSpacing: 1, height: 1.25)),
                Text('组队去野', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF333333), letterSpacing: 1, height: 1.25)),
              ],
            ),
          ),
          Positioned(right: -8, bottom: -12, width: 100, height: 100, child: CustomPaint(painter: _OwlPainter())),
          const Positioned(right: 10, bottom: 8, child: Text('1/1', style: TextStyle(fontSize: 11, color: Color(0x73000000)))),
          Positioned(
            bottom: 4, left: 0, right: 0,
            child: Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
          ),
        ],
      ),
    );
  }

  // ── 原有：搜索栏 ──────────────────────────────────────────────────────────
  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/buddy/search'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        height: 42,
        decoration: BoxDecoration(color: const Color(0xFFFFE8C0), borderRadius: BorderRadius.circular(999)),
        child: const Row(
          children: [
            SizedBox(width: 14),
            Icon(Icons.search_rounded, color: Color(0xFF888888), size: 18),
            SizedBox(width: 8),
            Text('请输入关键词', style: TextStyle(color: Color(0xFF888888), fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ── 原有：三分类卡片（线上搭子/线下搭子/职业搭子）────────────────────────
  Widget _buildCategoryGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: SizedBox(
        height: 202,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _CategoryCard(title: '线上搭子', subtitle: '快速匹配', bgColor: const Color(0xFFFFE8C0), decoType: _CardDecoType.online, onTap: () => context.push('/buddy/candidates')),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _CategoryCard(title: '线下搭子', subtitle: '按照需求进行匹配', bgColor: const Color(0xFFFFE082), decoType: _CardDecoType.offline, onTap: () => context.push('/buddy/candidates')),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CategoryCard(title: '职业搭子', subtitle: '您的专业老师', bgColor: const Color(0xFFFFE8C0), decoType: _CardDecoType.pro, onTap: () => context.push('/buddy/career')),
            ),
          ],
        ),
      ),
    );
  }

  // ── 原有：标签行 ──────────────────────────────────────────────────────────
  Widget _buildTagRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 0, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _tags.map((tag) {
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFF0F0F0)),
                boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x0D000000), offset: Offset(0, 2))],
              ),
              child: Text(tag, style: const TextStyle(fontSize: 13, color: Color(0xFF222222))),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  以下是新增的搭子局 / 搭子人物 两层切换
  // ══════════════════════════════════════════════════════════════════════════

  // ── 顶部 Tab 栏：搭子局 / 搭子 + 发起按钮 ────────────────────────────────
  Widget _buildTopTabBar() {
    return Container(
      height: 50,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Spacer(),
          if (_topTab == 0)
            GestureDetector(
              onTap: () => _showPublishDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFF7A00), borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('发起搭子局', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── 一级分类 Tab（搭子局 Tab 下才显示）────────────────────────────────────
  Widget _buildCategoryTabs() {
    if (_topTab != 0) return const SizedBox.shrink();
    return Container(
      height: 44,
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: List.generate(_categories.length, (i) {
            final selected = i == _catIndex;
            return GestureDetector(
              onTap: () => setState(() { _catIndex = i; _subTagIndex = -1; }),
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFFF7A00) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _categories[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? Colors.white : const Color(0xFF666666),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── 二级子标签行（点击 → 显示搭子人物）────────────────────────────────────
  Widget _buildSubTagRow() {
    if (_topTab != 0) return const SizedBox.shrink();
    final subTags = _subTags[_categories[_catIndex]] ?? [];
    return Container(
      height: 40,
      color: const Color(0xFFFFF9EF),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: List.generate(subTags.length, (i) {
            final selected = i == _subTagIndex;
            final isMore = subTags[i] == '更多...';
            return GestureDetector(
              onTap: isMore ? null : () => setState(() { _subTagIndex = selected ? -1 : i; }),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFFFEDD0) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected ? const Color(0xFFFF7A00) : const Color(0xFFEEEEEE)),
                ),
                child: Text(
                  subTags[i],
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? const Color(0xFFFF7A00) : const Color(0xFF666666),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── 搭子局卡片列表（Sliver）───────────────────────────────────────────────
  SliverList _buildGatherListSliver() {
    final items = _mockGatherItems(_categories[_catIndex]);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => Padding(
          padding: EdgeInsets.fromLTRB(12, i == 0 ? 10 : 0, 12, 12),
          child: _GatherCard(item: items[i], onTap: () => _showGatherDetail(context, items[i])),
        ),
        childCount: items.length,
      ),
    );
  }

  void _showGatherDetail(BuildContext context, _GatherItem item) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _GatherDetailSheet(item: item),
    );
  }

  // ── 子标签 → 搭子人物网格（Sliver）────────────────────────────────────────
  SliverToBoxAdapter _buildSubTagBuddyGridSliver() {
    final subTags = _subTags[_categories[_catIndex]] ?? [];
    final tag = (_subTagIndex >= 0 && _subTagIndex < subTags.length) ? subTags[_subTagIndex] : '';
    final people = _mockBuddyPeople(tag);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
          childAspectRatio: 0.72,
          children: people.map((p) => _BuddyPersonCard(data: p)).toList(),
        ),
      ),
    );
  }

  // ── 搭子 Tab → 原有 Feed 网格（Sliver）───────────────────────────────────
  SliverToBoxAdapter _buildBuddyFeedGridSliver() {
    const feeds = [
      _OrigFeedData('星际海渊', '价格面议', '已预约：0 剩余：10', 'https://picsum.photos/seed/meal/300/240'),
      _OrigFeedData('室内烤肉自助活动', '¥58.00', '已预约：0 剩余：8', 'https://picsum.photos/seed/bbq/300/240'),
      _OrigFeedData('骑在黎明破晓前露营折叠车', '免费', '已预约：0 剩余：5', 'https://picsum.photos/seed/friend/300/240'),
      _OrigFeedData('室内网球活动', '¥88.00', '已预约：0 剩余：12', 'https://picsum.photos/seed/tennis/300/240'),
    ];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
          childAspectRatio: 0.78,
          children: feeds.map((f) => _OrigFeedCard(data: f)).toList(),
        ),
      ),
    );
  }

  void _showPublishDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,          // 禁止下滑手势关闭，防止事件穿透到底层页面
      backgroundColor: Colors.transparent,
      builder: (_) => const _PublishGatherSheet(),
    );
  }

  // ── 搭子局模拟数据 ────────────────────────────────────────────────────────
  List<_GatherItem> _mockGatherItems(String cat) {
    switch (cat) {
      case '生活':
        return [
          _GatherItem(title: '周末饭局 · 探秘地道川菜', location: '上海市黄浦区南京东路888号', startTime: DateTime(2026, 4, 19, 18, 30, 0), endTime: DateTime(2026, 4, 19, 21, 0, 0), theme: '饭搭子', themeColor: const Color(0xFFFF7A00), joinedCount: 4, totalCount: 8, avatars: ['https://picsum.photos/seed/u1/40/40', 'https://picsum.photos/seed/u2/40/40', 'https://picsum.photos/seed/u3/40/40']),
          _GatherItem(title: '遛猫下午茶 · 宠物友好咖啡馆', location: '上海市徐汇区衡山路12号', startTime: DateTime(2026, 4, 20, 14, 0, 0), endTime: DateTime(2026, 4, 20, 17, 0, 0), theme: '遛宠搭子', themeColor: const Color(0xFF5DCAA5), joinedCount: 2, totalCount: 6, avatars: ['https://picsum.photos/seed/u4/40/40', 'https://picsum.photos/seed/u5/40/40']),
          _GatherItem(title: '周五观影 · 《流浪地球3》首映', location: '上海市浦东新区张江CGV影城', startTime: DateTime(2026, 4, 18, 19, 40, 0), endTime: DateTime(2026, 4, 18, 22, 0, 0), theme: '观影搭子', themeColor: const Color(0xFF9C27B0), joinedCount: 5, totalCount: 10, avatars: ['https://picsum.photos/seed/u6/40/40', 'https://picsum.photos/seed/u7/40/40', 'https://picsum.photos/seed/u8/40/40']),
        ];
      case '学习':
        return [
          _GatherItem(title: '考研备战 · 图书馆打卡团', location: '上海图书馆东馆（陆家嘴）', startTime: DateTime(2026, 4, 16, 9, 0, 0), endTime: DateTime(2026, 4, 16, 18, 0, 0), theme: '考研搭子', themeColor: const Color(0xFF2196F3), joinedCount: 6, totalCount: 10, avatars: ['https://picsum.photos/seed/s1/40/40', 'https://picsum.photos/seed/s2/40/40']),
          _GatherItem(title: '英语角 · 外教口语练习', location: '上海市静安区南京西路1788号', startTime: DateTime(2026, 4, 17, 19, 0, 0), endTime: DateTime(2026, 4, 17, 21, 0, 0), theme: '语言搭子', themeColor: const Color(0xFF4CAF50), joinedCount: 3, totalCount: 8, avatars: ['https://picsum.photos/seed/s3/40/40']),
        ];
      case '兴趣':
        return [
          _GatherItem(title: '街头摄影 · 外滩黄金时刻', location: '上海市黄浦区中山东一路外滩', startTime: DateTime(2026, 4, 19, 17, 30, 0), endTime: DateTime(2026, 4, 19, 20, 0, 0), theme: '摄影搭子', themeColor: const Color(0xFFE91E63), joinedCount: 3, totalCount: 6, avatars: ['https://picsum.photos/seed/h1/40/40', 'https://picsum.photos/seed/h2/40/40']),
        ];
      case '游戏':
        return [
          _GatherItem(title: '剧本杀 · 悬疑推理专场', location: '上海市杨浦区五角场线索屋', startTime: DateTime(2026, 4, 20, 13, 0, 0), endTime: DateTime(2026, 4, 20, 18, 0, 0), theme: '剧本杀搭子', themeColor: const Color(0xFF795548), joinedCount: 4, totalCount: 6, avatars: ['https://picsum.photos/seed/g1/40/40', 'https://picsum.photos/seed/g2/40/40', 'https://picsum.photos/seed/g3/40/40']),
        ];
      default:
        return [];
    }
  }

  // ── 搭子人物模拟数据 ──────────────────────────────────────────────────────
  List<_BuddyPerson> _mockBuddyPeople(String tag) {
    switch (tag) {
      case '饭搭子':
        return const [
          _BuddyPerson(name: '小鱼', age: 23, city: '上海', avatar: 'https://picsum.photos/seed/p1/200/200', desc: '爱吃川菜，周末约饭', tag: '饭搭子'),
          _BuddyPerson(name: '阿杰', age: 25, city: '上海', avatar: 'https://picsum.photos/seed/p2/200/200', desc: '探店达人，火锅爱好者', tag: '饭搭子'),
          _BuddyPerson(name: '甜甜', age: 22, city: '上海', avatar: 'https://picsum.photos/seed/p3/200/200', desc: '甜品控，周末想约下午茶', tag: '饭搭子'),
          _BuddyPerson(name: '大壮', age: 27, city: '上海', avatar: 'https://picsum.photos/seed/p4/200/200', desc: '烧烤达人，自带装备', tag: '饭搭子'),
        ];
      case '探店搭子':
        return const [
          _BuddyPerson(name: '小薇', age: 24, city: '上海', avatar: 'https://picsum.photos/seed/p5/200/200', desc: '咖啡探店，拍照达人', tag: '探店搭子'),
          _BuddyPerson(name: '浩哥', age: 26, city: '上海', avatar: 'https://picsum.photos/seed/p6/200/200', desc: '美食博主，寻找新店', tag: '探店搭子'),
        ];
      case '遛宠搭子':
        return const [
          _BuddyPerson(name: '毛毛妈', age: 25, city: '上海', avatar: 'https://picsum.photos/seed/p7/200/200', desc: '金毛家长，周末公园遛弯', tag: '遛宠搭子'),
          _BuddyPerson(name: '猫叔', age: 28, city: '上海', avatar: 'https://picsum.photos/seed/p8/200/200', desc: '三只猫主人，猫咖常客', tag: '遛宠搭子'),
          _BuddyPerson(name: '柯基控', age: 23, city: '上海', avatar: 'https://picsum.photos/seed/p9/200/200', desc: '柯基爸爸，寻遛狗伙伴', tag: '遛宠搭子'),
        ];
      case '观影搭子':
        return const [
          _BuddyPerson(name: '影迷小李', age: 24, city: '上海', avatar: 'https://picsum.photos/seed/p10/200/200', desc: '科幻迷，每周必看新片', tag: '观影搭子'),
          _BuddyPerson(name: '文艺青年', age: 26, city: '上海', avatar: 'https://picsum.photos/seed/p11/200/200', desc: '独立电影爱好者', tag: '观影搭子'),
        ];
      case '考研搭子':
        return const [
          _BuddyPerson(name: '学霸小陈', age: 22, city: '上海', avatar: 'https://picsum.photos/seed/p12/200/200', desc: '备战27考研，每天图书馆', tag: '考研搭子'),
          _BuddyPerson(name: '阿文', age: 23, city: '上海', avatar: 'https://picsum.photos/seed/p13/200/200', desc: '二战考研，互相监督', tag: '考研搭子'),
          _BuddyPerson(name: '小月', age: 21, city: '上海', avatar: 'https://picsum.photos/seed/p14/200/200', desc: '法硕备考，求研友', tag: '考研搭子'),
        ];
      case '摄影搭子':
        return const [
          _BuddyPerson(name: '阿光', age: 27, city: '上海', avatar: 'https://picsum.photos/seed/p15/200/200', desc: '风光摄影，周末扫街', tag: '摄影搭子'),
          _BuddyPerson(name: '小美', age: 24, city: '上海', avatar: 'https://picsum.photos/seed/p16/200/200', desc: '人像摄影，互拍互修', tag: '摄影搭子'),
        ];
      case '剧本杀搭子':
        return const [
          _BuddyPerson(name: '推理王', age: 25, city: '上海', avatar: 'https://picsum.photos/seed/p17/200/200', desc: '硬核推理，百本+经验', tag: '剧本杀搭子'),
          _BuddyPerson(name: '戏精本精', age: 23, city: '上海', avatar: 'https://picsum.photos/seed/p18/200/200', desc: '情感本爱好者，喜欢沉浸式', tag: '剧本杀搭子'),
          _BuddyPerson(name: '新手小白', age: 22, city: '上海', avatar: 'https://picsum.photos/seed/p19/200/200', desc: '刚入坑，求带飞', tag: '剧本杀搭子'),
        ];
      default:
        return const [
          _BuddyPerson(name: '搭伴用户', age: 25, city: '上海', avatar: 'https://picsum.photos/seed/pd/200/200', desc: '期待与你相遇', tag: '搭子'),
        ];
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  原有组件（保持不变）
// ═════════════════════════════════════════════════════════════════════════════

class _CloudShape extends StatelessWidget {
  const _CloudShape({required this.width, required this.height, this.opacity = 1.0});
  final double width;
  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85 * opacity), borderRadius: BorderRadius.circular(50)),
    );
  }
}

class _OwlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    void ell(double cx, double cy, double rx, double ry, Color color) {
      canvas.drawOval(Rect.fromCenter(center: Offset(cx * s, cy * s), width: rx * 2 * s, height: ry * 2 * s), Paint()..color = color);
    }
    void circ(double cx, double cy, double r, Color color) {
      canvas.drawCircle(Offset(cx * s, cy * s), r * s, Paint()..color = color);
    }
    ell(72, 78, 42, 38, const Color(0xFFC5E1A5));
    ell(72, 72, 38, 34, const Color(0xFFDCEDC8));
    ell(58, 52, 18, 20, Colors.white);
    ell(58, 52, 10, 12, const Color(0xFF263238));
    circ(56, 48, 3, Colors.white);
    ell(78, 48, 14, 16, Colors.white);
    ell(78, 48, 8, 9, const Color(0xFF263238));
    circ(76, 44, 2.5, Colors.white);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _CardDecoType { online, offline, pro }

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.title, required this.subtitle, required this.bgColor, required this.decoType, required this.onTap});
  final String title;
  final String subtitle;
  final Color bgColor;
  final _CardDecoType decoType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x0D000000), offset: Offset(0, 2))]),
        child: Stack(
          children: [
            Positioned(right: 4, bottom: 4, width: decoType == _CardDecoType.pro ? 80 : 64, height: decoType == _CardDecoType.pro ? 80 : 48, child: CustomPaint(painter: _CardDecoPainter(decoType))),
            Positioned(
              left: 14, top: 14, right: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF222222))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF666666), height: 1.4), maxLines: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardDecoPainter extends CustomPainter {
  const _CardDecoPainter(this.type);
  final _CardDecoType type;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    void ell(double cx, double cy, double rx, double ry, Color color, {double opacity = 1.0}) {
      canvas.drawOval(Rect.fromCenter(center: Offset(cx * w, cy * h), width: rx * 2 * w, height: ry * 2 * h), Paint()..color = color.withValues(alpha: opacity));
    }
    switch (type) {
      case _CardDecoType.online:
        ell(0.67, 0.68, 0.31, 0.29, const Color(0xFFFCE4EC), opacity: 0.95);
        ell(0.39, 0.39, 0.25, 0.25, Colors.white);
        ell(0.72, 0.32, 0.19, 0.20, const Color(0xFFF8BBD9));
      case _CardDecoType.offline:
        ell(0.61, 0.64, 0.31, 0.27, Colors.white);
        ell(0.36, 0.36, 0.22, 0.23, const Color(0xFFFFF9C4));
        ell(0.72, 0.29, 0.17, 0.18, const Color(0xFFFFE082));
      case _CardDecoType.pro:
        ell(0.43, 0.28, 0.22, 0.14, Colors.white, opacity: 0.9);
        ell(0.65, 0.58, 0.30, 0.24, const Color(0xFF42A5F5), opacity: 0.65);
        ell(0.50, 0.78, 0.22, 0.16, const Color(0xFF64B5F6), opacity: 0.55);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
//  顶层 Tab 文字
// ═════════════════════════════════════════════════════════════════════════════

class _TopTab extends StatelessWidget {
  const _TopTab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, color: selected ? const Color(0xFF222222) : const Color(0xFF999999))),
          const SizedBox(height: 2),
          AnimatedContainer(duration: const Duration(milliseconds: 200), height: 3, width: selected ? 24 : 0, decoration: BoxDecoration(color: const Color(0xFFFF7A00), borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  搭子局数据模型 + 卡片
// ═════════════════════════════════════════════════════════════════════════════

class _GatherItem {
  const _GatherItem({required this.title, required this.location, required this.startTime, required this.endTime, required this.theme, required this.themeColor, required this.joinedCount, required this.totalCount, required this.avatars});
  final String title;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final String theme;
  final Color themeColor;
  final int joinedCount;
  final int totalCount;
  final List<String> avatars;
}

class _GatherCard extends StatelessWidget {
  const _GatherCard({required this.item, required this.onTap});
  final _GatherItem item;
  final VoidCallback onTap;

  String _fmt(DateTime dt) {
    return '${dt.year}年${dt.month.toString().padLeft(2, '0')}月'
        '${dt.day.toString().padLeft(2, '0')}日 '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x0D000000), offset: Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(item.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF222222), height: 1.4))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: item.themeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: item.themeColor.withValues(alpha: 0.4))),
                child: Text(item.theme, style: TextStyle(fontSize: 11, color: item.themeColor, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF999999)),
              const SizedBox(width: 4),
              Expanded(child: Text(item.location, style: const TextStyle(fontSize: 12, color: Color(0xFF888888)), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.play_circle_outline, size: 13, color: Color(0xFF5DCAA5)),
              const SizedBox(width: 4),
              Text('开始：${_fmt(item.startTime)}', style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.stop_circle_outlined, size: 13, color: Color(0xFFE24B4A)),
              const SizedBox(width: 4),
              Text('结束：${_fmt(item.endTime)}', style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              SizedBox(
                height: 28, width: item.avatars.length * 20.0 + 8,
                child: Stack(children: List.generate(item.avatars.length, (i) {
                  return Positioned(left: i * 20.0, child: Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: ClipOval(child: PmImage(item.avatars[i], width: 28, height: 28, fit: BoxFit.cover))));
                })),
              ),
              const SizedBox(width: 8),
              Text('${item.joinedCount}/${item.totalCount} 人参加', style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFFF7A00), borderRadius: BorderRadius.circular(16)),
                  child: const Text('参加', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  搭子人物数据模型 + 卡片
// ═════════════════════════════════════════════════════════════════════════════

class _BuddyPerson {
  const _BuddyPerson({required this.name, required this.age, required this.city, required this.avatar, required this.desc, required this.tag});
  final String name;
  final int age;
  final String city;
  final String avatar;
  final String desc;
  final String tag;
}

class _BuddyPersonCard extends StatelessWidget {
  const _BuddyPersonCard({required this.data});
  final _BuddyPerson data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/buddy/user/mock_person'),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x0D000000), offset: Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: PmImage(data.avatar, fit: BoxFit.cover, width: double.infinity)),
                Positioned(top: 8, left: 8, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFFF7A00).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(10)),
                  child: Text(data.tag, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                )),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(data.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF222222))),
                  const SizedBox(width: 6),
                  Text('${data.city} · ${data.age}岁', style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
                ]),
                const SizedBox(height: 4),
                Text(data.desc, style: const TextStyle(fontSize: 11, color: Color(0xFF888888)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity, height: 28,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A00), padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('邀约', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  原有 Feed 卡片（搭子 Tab 用）
// ═════════════════════════════════════════════════════════════════════════════

class _OrigFeedData {
  const _OrigFeedData(this.title, this.price, this.status, this.imageUrl);
  final String title;
  final String price;
  final String status;
  final String imageUrl;
}

class _OrigFeedCard extends StatelessWidget {
  const _OrigFeedCard({required this.data});
  final _OrigFeedData data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/buddy/user/mock_feed'),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x0D000000), offset: Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: PmImage(data.imageUrl, fit: BoxFit.cover, width: double.infinity))),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF222222)), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(data.price, style: const TextStyle(fontSize: 13, color: Color(0xFFFF6700), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(data.status, style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  搭子局详情弹窗
// ═════════════════════════════════════════════════════════════════════════════

class _GatherDetailSheet extends StatelessWidget {
  const _GatherDetailSheet({required this.item});
  final _GatherItem item;

  String _fmt(DateTime dt) {
    return '${dt.year}年${dt.month.toString().padLeft(2, '0')}月'
        '${dt.day.toString().padLeft(2, '0')}日 '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF222222)))),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: item.themeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: item.themeColor.withValues(alpha: 0.4))),
                child: Text(item.theme, style: TextStyle(fontSize: 12, color: item.themeColor, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _DetailRow(icon: Icons.location_on_outlined, iconColor: const Color(0xFFFF7A00), label: '活动地点', value: item.location),
                const SizedBox(height: 16),
                _DetailRow(icon: Icons.play_circle_outline, iconColor: const Color(0xFF5DCAA5), label: '开始时间', value: _fmt(item.startTime)),
                const SizedBox(height: 16),
                _DetailRow(icon: Icons.stop_circle_outlined, iconColor: const Color(0xFFE24B4A), label: '结束时间', value: _fmt(item.endTime)),
                const SizedBox(height: 24),
                const Text('参加的搭子', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                const SizedBox(height: 12),
                Row(children: [
                  ...item.avatars.map((url) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFEEEEEE), width: 2)), child: ClipOval(child: PmImage(url, width: 40, height: 40, fit: BoxFit.cover))),
                  )),
                  ...List.generate((item.totalCount - item.joinedCount).clamp(0, 3), (_) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5), color: const Color(0xFFF5F5F5)), child: const Icon(Icons.add, size: 18, color: Color(0xFFCCCCCC))),
                  )),
                ]),
                const SizedBox(height: 8),
                Text('已参加 ${item.joinedCount} 人，共 ${item.totalCount} 个名额', style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
              ]),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF0F0F0)))),
            child: SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('立即参加（${item.joinedCount}/${item.totalCount}）', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.iconColor, required this.label, required this.value});
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 20, color: iconColor),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500)),
      ]),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  发起搭子局弹窗
// ═════════════════════════════════════════════════════════════════════════════

class _PublishGatherSheet extends StatefulWidget {
  const _PublishGatherSheet();

  @override
  State<_PublishGatherSheet> createState() => _PublishGatherSheetState();
}

class _PublishGatherSheetState extends State<_PublishGatherSheet> {
  DateTime? _startTime;
  DateTime? _endTime;

  static String _fmt(DateTime dt) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}年${p(dt.month)}月${p(dt.day)}日 ${p(dt.hour)}:${p(dt.minute)}';
  }

  Future<void> _pickTime(bool isStart) async {
    final now    = DateTime.now();
    final initial = isStart ? (_startTime ?? now) : (_endTime ?? (_startTime ?? now).add(const Duration(hours: 2)));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('zh'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFFF7A00)),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFFF7A00)),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    final result = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startTime = result;
        // 结束时间若早于开始时间，自动顺延 2 小时
        if (_endTime != null && _endTime!.isBefore(result)) {
          _endTime = result.add(const Duration(hours: 2));
        }
      } else {
        _endTime = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text('发起搭子局', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF222222))),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF999999)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _FormField(label: '活动名称', hint: '给你的搭子局起个名字'),
                const SizedBox(height: 16),
                _FormField(label: '活动地点', hint: '输入详细地址'),
                const SizedBox(height: 16),
                _DateTimeTile(
                  label: '开始时间',
                  value: _startTime != null ? _fmt(_startTime!) : null,
                  hint: '请选择开始时间',
                  onTap: () => _pickTime(true),
                ),
                const SizedBox(height: 16),
                _DateTimeTile(
                  label: '结束时间',
                  value: _endTime != null ? _fmt(_endTime!) : null,
                  hint: '请选择结束时间',
                  onTap: () => _pickTime(false),
                ),
                const SizedBox(height: 16),
                _FormField(label: '人数上限', hint: '最多几人参加（2-50）', keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _FormField(label: '活动主题', hint: '饭搭子 / 观影搭子 / 其他...'),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('发布搭子局', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({required this.label, required this.hint, this.value, required this.onTap});
  final String label;
  final String hint;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? hint,
                  style: TextStyle(fontSize: 14, color: value != null ? const Color(0xFF333333) : const Color(0xFFBBBBBB)),
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: Color(0xFFBBBBBB)),
            ],
          ),
        ),
      ),
    ]);
  }
}

class _FormField extends StatelessWidget {
  const _FormField({required this.label, required this.hint, this.keyboardType});
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
      const SizedBox(height: 8),
      TextField(
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
          filled: true, fillColor: const Color(0xFFF7F7F7),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);
  }
}
