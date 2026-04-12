import 'package:flutter/material.dart';
import '../../../../shared/widgets/pm_image.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 数据模型
// TODO: 替换为 API 接口时，将下方静态数据改为 Riverpod AsyncNotifier 即可，
//       Widget 层无需改动。
// ═══════════════════════════════════════════════════════════════════════════

class CircleTopicItem {
  const CircleTopicItem({
    required this.title,
    required this.desc,
    required this.author,
    required this.time,
    required this.imageUrl,
    this.fallbackColor = const Color(0xFFFFDDB3),
  });
  final String title;
  final String desc;
  final String author;
  final String time;
  final String imageUrl;
  final Color fallbackColor;
}

class CircleGroupItem {
  const CircleGroupItem({
    required this.name,
    required this.memberCount,
    required this.newToday,
    this.badge = 0,
    this.avatarColor = const Color(0xFFFFE8C0),
  });
  final String name;
  final int memberCount;
  final int newToday;
  final int badge;
  final Color avatarColor;
}

// ── 图片域名 ──────────────────────────────────────────────────────────────────
const _imgBase = 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=';

// ── 推荐页分类标签 ─────────────────────────────────────────────────────────────
const _recommendTags = ['热点', '关注', '自我成长', '认知升级', '情绪管理', '人际关系', '职场进阶', '更多'];

