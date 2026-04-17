import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/pm_image.dart';

/// 搭子 Tab 首页
class BuddyScreen extends StatefulWidget {
  const BuddyScreen({super.key});

  @override
  State<BuddyScreen> createState() => _BuddyScreenState();
}

class _BuddyScreenState extends State<BuddyScreen> with WidgetsBindingObserver {
  // 搭子局 分类
  static const _categories = ['生活', '学习', '兴趣', '游戏', '自定义'];
  int _catIndex = 0;

  static const _subTags = {
    '生活': ['饭搭子', '探店搭子', '遛宠搭子', '观影搭子', '健身搭子', '更多...'],
    '学习': ['考研搭子', '刷题搭子', '图书馆搭子', '语言搭子', '更多...'],
    '兴趣': ['摄影搭子', '手工搭子', '读书搭子', '音乐搭子', '更多...'],
    '游戏': ['手游搭子', '桌游搭子', '剧本杀搭子', 'Steam搭子', '更多...'],
    '自定义': ['我发起的', '我参与的'],
  };
  int _subTagIndex = -1;
  final int _topTab = 0;

  // ── 搜索状态 ──────────────────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchActive = false; // 搜索模式是否激活（唯一权威标志）
  bool _hasResults = false;
  int _searchTab = 0;

  static const _hotTags = ['爬山搭子', '读书搭子', '健身搭子', '游戏搭子', '电影搭子', '旅行搭子', '摄影搭子', '美食搭子'];
  static const _searchTabs = ['精选搭子', '新人搭子', '附近搭子', '活跃搭子'];
  static const _people = [
    _PersonData(emoji: '😊', g1: Color(0xFFFDE68A), g2: Color(0xFFFB923C), name: '阿毛', online: true),
    _PersonData(emoji: '🙂', g1: Color(0xFFFED7AA), g2: Color(0xFFF97316), name: '大欢', online: false),
    _PersonData(emoji: '😄', g1: Color(0xFFD9F99D), g2: Color(0xFF84CC16), name: '小雅', online: true),
    _PersonData(emoji: '😃', g1: Color(0xFFBFDBFE), g2: Color(0xFF60A5FA), name: '邓子', online: false),
    _PersonData(emoji: '😆', g1: Color(0xFFFECDD3), g2: Color(0xFFF43F5E), name: '欢哥', online: true),
    _PersonData(emoji: '🙃', g1: Color(0xFFC7D2FE), g2: Color(0xFF818CF8), name: '小鱼', online: false),
    _PersonData(emoji: '😁', g1: Color(0xFFA7F3D0), g2: Color(0xFF34D399), name: '老王', online: false),
    _PersonData(emoji: '😏', g1: Color(0xFFFDE68A), g2: Color(0xFFFBBF24), name: '冬冬', online: true),
  ];
  static const _results = [
    _ResultData(emoji: '🧗', gradientColors: [Color(0xFFD9F99D), Color(0xFF84CC16)], name: '登山小雅', badge: '精选', badgeGreen: false, tags: ['爬山', '户外', '摄影'], desc: '周末常爬北山，想找一起看日出的搭子', meta: '3.2km · 上线 2 小时前'),
    _ResultData(emoji: '⛰️', gradientColors: [Color(0xFFFDE68A), Color(0xFFF59E0B)], name: '阿毛户外', badge: '在线', badgeGreen: true, tags: ['爬山', '露营'], desc: '资深驴友，去过华山泰山，周末空闲', meta: '5.1km · 刚刚在线'),
    _ResultData(emoji: '🥾', gradientColors: [Color(0xFFC7D2FE), Color(0xFF818CF8)], name: '欢哥探路', badge: '活跃', badgeGreen: false, tags: ['爬山', '徒步', '野炊'], desc: '组建过多次周末爬山小队，欢迎加入', meta: '7.8km · 昨天在线'),
  ];

