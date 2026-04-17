import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/pm_swipe_back.dart';

class BuddySearchScreen extends StatefulWidget {
  const BuddySearchScreen({super.key});

  @override
  State<BuddySearchScreen> createState() => _BuddySearchScreenState();
}

class _BuddySearchScreenState extends State<BuddySearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasResults = false;
  int _selectedTab = 0;
  int _selectedFilter = 0;

  static const _hotTags = [
    '爬山搭子', '读书搭子', '健身搭子', '游戏搭子',
    '电影搭子', '旅行搭子', '摄影搭子', '美食搭子',
  ];

  static const _tabs = ['精选搭子', '新人搭子', '附近搭子', '活跃搭子'];

  static const _filterChips = ['全部', '搭子', '搭子局', '附近', '在线', '新人'];

  static const _people = [
    _PersonData('阿毛', '😊', [Color(0xFFFDE68A), Color(0xFFFB923C)], true, true),
    _PersonData('大欢', '🙂', [Color(0xFFFED7AA), Color(0xFFF97316)], false, false),
    _PersonData('小雅', '😄', [Color(0xFFD9F99D), Color(0xFF84CC16)], true, false),
    _PersonData('邓子', '😃', [Color(0xFFBFDBFE), Color(0xFF60A5FA)], false, false),
    _PersonData('欢哥', '😆', [Color(0xFFFECDD3), Color(0xFFF43F5E)], true, false),
    _PersonData('小鱼', '🙃', [Color(0xFFC7D2FE), Color(0xFF818CF8)], false, false),
    _PersonData('老王', '😁', [Color(0xFFA7F3D0), Color(0xFF34D399)], false, false),
    _PersonData('冬冬', '😏', [Color(0xFFFDE68A), Color(0xFFFBBF24)], true, true),
  ];

  static const _results = [
    _ResultData(
      emoji: '🧗',
      gradientColors: [Color(0xFFD9F99D), Color(0xFF84CC16)],
      name: '登山小雅',
      badge: '精选',
      badgeGreen: false,
      tags: ['爬山', '户外', '摄影'],
      desc: '周末常爬北山，想找一起看日出的搭子',
      meta: '3.2km · 上线 2 小时前',
    ),
    _ResultData(
      emoji: '⛰️',
      gradientColors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
      name: '阿毛户外',
      badge: '在线',
      badgeGreen: true,
      tags: ['爬山', '露营'],
      desc: '资深驴友，去过华山泰山，周末空闲',
      meta: '5.1km · 刚刚在线',
    ),
    _ResultData(
      emoji: '🥾',
      gradientColors: [Color(0xFFC7D2FE), Color(0xFF818CF8)],
      name: '欢哥探路',
      badge: '活跃',
      badgeGreen: false,
      tags: ['爬山', '徒步', '野炊'],
      desc: '组建过多次周末爬山小队，欢迎加入',
      meta: '7.8km · 昨天在线',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _doSearch() {
    if (_controller.text.trim().isEmpty) return;
    _focusNode.unfocus();
    setState(() => _hasResults = true);
  }

  void _tapTag(String tag) {
    _controller.text = tag;
    _doSearch();
  }

  void _clearQuery() {
    _controller.clear();
    setState(() => _hasResults = false);
    _focusNode.requestFocus();
  }

  void _cancel() {
    _controller.clear();
    _focusNode.unfocus();
    setState(() => _hasResults = false);
    context.pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PmSwipeBack(
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF9F6),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SearchBar(
                controller: _controller,
                focusNode: _focusNode,
                hasResults: _hasResults,
                onSearch: _doSearch,
                onClear: _clearQuery,
                onCancel: _cancel,
              ),
              Expanded(
                child: _hasResults
                    ? _buildResults()
                    : _buildDefault(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Default content (before search) ──────────────────────────────────────

  Widget _buildDefault() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hot tags section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Text(
              '大家都在搜',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFFFF8C42),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _hotTags
                  .map((tag) => _HotTag(label: tag, onTap: () => _tapTag(tag)))
                  .toList(),
            ),
          ),

          // Tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0ECE7),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final selected = i == _selectedTab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          _tabs[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                            color: selected
                                ? const Color(0xFFFF8C42)
                                : const Color(0xFF888780),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // People grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _people.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 14,
                crossAxisSpacing: 6,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (_, i) => _PersonCell(data: _people[i]),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Result content (after search) ─────────────────────────────────────────

  Widget _buildResults() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              itemCount: _filterChips.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final selected = i == _selectedFilter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFFF8C42) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFFF8C42)
                            : const Color(0xFFFF8C42).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _filterChips[i],
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : const Color(0xFF888780),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // 搭子推荐 header
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

          // Result cards
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

          // Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            height: 0.5,
            color: const Color(0xFFE8E6E0),
          ),

          // 相关搭子局 header
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

          // Group card
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _GroupCard(),
          ),

          // More button
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '查看更多结果',
                style: TextStyle(fontSize: 13, color: Color(0xFFFF8C42)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.hasResults,
    required this.onSearch,
    required this.onClear,
    required this.onCancel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasResults;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          // Search input box
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
                  const Icon(Icons.search_rounded,
                      color: Color(0xFFFF8C42), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF2C2C2A)),
                      decoration: const InputDecoration(
                        hintText: '搜搭子或搭子局…',
                        hintStyle:
                            TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                      onSubmitted: (_) => onSearch(),
                    ),
                  ),
                  // Clear × button (only after search)
                  if (hasResults)
                    GestureDetector(
                      onTap: onClear,
                      child: Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDDDDDD),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 11, color: Color(0xFF999999)),
                      ),
                    )
                  else
                    const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 搜索前：搜索按钮；搜索后：取消按钮
          if (!hasResults)
            GestureDetector(
              onTap: onSearch,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C42),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '搜索',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: onCancel,
              child: const Text(
                '取消',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFFF8C42)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hot tag chip
