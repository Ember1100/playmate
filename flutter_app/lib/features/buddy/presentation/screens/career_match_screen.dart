import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/im/data/im_repository.dart';
import '../../../../features/im/data/websocket_service.dart';
import '../../../../shared/widgets/pm_swipe_back.dart';
import '../../data/career_match_repository.dart';
import '../../providers/career_match_provider.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  职业搭子 · 智能匹配（3页流程）
// ═════════════════════════════════════════════════════════════════════════════

const _navy     = Color(0xFF1A3A5C);
const _navyMid  = Color(0xFF2A5480);
const _navyDeep = Color(0xFF1E4A6E);
const _blueBg   = Color(0xFFF0F5FF);
const _border   = Color(0xFFD5E3F0);
const _sub      = Color(0xFF7A9CC0);
const _lightBg  = Color(0xFFF4F7FB);
const _hiBlue   = Color(0xFF60A5FA);

// ── Data Types ───────────────────────────────────────────────────────────────
typedef _Node  = ({double cx, double cy, double r, String label, bool hi, int delay});
typedef _Phase = ({int t, String phase, String detail, double pct});
typedef _Goal  = ({IconData icon, String name, String desc, Color bg, Color ic});

const List<_Node> _kNodes = [
  (cx: 80.0,  cy: 65.0,  r: 14.0, label: 'PM',   hi: false, delay: 0),
  (cx: 210.0, cy: 75.0,  r: 12.0, label: 'Dev',  hi: false, delay: 200),
  (cx: 55.0,  cy: 165.0, r: 11.0, label: 'Ops',  hi: false, delay: 350),
  (cx: 230.0, cy: 170.0, r: 13.0, label: 'UX',   hi: false, delay: 500),
  (cx: 130.0, cy: 55.0,  r: 10.0, label: 'Mkt',  hi: false, delay: 650),
  (cx: 175.0, cy: 210.0, r: 15.0, label: '林晓', hi: true,  delay: 900),
  (cx: 70.0,  cy: 230.0, r: 10.0, label: 'DA',   hi: false, delay: 1100),
  (cx: 240.0, cy: 230.0, r: 9.0,  label: 'PM',   hi: false, delay: 1250),
];

const List<_Phase> _kPhases = [
  (t: 0,    phase: '扫描职业网络...',    detail: '正在分析 3,241 位用户档案',           pct: 0.00),
  (t: 800,  phase: '过滤领域匹配...',    detail: '筛选出 284 位产品经理',              pct: 0.20),
  (t: 1600, phase: '分析技能重叠...',    detail: '匹配需求分析 · 数据驱动 · 用户研究',  pct: 0.42),
  (t: 2400, phase: '计算目标契合度...', detail: '技能提升 · 项目协作 双重匹配',          pct: 0.61),
  (t: 3200, phase: '评估发展阶段...',    detail: '工作年限与职业阶段高度吻合',           pct: 0.78),
  (t: 4000, phase: '生成匹配报告...',    detail: '综合契合度评分 92%',                 pct: 0.92),
  (t: 4800, phase: '匹配成功！',         detail: '找到最佳职业搭子',                   pct: 1.00),
];

const _kFields = ['产品经理', '设计师', '前端开发', '后端开发', '运营', '市场营销', '数据分析', '创业者'];
const _kExps   = ['应届', '1-3年', '3-5年', '5年+'];

const List<_Goal> _kGoals = [
  (icon: Icons.star_border_rounded,         name: '技能提升', desc: '互相学习成长', bg: Color(0xFFE8F0FE), ic: _navy),
  (icon: Icons.lock_outline_rounded,        name: '求职内推', desc: '内部机会推荐', bg: Color(0xFFFEF3C7), ic: Color(0xFF854F0B)),
  (icon: Icons.check_circle_outline_rounded,name: '项目协作', desc: '一起做项目',   bg: Color(0xFFECFDF5), ic: Color(0xFF059669)),
  (icon: Icons.lightbulb_outline_rounded,   name: '灵感碰撞', desc: '头脑风暴交流', bg: Color(0xFFFCE7F3), ic: Color(0xFF9D174D)),
];