  // 搜索模式：只要 _searchActive=true 就拦截返回手势，避免中间帧导致的漏拦截
  bool get _isSearching => _searchActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus && !_searchActive) {
        setState(() => _searchActive = true);
      } else {
        setState(() {}); // 失焦时仅刷新，不清 _searchActive
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // 在 WidgetsBinding 层拦截 Android 返回手势，
  // 比 PopScope 更早执行，与 go_router 嵌套 Navigator 层级无关
  @override
  Future<bool> didPopRoute() async {
    if (_searchActive) {
      _cancelSearch();
      return true; // 已处理，不再向上冒泡
    }
    return false; // 未处理，交给系统
  }

  void _doSearch() {
    final text = _searchCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _hasResults = false);
    } else {
      setState(() { _searchActive = true; _hasResults = true; });
    }
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _hasResults = false);
    // 焦点保持，键盘不收起，用户可继续输入
  }

  void _cancelSearch() {
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() { _searchActive = false; _hasResults = false; });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 搜索激活时拦截系统返回（Android 返回键 / 边缘滑动），改为取消搜索
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelSearch();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF9EF),
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: _isSearching
                    ? (_hasResults ? _buildResultList() : _buildSearchDefaultContent())
                    : _buildNormalContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 搜索栏（贯穿所有状态的唯一输入框）────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          // 搜索框
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFF8C42), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8C42).withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search_rounded, color: Color(0xFFFF8C42), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => _doSearch(),
                      onSubmitted: (_) => _doSearch(),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF2C2C2A)),
                      decoration: const InputDecoration(
                        hintText: '搜搭子或搭子局…',
                        hintStyle: TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Container(
                        width: 18, height: 18,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: const BoxDecoration(color: Color(0xFFDDDDDD), shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 11, color: Color(0xFF999999)),
                      ),
                    )
                  else
                    const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 搜索结果列表（有结果时显示）─────────────────────────────────────────

  Widget _buildResultList() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('搭子推荐',
                    style: TextStyle(fontSize: 13, color: Color(0xFF888780))),
                Text('共 24 人',
                    style: TextStyle(fontSize: 12, color: Color(0xFFFF8C42))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: _results
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ResultCard(data: r),
                      ))
                  .toList(),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            height: 0.5,
            color: const Color(0xFFE8E6E0),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('相关搭子局',
                    style: TextStyle(fontSize: 13, color: Color(0xFF888780))),
                Text('共 8 个',
                    style: TextStyle(fontSize: 12, color: Color(0xFFFF8C42))),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _GroupCard(),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('查看更多结果',
                  style: TextStyle(fontSize: 13, color: Color(0xFFFF8C42))),
            ),
          ),
        ],
      ),
    );
  }

  // ── 搜索激活但未出结果：热搜词 + Tab + 人物宫格 ───────────────────────────

  Widget _buildSearchDefaultContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          // 热搜标签
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text('大家都在搜',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFFF8C42))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _hotTags.map((tag) => GestureDetector(
                onTap: () {
                  _searchCtrl.text = tag;
                  _doSearch();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF8C42).withValues(alpha: 0.25), width: 0.5),
                  ),
                  child: Text(tag, style: const TextStyle(fontSize: 13, color: Color(0xFF555550))),
                ),
              )).toList(),
            ),
          ),
          // Tab 切换
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0ECE7),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: List.generate(_searchTabs.length, (i) {
                  final active = i == _searchTab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _searchTab = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: active
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
                              : null,
                        ),
                        child: Text(
                          _searchTabs[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                            color: active ? const Color(0xFFFF8C42) : const Color(0xFF888780),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          // 5列人物宫格
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 14,
                crossAxisSpacing: 6,
                childAspectRatio: 0.75,
              ),
              itemCount: _people.length,
              itemBuilder: (_, i) => _PersonCell(data: _people[i]),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── 普通内容（搜索未激活时）────────────────────────────────────────────────

  Widget _buildNormalContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildBanner()),
        SliverToBoxAdapter(child: _buildCategoryGrid(context)),
        SliverToBoxAdapter(child: _buildTopTabBar()),
        SliverToBoxAdapter(child: _buildCategoryTabs()),
        SliverToBoxAdapter(child: _buildSubTagRow()),
        _topTab == 0
            ? (_subTagIndex < 0
                ? _buildGatherListSliver()
                : _buildSubTagBuddyGridSliver())
            : _buildBuddyFeedGridSliver(),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
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
                    child: _CategoryCard(title: '发起搭子局', subtitle: '呼朋唤友出去玩', bgColor: const Color(0xFFFFE082), decoType: _CardDecoType.offline, onTap: () => _showPublishDialog()),
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
  // ══════════════════════════════════════════════════════════════════════════
  //  以下是新增的搭子局 / 搭子人物 两层切换
  // ══════════════════════════════════════════════════════════════════════════

  // ── 顶部 Tab 栏：搭子局 / 搭子 ─────────────────────────────────────────
  Widget _buildTopTabBar() {
    return const SizedBox.shrink();
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
          childAspectRatio: 0.47,
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
      useRootNavigator: true,     // 挂到根 Navigator，不受 Scaffold resizeToAvoidBottomInset 影响
      enableDrag: false,
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
    final mo = dt.month.toString().padLeft(2, '0');
    final d  = dt.day.toString().padLeft(2, '0');
    final h  = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}年${mo}月${d}日 $h:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final isFull = item.joinedCount >= item.totalCount;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDE5DA), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 90px image strip ──────────────────────────────────────────
            SizedBox(
              height: 90,
              child: Stack(fit: StackFit.expand, children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [item.themeColor.withAlpha(210), item.themeColor.withAlpha(130)],
                      ),
                    ),
                  ),
                ),
                // Dark overlay
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(color: Colors.black.withAlpha(56)),
                ),
                // Category badge — bottom left
                Positioned(
                  bottom: 10, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.themeColor.withAlpha(230),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(item.theme, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
                  ),
                ),
              ]),
            ),
            // ── Body ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF222222), height: 1.35)),
                const SizedBox(height: 8),
                // Location
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFFC8BFB5)),
                  const SizedBox(width: 5),
                  Expanded(child: Text(item.location, style: const TextStyle(fontSize: 12, color: Color(0xFF888888)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 4),
                // Start time
                Row(children: [
                  const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF4ADE80)),
                  const SizedBox(width: 5),
                  const Text('开始', style: TextStyle(fontSize: 12, color: Color(0xFF16A34A))),
                  const SizedBox(width: 3),
                  Text(_fmt(item.startTime), style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                ]),
                const SizedBox(height: 4),
                // End time
                Row(children: [
                  const Icon(Icons.cancel_outlined, size: 12, color: Color(0xFFF87171)),
                  const SizedBox(width: 5),
                  const Text('结束', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                  const SizedBox(width: 3),
                  Text(_fmt(item.endTime), style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                ]),
                const SizedBox(height: 10),
                // Footer
                Row(children: [
                  // Avatar stack (24px, -6px overlap)
                  SizedBox(
                    height: 24,
                    width: item.avatars.length * 18.0 + 6,
                    child: Stack(children: List.generate(item.avatars.length, (i) => Positioned(
                      left: i * 18.0,
                      child: Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: ClipOval(child: PmImage(item.avatars[i], width: 24, height: 24, fit: BoxFit.cover)),
                      ),
                    ))),
                  ),
                  const SizedBox(width: 10),
                  Text('${item.joinedCount}/${item.totalCount} 人参加', style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                  const Spacer(),
                  GestureDetector(
                    onTap: isFull ? null : () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                      decoration: BoxDecoration(
                        color: isFull ? const Color(0xFFF0ECE6) : const Color(0xFFFF8C42),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('参加', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: isFull ? const Color(0xFFC8BFB5) : Colors.white,
                      )),
                    ),
                  ),
                ]),
              ]),
            ),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDE5DA), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 3:4 cover image ──────────────────────────────────────────
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(fit: StackFit.expand, children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: PmImage(data.avatar, fit: BoxFit.cover, width: double.infinity),
                ),
                Positioned(
                  top: 9, left: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C42).withAlpha(230),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(data.tag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white)),
                  ),
                ),
              ]),
            ),
            // ── Body ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Name + age
                Row(children: [
                  Text(data.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF222222))),
                  const SizedBox(width: 5),
                  Text('${data.age}岁', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ]),
                const SizedBox(height: 3),
                // Location
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 10, color: Color(0xFFC8BFB5)),
                  const SizedBox(width: 3),
                  Text(data.city, style: const TextStyle(fontSize: 11, color: Color(0xFFC8BFB5))),
                ]),
                const SizedBox(height: 6),
                // Description (2 lines)
                Text(data.desc,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999), height: 1.45),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 9),
                // Invite button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C42),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('邀约', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _customPeopleCtrl = TextEditingController();

  int? _categoryIndex;
  DateTime? _startTime;
  DateTime? _endTime;
  // 2/3/4 → 固定；-1 → 自定义（读 _customPeopleCtrl）
  int? _peopleCount;
  bool _customPeopleMode = false;
  String? _location;
  final Set<int> _vibeSet = {};

  static const _categories = [
    ('🍜', '吃货'),
    ('👀', '看看'),
    ('⚽', '运动'),
    ('🎮', '游戏'),
    ('✨', '其他'),
  ];
  static const _vibes = ['轻松', '认真', '新手友好'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // 时间格式：2026年4月17日 20:30
  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}年${dt.month}月${dt.day}日 $h:$m';
  }

  Future<void> _pickLocation() async {
    final ctrl = TextEditingController(text: _location);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('输入集合地点', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '如：图书馆南门、B区食堂门口',
                  hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
                  filled: true,
                  fillColor: const Color(0xFFF7F7F7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _location = ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                  ),
                  child: const Text('确认', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickStartTime() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final init = _startTime ?? now;
    final date = await showDatePicker(
      context: context, initialDate: init, firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFFF7A00))), child: child!),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context, initialTime: TimeOfDay.fromDateTime(init),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFFF7A00))), child: child!),
    );
    if (time == null || !mounted) return;
    final result = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      _startTime = result;
      if (_endTime != null && _endTime!.isBefore(result)) {
        _endTime = result.add(const Duration(hours: 2));
      }
    });
  }

  Future<void> _pickEndTime() async {
    final base = _startTime ?? DateTime.now();
    final baseDay = DateTime(base.year, base.month, base.day);
    final init = _endTime ?? base.add(const Duration(hours: 2));
    final date = await showDatePicker(
      context: context, initialDate: init, firstDate: baseDay,
      lastDate: baseDay.add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFFF7A00))), child: child!),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context, initialTime: TimeOfDay.fromDateTime(init),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFFF7A00))), child: child!),
    );
    if (time == null || !mounted) return;
    setState(() => _endTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── 橙色渐变头部 ──────────────────────────────────────────────────
          _buildHeader(),

          // ── 表单区 ───────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleField(),
                  _buildDivider(),
                  _buildCategoryRow(),
                  _buildDivider(),
                  _buildLocationRow(),
                  _buildDivider(),
                  _buildTimeRow(),
                  _buildDivider(),
                  _buildPeopleRow(),
                  _buildDivider(),
                  _buildVibeRow(),
                  _buildDivider(),
                  _buildDescField(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── 底部发布按钮 ─────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9A3C), Color(0xFFFF6B00)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7A00).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text('发布搭子局',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 头部 ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D1B69), Color(0xFF11998E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 44, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('🎯 发起搭子局',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.3)),
                SizedBox(height: 4),
                Text('习惯相遇，就是找到人',
                    style: TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white70, size: 22),
          ),
        ],
      ),
    );
  }

  // ── 活动名称 ─────────────────────────────────────────────────────────────

  Widget _buildTitleField() {
    return _Section(
      iconBg: const Color(0xFFFFF0E0),
      icon: '📝',
      label: '活动名称',
      child: TextField(
        controller: _titleCtrl,
        style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
        decoration: InputDecoration(
          hintText: '今晚一起打羽毛球',
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
          filled: true,
          fillColor: const Color(0xFFF7F7F7),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        ),
      ),
    );
  }

  // ── 类型 ─────────────────────────────────────────────────────────────────

  Widget _buildCategoryRow() {
    return _Section(
      iconBg: const Color(0xFFE8F5E9),
      icon: '🎨',
      label: '类型',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_categories.length, (i) {
            final selected = i == _categoryIndex;
            return GestureDetector(
              onTap: () => setState(() => _categoryIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFFF7A00) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_categories[i].$1} ${_categories[i].$2}',
                  style: TextStyle(
                    fontSize: 13,
                    color: selected ? Colors.white : const Color(0xFF555555),
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

  // ── 地点 ─────────────────────────────────────────────────────────────────

  Widget _buildLocationRow() {
    return _Section(
      iconBg: const Color(0xFFFFEBEE),
      icon: '📍',
      label: '地点',
      child: GestureDetector(
        onTap: _pickLocation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _location ?? '选择位置',
                  style: TextStyle(
                    fontSize: 14,
                    color: _location != null ? const Color(0xFF333333) : const Color(0xFFBBBBBB),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCCCCCC)),
            ],
          ),
        ),
      ),
    );
  }

  // ── 时间 ─────────────────────────────────────────────────────────────────

  Widget _buildTimeRow() {
    final hasStart = _startTime != null;
    final hasEnd = _endTime != null;
    return _Section(
      iconBg: const Color(0xFFE3F2FD),
      icon: '🕐',
      label: '时间',
      child: Column(
        children: [
          // 开始时间行
          GestureDetector(
            onTap: _pickStartTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('开始  ', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                  Expanded(
                    child: Text(
                      hasStart ? _fmtTime(_startTime!) : '选择开始时间',
                      style: TextStyle(
                        fontSize: 13,
                        color: hasStart ? const Color(0xFF333333) : const Color(0xFFBBBBBB),
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: Color(0xFFCCCCCC)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 结束时间行
          GestureDetector(
            onTap: _pickEndTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('结束  ', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                  Expanded(
                    child: Text(
                      hasEnd ? _fmtTime(_endTime!) : '选择结束时间',
                      style: TextStyle(
                        fontSize: 13,
                        color: hasEnd ? const Color(0xFF333333) : const Color(0xFFBBBBBB),
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: Color(0xFFCCCCCC)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 人数 ─────────────────────────────────────────────────────────────────

  Widget _buildPeopleRow() {
    Widget pill({required String label, required bool selected, required VoidCallback onTap}) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 36,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFF7A00) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? Colors.white : const Color(0xFF555555),
              ),
            ),
          ),
        ),
      );
    }

    return _Section(
      iconBg: const Color(0xFFF3E5F5),
      icon: '👥',
      label: '人数',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...([2, 3, 4].map((n) => pill(
                label: '$n人',
                selected: !_customPeopleMode && n == _peopleCount,
                onTap: () => setState(() { _peopleCount = n; _customPeopleMode = false; }),
              ))),
              pill(
                label: '自定义',
                selected: _customPeopleMode,
                onTap: () => setState(() { _customPeopleMode = true; _peopleCount = -1; }),
              ),
            ],
          ),
          if (_customPeopleMode) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: TextField(
                controller: _customPeopleCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '请输入人数',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
                  filled: true,
                  fillColor: const Color(0xFFF7F7F7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                  suffixText: '人',
                  suffixStyle: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 氛围（可选）─────────────────────────────────────────────────────────

  Widget _buildVibeRow() {
    return _Section(
      iconBg: const Color(0xFFFFF8E1),
      icon: '💬',
      label: '氛围',
      optional: true,
      child: Row(
        children: List.generate(_vibes.length, (i) {
          final selected = _vibeSet.contains(i);
          return GestureDetector(
            onTap: () => setState(() {
              if (selected) { _vibeSet.remove(i); } else { _vibeSet.add(i); }
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFFF0DC) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? const Color(0xFFFF7A00) : Colors.transparent,
                ),
              ),
              child: Text(
                _vibes[i],
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? const Color(0xFFFF7A00) : const Color(0xFF777777),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── 说明（可选）─────────────────────────────────────────────────────────

  Widget _buildDescField() {
    return _Section(
      iconBg: const Color(0xFFE8EAF6),
      icon: '✏️',
      label: '说明',
      optional: true,
      child: TextField(
        controller: _descCtrl,
        maxLines: 3,
        style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
        decoration: InputDecoration(
          hintText: '比如：新手也可以，女生优先…',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
          filled: true,
          fillColor: const Color(0xFFF7F7F7),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDivider() =>
      const Divider(height: 24, thickness: 0.5, color: Color(0xFFF0F0F0));
}

// ─────────────────────────────────────────────────────────────────────────────
// 表单行通用容器
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.iconBg,
    required this.icon,
    required this.label,
    required this.child,
    this.optional = false,
  });

  final Color iconBg;
  final String icon;
  final String label;
  final Widget child;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
            if (optional) ...[
              const SizedBox(width: 6),
              const Text('(可选)',
                  style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
            ],
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  搜索相关：人物数据 + 人物格子
// ═════════════════════════════════════════════════════════════════════════════

class _PersonData {
  const _PersonData({
    required this.emoji,
    required this.g1,
    required this.g2,
    required this.name,
    required this.online,
  });
  final String emoji;
  final Color g1;
  final Color g2;
  final String name;
  final bool online;
}

class _PersonCell extends StatelessWidget {
  const _PersonCell({required this.data});
  final _PersonData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [data.g1, data.g2],
                ),
              ),
              child: Center(child: Text(data.emoji, style: const TextStyle(fontSize: 24))),
            ),
            if (data.online)
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFDF9F6), width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Text(data.name,
            style: const TextStyle(fontSize: 11, color: Color(0xFF888780)),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  搜索相关：结果数据 + 结果卡片
// ═════════════════════════════════════════════════════════════════════════════

class _ResultData {
  const _ResultData({
    required this.emoji,
    required this.gradientColors,
    required this.name,
    required this.badge,
    required this.badgeGreen,
    required this.tags,
    required this.desc,
    required this.meta,
  });
  final String emoji;
  final List<Color> gradientColors;
  final String name;
  final String badge;
  final bool badgeGreen;
  final List<String> tags;
  final String desc;
  final String meta;
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.data});
  final _ResultData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: data.gradientColors,
              ),
            ),
            child: Center(
              child: Text(data.emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(data.name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2C2C2A))),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: data.badgeGreen
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: data.badgeGreen
                              ? const Color(0xFF16A34A).withValues(alpha: 0.2)
                              : const Color(0xFFFF8C42).withValues(alpha: 0.25),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        data.badge,
                        style: TextStyle(
                          fontSize: 11,
                          color: data.badgeGreen
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFFF8C42),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 5,
                  children: data.tags
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(t,
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF888780))),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 5),
                Text(
                  data.desc,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF888780), height: 1.4),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(data.meta,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFBBBBBB))),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8C42),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('打招呼',
                          style:
                              TextStyle(fontSize: 12, color: Colors.white)),
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
}

// ═════════════════════════════════════════════════════════════════════════════
//  搜索相关：搭子局卡片
// ═════════════════════════════════════════════════════════════════════════════

class _GroupCard extends StatelessWidget {
  const _GroupCard();

  static const _memberColors = [
    [Color(0xFFFDE68A), Color(0xFFF59E0B)],
    [Color(0xFFD9F99D), Color(0xFF84CC16)],
    [Color(0xFFBFDBFE), Color(0xFF60A5FA)],
    [Color(0xFFFECDD3), Color(0xFFF43F5E)],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.black.withValues(alpha: 0.06), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('周末爬山小队 · 本周六',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C2C2A))),
              Text('12/20 人',
                  style:
                      TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('爬山',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFFFF8C42))),
              ),
              const SizedBox(width: 8),
              const Text('市郊北山 · 8:00 集合',
                  style:
                      TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))),
            ],
          ),
          const SizedBox(height: 6),
          const Text('轻装徒步，来回约 5 小时，老手新手都欢迎',
              style: TextStyle(
                  fontSize: 12, color: Color(0xFF888780), height: 1.4)),
          const SizedBox(height: 8),
          SizedBox(
            height: 26,
            child: Stack(
              children: [
                ..._memberColors.asMap().entries.map((e) => Positioned(
                      left: e.key * 18.0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: e.value,
                          ),
                          border:
                              Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    )),
                Positioned(
                  left: _memberColors.length * 18.0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF3F3F3),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Center(
                      child: Text('+8',
                          style: TextStyle(
                              fontSize: 8, color: Color(0xFFAAAAAA))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
