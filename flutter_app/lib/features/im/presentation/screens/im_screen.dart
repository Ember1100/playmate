import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/widgets/pm_image.dart';
import '../../data/im_model.dart';
import '../../data/websocket_service.dart';
import '../../providers/im_provider.dart';

class ImScreen extends ConsumerStatefulWidget {
  const ImScreen({super.key});

  @override
  ConsumerState<ImScreen> createState() => _ImScreenState();
}

class _ImScreenState extends ConsumerState<ImScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // 编辑模式（聊天 Tab）
  bool _editMode = false;
  final Set<String> _selected = {};

  static const _tabs = ['聊天', '互动', '交易', '活动', '系统通知'];

  // HTML avatar 颜色池
  static const _avatarPalette = [
    (_Color(0xFFFBEAF0), _Color(0xFF993556)),
    (_Color(0xFFE6F1FB), _Color(0xFF185FA5)),
    (_Color(0xFFE1F5EE), _Color(0xFF0F6E56)),
    (_Color(0xFFFAEEDA), _Color(0xFF854F0B)),
    (_Color(0xFFFAECE7), _Color(0xFF993C1D)),
    (_Color(0xFFEEEDFE), _Color(0xFF534AB7)),
    (_Color(0xFFF1EFE8), _Color(0xFF5F5E5A)),
    (_Color(0xFFFCEBEB), _Color(0xFFA32D2D)),
  ];

  (Color, Color) _avatarColor(String seed) {
    final pair = _avatarPalette[seed.hashCode.abs() % _avatarPalette.length];
    return (pair.$1.toColor(), pair.$2.toColor());
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _initWebSocket();
  }

  Future<void> _initWebSocket() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final token = await tokenStorage.getAccessToken();
    if (token == null) return;
    ref.read(wsServiceProvider).connect(token);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() { _editMode = !_editMode; _selected.clear(); });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) { _selected.remove(id); } else { _selected.add(id); }
    });
  }

  void _markReadSelected() {
    ref.read(conversationsProvider.notifier).markSelectedRead(_selected);
    setState(() { _editMode = false; _selected.clear(); });
  }

  void _deleteSelected() {
    ref.read(conversationsProvider.notifier).deleteSelected(_selected);
    setState(() { _editMode = false; _selected.clear(); });
  }

  void _clearAllRead() {
    ref.read(notificationsProvider.notifier).markAllRead();
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inDays == 0)    return DateFormat('HH:mm').format(dt);
    if (diff.inDays < 7)     return ['日','一','二','三','四','五','六'][dt.weekday % 7];
    return DateFormat('MM-dd').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final groupSessionsAsync  = ref.watch(groupSessionsProvider);
    final notificationsAsync  = ref.watch(notificationsProvider);
    final notifs = notificationsAsync.valueOrNull ?? [];

    final systemUnread   = notifs.where((n) => n.type == NotificationType.system && !n.isRead).length;
    final interactUnread = notifs.where((n) =>
        n.type == NotificationType.interaction ||
        n.type == NotificationType.buddyRequest ||
        n.type == NotificationType.invitation).where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF333333)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '通知中心',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
        ),
        actions: [
          TextButton(
            onPressed: _clearAllRead,
            child: const Text('清空已读', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20, color: Color(0xFF888888)),
            onPressed: () => context.push('/profile/settings'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(41),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 0.5)),
            ),
            child: TabBar(
              controller:           _tabController,
              isScrollable:         true,
              tabAlignment:         TabAlignment.start,
              labelColor:           const Color(0xFF1A1A1A),
              unselectedLabelColor: const Color(0xFF888888),
              labelStyle:           const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 2, color: Color(0xFF1A1A1A)),
                insets: EdgeInsets.symmetric(horizontal: 8),
              ),
              dividerColor: Colors.transparent,
              tabs: [
                const Tab(text: '聊天'),
                _InlineBadgeTab(label: '互动', count: interactUnread),
                const Tab(text: '交易'),
                const Tab(text: '活动'),
                _InlineBadgeTab(label: '系统通知', count: systemUnread),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _editMode
          ? SafeArea(
              child: Container(
                height: 56,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _selected.isEmpty ? null : _markReadSelected,
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: const Text('标记已读'),
                        style: TextButton.styleFrom(
                          foregroundColor: _selected.isEmpty ? const Color(0xFFAAAAAA) : AppColors.primary,
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1, indent: 12, endIndent: 12),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _selected.isEmpty ? null : _deleteSelected,
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('删除'),
                        style: TextButton.styleFrom(
                          foregroundColor: _selected.isEmpty ? const Color(0xFFAAAAAA) : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatTab(conversationsAsync, groupSessionsAsync),
          _buildInteractTab(notifs),
          _buildEmptyTab('暂无交易通知', Icons.receipt_long_outlined),
          _buildEmptyTab('暂无活动通知', Icons.event_outlined),
          _buildSystemTab(notifs.where((n) => n.type == NotificationType.system).toList()),
        ],
      ),
    );
  }

  // ── 聊天 Tab ─────────────────────────────────────────────────────────────────

  Widget _buildChatTab(
    AsyncValue<List<Conversation>>  convsAsync,
    AsyncValue<List<GroupSession>>  groupsAsync,
  ) {
    final convs  = convsAsync.valueOrNull  ?? [];
    final groups = groupsAsync.valueOrNull ?? [];

    final sessions = <_Session>[
      ...convs.map(_Session.fromConv),
      ...groups.map(_Session.fromGroup),
    ]..sort((a, b) {
        if (a.lastMessageAt == null) return 1;
        if (b.lastMessageAt == null) return -1;
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      });

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await Future.wait([
          ref.read(conversationsProvider.notifier).refresh(),
          ref.read(groupSessionsProvider.notifier).refresh(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 编辑按钮行
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('私信 & 群聊',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA), fontWeight: FontWeight.w500)),
                GestureDetector(
                  onTap: _toggleEdit,
                  child: Text(
                    _editMode ? '完成' : '编辑',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                  ),
                ),
              ],
            ),
          ),
          if (sessions.isEmpty)
            _buildEmptyTab('暂无消息，去找个搭伴聊聊吧', Icons.chat_bubble_outline)
          else
            ...sessions.asMap().entries.map((e) => _buildSessionRow(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildSessionRow(int index, _Session item) {
    final (bg, fg) = _avatarColor(item.name);
    final isChecked = _selected.contains(item.id);

    return Column(
      children: [
        InkWell(
          onTap: () {
            if (_editMode) { _toggleSelect(item.id); return; }
            if (item.type == _SessionType.dm) {
              ref.read(conversationsProvider.notifier).clearUnread(item.id);
              context.push('/im/chat/${item.id}', extra: {
                'username': item.name,
                'otherUserId': item.otherId,
              });
            } else {
              context.push('/im/group/${item.id}', extra: {'groupName': item.name});
            }
          },
          child: Container(
            color: isChecked ? AppColors.primaryLight.withValues(alpha: 0.5) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // 编辑模式复选框
                if (_editMode) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isChecked ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: isChecked ? AppColors.primary : const Color(0xFFBBBBBB),
                        width: 2,
                      ),
                    ),
                    child: isChecked ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 10),
                ],
                // 未读点
                SizedBox(
                  width: 11,
                  child: item.unreadCount > 0
                      ? Container(width: 7, height: 7,
                          decoration: const BoxDecoration(color: Color(0xFFE24B4A), shape: BoxShape.circle))
                      : null,
                ),
                const SizedBox(width: 4),
                // 头像
                _AvatarCircle(
                  label: item.avatarUrl != null ? '' : (item.name.isNotEmpty ? item.name[0] : '?'),
                  imageUrl: item.avatarUrl,
                  bg: bg, fg: fg, size: 36,
                  badge: item.type == _SessionType.group
                      ? const Icon(Icons.people, size: 10, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                // 内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(item.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A1A1A)),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(_formatTime(item.lastMessageAt),
                              style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(item.lastMessage ?? '',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 0.5, thickness: 0.5, indent: 64, color: Color(0xFFEEEEEE)),
      ],
    );
  }

  // ── 互动 Tab ──────────────────────────────────────────────────────────────────

  Widget _buildInteractTab(List<AppNotification> allNotifs) {
    final topicNotifs = allNotifs.where((n) => n.type == NotificationType.interaction).toList();
    final buddyNotifs = allNotifs.where((n) =>
        n.type == NotificationType.buddyRequest || n.type == NotificationType.invitation).toList();

    if (topicNotifs.isEmpty && buddyNotifs.isEmpty) {
      return _buildEmptyTab('暂无互动通知', Icons.favorite_border_rounded);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (topicNotifs.isNotEmpty) ...[
          _SectionLabel(label: '话题动态'),
          ...topicNotifs.map(_buildNotifRow),
        ],
        if (buddyNotifs.isNotEmpty) ...[
          if (topicNotifs.isNotEmpty) const _Divider(),
          _SectionLabel(label: '搭子互动'),
          ...buddyNotifs.map(_buildNotifRow),
        ],
      ],
    );
  }

  // ── 系统通知 Tab ──────────────────────────────────────────────────────────────

  Widget _buildSystemTab(List<AppNotification> notifs) {
    final hasUrgent = notifs.any((n) => !n.isRead);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (hasUrgent) _buildAlertBar(),
        _SectionLabel(label: '平台运营通知'),
        if (notifs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('暂无系统通知', style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA))),
            ),
          )
        else
          ...notifs.map(_buildNotifRow),
      ],
    );
  }

  Widget _buildAlertBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18, height: 18,
            decoration: const BoxDecoration(color: Color(0xFFE24B4A), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Text('!', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '您有未读的系统通知，请及时查看',
              style: TextStyle(fontSize: 12, color: Color(0xFFA32D2D), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifRow(AppNotification n) {
    final (bg, fg) = _notifAvatarColor(n.type);
    final initial  = _notifInitial(n.type);
    final tagLabel = _notifTagLabel(n.type);
    final tagColor = _notifTagColor(n.type);

    return Column(
      children: [
        InkWell(
          onTap: () {
            ref.read(notificationsProvider.notifier).markRead(n.id);
            if (n.type == NotificationType.buddyRequest || n.type == NotificationType.invitation) {
              context.push('/buddy/invitations');
            }
          },
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 未读点
                SizedBox(
                  width: 11,
                  child: !n.isRead
                      ? Container(
                          width: 7, height: 7, margin: const EdgeInsets.only(top: 5),
                          decoration: const BoxDecoration(color: Color(0xFFE24B4A), shape: BoxShape.circle),
                        )
                      : null,
                ),
                const SizedBox(width: 4),
                // 头像圆圈
                _AvatarCircle(label: initial, bg: bg, fg: fg, size: 36),
                const SizedBox(width: 10),
                // 内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(n.title,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A1A1A)),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(_formatTime(n.createdAt),
                              style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(n.content,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF888888), height: 1.5),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (tagLabel != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(tagLabel,
                              style: TextStyle(fontSize: 11, color: tagColor, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 0.5, thickness: 0.5, indent: 64, color: Color(0xFFEEEEEE)),
      ],
    );
  }

  // ── 空状态 ────────────────────────────────────────────────────────────────────

  Widget _buildEmptyTab(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: const Color(0xFFCCCCCC)),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA))),
        ],
      ),
    );
  }

  // ── 通知图标/颜色辅助 ─────────────────────────────────────────────────────────

  (Color, Color) _notifAvatarColor(NotificationType t) => switch (t) {
        NotificationType.system       => (const Color(0xFFFCEBEB), const Color(0xFFA32D2D)),
        NotificationType.buddyRequest => (const Color(0xFFE1F5EE), const Color(0xFF0F6E56)),
        NotificationType.invitation   => (const Color(0xFFEEEDFE), const Color(0xFF534AB7)),
        NotificationType.interaction  => (const Color(0xFFFAECE7), const Color(0xFF993C1D)),
      };

  String _notifInitial(NotificationType t) => switch (t) {
        NotificationType.system       => '系',
        NotificationType.buddyRequest => '搭',
        NotificationType.invitation   => '邀',
        NotificationType.interaction  => '互',
      };

  String? _notifTagLabel(NotificationType t) => switch (t) {
        NotificationType.system       => '系统',
        NotificationType.buddyRequest => '搭子匹配',
        NotificationType.invitation   => '邀约',
        NotificationType.interaction  => null,
      };

  Color _notifTagColor(NotificationType t) => switch (t) {
        NotificationType.system       => const Color(0xFFA32D2D),
        NotificationType.buddyRequest => const Color(0xFF0F6E56),
        NotificationType.invitation   => const Color(0xFF534AB7),
        NotificationType.interaction  => const Color(0xFF993C1D),
      };
}

