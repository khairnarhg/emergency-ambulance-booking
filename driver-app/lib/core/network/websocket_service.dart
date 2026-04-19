import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:stomp_dart_client/stomp_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';

final websocketServiceProvider =
    Provider<WebSocketService>((ref) => WebSocketService());

typedef StompCallback = void Function(Map<String, dynamic> data);

class WebSocketService {
  StompClient? _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final List<_PendingSub> _pending = [];
  bool _connected = false;

  bool get isConnected => _connected;

  Future<void> connect() async {
    if (_client != null && _connected) return;

    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token == null) return;

    _client = StompClient(
      config: StompConfig.sockJS(
        url: AppConstants.wsBaseUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: _onConnect,
        onDisconnect: (_) => _connected = false,
        onWebSocketError: (_) => _connected = false,
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    _connected = true;
    for (final sub in _pending) {
      _subscribe(sub.topic, sub.callback);
    }
    _pending.clear();
  }

  StompUnsubscribe? subscribe(String topic, StompCallback callback) {
    if (_connected && _client != null) {
      return _subscribe(topic, callback);
    }
    _pending.add(_PendingSub(topic, callback));
    return null;
  }

  StompUnsubscribe? _subscribe(String topic, StompCallback callback) {
    return _client?.subscribe(
      destination: topic,
      callback: (frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!) as Map<String, dynamic>;
            callback(data);
          } catch (_) {}
        }
      },
    );
  }

  void disconnect() {
    _pending.clear();
    _client?.deactivate();
    _client = null;
    _connected = false;
  }
}

class _PendingSub {
  final String topic;
  final StompCallback callback;
  _PendingSub(this.topic, this.callback);
}
