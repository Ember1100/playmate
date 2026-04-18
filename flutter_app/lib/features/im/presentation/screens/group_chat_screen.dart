import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/im_model.dart';
import '../../data/websocket_service.dart';
import '../../providers/im_provider.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.memberCount,
  });

  final String groupId;
  final String groupName;
  final int? memberCount;

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _textController  = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  static const _colorPool = [
    Color(0xFF7F77DD), Color(0xFF4ECDC4), Color(0xFFFF6B6B),
    Color(0xFFFFBE0B), Color(0xFF06D6A0), Color(0xFF5DCAA5),
    Color(0xFFFF9F43), Color(0xFFA29BFE),
  ];
  final _colorMap = <String, Color>{};

  Color _avatarColor(String senderId) =>
      _colorMap.putIfAbsent(senderId, () => _colorPool[_colorMap.length % _colorPool.length]);

  @override
  void initState() {
    super.initState();
    _initWebSocket();
  }

  Future<void> _initWebSocket() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final token = await tokenStorage.getAccessToken();
    if (token == null) return;

    final wsService = ref.read(wsServiceProvider);
    await wsService.connect(token);

    // 进入群聊时标记已读
    _markRead();

    _wsSub = wsService.messages.listen((data) {
      if (data['type'] == 'new_group_message') {
        final gid = data['group_id'] as String?;
        if (gid != widget.groupId) return;

        final currentUser = ref.read(currentUserProvider);
        final msg = GroupMessage(
          id: (data['message_id'] as String?) ?? '',
          groupId: gid ?? widget.groupId,
          senderId: data['sender_id'] as String?,
          senderUsername: data['sender_username'] as String? ?? '未知',
          senderAvatarUrl: data['sender_avatar_url'] as String?,
          type: data['msg_type'] as int? ?? 1,
          content: data['content'] as String?,
          mediaUrl: data['media_url'] as String?,
          isRecalled: false,
          createdAt: DateTime.tryParse(data['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
        );

        // 过滤掉自己发的消息（已由 WS ack 时的乐观消息处理）
        final senderId = data['sender_id'] as String?;
        if (senderId == currentUser?.id) return;

        ref.read(groupChatProvider(widget.groupId).notifier).addMessage(msg);
        _scrollToBottom();
      }
    });
  }

  void _markRead() {
    // 乐观清零本地未读数，避免退出时 refresh() 竞态覆盖
    ref.read(groupSessionsProvider.notifier).clearGroupUnread(widget.groupId);
    ref.read(wsServiceProvider).sendMessage({
      'type': 'mark_group_read',
      'group_id': widget.groupId,
      'last_read_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0)   return DateFormat('HH:mm').format(dt);
    if (diff.inDays == 1)   return '昨天 ${DateFormat('HH:mm').format(dt)}';
    if (diff.inDays < 7)    return '${['日','一','二','三','四','五','六'][dt.weekday % 7]}曜 ${DateFormat('HH:mm').format(dt)}';
    return DateFormat('MM月dd日 HH:mm').format(dt);
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final wsService = ref.read(wsServiceProvider);
    if (!wsService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('连接中，请稍后重试')),
      );
      return;
    }

    _textController.clear();

    final currentUser = ref.read(currentUserProvider);
    // 乐观添加本地消息
    final tempMsg = GroupMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      groupId: widget.groupId,
      senderId: currentUser?.id,
      senderUsername: currentUser?.username ?? '我',
      type: 1,
      content: text,
      isRecalled: false,
      createdAt: DateTime.now(),
    );
    ref.read(groupChatProvider(widget.groupId).notifier).addMessage(tempMsg);
    _scrollToBottom();

    // 通过 WebSocket 发送
    wsService.sendMessage({
      'type': 'send_group_message',
      'group_id': widget.groupId,
      'msg_type': 1,
      'content': text,
    });

    // 标记已读
    _markRead();
  }

  @override
  Widget build(BuildContext context) {
    final msgsAsync = ref.watch(groupChatProvider(widget.groupId));
    final currentUser = ref.watch(currentUserProvider);
    final subtitle  = widget.memberCount != null ? '${widget.memberCount}人' : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: const BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.groupName, style: const TextStyle(fontSize: 16)),
            if (subtitle != null)
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: msgsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                child: Text('加载失败', style: TextStyle(color: AppColors.textSecondary)),
              ),
              data: (msgs) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                if (msgs.isEmpty) {
                  return const Center(
                    child: Text('暂无消息，快来聊聊吧',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final msg  = msgs[i];
                    final prev = i > 0 ? msgs[i - 1] : null;
                    final showTime = prev == null ||
                        msg.createdAt.difference(prev.createdAt).abs().inMinutes > 5;
                    final isMe = msg.senderId != null && msg.senderId == currentUser?.id;
                    return _GroupMsgItem(
                      msg: msg,
                      showTime: showTime,
                      isMe: isMe,
                      myUsername: currentUser?.username ?? '我',
                      avatarColor: _avatarColor(msg.senderId ?? 'sys'),
                      formatTime: _formatTime,
                    );
                  },
                );
              },
            ),
          ),

          // 输入栏
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: '发消息...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendText,
                    child: Container(
                      width: 40, height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 消息气泡 ──────────────────────────────────────────────────────────────────

class _GroupMsgItem extends StatelessWidget {
  const _GroupMsgItem({
    required this.msg,
    required this.showTime,
    required this.isMe,
    required this.myUsername,
    required this.avatarColor,
    required this.formatTime,
  });

  final GroupMessage msg;
  final bool showTime;
  final bool isMe;
  final String myUsername;
  final Color avatarColor;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 时间戳
        if (showTime)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                formatTime(msg.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ),

        // 系统消息
        if (msg.isSystemMsg)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                msg.content ?? '',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 对方头像
                if (!isMe) ...[
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: avatarColor,
                    child: Text(
                      msg.senderUsername.isNotEmpty ? msg.senderUsername[0] : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // 名字 + 气泡
                Flexible(
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 2),
                          child: Text(
                            msg.senderUsername,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ),
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.62,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary : const Color(0xFFF0F0F5),
                          borderRadius: BorderRadius.only(
                            topLeft:     Radius.circular(isMe ? 18 : 4),
                            topRight:    Radius.circular(isMe ? 4 : 18),
                            bottomLeft:  const Radius.circular(18),
                            bottomRight: const Radius.circular(18),
                          ),
                        ),
                        child: msg.isRecalled
                            ? Text(
                                isMe ? '你撤回了一条消息' : '${msg.senderUsername}撤回了一条消息',
                                style: TextStyle(
                                  color: isMe ? Colors.white70 : AppColors.textSecondary,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : Text(
                                msg.content ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.white : AppColors.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                if (isMe) const SizedBox(width: 8),

                // 自己头像
                if (isMe)
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      myUsername.isNotEmpty ? myUsername[0] : '我',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
