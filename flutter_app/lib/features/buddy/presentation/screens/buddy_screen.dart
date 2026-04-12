import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/pm_image.dart';


/// 搭子 Tab 首页
class BuddyScreen extends StatelessWidget {
  const BuddyScreen({super.key});

  static const _tags = ['旅行户外', '🎤 娱乐搭子', '🎮 游戏搭子', '💗 脱单搭子'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EF),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildBanner()),
            SliverToBoxAdapter(child: _buildSearchBar(context)),
            SliverToBoxAdapter(child: _buildCategoryGrid(context)),
            SliverToBoxAdapter(child: _buildTagRow()),
            SliverToBoxAdapter(child: _buildFeedGrid()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Expanded(
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

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      height: 148,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // 渐变背景
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
          // 云朵 c1
          Positioned(
            left: 28,
            top: 12,
            child: _CloudShape(width: 72, height: 36),
          ),
          // 云朵 c2
          Positioned(
            left: 96,
            top: 24,
            child: _CloudShape(width: 56, height: 28, opacity: 0.9),
          ),
          // 云朵 c3
          Positioned(
            right: 80,
            top: 8,
            child: _CloudShape(width: 64, height: 32),
          ),
          // 左侧文字
          const Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('周末不宅',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF333333),
                      letterSpacing: 1,
                      height: 1.25,
                    )),
                Text('组队去野',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF333333),
                      letterSpacing: 1,
                      height: 1.25,
                    )),
              ],
            ),
          ),
          // 吉祥物（猫头鹰）
          Positioned(
            right: -8,
            bottom: -12,
            width: 100,
            height: 100,
            child: CustomPaint(painter: _OwlPainter()),
          ),
          // 页码
          const Positioned(
            right: 10,
            bottom: 8,
            child: Text('1/1',
                style: TextStyle(fontSize: 11, color: Color(0x73000000))),
          ),
          // handle
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/buddy/search'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE8C0),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          children: [
            SizedBox(width: 14),
            Icon(Icons.search_rounded, color: Color(0xFF888888), size: 18),
            SizedBox(width: 8),
            Text('请输入关键词',
                style: TextStyle(color: Color(0xFF888888), fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: SizedBox(
        height: 202,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 左列
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _CategoryCard(
                      title: '线上搭子',
                      subtitle: '快速匹配',
                      bgColor: const Color(0xFFFFE8C0),
                      decoType: _CardDecoType.online,
                      onTap: () => context.push('/buddy/candidates'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _CategoryCard(
                      title: '线下搭子',
                      subtitle: '按照需求进行匹配',
                      bgColor: const Color(0xFFFFE082),
                      decoType: _CardDecoType.offline,
                      onTap: () => context.push('/buddy/candidates'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // 右列：职业（跨两行）
            Expanded(
              child: _CategoryCard(
                title: '职业搭子',
                subtitle: '您的专业老师',
                bgColor: const Color(0xFFFFE8C0),
                decoType: _CardDecoType.pro,
                onTap: () => context.push('/buddy/career'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 0, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _tags.map((tag) {
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFF0F0F0)),
                boxShadow: const [
                  BoxShadow(
                      blurRadius: 8,
                      color: Color(0x0D000000),
                      offset: Offset(0, 2))
                ],
              ),
              child: Text(tag,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF222222))),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFeedGrid() {
    const feeds = [
      _FeedData('星际海渊', '价格面议', '已预约：0 剩余：10',
          'https://picsum.photos/seed/meal/300/240'),
      _FeedData('室内烤肉自助活动', '¥58.00', '已预约：0 剩余：8',
          'https://picsum.photos/seed/bbq/300/240'),
      _FeedData('骑在黎明破晓前露营折叠车', '免费', '已预约：0 剩余：5',
          'https://picsum.photos/seed/friend/300/240'),
      _FeedData('室内网球活动', '¥88.00', '已预约：0 剩余：12',
          'https://picsum.photos/seed/tennis/300/240'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.78,
        children: feeds.map((f) => _FeedCard(data: f)).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 云朵形状
// ─────────────────────────────────────────────────────────────────────────────

class _CloudShape extends StatelessWidget {
  const _CloudShape({
    required this.width,
    required this.height,
    this.opacity = 1.0,
  });

  final double width;
  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85 * opacity),
        borderRadius: BorderRadius.circular(50),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 吉祥物 Painter（猫头鹰 SVG → CustomPaint）
// viewBox="0 0 100 100"
// ─────────────────────────────────────────────────────────────────────────────

class _OwlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;

    void ell(double cx, double cy, double rx, double ry, Color color) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx * s, cy * s),
            width: rx * 2 * s,
            height: ry * 2 * s),
        Paint()..color = color,
      );
    }

    void circ(double cx, double cy, double r, Color color) {
      canvas.drawCircle(
          Offset(cx * s, cy * s), r * s, Paint()..color = color);
    }

    ell(72, 78, 42, 38, const Color(0xFFC5E1A5)); // outer body
    ell(72, 72, 38, 34, const Color(0xFFDCEDC8)); // inner body
    ell(58, 52, 18, 20, Colors.white);             // left eye white
    ell(58, 52, 10, 12, const Color(0xFF263238));  // left pupil
    circ(56, 48, 3, Colors.white);                 // left highlight
    ell(78, 48, 14, 16, Colors.white);             // right eye white
    ell(78, 48, 8, 9, const Color(0xFF263238));    // right pupil
    circ(76, 44, 2.5, Colors.white);               // right highlight
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// 卡片装饰类型
// ─────────────────────────────────────────────────────────────────────────────

enum _CardDecoType { online, offline, pro }

// ─────────────────────────────────────────────────────────────────────────────
// 类别卡片
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.decoType,
    required this.onTap,
  });

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
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                blurRadius: 8,
                color: Color(0x0D000000),
                offset: Offset(0, 2))
          ],
        ),
        child: Stack(
          children: [
            // 装饰图形（底部右侧，不遮挡文字）
            Positioned(
              right: 4,
              bottom: 4,
              width: decoType == _CardDecoType.pro ? 80 : 64,
              height: decoType == _CardDecoType.pro ? 80 : 48,
              child: CustomPaint(painter: _CardDecoPainter(decoType)),
            ),
            // 文字（顶部左对齐，与 HTML 一致）
            Positioned(
              left: 14,
              top: 14,
              right: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF222222))),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF666666),
                          height: 1.4),
                      maxLines: 2),
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
    final w = size.width;
    final h = size.height;

    void ell(double cx, double cy, double rx, double ry, Color color,
        {double opacity = 1.0}) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx * w, cy * h),
            width: rx * 2 * w,
            height: ry * 2 * h),
        Paint()..color = color.withValues(alpha: opacity),
      );
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

// ─────────────────────────────────────────────────────────────────────────────
// Feed 卡片
// ─────────────────────────────────────────────────────────────────────────────

class _FeedData {
  const _FeedData(this.title, this.price, this.status, this.imageUrl);
  final String title;
  final String price;
  final String status;
  final String imageUrl;
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.data});
  final _FeedData data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/buddy/user/mock_feed'),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              blurRadius: 8,
              color: Color(0x0D000000),
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: PmImage(data.imageUrl, fit: BoxFit.cover, width: double.infinity),
            ),
          ),
          // 信息
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  data.price,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFFF6700),
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  data.status,
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