// ── 推荐页话题卡片（每分类4条）── TODO: GET /api/v1/topics?category=hot&page=1
final _recommendTopics = <String, List<CircleTopicItem>>{
  '热点': [
    CircleTopicItem(title: '职场内卷是否值得，年轻人该如何选择', desc: '内卷时代，是被迫竞争还是寻找破局之路，理性看待职场内卷', author: '热点观察员', time: '30分钟前', imageUrl: '${_imgBase}young%20asian%20student%20portrait', fallbackColor: const Color(0xFFFFDDB3)),
    CircleTopicItem(title: '考研考公热背后的真实选择', desc: '分析考研考公的利弊，帮助年轻人做出理性决策', author: '教育博主', time: '1小时前', imageUrl: '${_imgBase}student%20exam%20preparation%20study', fallbackColor: const Color(0xFFD4E8FF)),
    CircleTopicItem(title: '35岁职场危机如何破局', desc: '35岁不是终点，而是新的起点，掌握职业转型的关键策略', author: '职业规划师', time: '2小时前', imageUrl: '${_imgBase}young%20professional%20career%20planning', fallbackColor: const Color(0xFFD4F5E4)),
    CircleTopicItem(title: '普通人创业的真实案例分享', desc: '100个小成本创业案例，避开坑点，少走弯路', author: '创业导师', time: '3小时前', imageUrl: '${_imgBase}entrepreneur%20meeting%20business%20planning', fallbackColor: const Color(0xFFFFE4D4)),
  ],
  '关注': [
    CircleTopicItem(title: '如何培养深度阅读习惯', desc: '在碎片化时代，找回深度阅读的能力和乐趣', author: '阅读导师', time: '30分钟前', imageUrl: '${_imgBase}book%20reading%20sharing', fallbackColor: const Color(0xFFE8D4FF)),
    CircleTopicItem(title: '每天10分钟冥想练习', desc: '简单的冥想方法，帮助缓解压力提升专注力', author: '心灵导师', time: '1小时前', imageUrl: '${_imgBase}meditation%20mindfulness%20relaxation', fallbackColor: const Color(0xFFD4F5E4)),
    CircleTopicItem(title: '写日记对成长的帮助', desc: '通过日记记录反思，持续提升自我认知', author: '写作教练', time: '2小时前', imageUrl: '${_imgBase}journal%20writing%20reflection', fallbackColor: const Color(0xFFFFE4D4)),
    CircleTopicItem(title: '打造高效晨间习惯', desc: '5个简单步骤，建立属于自己的晨间仪式感', author: '生活教练', time: '3小时前', imageUrl: '${_imgBase}healthy%20lifestyle%20morning%20routine', fallbackColor: const Color(0xFFD4E8FF)),
  ],
  '自我成长': [
    CircleTopicItem(title: '如何建立成长型思维', desc: '从固定思维到成长思维，改变看待问题的方式', author: '心理专家', time: '30分钟前', imageUrl: '${_imgBase}young%20asian%20student%20portrait', fallbackColor: const Color(0xFFFFDDB3)),
    CircleTopicItem(title: '高效学习方法分享', desc: '掌握科学的学习方法，提升学习效率', author: '教育博主', time: '1小时前', imageUrl: '${_imgBase}student%20exam%20preparation%20study', fallbackColor: const Color(0xFFD4E8FF)),
    CircleTopicItem(title: '如何制定有效的人生目标', desc: 'SMART原则教你制定可执行的目标计划', author: '成长教练', time: '2小时前', imageUrl: '${_imgBase}goal%20setting%20planning', fallbackColor: const Color(0xFFD4F5E4)),
    CircleTopicItem(title: '克服公众演讲恐惧', desc: '5个实用技巧，让你在公众场合自信表达', author: '沟通导师', time: '3小时前', imageUrl: '${_imgBase}public%20speaking%20confidence', fallbackColor: const Color(0xFFFFE4D4)),
  ],
  '认知升级': [
    CircleTopicItem(title: '如何提升认知能力', desc: '通过刻意练习和系统学习，持续提升认知水平', author: '认知教练', time: '30分钟前', imageUrl: '${_imgBase}brain%20thinking%20idea', fallbackColor: const Color(0xFFE8D4FF)),
    CircleTopicItem(title: '学习新技能的正确方法', desc: '20小时快速掌握任何新技能的秘诀', author: '技能导师', time: '1小时前', imageUrl: '${_imgBase}learning%20new%20skill', fallbackColor: const Color(0xFFFFDDB3)),
    CircleTopicItem(title: '如何培养创新思维', desc: '打破思维定式，培养独特的创新能力', author: '创新导师', time: '2小时前', imageUrl: '${_imgBase}creative%20thinking%20innovation', fallbackColor: const Color(0xFFD4E8FF)),
    CircleTopicItem(title: '提升决策能力的5个方法', desc: '在复杂环境中做出更好决策的实用技巧', author: '决策教练', time: '3小时前', imageUrl: '${_imgBase}decision%20making%20analysis', fallbackColor: const Color(0xFFD4F5E4)),
  ],
  '情绪管理': [
    CircleTopicItem(title: '如何管理负面情绪', desc: '识别、接纳和转化负面情绪的实用方法', author: '心理专家', time: '30分钟前', imageUrl: '${_imgBase}calm%20relaxation%20peaceful', fallbackColor: const Color(0xFFFFE4D4)),
    CircleTopicItem(title: '快速缓解压力的5个方法', desc: '工作生活压力大？这些方法帮你快速放松', author: '减压导师', time: '1小时前', imageUrl: '${_imgBase}stress%20relief%20relaxation', fallbackColor: const Color(0xFFE8D4FF)),
    CircleTopicItem(title: '提升情绪智力的方法', desc: 'EQ比IQ更重要，掌握情绪管理的智慧', author: '情商教练', time: '2小时前', imageUrl: '${_imgBase}emotional%20intelligence%20self%20awareness', fallbackColor: const Color(0xFFFFDDB3)),
    CircleTopicItem(title: '培养感恩心态的力量', desc: '每天记录3件感恩的事，改变你的生活视角', author: '积极心理', time: '3小时前', imageUrl: '${_imgBase}gratitude%20positive%20thinking', fallbackColor: const Color(0xFFD4E8FF)),
  ],
  '人际关系': [
    CircleTopicItem(title: '如何建立深度人际关系', desc: '真诚沟通是建立深度关系的关键', author: '社交导师', time: '30分钟前', imageUrl: '${_imgBase}communication%20listening%20understanding', fallbackColor: const Color(0xFFD4F5E4)),
    CircleTopicItem(title: '处理人际冲突的5个技巧', desc: '把冲突转化为理解与成长的机会', author: '调解专家', time: '1小时前', imageUrl: '${_imgBase}conflict%20resolution%20mediation', fallbackColor: const Color(0xFFFFE4D4)),
    CircleTopicItem(title: '如何拓展优质人脉圈', desc: '建立有价值的人际关系网络', author: '人脉教练', time: '2小时前', imageUrl: '${_imgBase}networking%20professional%20connection', fallbackColor: const Color(0xFFE8D4FF)),
    CircleTopicItem(title: '学会设立人际边界', desc: '健康的边界感是良好关系的基础', author: '关系导师', time: '3小时前', imageUrl: '${_imgBase}boundaries%20respect%20communication', fallbackColor: const Color(0xFFFFDDB3)),
  ],
  '职场进阶': [
    CircleTopicItem(title: '如何在职场中快速成长', desc: '主动学习、多问多思、持续精进', author: '职场导师', time: '30分钟前', imageUrl: '${_imgBase}office%20scene%20with%20business%20people', fallbackColor: const Color(0xFFD4E8FF)),
    CircleTopicItem(title: '职场汇报技巧分享', desc: '清晰、简洁、有逻辑的职场表达', author: '表达教练', time: '1小时前', imageUrl: '${_imgBase}presentation%20public%20speaking', fallbackColor: const Color(0xFFD4F5E4)),
    CircleTopicItem(title: '从执行者到管理者的转变', desc: '思维方式和工作方法的全面升级', author: '管理导师', time: '2小时前', imageUrl: '${_imgBase}leadership%20team%20management', fallbackColor: const Color(0xFFFFE4D4)),
    CircleTopicItem(title: '制定你的3年职业规划', desc: '明确方向、分解目标、持续行动', author: '职业规划师', time: '3小时前', imageUrl: '${_imgBase}career%20planning%20goal%20setting', fallbackColor: const Color(0xFFE8D4FF)),
  ],
  '更多': [
    CircleTopicItem(title: '更多精彩内容持续更新', desc: '敬请期待更多优质话题和讨论', author: '系统', time: '1小时前', imageUrl: '${_imgBase}miscellaneous%20collection%20ideas', fallbackColor: const Color(0xFFFFDDB3)),
    CircleTopicItem(title: '社区互动活动预告', desc: '精彩活动即将上线，敬请期待', author: '社区运营', time: '2小时前', imageUrl: '${_imgBase}community%20discussion%20engagement', fallbackColor: const Color(0xFFD4E8FF)),
    CircleTopicItem(title: '你的建议对我们很重要', desc: '欢迎提出宝贵意见，帮助我们改进', author: '产品团队', time: '3小时前', imageUrl: '${_imgBase}feedback%20suggestion%20improvement', fallbackColor: const Color(0xFFD4F5E4)),
    CircleTopicItem(title: '新功能上线通知', desc: '更多实用功能即将上线', author: '技术团队', time: '4小时前', imageUrl: '${_imgBase}feature%20update%20new%20function', fallbackColor: const Color(0xFFFFE4D4)),
  ],
};

