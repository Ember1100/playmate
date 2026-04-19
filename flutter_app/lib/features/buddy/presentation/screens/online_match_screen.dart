import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/pm_swipe_back.dart';
import '../../../../features/im/data/websocket_service.dart';
import '../../../../features/im/data/im_repository.dart';
import '../../data/match_repository.dart';
import '../../providers/match_provider.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  线上搭子 · 快速匹配（3页流程）
// ═════════════════════════════════════════════════════════════════════════════

class OnlineMatchScreen extends ConsumerStatefulWidget {
  const OnlineMatchScreen({super.key});

  @override
  ConsumerState<OnlineMatchScreen> createState() => _OnlineMatchScreenState();
}

class _OnlineMatchScreenState extends ConsumerState<OnlineMatchScreen> {
  int _page = 0; // 0=设置 1=匹配中 2=匹配结果

  // ── 设置页状态 ─────────────────────────────────────────────────────────────
  final Set<int> _selectedActivities = {0};
  int _selectedMood   = 0;
  int _selectedGender = 0;

  // ── 匹配页动画状态 ─────────────────────────────────────────────────────────
  double _sweepAngle = 0;
  int    _foundCount = 0;
  final  List<_FoundDot> _foundDots = [];
  String _statusText = '扫描附近在线用户...';
  Timer? _sweepTimer;

  // ── 结果页状态 ─────────────────────────────────────────────────────────────
  double _matchBarTarget = 0;

  // ── WS 订阅 ────────────────────────────────────────────────────────────────
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  // ── 静态数据 ───────────────────────────────────────────────────────────────
  static const _activities = ['游戏', '追剧', '学习', '聊天', '读书', '音乐', '健身打卡'];
  static const _moods = [('😊', '开心'), ('😌', '放松'), ('😑', '无聊'), ('😰', '焦虑')];
  static const _genders = ['不限', '男生', '女生'];
  static const _dotColors = [
    Color(0xFFFF8C42), Color(0xFFF59E0B), Color(0xFF84CC16),
    Color(0xFF60A5FA), Color(0xFFF43F5E), Color(0xFF818CF8),
  ];
  static const _statuses = ['发现新用户...', '正在分析兴趣...', '计算契合度...', '匹配中...'];
  static const _buddyAngles = [
    (angle: 40.0,  r: 72.0),
    (angle: 110.0, r: 85.0),
    (angle: 200.0, r: 60.0),
    (angle: 290.0, r: 78.0),
    (angle: 155.0, r: 50.0),
    (angle: 330.0, r: 90.0),
  ];