// ── Main Widget ───────────────────────────────────────────────────────────────
class CareerMatchScreen extends ConsumerStatefulWidget {
  const CareerMatchScreen({super.key});
  @override
  ConsumerState<CareerMatchScreen> createState() => _CareerMatchScreenState();
}

class _CareerMatchScreenState extends ConsumerState<CareerMatchScreen> {
  int _page = 0;

  // P1 state
  final Set<int> _fields = {0};
  final Set<int> _goals  = {0};
  int _exp = 1;

  // P2 animation state
  final Set<int> _visible = {};
  int _phaseIdx = 0;
  final List<Timer> _timers = [];

  // P3 score counter state
  int _displayScore = 0;
  Timer? _scoreTimer;

  // WS subscription
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  @override
  void initState() {
    super.initState();
    _listenWs();
  }

  void _listenWs() {
    final wsService = ref.read(wsServiceProvider);
    _wsSub = wsService.messages.listen((msg) {
      if (msg['type'] == 'career_match_found') {
        final result = CareerMatchResult(
          matched:           true,
          matchedUserId:     msg['matched_user_id'] as String?,
          username:          msg['username'] as String?,
          avatarUrl:         msg['avatar_url'] as String?,
          careerRole:        msg['career_role'] as String?,
          company:           msg['company'] as String?,
          experience:        msg['experience'] as String?,
          score:             (msg['score'] as num?)?.toInt(),
          commonSkills:      (msg['common_skills'] as List<dynamic>?)
                                 ?.map((e) => e as String).toList(),
          commonSkillCount:  (msg['common_skill_count'] as num?)?.toInt(),
          commonGoalCount:   (msg['common_goal_count'] as num?)?.toInt(),
          collabSuggestions: (msg['collab_suggestions'] as List<dynamic>?)
                                 ?.map((e) => e as String).toList(),
        );
        ref.read(careerMatchProvider.notifier).onMatchFound(result);
      }
    });
  }

  List<String> get _selectedFieldNames =>
      _fields.map((i) => _kFields[i]).toList();

  List<String> get _selectedGoalNames =>
      _goals.map((i) => _kGoals[i].name).toList();

  String get _selectedExp => _kExps[_exp];

  void _startMatch() {
    for (final t in _timers) { t.cancel(); }
    _timers.clear();
    setState(() { _page = 1; _visible.clear(); _phaseIdx = 0; });
    _runAnimation();

    ref.read(careerMatchProvider.notifier).join(
      fields:     _selectedFieldNames,
      goals:      _selectedGoalNames,
      experience: _selectedExp,
    );
  }

  void _runAnimation() {
    for (int i = 0; i < _kNodes.length; i++) {
      final i0 = i;
      _timers.add(Timer(Duration(milliseconds: _kNodes[i0].delay),
          () { if (mounted) setState(() => _visible.add(i0)); }));
    }
    for (int i = 0; i < _kPhases.length; i++) {
      final i0 = i;
      _timers.add(Timer(Duration(milliseconds: _kPhases[i0].t),
          () { if (mounted) setState(() => _phaseIdx = i0); }));
    }
  }

  void _cancelMatch() {
    for (final t in _timers) { t.cancel(); }
    _timers.clear();
    _scoreTimer?.cancel();
    ref.read(careerMatchProvider.notifier).leave();
    if (mounted) setState(() => _page = 0);
  }