// ─────────────────────────────────────────────────────────────────────────────

class _HotTag extends StatelessWidget {
  const _HotTag({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFFFF8C42).withValues(alpha: 0.25), width: 0.5),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF888780)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Person data & cell
// ─────────────────────────────────────────────────────────────────────────────

class _PersonData {
  const _PersonData(
      this.name, this.emoji, this.colors, this.isOnline, this.isSelected);
  final String name;
  final String emoji;
  final List<Color> colors;
  final bool isOnline;
  final bool isSelected;
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
                  colors: data.colors,
                ),
                border: data.isSelected
                    ? Border.all(color: const Color(0xFFFF8C42), width: 2.5)
                    : null,
              ),
              child: Center(
                child: Text(data.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            if (data.isOnline)
              Positioned(
                bottom: 0,
                right: 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFFDF9F6), width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          data.name,
          style: const TextStyle(fontSize: 11, color: Color(0xFF888780)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result data & card
// ─────────────────────────────────────────────────────────────────────────────

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
          // Avatar
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
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + badge
                Row(
                  children: [
                    Text(
                      data.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2C2C2A)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
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
                // Tags
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
                            child: Text(
                              t,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF888780)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 5),
                // Desc
                Text(
                  data.desc,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888780),
                      height: 1.4),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Meta + button
                Row(
                  children: [
                    Text(
                      data.meta,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFBBBBBB)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8C42),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '打招呼',
                        style: TextStyle(fontSize: 12, color: Colors.white),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Group card
// ─────────────────────────────────────────────────────────────────────────────

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
        border: Border.all(color: Colors.black.withValues(alpha: 0.06), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '周末爬山小队 · 本周六',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2C2C2A)),
              ),
              Text(
                '12/20 人',
                style: TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Tag + location
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '爬山',
                  style:
                      TextStyle(fontSize: 11, color: Color(0xFFFF8C42)),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '市郊北山 · 8:00 集合',
                style: TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Desc
          const Text(
            '轻装徒步，来回约 5 小时，老手新手都欢迎',
            style: TextStyle(
                fontSize: 12, color: Color(0xFF888780), height: 1.4),
          ),
          const SizedBox(height: 8),
          // Overlap avatars
          SizedBox(
            height: 26,
            child: Stack(
              children: [
                ..._memberColors.asMap().entries.map((e) {
                  return Positioned(
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
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  );
                }),
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
