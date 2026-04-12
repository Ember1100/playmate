import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/pm_swipe_back.dart';

/// 搜索+搭子精选+筛选展示页面
class BuddySearchScreen extends StatefulWidget {
  const BuddySearchScreen({super.key});

  @override
  State<BuddySearchScreen> createState() => _BuddySearchScreenState();
}

class _BuddySearchScreenState extends State<BuddySearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedFilter = 0;

  static const _filters = ['精选搭子', '新人搭子', '附近搭子', '活跃搭子', '职业搭子'];

  static const _hotSearches = [
    '爬山搭子',
    '读书搭子',
    '健身搭子',
    '游戏搭子',
    '电影搭子',
    '旅行搭子',
  ];

  static const _candidates = [
    _CandidateData('阿毛', null, false),
    _CandidateData('大欢', null, false),
    _CandidateData('小雅', null, true),
    _CandidateData('邓子', null, false),
    _CandidateData('欢哥', null, false),
    _CandidateData('小鱼', null, true),
    _CandidateData('老王', null, false),
    _CandidateData('冬冬', null, true),
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

  @override
  Widget build(BuildContext context) {
    return PmSwipeBack(
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8EC),
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTypeButtons(),
                      _buildHotSearch(),
                      _buildFilterRow(),
                      _buildCandidateGrid(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 顶部搜索栏 ────────────────────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search_rounded,
                      color: Color(0xFF888888), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF2C2C2A)),
                      decoration: const InputDecoration(
                        hintText: '搜索搭子局或搭子...',
                        hintStyle: TextStyle(
                            fontSize: 14, color: Color(0xFF888780)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              '取消',
              style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFFFF7A00),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── 搜索类型入口 ───────────────────────────────────────────────────────────

  Widget _buildTypeButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TypeButton(
            icon: Icons.person_search_outlined,
            label: '搜索搭子',
            onTap: () {},
          ),
          _TypeButton(
            icon: Icons.groups_outlined,
            label: '搜索搭子局',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ── 大家都在搜 ─────────────────────────────────────────────────────────────

  Widget _buildHotSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '大家都在搜',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF7A00),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0DC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: _hotSearches.map((kw) {
                return GestureDetector(
                  onTap: () {
                    _controller.text = kw;
                    _focusNode.unfocus();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      kw,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF2C2C2A)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── 筛选 Tab ───────────────────────────────────────────────────────────────

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 0, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_filters.length, (i) {
            final selected = i == _selectedFilter;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFFF7A00)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFFF7A00)
                        : const Color(0xFFE8E6E0),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF7A00).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  _filters[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: selected
                        ? Colors.white
                        : const Color(0xFF2C2C2A),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── 搭子网格 ───────────────────────────────────────────────────────────────

  Widget _buildCandidateGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _candidates.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 16,
          crossAxisSpacing: 8,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, i) => _CandidateCell(data: _candidates[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 搜索类型按钮
// ─────────────────────────────────────────────────────────────────────────────

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0DC),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF7A00).withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFFFF7A00), size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF2C2C2A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 搭子候选数据
// ─────────────────────────────────────────────────────────────────────────────

class _CandidateData {
  const _CandidateData(this.name, this.avatarUrl, this.isFemale);
  final String name;
  final String? avatarUrl;
  final bool isFemale;
}

// ─────────────────────────────────────────────────────────────────────────────
// 搭子头像单元格
// ─────────────────────────────────────────────────────────────────────────────

class _CandidateCell extends StatelessWidget {
  const _CandidateCell({required this.data});
  final _CandidateData data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/buddy/user/mock_${data.name}'),
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF5F5F5),
            border: Border.all(
              color: data.isFemale
                  ? const Color(0xFFFF7A00).withValues(alpha: 0.3)
                  : const Color(0xFFE8E6E0),
              width: 1.5,
            ),
          ),
          child: Icon(
            data.isFemale
                ? Icons.person_outline_rounded
                : Icons.person_outline_rounded,
            color: data.isFemale
                ? const Color(0xFFFF7A00)
                : const Color(0xFF888780),
            size: 28,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          data.name,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF2C2C2A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
      ),
    );
  }
}