// ── 辅助数据类 ────────────────────────────────────────────────────────────────

enum _SessionType { dm, group }

class _Session {
  const _Session({
    required this.id,
    required this.type,
    required this.name,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    this.otherId,
  });

  factory _Session.fromConv(Conversation c) => _Session(
        id: c.id, type: _SessionType.dm,
        name: c.otherUsername, avatarUrl: c.otherAvatarUrl,
        lastMessage: c.lastMessage, lastMessageAt: c.lastMessageAt,
        unreadCount: c.unreadCount, otherId: c.otherUserId,
      );

  factory _Session.fromGroup(GroupSession g) => _Session(
        id: g.id, type: _SessionType.group,
        name: g.name, avatarUrl: g.avatarUrl,
        lastMessage: g.lastMessage, lastMessageAt: g.lastMessageAt,
        unreadCount: g.unreadCount,
      );

  final String       id;
  final _SessionType type;
  final String       name;
  final String?      avatarUrl;
  final String?      lastMessage;
  final DateTime?    lastMessageAt;
  final int          unreadCount;
  final String?      otherId;
}

// ── 小组件 ────────────────────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.label,
    required this.bg,
    required this.fg,
    required this.size,
    this.imageUrl,
    this.badge,
  });

  final String   label;
  final Color    bg;
  final Color    fg;
  final double   size;
  final String?  imageUrl;
  final Widget?  badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: bg,
          backgroundImage: imageUrl != null ? PmImageProvider(imageUrl!) : null,
          child: imageUrl == null
              ? Text(label, style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w500, color: fg))
              : null,
        ),
        if (badge != null)
          Positioned(
            right: -2, bottom: -2,
            child: Container(
              width: 16, height: 16,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: badge,
            ),
          ),
      ],
    );
  }
}

class _InlineBadgeTab extends StatelessWidget {
  const _InlineBadgeTab({required this.label, required this.count});
  final String label;
  final int    count;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFE24B4A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA), fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Divider(height: 0.5, thickness: 0.5, color: Color(0xFFEEEEEE)),
      );
}

// 用于 record 中的颜色常量（不能直接用 Color 作为 const record 元素）
class _Color {
  const _Color(this.value);
  final int value;
  Color toColor() => Color(value);
}
