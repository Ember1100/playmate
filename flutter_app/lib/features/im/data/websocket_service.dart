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

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String token) async {
    _lastToken = token;
    await _doConnect(token);
  }

  Future<void> _doConnect(String token) async {
    try {
      _channel?.sink.close();
      final uri = Uri.parse(
          'ws://8.138.190.48:8080/api/v1/im/ws?token=$token');
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      _channel!.stream.listen(
        (data) {
          if (data is String) {
            try {
              final decoded = jsonDecode(data) as Map<String, dynamic>;
              _messageController.add(decoded);
            } catch (_) {
              // Ignore parse errors
            }
          }
        },
        onError: (error) {
          _isConnected = false;
          // Attempt reconnect after delay
          Future.delayed(const Duration(seconds: 3), () {
            if (_lastToken != null && !_messageController.isClosed) {
              _doConnect(_lastToken!);
            }
          });
        },
        onDone: () {
          _isConnected = false;
          // Attempt reconnect after delay
          Future.delayed(const Duration(seconds: 3), () {
            if (_lastToken != null && !_messageController.isClosed) {
              _doConnect(_lastToken!);
            }
          });
        },
      );
    } catch (e) {
      _isConnected = false;
    }
  }

  void sendMessage(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void sendPing() => sendMessage({'type': 'ping'});

  void disconnect() {
    _isConnected = false;
    _lastToken = null;
    _channel?.sink.close();
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