  void _showResult(int targetScore) {
    _scoreTimer?.cancel();
    _displayScore = 0;
    _scoreTimer = Timer.periodic(const Duration(milliseconds: 20), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_displayScore < targetScore) {
          _displayScore = (_displayScore + 4).clamp(0, targetScore);
        }
      });
      if (_displayScore >= targetScore) t.cancel();
    });
  }

  Future<void> _sendCard(CareerMatchResult result) async {
    if (result.matchedUserId == null) return;
    try {
      final imRepo = ref.read(imRepositoryProvider);
      final convId = await imRepo.createConversation(result.matchedUserId!);
      if (!mounted) return;
      context.push('/im/chat/$convId', extra: {
        'username':       result.username ?? '搭子',
        'otherAvatarUrl': result.avatarUrl,
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final t in _timers) { t.cancel(); }
    _scoreTimer?.cancel();
    _wsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(careerMatchProvider);

    // 匹配成功时切换到结果页
    ref.listen<CareerMatchState>(careerMatchProvider, (prev, next) {
      if (next.status == CareerMatchStatus.matched && _page != 2) {
        for (final t in _timers) { t.cancel(); }
        _timers.clear();
        setState(() { _page = 2; });
        _showResult(next.result?.score ?? 92);
      }
    });

    return PopScope(
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_page == 1) {
          _cancelMatch();
        } else {
          ref.read(careerMatchProvider.notifier).reset();
          setState(() => _page = 0);
        }
      },
      child: Scaffold(
        backgroundColor: _lightBg,
        body: switch (_page) {
          0 => PmSwipeBack(
              child: _SetupPage(
                fields: _fields, goals: _goals, exp: _exp,
                onField: (i) => setState(() =>
                    _fields.contains(i) ? _fields.remove(i) : _fields.add(i)),
                onGoal:  (i) => setState(() =>
                    _goals.contains(i)  ? _goals.remove(i)  : _goals.add(i)),
                onExp:   (i) => setState(() => _exp = i),
                onStart: _startMatch,
              ),
            ),
          1 => _MatchingPage(
              visible:  _visible,
              phase:    _kPhases[_phaseIdx].phase,
              detail:   _kPhases[_phaseIdx].detail,
              progress: _kPhases[_phaseIdx].pct,
              onCancel: _cancelMatch,
            ),
          _ => _MatchedPage(
              score:  _displayScore,
              result: matchState.result,
              onSendCard: () {
                if (matchState.result != null) _sendCard(matchState.result!);
              },
              onViewProfile: () {
                final uid = matchState.result?.matchedUserId;
                if (uid != null) {
                  context.push('/buddy/user/$uid', extra: {
                    'username':  matchState.result?.username,
                    'avatarUrl': matchState.result?.avatarUrl,
                  });
                }
              },
              onNext: () {
                ref.read(careerMatchProvider.notifier).next();
                setState(() { _page = 1; _visible.clear(); _phaseIdx = 0; });
                _runAnimation();
              },
              onHome: () {
                ref.read(careerMatchProvider.notifier).reset();
                setState(() => _page = 0);
              },
            ),
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAGE 1 — Setup
// ─────────────────────────────────────────────────────────────────────────────
class _SetupPage extends StatelessWidget {
  final Set<int> fields;
  final Set<int> goals;
  final int exp;
  final ValueChanged<int> onField;
  final ValueChanged<int> onGoal;
  final ValueChanged<int> onExp;
  final VoidCallback onStart;

  const _SetupPage({
    required this.fields, required this.goals, required this.exp,
    required this.onField, required this.onGoal, required this.onExp,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bot = MediaQuery.of(context).padding.bottom;
    return SizedBox.expand(
      child: Column(children: [
      // ── Header ──
      Container(
        width: double.infinity,
        color: _navy,
        padding: EdgeInsets.fromLTRB(20, top + 28, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text('职业搭子', style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(217))),
            ]),
          ),
          const SizedBox(height: 10),
          const Text('找到你的\n职场同行者',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white, height: 1.3)),
          const SizedBox(height: 4),
          Text('精准匹配 · 共同成长',
              style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(153))),
        ]),
      ),
      // ── Scrollable Body ──
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Fields
            const _SecLabel('你的领域'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7, runSpacing: 7,
              children: [
                for (int i = 0; i < _kFields.length; i++)
                  _FieldTag(
                    label: _kFields[i],
                    selected: fields.contains(i),
                    onTap: () => onField(i),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Goals
            const _SecLabel('搭子目标'),
            const SizedBox(height: 8),
            GridView.count(
              padding: EdgeInsets.zero,
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.85,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (int i = 0; i < _kGoals.length; i++)
                  _GoalCard(data: _kGoals[i], selected: goals.contains(i), onTap: () => onGoal(i)),
              ],
            ),
            const SizedBox(height: 16),
            // Experience
            const _SecLabel('工作年限'),
            const SizedBox(height: 8),
            Row(children: [
              for (int i = 0; i < _kExps.length; i++) ...[
                if (i > 0) const SizedBox(width: 7),
                Expanded(child: _ExpBtn(label: _kExps[i], selected: exp == i, onTap: () => onExp(i))),
              ],
            ]),
          ]),
        ),
      ),
      // ── Start Button ──
      Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bot + 16),
        child: GestureDetector(
          onTap: onStart,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(14)),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.radar_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('开始智能匹配', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
            ]),
          ),
        ),
      ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAGE 2 — Matching
