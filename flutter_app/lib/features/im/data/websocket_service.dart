import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  bool _isConnected = false;
  String? _lastToken;

  // 每次新建连接递增；onDone/onError 持有旧 gen 值，
  // 若 gen 已过期则不触发重连，避免 reconnect 循环。
  int _gen = 0;

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String token) async {
    // 已用相同 token 连接则不重建
    if (_isConnected && _lastToken == token) return;
    _lastToken = token;
    _doConnect(token);
  }

  void _doConnect(String token) {
    // 递增 generation，使旧 onDone/onError 失效
    final gen = ++_gen;

    try {
      _channel?.sink.close();
    } catch (_) {}

    try {
      final uri = Uri.parse(
          'ws://8.138.190.48:8080/api/v1/im/ws?token=$token');
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      _channel!.stream.listen(
        (data) {
          if (_gen != gen) return; // 过期连接，忽略
          if (data is String) {
            try {
              final decoded = jsonDecode(data) as Map<String, dynamic>;
              _messageController.add(decoded);
            } catch (_) {}
          }
        },
        onError: (error) {
          if (_gen != gen) return;
          _isConnected = false;
          _scheduleReconnect(token, gen);
        },
        onDone: () {
          if (_gen != gen) return; // 我们自己关的，不重连
          _isConnected = false;
          _scheduleReconnect(token, gen);
        },
        cancelOnError: false,
      );
    } catch (e) {
      _isConnected = false;
      _scheduleReconnect(token, gen);
    }
  }

  void _scheduleReconnect(String token, int gen) {
    Future.delayed(const Duration(seconds: 3), () {
      if (_gen == gen && _lastToken != null && !_messageController.isClosed) {
        _doConnect(token);
      }
    });
  }

  void sendMessage(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(data));
      } catch (_) {}
    }
  }

  void sendPing() => sendMessage({'type': 'ping'});

  void disconnect() {
    _lastToken = null;
    _gen++; // 使所有 pending reconnect 失效
    _isConnected = false;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}

final wsServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});