  // ── 逻辑 ───────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _listenWs();
  }

  void _listenWs() {
    final wsService = ref.read(wsServiceProvider);
    _wsSub = wsService.messages.listen((msg) {
      if (msg['type'] == 'match_found') {
        final result = MatchResult(
          matched:          true,
          matchedUserId:    msg['matched_user_id'] as String?,
          username:         msg['username'] as String?,
          avatarUrl:        msg['avatar_url'] as String?,
          commonInterests:  (msg['common_interests'] as List<dynamic>?)
                                ?.map((e) => e as String)
                                .toList(),
          score:            (msg['score'] as num?)?.toInt(),
        );
        ref.read(matchProvider.notifier).onMatchFound(result);
      }
    });
  }

  List<String> get _selectedActivityNames =>
      _selectedActivities.map((i) => _activities[i]).toList();

  void _startMatch() {
    _sweepTimer?.cancel();
    setState(() {
      _page       = 1;
      _sweepAngle = 0;
      _foundCount = 0;
      _foundDots.clear();
      _statusText = '扫描附近在线用户...';
    });
    _startRadarAnimation();

    ref.read(matchProvider.notifier).join(
      activities: _selectedActivityNames,
      mood:       _selectedMood,
      genderPref: _selectedGender,
    );
  }

  void _startRadarAnimation() {
    _sweepTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!mounted) return;
      setState(() {
        _sweepAngle = (_sweepAngle + 3) % 360;
        for (int i = 0; i < _buddyAngles.length; i++) {
          final bp = _buddyAngles[i];
          if (_sweepAngle >= bp.angle && _sweepAngle < bp.angle + 4 && _foundCount <= i) {
            _foundCount++;
            final bx = 120 + bp.r * sin(bp.angle * pi / 180);
            final by = 120 - bp.r * cos(bp.angle * pi / 180);
            _foundDots.add(_FoundDot(x: bx, y: by, color: _dotColors[i % _dotColors.length]));
            _statusText = _statuses[min(_foundCount - 1, _statuses.length - 1)];
          }
        }
      });
    });
  }

  void _cancelMatch() {
    _sweepTimer?.cancel();
    ref.read(matchProvider.notifier).leave();
    if (mounted) setState(() => _page = 0);
  }

  void _nextMatch() {
    setState(() {
      _page       = 1;
      _sweepAngle = 0;
      _foundCount = 0;
      _foundDots.clear();
      _statusText = '扫描附近在线用户...';
    });
    _startRadarAnimation();
    ref.read(matchProvider.notifier).next();
  }

  Future<void> _sayHi(MatchResult result) async {
    if (result.matchedUserId == null) return;
    try {
      final imRepo = ref.read(imRepositoryProvider);
      final convId = await imRepo.createConversation(result.matchedUserId!);
      if (!mounted) return;
      context.push('/im/chat/$convId', extra: {
        'username':      result.username ?? '搭子',
        'otherAvatarUrl': result.avatarUrl,
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _sweepTimer?.cancel();
    _wsSub?.cancel();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(matchProvider);

    // 当 provider 变为 matched 状态时切换到结果页
    ref.listen<MatchState>(matchProvider, (prev, next) {
      if (next.status == MatchStatus.matched && _page != 2) {
        _sweepTimer?.cancel();
        setState(() { _page = 2; _matchBarTarget = 0; });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _matchBarTarget = (next.result?.score ?? 92) / 100.0);
        });
      }
    });

    return PopScope(
      // page 0：允许系统返回（go_router 正常 pop 回搭子页）
      // page 1/2：拦截系统返回，在应用层处理，防止直接退出 app
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return; // page 0 已由框架处理
        if (_page == 1) {
          _cancelMatch(); // 取消匹配并回到 page 0
        } else {
          ref.read(matchProvider.notifier).reset();
          setState(() => _page = 0);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF9F6),
        body: switch (_page) {
          // page 0 保留 PmSwipeBack 支持右滑返回
          0 => PmSwipeBack(
              child: _SetupPage(
                selectedActivities: _selectedActivities,
                selectedMood:       _selectedMood,
                selectedGender:     _selectedGender,
                activities:         _activities,
                moods:              _moods,
                genders:            _genders,
                onActivityTap:      (i) => setState(() {
                  if (_selectedActivities.contains(i)) { _selectedActivities.remove(i); } else { _selectedActivities.add(i); }
                }),
                onMoodTap:   (i) => setState(() => _selectedMood   = i),
                onGenderTap: (i) => setState(() => _selectedGender = i),
                onStart:     _startMatch,
              ),
            ),
          // page 1/2：不加 PmSwipeBack，系统返回由 PopScope 拦截
          1 => _MatchingPage(
              sweepAngle: _sweepAngle,
              foundDots:  _foundDots,
              foundCount: _foundCount,
              statusText: _statusText,
              onCancel:   _cancelMatch,
            ),
          _ => _MatchedPage(
              matchBarTarget: _matchBarTarget,
              result:         matchState.result,
              onSayHi:  () { if (matchState.result != null) _sayHi(matchState.result!); },
              onProfile: () {
                final uid = matchState.result?.matchedUserId;
                if (uid != null) {
                  context.push('/buddy/user/$uid', extra: {
                    'username':  matchState.result?.username,
                    'avatarUrl': matchState.result?.avatarUrl,
                  });
                }
              },
              onNext:   _nextMatch,
              onHome:   () {
                ref.read(matchProvider.notifier).reset();
                setState(() => _page = 0);
              },
            ),
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  PAGE 1 — 设置
// ═════════════════════════════════════════════════════════════════════════════

class _SetupPage extends StatelessWidget {
  const _SetupPage({
    required this.selectedActivities,
    required this.selectedMood,
    required this.selectedGender,
    required this.activities,
    required this.moods,
    required this.genders,
    required this.onActivityTap,
    required this.onMoodTap,
    required this.onGenderTap,
    required this.onStart,
  });

  final Set<int> selectedActivities;
  final int selectedMood;
  final int selectedGender;
  final List<String> activities;
  final List<(String, String)> moods;
  final List<String> genders;
  final void Function(int) onActivityTap;
  final void Function(int) onMoodTap;
  final void Function(int) onGenderTap;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Column(
      children: [
        // ── 橙色头部 ─────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, top + 16, 20, 24),
          color: const Color(0xFFFF8C42),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(top: -10, right: -10, child: _Circle(120, 0.08)),
              Positioned(bottom: -20, left: -10, child: _Circle(80, 0.06)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 12),
                  const Text('找线上搭子',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white, height: 1.3)),
                  const SizedBox(height: 4),
                  const Text('快速匹配，马上开玩',
                      style: TextStyle(fontSize: 13, color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),

        // ── 表单 ─────────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('选择你想玩的'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: List.generate(activities.length, (i) {
                    final sel = selectedActivities.contains(i);
                    return _Chip(label: activities[i], selected: sel, onTap: () => onActivityTap(i));
                  }),
                ),
                const SizedBox(height: 16),

                _Label('现在的状态'),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(moods.length, (i) {
                    final sel = selectedMood == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onMoodTap(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: EdgeInsets.only(right: i < moods.length - 1 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFFFFF7ED) : const Color(0xFFFDF9F6),
                            border: Border.all(
                              color: sel ? const Color(0xFFFF8C42) : const Color(0xFFE8E0D8),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(moods[i].$1, style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 4),
                              Text(moods[i].$2,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: sel ? const Color(0xFFFF8C42) : const Color(0xFF888780),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                _Label('搭子性别偏好'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(genders.length, (i) {
                    return _Chip(label: genders[i], selected: selectedGender == i, onTap: () => onGenderTap(i));
                  }),
                ),
                const SizedBox(height: 24),

                // 开始按钮
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: onStart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8C42),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('开始匹配',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  PAGE 2 — 匹配中
// ═════════════════════════════════════════════════════════════════════════════

class _MatchingPage extends StatelessWidget {
  const _MatchingPage({
    required this.sweepAngle,
    required this.foundDots,
    required this.foundCount,
    required this.statusText,
    required this.onCancel,
  });

  final double sweepAngle;
  final List<_FoundDot> foundDots;
  final int foundCount;
  final String statusText;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF9F5),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('正在为你匹配搭子',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF2C2C2A))),
            const SizedBox(height: 6),
            const Text('根据兴趣 · 在线状态 · 心情匹配',
                style: TextStyle(fontSize: 13, color: Color(0xFF888780))),
            const SizedBox(height: 32),

            // 雷达
            SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(
                painter: _RadarPainter(sweepAngle: sweepAngle, foundDots: foundDots),
              ),
            ),
            const SizedBox(height: 32),

            Text(statusText, style: const TextStyle(fontSize: 13, color: Color(0xFFFF8C42))),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('已发现 ', style: TextStyle(fontSize: 12, color: Color(0xFF888780))),
                Text('$foundCount',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFF8C42))),
                const Text(' 位潜在搭子', style: TextStyle(fontSize: 12, color: Color(0xFF888780))),
              ],
            ),
            const SizedBox(height: 16),

            // 进度点
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 6, height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i < foundCount.clamp(0, 3) ? const Color(0xFFFF8C42) : const Color(0xFFE8E0D8),
                  shape: BoxShape.circle,
                ),
              )),
            ),
            const SizedBox(height: 28),

            GestureDetector(
              onTap: onCancel,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE8E0D8), width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('取消匹配',
                    style: TextStyle(fontSize: 14, color: Color(0xFF888780))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  PAGE 3 — 匹配结果
// ═════════════════════════════════════════════════════════════════════════════

class _MatchedPage extends StatelessWidget {
  const _MatchedPage({
    required this.matchBarTarget,
    required this.result,
    required this.onSayHi,
    required this.onProfile,
    required this.onNext,
    required this.onHome,
  });

  final double matchBarTarget;
  final MatchResult? result;
  final VoidCallback onSayHi;
  final VoidCallback onProfile;
  final VoidCallback onNext;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final top    = MediaQuery.of(context).padding.top;
    final name   = result?.username ?? '搭子';
    final score  = result?.score ?? 0;
    final interests = result?.commonInterests ?? [];

    return Column(
      children: [
        // ── 橙色头部 ─────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, top + 20, 20, 28),
          color: const Color(0xFFFF8C42),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(top: -30, right: -20, child: _Circle(160, 0.07)),
              Column(
                children: [
                  const Text('匹配成功',
                      style: TextStyle(fontSize: 12, color: Colors.white70, letterSpacing: 1.0)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _AvatarCircle(emoji: '😊', bg: const Color(0xFFFFD49A)),
                      const SizedBox(width: 4),
                      Container(
                        width: 28, height: 28,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Center(child: Text('❤️', style: TextStyle(fontSize: 13))),
                      ),
                      const SizedBox(width: 4),
                      _AvatarCircle(emoji: '😄', bg: const Color(0xFFFFCC80)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('找到搭子啦！',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    interests.isEmpty
                        ? '契合度 $score%'
                        : '契合度 $score% · 共同兴趣 ${interests.length} 个',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── 内容 ─────────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              children: [
                // 资料卡
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF9F6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF0E8DE), width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 头部信息
                      Row(
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: const BoxDecoration(color: Color(0xFFFFE0B2), shape: BoxShape.circle),
                            child: const Center(child: Text('😊', style: TextStyle(fontSize: 24))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(name,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF2C2C2A))),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.2), width: 0.5),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(width: 6, height: 6,
                                              decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                                          const SizedBox(width: 4),
                                          const Text('在线', style: TextStyle(fontSize: 11, color: Color(0xFF22C55E))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (result?.bio != null) ...[
                                  const SizedBox(height: 2),
                                  Text(result!.bio!,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF888780)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 契合度条
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Text('契合度', style: TextStyle(fontSize: 12, color: Color(0xFF854F0B))),
                            const SizedBox(width: 10),
                            Expanded(
                              child: LayoutBuilder(builder: (ctx, cst) {
                                return Stack(
                                  children: [
                                    Container(height: 6,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFDE8D0),
                                          borderRadius: BorderRadius.circular(3),
                                        )),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 1200),
                                      curve: Curves.easeOut,
                                      height: 6,
                                      width: cst.maxWidth * matchBarTarget,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF8C42),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                            const SizedBox(width: 10),
                            Text('$score%',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF854F0B))),
                          ],
                        ),
                      ),

                      if (interests.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text('共同兴趣',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF888780))),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: interests.map((t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFF8C42).withValues(alpha: 0.25), width: 0.5),
                            ),
                            child: Text(t, style: const TextStyle(fontSize: 12, color: Color(0xFF854F0B))),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 操作按钮
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: onSayHi,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8C42),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text('立即打招呼',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _SecBtn(label: '查看主页', onTap: onProfile)),
                    const SizedBox(width: 10),
                    Expanded(child: _SecBtn(label: '换一个', onTap: onNext)),
                  ],
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onHome,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('回到首页',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Color(0xFF888780))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  雷达 CustomPainter
// ═════════════════════════════════════════════════════════════════════════════

class _FoundDot {
  const _FoundDot({required this.x, required this.y, required this.color});
  final double x;
  final double y;
  final Color color;
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({required this.sweepAngle, required this.foundDots});
  final double sweepAngle;
  final List<_FoundDot> foundDots;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);

    void ring(double r, double opacity) {
      canvas.drawCircle(center, r, Paint()
        ..color = const Color(0xFFFF8C42).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
    }
    ring(95, 0.20);
    ring(65, 0.15);
    ring(35, 0.12);
    ring(95, 0.12);
    ring(65, 0.08);
    ring(35, 0.06);

    const sweepSpan = 30.0;
    final startRad = (sweepAngle - sweepSpan) * pi / 180 - pi / 2;
    final sweepRad = sweepSpan * pi / 180;

    final sweepPath = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx + 95 * cos(startRad), cy + 95 * sin(startRad))
      ..arcTo(Rect.fromCircle(center: center, radius: 95), startRad, sweepRad, false)
      ..close();
    canvas.drawPath(sweepPath, Paint()..color = const Color(0xFFFF8C42).withValues(alpha: 0.10));

    for (final dot in foundDots) {
      final dc = Offset(dot.x, dot.y);
      canvas.drawCircle(dc, 9, Paint()
        ..color = dot.color.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
      canvas.drawCircle(dc, 6, Paint()..color = dot.color.withValues(alpha: 0.9));
    }

    canvas.drawCircle(center, 12, Paint()..color = const Color(0xFFFF8C42));
    final tp = TextPainter(
      text: const TextSpan(
          text: '我',
          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.sweepAngle != sweepAngle || old.foundDots.length != foundDots.length;
}

// ═════════════════════════════════════════════════════════════════════════════
//  公用小组件
// ═════════════════════════════════════════════════════════════════════════════

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF888780)));
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF8C42) : const Color(0xFFFDF9F6),
          border: Border.all(
            color: selected ? const Color(0xFFFF8C42) : const Color(0xFFE8E0D8),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 13, color: selected ? Colors.white : const Color(0xFF888780))),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.emoji, required this.bg});
  final String emoji;
  final Color bg;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68, height: 68,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3)),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
    );
  }
}

class _SecBtn extends StatelessWidget {
  const _SecBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF9F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E0D8), width: 1.5),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF2C2C2A))),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle(this.size, this.opacity);
  final double size;
  final double opacity;
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      shape: BoxShape.circle,
    ),
  );
}