// ─────────────────────────────────────────────────────────────────────────────
class _MatchingPage extends StatelessWidget {
  final Set<int> visible;
  final String phase;
  final String detail;
  final double progress;
  final VoidCallback onCancel;

  const _MatchingPage({
    required this.visible, required this.phase,
    required this.detail, required this.progress,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: _blueBg,
        child: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const SizedBox(height: 40),
          const Text('正在匹配职业搭子',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: _navy)),
          const SizedBox(height: 5),
          const Text('基于技能 · 目标 · 工作年限分析',
              style: TextStyle(fontSize: 12, color: _sub)),
          const SizedBox(height: 36),
          // Network graph
          SizedBox(
            width: 280, height: 280,
            child: CustomPaint(
              painter: _NetworkPainter(visible: visible, nodes: _kNodes),
            ),
          ),
          const SizedBox(height: 28),
          // Phase text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(phase, key: ValueKey(phase),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _navy)),
          ),
          const SizedBox(height: 5),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(detail, key: ValueKey(detail),
                style: const TextStyle(fontSize: 12, color: _sub),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          // Progress bar
          Container(
            width: 200, height: 4,
            decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 200 * progress,
                height: 4,
                decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('${(progress * 100).toInt()}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _navy)),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onCancel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 9),
              decoration: BoxDecoration(
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('取消匹配', style: TextStyle(fontSize: 13, color: _sub)),
            ),
          ),
          ]),
        ),
      ),
    );
  }
}

// ── Network graph painter ─────────────────────────────────────────────────────
class _NetworkPainter extends CustomPainter {
  final Set<int> visible;
  final List<_Node> nodes;

  _NetworkPainter({required this.visible, required this.nodes});

  static const _cx = 140.0;
  static const _cy = 140.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw edges
    for (int i = 0; i < nodes.length; i++) {
      if (!visible.contains(i)) continue;
      final nd = nodes[i];
      canvas.drawLine(
        const Offset(_cx, _cy),
        Offset(nd.cx, nd.cy),
        Paint()
          ..color = nd.hi ? _hiBlue.withAlpha(204) : _border
          ..strokeWidth = nd.hi ? 1.5 : 0.8,
      );
    }

    // Center node
    canvas.drawCircle(const Offset(_cx, _cy), 22, Paint()..color = _navy);
    canvas.drawCircle(const Offset(_cx, _cy), 14, Paint()..color = _navyMid);
    _drawText(canvas, '我', const Offset(_cx, _cy), 9, Colors.white, bold: true);

    // Satellite nodes
    for (int i = 0; i < nodes.length; i++) {
      if (!visible.contains(i)) continue;
      final nd = nodes[i];
      final c = Offset(nd.cx, nd.cy);

      if (nd.hi) {
        canvas.drawCircle(c, nd.r + 5,
          Paint()
            ..color = _hiBlue.withAlpha(102)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0);
      }
      canvas.drawCircle(c, nd.r,
          Paint()..color = nd.hi ? _navyDeep : _navyMid);
      if (nd.hi) {
        canvas.drawCircle(c, nd.r,
          Paint()
            ..color = _hiBlue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0);
      }
      _drawText(canvas, nd.label, c, nd.hi ? 8 : 7, Colors.white, bold: nd.hi);
    }
  }

  void _drawText(Canvas canvas, String text, Offset center, double fontSize, Color color, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: bold ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_NetworkPainter old) => old.visible.length != visible.length;
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAGE 3 — Result
// ─────────────────────────────────────────────────────────────────────────────
class _MatchedPage extends StatelessWidget {
  final int score;
  final CareerMatchResult? result;
  final VoidCallback onSendCard;
  final VoidCallback onViewProfile;
  final VoidCallback onNext;
  final VoidCallback onHome;