// ── 话题页分类标签 ─────────────────────────────────────────────────────────────
const _topicPageTags = ['事业财富', '天道规则', '人性洞察', '认知升级', '生活挑战', '情感家庭', '考研考公', '英语学习'];

// ── 话题页话题列表 ── TODO: GET /api/v1/topics?page=1
const _topicPageItems = [
  CircleTopicItem(title: '遭遇职场霸凌该如何应对？', desc: '识别职场霸凌的常见形式，掌握保护自己的方法，勇敢说不', author: '职场导师', time: '2小时前', imageUrl: '${_imgBase}office%20scene%20with%20business%20people', fallbackColor: Color(0xFFD4E8FF)),
  CircleTopicItem(title: '35岁之后的职业出路在哪里？', desc: '打破年龄焦虑，找到适合自己的职业转型方向和提升路径', author: '职业规划师', time: '4小时前', imageUrl: '${_imgBase}young%20professional%20career%20planning', fallbackColor: Color(0xFFD4F5E4)),
  CircleTopicItem(title: '普通人创业成功的真实案例分享', desc: '精选100个小成本创业案例，避开坑点，少走弯路', author: '创业导师', time: '1天前', imageUrl: '${_imgBase}entrepreneur%20meeting%20business%20planning', fallbackColor: Color(0xFFFFDDB3)),
  CircleTopicItem(title: '如何看待职场中的"佛系"文化？', desc: '佛系不是躺平，而是在高压环境下的自我调节和心态平衡', author: '心理专家', time: '1天前', imageUrl: '${_imgBase}relaxing%20meditation%20and%20mindfulness', fallbackColor: Color(0xFFFFE4D4)),
  CircleTopicItem(title: '考研还是考公？如何做最优选择', desc: '分析不同路径的优缺点，结合自身情况做出适合的选择', author: '教育博主', time: '2天前', imageUrl: '${_imgBase}student%20exam%20preparation%20study', fallbackColor: Color(0xFFE8D4FF)),
];

