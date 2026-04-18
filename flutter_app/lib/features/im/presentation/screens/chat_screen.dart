import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/widgets/pm_image.dart';
import '../../../../core/services/upload_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/im_model.dart';
import '../../data/websocket_service.dart';
import '../../providers/im_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUsername,
    this.otherAvatarUrl,
  });

  final String conversationId;
  final String otherUsername;
  final String? otherAvatarUrl;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  bool _uploadingImage = false;

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

    // 进入会话：乐观清零未读 + 通知服务端更新 last_read_at
    _markRead();

    _wsSub = wsService.messages.listen((data) {
      if (data['type'] == 'new_message') {
        final convId = data['conversation_id'] as String?;
        final msg = Message(
          id: data['message_id'] as String? ?? '',
          conversationId: convId ?? widget.conversationId,
          senderId: data['sender_id'] as String? ?? '',
          type: data['msg_type'] as int? ?? 1,
          content: data['content'] as String?,
          mediaUrl: data['media_url'] as String?,
          createdAt: (DateTime.tryParse(
                      data['created_at'] as String? ?? '')
                  ?.toLocal()) ??
              DateTime.now(),
          isRecalled: false,
        );

        if (convId == widget.conversationId) {
          // 当前会话：追加消息并滚到底部
          ref
              .read(chatNotifierProvider(widget.conversationId).notifier)
              .addMessage(msg);
          _scrollToBottom();
          // 立刻标记已读（自己正在看着）
          _markRead();
        }

        // 无论哪个会话，都刷新会话列表（更新最新消息预览 + 未读数）
        ref.read(conversationsProvider.notifier).refresh();
      }
    });
  }

  void _markRead() {
    ref.read(conversationsProvider.notifier).clearUnread(widget.conversationId);
    ref.read(wsServiceProvider).sendMessage({
      'type': 'mark_read',
      'conversation_id': widget.conversationId,
      'last_read_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // reverse:true 时 position 0 即底部（最新消息）
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendTextMessage() async {
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
    final tempMsg = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversationId,
      senderId: currentUser?.id ?? 'me',
      type: 1,
      content: text,
      createdAt: DateTime.now(),
      isRecalled: false,
    );
    ref
        .read(chatNotifierProvider(widget.conversationId).notifier)
        .addMessage(tempMsg);
    _scrollToBottom();

    wsService.sendMessage({
      'type': 'send_message',
      'conversation_id': widget.conversationId,
      'msg_type': 1,
      'content': text,
    });
  }

  Future<void> _sendImageMessage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    final wsService = ref.read(wsServiceProvider);
    if (!wsService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('连接中，请稍后重试')),
      );
      return;
    }

    setState(() => _uploadingImage = true);

    try {
      final url = await ref
          .read(uploadServiceProvider)
          .uploadPostImage(File(picked.path));

      if (!mounted) return;

      final currentUser = ref.read(currentUserProvider);
      final tempMsg = Message(
        id: 'temp_img_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: widget.conversationId,
        senderId: currentUser?.id ?? 'me',
        type: 2,
        mediaUrl: url,
        createdAt: DateTime.now(),
        isRecalled: false,
      );
      ref
          .read(chatNotifierProvider(widget.conversationId).notifier)
          .addMessage(tempMsg);
      _scrollToBottom();

      wsService.sendMessage({
        'type': 'send_message',
        'conversation_id': widget.conversationId,
        'msg_type': 2,
        'media_url': url,
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('图片发送失败，请重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(chatNotifierProvider(widget.conversationId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: const BackButton(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(
                widget.otherUsername.substring(0, 1).toUpperCase(),
                style:
                    const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.otherUsername,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.onlineGreen,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(
                child: Text('消息加载失败',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('暂无消息，开始聊天吧',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                // reverse:true → index 0 在底部，配合后端 DESC 返回
                // 不需要 _scrollToBottom，列表天然停在最新消息
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUser?.id ||
                        msg.senderId == 'me';
                    return _MessageBubble(
                      message: msg,
                      isMe: isMe,
                      otherAvatarUrl: widget.otherAvatarUrl,
                      otherUsername: widget.otherUsername,
                    );
                  },
                );
              },
            ),
          ),

          // 图片上传进度条
          if (_uploadingImage)
            const LinearProgressIndicator(
              backgroundColor: AppColors.border,
              color: AppColors.primary,
              minHeight: 2,
            ),

          // 输入栏
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // 图片按钮
                  IconButton(
                    icon: const Icon(Icons.image_outlined,
                        color: AppColors.textSecondary),
                    onPressed: _uploadingImage ? null : _sendImageMessage,
                  ),
                  // 文本输入框
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: '发消息...',
                        hintStyle: const TextStyle(
                            color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
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
                      onSubmitted: (_) => _sendTextMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 发送按钮
                  GestureDetector(
                    onTap: _sendTextMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.otherUsername,
    this.otherAvatarUrl,
  });

  final Message message;
  final bool isMe;
  final String otherUsername;
  final String? otherAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(message.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.secondary,
                  backgroundImage: otherAvatarUrl != null
                      ? PmImageProvider(otherAvatarUrl!)
                      : null,
                  child: otherAvatarUrl == null
                      ? Text(
                          otherUsername.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  padding: message.type == 2
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                  decoration: message.type == 2
                      ? null
                      : BoxDecoration(
                          color: isMe
                              ? AppColors.primary
                              : const Color(0xFFF0F0F5),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 18),
                          ),
                        ),
                  child: _buildContent(isMe),
                ),
              ),
              if (isMe) const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: EdgeInsets.only(left: isMe ? 0 : 40),
            child: Text(
              timeStr,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isMe) {
    if (message.isRecalled) {
      return Text(
        '消息已撤回',
        style: TextStyle(
          color: isMe ? Colors.white70 : AppColors.textSecondary,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // 图片消息
    if (message.type == 2 && message.mediaUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(isMe ? 12 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 12),
        ),
        child: PmImage(
          message.mediaUrl!,
          width: 180,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    }

    // 文本消息
    return Text(
      message.content ?? '',
      style: TextStyle(
        color: isMe ? Colors.white : AppColors.textPrimary,
        fontSize: 15,
      ),
    );
  }
}