  const _MatchedPage({
    required this.score,
    required this.result,
    required this.onSendCard, required this.onViewProfile,
    required this.onNext, required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final top      = MediaQuery.of(context).padding.top;
    final bot      = MediaQuery.of(context).padding.bottom;
    final name     = result?.username ?? '搭子';
    final roleText = [
      result?.careerRole,
      result?.experience != null ? '${result!.experience}经验' : null,
    ].whereType<String>().join(' · ');

    return SizedBox.expand(
      child: Column(children: [
        // ── Navy Header ──
        Container(
          width: double.infinity,
          color: _navy,
          padding: EdgeInsets.fromLTRB(20, top + 44, 20, 28),
          child: Column(children: [
            // "匹配成功" label with lines
            Row(children: [
              Expanded(child: Divider(color: Colors.white.withAlpha(25), thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('匹配成功',
                    style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(153), letterSpacing: 1.0)),
              ),
              Expanded(child: Divider(color: Colors.white.withAlpha(25), thickness: 1)),
            ]),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _HeaderAvatar(label: '我', darker: false),
              const SizedBox(width: 12),
              _MatchBadge(score: score),
              const SizedBox(width: 12),
              _HeaderAvatar(label: name, darker: true),
            ]),
            const SizedBox(height: 14),
            Text(name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white)),
            const SizedBox(height: 3),
            if (roleText.isNotEmpty)
              Text(roleText,
                  style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(178))),
          ]),
        ),
        // ── Scrollable Body ──
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 18, 16, bot + 16),
            child: Column(children: [
              _InfoCard(score: score, result: result),
              const SizedBox(height: 12),
              _TimelineCard(suggestions: result?.collabSuggestions),
              const SizedBox(height: 12),
              _ActionButtons(
                onSendCard:    onSendCard,
                onViewProfile: onViewProfile,
                onNext:        onNext,
              ),
              GestureDetector(
                onTap: onHome,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('回到首页', style: TextStyle(fontSize: 12, color: _sub)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Result sub-widgets ────────────────────────────────────────────────────────

class _HeaderAvatar extends StatelessWidget {
  final String label;
  final bool darker;
  const _HeaderAvatar({required this.label, required this.darker});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          color: darker ? _navyDeep : _navyMid,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(51), width: 2),
        ),
        child: Icon(Icons.person_rounded, color: Colors.white.withAlpha(178), size: 30),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(140))),
    ]);
  }
}

class _MatchBadge extends StatelessWidget {
  final int score;
  const _MatchBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(width: 32, height: 1, color: Colors.white.withAlpha(64)),
      const SizedBox(height: 5),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('$score%', style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(204))),
      ),
      const SizedBox(height: 5),
      Container(width: 32, height: 1, color: Colors.white.withAlpha(64)),
    ]);
  }
}

class _InfoCard extends StatelessWidget {
  final int score;
  final CareerMatchResult? result;
  const _InfoCard({required this.score, required this.result});

  @override
  Widget build(BuildContext context) {
    final name        = result?.username ?? '搭子';
    final company     = result?.company;
    final careerRole  = result?.careerRole;
    final subText     = [company, careerRole].whereType<String>().join(' · ');
    final commonSkills     = result?.commonSkills ?? [];
    final commonSkillCount = result?.commonSkillCount ?? commonSkills.length;
    final commonGoalCount  = result?.commonGoalCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Avatar + name
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.person_rounded, color: Color(0xFF378ADD), size: 26),
          ),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _navy)),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.circle, color: Color(0xFF059669), size: 6),
                  SizedBox(width: 3),
                  Text('在线', style: TextStyle(fontSize: 10, color: Color(0xFF059669))),
                ]),
              ),
            ]),
            if (subText.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(subText, style: const TextStyle(fontSize: 12, color: _sub)),
            ],
          ])),
        ]),
        const SizedBox(height: 12),
        // Score row
        Row(children: [
          _ScoreItem(num: '$score%',           label: '契合度'),
          const SizedBox(width: 8),
          _ScoreItem(num: '$commonSkillCount', label: '共同技能'),
          const SizedBox(width: 8),
          _ScoreItem(num: '$commonGoalCount',  label: '共同目标'),
        ]),
        if (commonSkills.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('共同技能', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _sub)),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: commonSkills
                .map((s) => _SkillTag(s, common: true))
                .toList(),
          ),
        ],
      ]),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  final String num;
  final String label;
  const _ScoreItem({required this.num, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(color: _lightBg, borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(num, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: _navy)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: _sub)),
        ]),
      ),
    );
  }
}

