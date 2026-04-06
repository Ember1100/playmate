import 'package:flutter/material.dart';

/// 集市 Tab 首页（4个子模块）
class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFE8C0),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopTabBar(),
              Expanded(
                child: TabBarView(
                  children: [
                    _LostFoundTab(),
                    const _ComingSoonTab(label: '二手闲置'),
                    const _ComingSoonTab(label: '兼职啦'),
                    const _ComingSoonTab(label: '以物换物'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopTabBar() {
    return Container(
      color: const Color(0xFFF7F7F8),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: TabBar(
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        labelColor: const Color(0xFF222222),
        unselectedLabelColor: const Color(0xFF888888),
        indicator: BoxDecoration(
          color: const Color(0xFFEBEBED),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '失物招领'),
          Tab(text: '二手闲置'),
          Tab(text: '兼职啦'),
          Tab(text: '以物换物'),
        ],
      ),
    );
  }
}

// ── 失物招领页 ────────────────────────────────────────────────────────────────

class _LostFoundTab extends StatefulWidget {
  @override
  State<_LostFoundTab> createState() => _LostFoundTabState();
}

class _LostFoundTabState extends State<_LostFoundTab>
    with SingleTickerProviderStateMixin {
  late final TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header 区（主色背景）
        Container(
          color: const Color(0xFFFFB703),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Column(
            children: [
              // 工具栏行
              Row(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 搜索框
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 12),
                          Icon(Icons.search_rounded, color: Color(0xFF999999), size: 18),
                          SizedBox(width: 6),
                          Text('搜索失物/招领', style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 标题行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '失物招领',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA000),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '我要发布',
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
              const SizedBox(height: 10),
            ],
          ),
        ),
        // 白色卡片区（圆角顶部）
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                color: Colors.black.withValues(alpha: 0.06),
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: TabBar(
            controller: _subTabController,
            labelColor: const Color(0xFF222222),
            unselectedLabelColor: const Color(0xFF999999),
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 14),
            indicatorColor: const Color(0xFFFFB703),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: const Color(0xFFF0F0F0),
            tabs: const [
              Tab(text: '失物'),
              Tab(text: '招领'),
              Tab(text: '全部'),
            ],
          ),
        ),
        // 列表区
        Expanded(
          child: Container(
            color: const Color(0xFFFFE8C0),
            child: TabBarView(
              controller: _subTabController,
              children: [
                _LostFoundList(type: 1),
                _LostFoundList(type: 2),
                _LostFoundList(type: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LostFoundList extends StatelessWidget {
  const _LostFoundList({required this.type});
  final int type; // 0=全部 1=失物 2=招领

  static const _items = [
    _LostItem(title: '红色钱包一个，内含身份证和银行卡', tags: ['证件', '钱包'], serial: '04-032-14-22'),
    _LostItem(title: 'AirPods Pro 耳机盒（右耳已丢失）', tags: ['电子', '耳机'], serial: '04-031-09-05'),
    _LostItem(title: '黑色双肩书包（内有课本和笔记本）', tags: ['背包', '书包'], serial: '04-030-16-48'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _items.length,
      itemBuilder: (_, i) => _LostFoundCard(item: _items[i]),
    );
  }
}

class _LostFoundCard extends StatelessWidget {
  const _LostFoundCard({required this.item});
  final _LostItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片占位
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.image_outlined, color: Color(0xFFCCCCCC), size: 28),
            ),
          ),
          const SizedBox(width: 14),
          // 信息区
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // 标签行
                Row(
                  children: item.tags.map((tag) {
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5E1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFFFE0B2)),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(fontSize: 11, color: Color(0xFFD36A00)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Text(
                  '编号：${item.serial}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LostItem {
  const _LostItem({
    required this.title,
    required this.tags,
    required this.serial,
  });
  final String title;
  final List<String> tags;
  final String serial;
}

// ── 开发中占位页 ──────────────────────────────────────────────────────────────

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction_rounded, size: 48, color: Color(0xFFFFB703)),
          const SizedBox(height: 12),
          Text(
            '$label 开发中...',
            style: const TextStyle(fontSize: 16, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}