// ── 群聊页左侧分类 ─────────────────────────────────────────────────────────────
const _chatCategories = ['我的群聊', '同城交友', '兴趣爱好', '职场交流', '游戏开黑', '美食探店', '运动健身'];

// ── 群聊页分组数据 ── TODO: GET /api/v1/circle/groups?page=1
const _chatSections = [
  (
    title: '同城车友会',
    groups: [
      CircleGroupItem(name: '宝马车友会-北京',  memberCount: 892,  newToday: 12, badge: 12, avatarColor: Color(0xFFD4E8FF)),
      CircleGroupItem(name: '新能源车主交流群', memberCount: 1568, newToday: 28, badge: 28, avatarColor: Color(0xFFD4F5E4)),
      CircleGroupItem(name: '二手车买卖交流群', memberCount: 753,  newToday: 9,  badge: 9,  avatarColor: Color(0xFFFFDDB3)),
    ],
  ),
  (
    title: '职场交流',
    groups: [
      CircleGroupItem(name: '互联网大厂交流群', memberCount: 2345, newToday: 45, badge: 45, avatarColor: Color(0xFFFFE4D4)),
      CircleGroupItem(name: '程序员技术交流群', memberCount: 3120, newToday: 68, badge: 68, avatarColor: Color(0xFFE8D4FF)),
    ],
  ),
  (
    title: '兴趣爱好',
    groups: [
      CircleGroupItem(name: '摄影爱好者交流群', memberCount: 1890, newToday: 32, badge: 32, avatarColor: Color(0xFFD4E8FF)),
      CircleGroupItem(name: '读书分享交流群',   memberCount: 1256, newToday: 18, badge: 18, avatarColor: Color(0xFFFFDDB3)),
    ],
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// 主页面
// ═══════════════════════════════════════════════════════════════════════════

class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key});

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _recommendTagIndex = 0;
  int _topicTagIndex = 0;
  int _chatCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8C0),
      body: SafeArea(
        child: Column(
          children: [
            const _SearchBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRecommendTab(),
                  _buildTopicTab(),
                  _buildChatTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 顶部 Tab ────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    const labels = ['推荐', '话题', '群聊'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(labels.length, (i) {
        final selected = _tabController.index == i;
        return GestureDetector(
          onTap: () => _tabController.animateTo(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? const Color(0xFFFFB703) : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                fontSize: 16,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? const Color(0xFF222222) : const Color(0xFF999999),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── 推荐页 ──────────────────────────────────────────────────────────────

  Widget _buildRecommendTab() {
    final tag = _recommendTags[_recommendTagIndex];
    final cards = _recommendTopics[tag] ?? [];
    return ListView(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 16),
      children: [
        _buildPublishBar(),
        const SizedBox(height: 8),
        _buildDebateBox(),
        const SizedBox(height: 16),
        _buildTagScroll(
          tags: _recommendTags,
          selectedIndex: _recommendTagIndex,
          onTap: (i) => setState(() => _recommendTagIndex = i),
        ),
        const SizedBox(height: 16),
        ...cards.map((item) => _TopicCard(item: item)),
      ],
    );
  }

  Widget _buildPublishBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB703),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _iconBox('✏️'),
                  const SizedBox(width: 8),
                  const Text('发布话题', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.35)),
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _iconBox('📊'),
                  const SizedBox(width: 8),
                  const Text('发布投票', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  const Text('›', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBox(String emoji) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
    );
  }

  Widget _buildDebateBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💬', style: TextStyle(fontSize: 17)),
              SizedBox(width: 6),
              Text('今日观点交锋',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
            ],
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5E1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFE8C0)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('正方', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFD36A00))),
                        SizedBox(height: 5),
                        Text('努力一定能改变命运，坚持付出就会有回报，脚踏实地才是人生正道',
                            style: TextStyle(fontSize: 12.5, color: Color(0xFFD36A00), height: 1.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('反方', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF555555))),
                        SizedBox(height: 5),
                        Text('选择比努力更重要，方向错了越努力越失败，思维认知决定上限',
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF555555), height: 1.5)),
                      ],
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

  // ── 话题页 ──────────────────────────────────────────────────────────────

  Widget _buildTopicTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 16),
      children: [
        _buildTagScroll(
          tags: _topicPageTags,
          selectedIndex: _topicTagIndex,
          onTap: (i) => setState(() => _topicTagIndex = i),
        ),
        const SizedBox(height: 16),
        ..._topicPageItems.map((item) => _TopicCard(item: item)),
      ],
    );
  }

  // ── 群聊页 ──────────────────────────────────────────────────────────────

  Widget _buildChatTab() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧分类栏 80px
        SizedBox(
          width: 80,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 12),
            itemCount: _chatCategories.length,
            itemBuilder: (_, i) {
              final selected = _chatCategoryIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _chatCategoryIndex = i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4, left: 8, right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFFFB703) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _chatCategories[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? Colors.white : const Color(0xFF666666),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ),
        // 右侧群列表
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
            children: [
              for (final section in _chatSections) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 0, 8),
                  child: Text(section.title,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                ),
                ...section.groups.map((g) => _buildChatGroupItem(g)),
                const SizedBox(height: 4),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatGroupItem(CircleGroupItem g) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFFFE0B2))),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: g.avatarColor, borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Icon(Icons.group_rounded, color: Color(0xFFFFB703), size: 24)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
                const SizedBox(height: 2),
                Text('${g.memberCount}人已加入 今日新增${g.newToday}人',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF999999), height: 1.2)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB703),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('加入',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                ),
              ),
              if (g.badge > 0) ...[
                const SizedBox(height: 4),
                Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(color: Color(0xFFFF4757), shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      g.badge > 99 ? '99+' : '${g.badge}',
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── 公共：标签横向滚动 ───────────────────────────────────────────────────

  Widget _buildTagScroll({
    required List<String> tags,
    required int selectedIndex,
    required ValueChanged<int> onTap,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tags.length, (i) {
          final selected = selectedIndex == i;
          return GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              margin: const EdgeInsets.only(right: 9),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFFB703) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: selected ? null : Border.all(color: const Color(0xFFFFE0B2)),
                boxShadow: selected
                    ? [BoxShadow(color: const Color(0xFFFFB703).withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))]
                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Text(
                tags[i],
                style: TextStyle(
                  fontSize: 12.5,
                  color: selected ? Colors.white : const Color(0xFF666666),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 话题卡片（独立 Widget，修复 Overflow）
// ═══════════════════════════════════════════════════════════════════════════

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.item});
  final CircleTopicItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面图 — 固定 102×82，网络图片加载，失败时显示彩色占位
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: PmImage(item.imageUrl, width: 102, height: 82, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          // 内容区 — 不设固定高度，内容自然撑开
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: Color(0xFF222222), height: 1.35),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  item.desc,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF777777), height: 1.45),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.author} · ${item.time}',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF999999)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB703),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFB703).withValues(alpha: 0.25),
                              blurRadius: 6, offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text('热议',
                            style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
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

  Widget _imagePlaceholder(Color color) {
    return Container(
      width: 102,
      height: 82,
      color: color,
      child: const Center(child: Icon(Icons.image_outlined, color: Colors.white54, size: 28)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 搜索栏
// ═══════════════════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 12, 15, 18),
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFB703).withValues(alpha: 0.15)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 14),
          Icon(Icons.search_rounded, color: Color(0xFF999999), size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text('搜索群聊...', style: TextStyle(color: Color(0xFF999999), fontSize: 14)),
          ),
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.star_outline_rounded, color: Color(0xFFFFB703), size: 20),
          ),
        ],
      ),
    );
  }
}