class _SkillTag extends StatelessWidget {
  final String label;
  final bool common;
  const _SkillTag(this.label, {required this.common});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:  common ? _navy : const Color(0xFFF0F5FF),
        border: Border.all(color: common ? _navy : const Color(0xFFC5D8F0), width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: common ? Colors.white : _navy)),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final List<String>? suggestions;
  const _TimelineCard({required this.suggestions});

  static const _dotColors = [_navy, Color(0xFF378ADD), Color(0xFF4ADE80)];

  @override
  Widget build(BuildContext context) {
    final items = (suggestions?.isNotEmpty == true)
        ? suggestions!
        : const ['每周互相分享行业动态', '探讨共同感兴趣的项目'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('可以一起做的事',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _navy)),
        const SizedBox(height: 8),
        for (int i = 0; i < items.length; i++) ...[
          _TlItem(
            color: _dotColors[i % _dotColors.length],
            title: items[i],
            desc:  '',
            last:  i == items.length - 1,
          ),
        ],
      ]),
    );
  }
}

class _TlItem extends StatelessWidget {
  final Color color;
  final String title;
  final String desc;
  final bool last;
  const _TlItem({required this.color, required this.title, required this.desc, required this.last});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _navy)),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 11, color: _sub)),
            ],
          ])),
        ]),
      ),
      if (!last)
        Divider(color: const Color(0xFFF0F5FF), thickness: 0.5, height: 0),
    ]);
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onSendCard;
  final VoidCallback onViewProfile;
  final VoidCallback onNext;
  const _ActionButtons({required this.onSendCard, required this.onViewProfile, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(
        onTap: onSendCard,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(12)),
          child: const Center(
            child: Text('发送职业名片', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _TextBtn(label: '查看完整档案', onTap: onViewProfile)),
        const SizedBox(width: 8),
        Expanded(child: _TextBtn(label: '换一位搭子', onTap: onNext)),
      ]),
      const SizedBox(height: 4),
    ]);
  }
}

class _TextBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TextBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Center(child: Text(label, style: const TextStyle(fontSize: 12, color: _navy))),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SecLabel extends StatelessWidget {
  final String text;
  const _SecLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _sub, letterSpacing: 0.5),
    );
  }
}

class _FieldTag extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FieldTag({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color:  selected ? _navy : Colors.white,
          border: Border.all(color: selected ? _navy : _border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12,
          color: selected ? Colors.white : const Color(0xFF3A5A7A),
        )),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final _Goal data;
  final bool selected;
  final VoidCallback onTap;
  const _GoalCard({required this.data, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:  selected ? const Color(0xFFF0F5FF) : Colors.white,
          border: Border.all(color: selected ? _navy : _border, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: data.bg, borderRadius: BorderRadius.circular(8)),
              child: Icon(data.icon, color: data.ic, size: 15),
            ),
            const SizedBox(height: 7),
            Text(data.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _navy)),
            const SizedBox(height: 2),
            Text(data.desc, style: const TextStyle(fontSize: 11, color: _sub)),
          ]),
          if (selected)
            Positioned(
              top: 0, right: 0,
              child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: _navy, shape: BoxShape.circle)),
            ),
        ]),
      ),
    );
  }
}

class _ExpBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ExpBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:  selected ? _navy : Colors.white,
          border: Border.all(color: selected ? _navy : _border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text(label, style: TextStyle(
          fontSize: 12,
          color: selected ? Colors.white : const Color(0xFF3A5A7A),
        ))),
      ),
    );
  }
}
