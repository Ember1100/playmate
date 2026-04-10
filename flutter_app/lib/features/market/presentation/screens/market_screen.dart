import 'package:flutter/material.dart';

// TODO: replace static data with API calls to /api/v1/market/...

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
              const Expanded(
                child: TabBarView(
                  children: [
                    _LostFoundTab(),
                    _SecondHandTab(),
                    _PartTimeTab(),
                    _BarterTab(),
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
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F8),
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: TabBar(
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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

// ── 通用 Header ────────────────────────────────────────────────────────────────

class _MarketHeader extends StatelessWidget {
  const _MarketHeader({
    required this.title,
    required this.searchHint,
    required this.color,
    this.publishLabel = '我要发布',
  });

  final String title;
  final String searchHint;
  final Color color;
  final String publishLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search_rounded,
                          color: Color(0xFF999999), size: 18),
                      const SizedBox(width: 6),
                      Text(searchHint,
                          style: const TextStyle(
                              color: Color(0xFF999999), fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.tune_rounded,
                    color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  publishLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

Widget _buildSubTabBar(TabController controller, List<String> labels,
    Color indicatorColor) {
  return Container(
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
      controller: controller,
      labelColor: const Color(0xFF222222),
      unselectedLabelColor: const Color(0xFF999999),
      labelStyle:
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 14),
      indicatorColor: indicatorColor,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: const Color(0xFFF0F0F0),
      tabs: labels.map((l) => Tab(text: l)).toList(),
    ),
  );
}

Widget _imagePlaceholder(Color color) {
  return Container(
    color: color,
    child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.white54, size: 22)),
  );
}

// ── 失物招领 ─────────────────────────────────────────────────────────────────

class _LostFoundTab extends StatefulWidget {
  const _LostFoundTab();

  @override
  State<_LostFoundTab> createState() => _LostFoundTabState();
}

class _LostFoundTabState extends State<_LostFoundTab>
    with SingleTickerProviderStateMixin {
  late final TabController _sub;

  // TODO: replace with API call to GET /api/v1/market/lost-found
  static const _items = [
    _LostFoundItem(
      title: '红色钱包一个，内含身份证和银行卡',
      tags: ['证件', '钱包'],
      serial: '04-032-14-22',
      imageUrl: 'https://picsum.photos/seed/lf1/80/80',
      category: 'cert',
    ),
    _LostFoundItem(
      title: 'AirPods Pro 耳机盒（右耳已丢失）',
      tags: ['电子', '耳机'],
      serial: '04-031-09-05',
      imageUrl: 'https://picsum.photos/seed/lf2/80/80',
      category: 'elec',
    ),
    _LostFoundItem(
      title: '黑色双肩书包（内有课本和笔记本）',
      tags: ['背包', '书包'],
      serial: '04-030-16-48',
      imageUrl: 'https://picsum.photos/seed/lf3/80/80',
      category: 'bag',
    ),
    _LostFoundItem(
      title: '蓝色牛仔外套，左袖有小口袋',
      tags: ['衣物', '外套'],
      serial: '04-029-11-30',
      imageUrl: 'https://picsum.photos/seed/lf4/80/80',
      category: 'cloth',
    ),
    _LostFoundItem(
      title: '学生证 + 公交卡（一起丢失）',
      tags: ['证件', '卡片'],
      serial: '04-028-08-15',
      imageUrl: 'https://picsum.photos/seed/lf5/80/80',
      category: 'cert',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _sub = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _sub.dispose();
    super.dispose();
  }

  List<_LostFoundItem> _filtered(String cat) {
    if (cat == 'all') return _items;
    return _items.where((i) => i.category == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _MarketHeader(
          title: '失物招领',
          searchHint: '搜索失物/招领',
          color: Color(0xFFFFB703),
        ),
        _buildSubTabBar(
          _sub,
          const ['全部', '证件', '电子', '衣物'],
          const Color(0xFFFFB703),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFFFE8C0),
            child: TabBarView(
              controller: _sub,
              children: [
                _LostFoundList(items: _filtered('all')),
                _LostFoundList(items: _filtered('cert')),
                _LostFoundList(items: _filtered('elec')),
                _LostFoundList(items: _filtered('cloth')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LostFoundList extends StatelessWidget {
  const _LostFoundList({required this.items});
  final List<_LostFoundItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
          child: Text('暂无数据', style: TextStyle(color: Color(0xFF999999))));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: items.length,
      itemBuilder: (_, i) => _LostFoundCard(item: items[i]),
    );
  }
}

class _LostFoundCard extends StatelessWidget {
  const _LostFoundCard({required this.item});
  final _LostFoundItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Image.network(
                item.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return _imagePlaceholder(const Color(0xFFFFE0B2));
                },
                errorBuilder: (_, e, s) =>
                    _imagePlaceholder(const Color(0xFFFFE0B2)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF222222)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: item.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5E1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFFFE0B2)),
                      ),
                      child: Text(tag,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFFD36A00))),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Text(
                  '编号：${item.serial}',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LostFoundItem {
  const _LostFoundItem({
    required this.title,
    required this.tags,
    required this.serial,
    required this.imageUrl,
    required this.category,
  });
  final String title;
  final List<String> tags;
  final String serial;
  final String imageUrl;
  final String category; // cert / elec / cloth / bag
}

// ── 二手闲置 ─────────────────────────────────────────────────────────────────

class _SecondHandTab extends StatefulWidget {
  const _SecondHandTab();

  @override
  State<_SecondHandTab> createState() => _SecondHandTabState();
}

class _SecondHandTabState extends State<_SecondHandTab>
    with SingleTickerProviderStateMixin {
  late final TabController _sub;

  // TODO: replace with API call to GET /api/v1/market/second-hand
  static const _items = [
    _SecondHandItem(
      title: 'iPhone 13 mini 128G 深空灰',
      price: 1200,
      condition: '九成新',
      category: 'digital',
      imageUrl: 'https://picsum.photos/seed/sh1/300/300',
    ),
    _SecondHandItem(
      title: 'Nike Air Force 1 42码 白色',
      price: 280,
      condition: '八成新',
      category: 'clothes',
      imageUrl: 'https://picsum.photos/seed/sh2/300/300',
    ),
    _SecondHandItem(
      title: '高等数学上下册 + 线性代数',
      price: 35,
      condition: '九成新',
      category: 'books',
      imageUrl: 'https://picsum.photos/seed/sh3/300/300',
    ),
    _SecondHandItem(
      title: '优衣库羊绒圆领毛衣 M码 黑色',
      price: 80,
      condition: '全新',
      category: 'clothes',
      imageUrl: 'https://picsum.photos/seed/sh4/300/300',
    ),
    _SecondHandItem(
      title: 'iPad Air 4 64G WiFi版',
      price: 2200,
      condition: '九成新',
      category: 'digital',
      imageUrl: 'https://picsum.photos/seed/sh5/300/300',
    ),
    _SecondHandItem(
      title: 'Python 编程书籍合集（5本）',
      price: 60,
      condition: '八成新',
      category: 'books',
      imageUrl: 'https://picsum.photos/seed/sh6/300/300',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _sub = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _sub.dispose();
    super.dispose();
  }

  List<_SecondHandItem> _filtered(String cat) {
    if (cat == 'all') return _items;
    return _items.where((i) => i.category == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _MarketHeader(
          title: '二手闲置',
          searchHint: '搜索二手好物',
          color: Color(0xFFFF7A00),
        ),
        _buildSubTabBar(
          _sub,
          const ['全部', '数码', '服饰', '图书', '其他'],
          const Color(0xFFFF7A00),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFFFE8C0),
            child: TabBarView(
              controller: _sub,
              children: [
                _SecondHandGrid(items: _filtered('all')),
                _SecondHandGrid(items: _filtered('digital')),
                _SecondHandGrid(items: _filtered('clothes')),
                _SecondHandGrid(items: _filtered('books')),
                _SecondHandGrid(items: []),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SecondHandGrid extends StatelessWidget {
  const _SecondHandGrid({required this.items});
  final List<_SecondHandItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
          child: Text('暂无数据', style: TextStyle(color: Color(0xFF999999))));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _SecondHandCard(item: items[i]),
    );
  }
}

class _SecondHandCard extends StatelessWidget {
  const _SecondHandCard({required this.item});
  final _SecondHandItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                width: double.infinity,
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return _imagePlaceholder(const Color(0xFFFFE0D0));
                  },
                  errorBuilder: (_, e, s) =>
                      _imagePlaceholder(const Color(0xFFFFE0D0)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF222222)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '¥${item.price}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF6B6B)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5E1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.condition,
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFFD36A00)),
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

class _SecondHandItem {
  const _SecondHandItem({
    required this.title,
    required this.price,
    required this.condition,
    required this.category,
    required this.imageUrl,
  });
  final String title;
  final int price;
  final String condition;
  final String category;
  final String imageUrl;
}

// ── 兼职啦 ───────────────────────────────────────────────────────────────────

class _PartTimeTab extends StatefulWidget {
  const _PartTimeTab();

  @override
  State<_PartTimeTab> createState() => _PartTimeTabState();
}

class _PartTimeTabState extends State<_PartTimeTab>
    with SingleTickerProviderStateMixin {
  late final TabController _sub;

  // TODO: replace with API call to GET /api/v1/market/part-time
  static const _items = [
    _PartTimeItem(
      title: '超市促销导购（周末场）',
      salary: '150元/天',
      tags: ['促销', '周末'],
      location: '上海·浦东新区',
      category: 'promo',
      imageUrl: 'https://picsum.photos/seed/pt1/600/300',
    ),
    _PartTimeItem(
      title: '初中数学一对一家教',
      salary: '80元/小时',
      tags: ['家教', '数学'],
      location: '上海·静安区',
      category: 'tutor',
      imageUrl: 'https://picsum.photos/seed/pt2/600/300',
    ),
    _PartTimeItem(
      title: '美团外卖骑手（弹性上班）',
      salary: '20元/单',
      tags: ['配送', '灵活'],
      location: '上海·全市',
      category: 'delivery',
      imageUrl: 'https://picsum.photos/seed/pt3/600/300',
    ),
    _PartTimeItem(
      title: '文创店文职助理（寒暑假）',
      salary: '200元/天',
      tags: ['文职', '文创'],
      location: '上海·黄浦区',
      category: 'office',
      imageUrl: 'https://picsum.photos/seed/pt4/600/300',
    ),
    _PartTimeItem(
      title: '商场活动促销员（节假日）',
      salary: '160元/天',
      tags: ['促销', '节假日'],
      location: '上海·徐汇区',
      category: 'promo',
      imageUrl: 'https://picsum.photos/seed/pt5/600/300',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _sub = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _sub.dispose();
    super.dispose();
  }

  List<_PartTimeItem> _filtered(String cat) {
    if (cat == 'all') return _items;
    return _items.where((i) => i.category == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _MarketHeader(
          title: '兼职啦',
          searchHint: '搜索兼职机会',
          color: Color(0xFF5DCAA5),
          publishLabel: '发布招募',
        ),
        _buildSubTabBar(
          _sub,
          const ['全部', '促销', '家教', '配送', '文职'],
          const Color(0xFF5DCAA5),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFFFE8C0),
            child: TabBarView(
              controller: _sub,
              children: [
                _PartTimeList(items: _filtered('all')),
                _PartTimeList(items: _filtered('promo')),
                _PartTimeList(items: _filtered('tutor')),
                _PartTimeList(items: _filtered('delivery')),
                _PartTimeList(items: _filtered('office')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PartTimeList extends StatelessWidget {
  const _PartTimeList({required this.items});
  final List<_PartTimeItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
          child: Text('暂无数据', style: TextStyle(color: Color(0xFF999999))));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: items.length,
      itemBuilder: (_, i) => _PartTimeCard(item: items[i]),
    );
  }
}

class _PartTimeCard extends StatelessWidget {
  const _PartTimeCard({required this.item});
  final _PartTimeItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return _imagePlaceholder(const Color(0xFFD0F0E8));
                },
                errorBuilder: (_, e, s) =>
                    _imagePlaceholder(const Color(0xFFD0F0E8)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF222222)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.salary,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5DCAA5)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: item.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8F3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(tag,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF3DAA85))),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Color(0xFF999999)),
                    const SizedBox(width: 4),
                    Text(
                      item.location,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF999999)),
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

class _PartTimeItem {
  const _PartTimeItem({
    required this.title,
    required this.salary,
    required this.tags,
    required this.location,
    required this.category,
    required this.imageUrl,
  });
  final String title;
  final String salary;
  final List<String> tags;
  final String location;
  final String category;
  final String imageUrl;
}

// ── 以物换物 ─────────────────────────────────────────────────────────────────

class _BarterTab extends StatelessWidget {
  const _BarterTab();

  // TODO: replace with API call to GET /api/v1/market/barter
  static const _items = [
    _BarterItem(
      title: 'iPhone SE 换 Switch 游戏卡',
      offerItem: 'iPhone SE 2020',
      wantItem: 'Switch NS 游戏卡',
      imageUrl: 'https://picsum.photos/seed/bt1/300/300',
    ),
    _BarterItem(
      title: '高中教材换大学教材',
      offerItem: '高中全套教材',
      wantItem: '大学英语 / 高数',
      imageUrl: 'https://picsum.photos/seed/bt2/300/300',
    ),
    _BarterItem(
      title: '旧相机换单反镜头',
      offerItem: '佳能 EOS M50',
      wantItem: '50mm 定焦镜头',
      imageUrl: 'https://picsum.photos/seed/bt3/300/300',
    ),
    _BarterItem(
      title: '电动滑板车换折叠自行车',
      offerItem: '小米电动滑板车',
      wantItem: '折叠自行车',
      imageUrl: 'https://picsum.photos/seed/bt4/300/300',
    ),
    _BarterItem(
      title: '咖啡机换空气炸锅',
      offerItem: 'Nespresso 胶囊机',
      wantItem: '空气炸锅（3L+）',
      imageUrl: 'https://picsum.photos/seed/bt5/300/300',
    ),
    _BarterItem(
      title: '乐高积木换积木桌',
      offerItem: '乐高城市系列',
      wantItem: '乐高专用积木桌',
      imageUrl: 'https://picsum.photos/seed/bt6/300/300',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _MarketHeader(
          title: '以物换物',
          searchHint: '搜索换物信息',
          color: Color(0xFF9C6FE4),
          publishLabel: '发布换物',
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFFFE8C0),
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.78,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _items.length,
              itemBuilder: (_, i) => _BarterCard(item: _items[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _BarterCard extends StatelessWidget {
  const _BarterCard({required this.item});
  final _BarterItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                width: double.infinity,
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return _imagePlaceholder(const Color(0xFFE8D8F8));
                  },
                  errorBuilder: (_, e, s) =>
                      _imagePlaceholder(const Color(0xFFE8D8F8)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF222222)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _BarterRow(label: '我有', value: item.offerItem,
                    color: const Color(0xFF5DCAA5)),
                const SizedBox(height: 3),
                _BarterRow(label: '想要', value: item.wantItem,
                    color: const Color(0xFFFF7A00)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarterRow extends StatelessWidget {
  const _BarterRow(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, color: Color(0xFF555555)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _BarterItem {
  const _BarterItem({
    required this.title,
    required this.offerItem,
    required this.wantItem,
    required this.imageUrl,
  });
  final String title;
  final String offerItem;
  final String wantItem;
  final String imageUrl;
}
