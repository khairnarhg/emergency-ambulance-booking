import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_handler.dart';
import '../core/constants/app_constants.dart';
import '../core/network/websocket_service.dart';
import '../data/api/notification_api.dart';
import '../data/models/notification.dart';
import 'auth_provider.dart';

final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  final api = ref.read(notificationApiProvider);
  return api.getNotifications();
});

final unreadCountProvider = StateNotifierProvider<UnreadCountNotifier, int>(
  (ref) {
    final userId = ref.watch(currentUserProvider)?.id;
    return UnreadCountNotifier(
      ref.read(notificationApiProvider),
      ref.read(websocketServiceProvider),
      userId,
    );
  },
);

class UnreadCountNotifier extends StateNotifier<int> {
  final NotificationApi _api;
  final WebSocketService _wsService;
  final int? _userId;
  Timer? _timer;
  StompUnsubscribe? _wsUnsub;

  static const int _wsFallbackPollSeconds = 60;

  UnreadCountNotifier(this._api, this._wsService, this._userId) : super(0) {
    _fetch();
    _startPolling();
    _subscribeWebSocket();
  }

  void _subscribeWebSocket() {
    if (_userId == null) return;
    _wsUnsub = _wsService.subscribe(
      '/topic/notifications/user/$_userId',
      _onNotification,
    );
  }

  void _onNotification(Map<String, dynamic> data) {
    if (!mounted) return;
    state = state + 1;
  }

  void _startPolling() {
    _timer = Timer.periodic(
      Duration(
        seconds: _wsService.isConnected
            ? _wsFallbackPollSeconds
            : AppConstants.notificationPollIntervalSeconds,
      ),
      (_) => _fetch(),
    );
  }

  Future<void> _fetch() async {
    try {
      final count = await _api.getUnreadCount();
      state = count;
    } catch (_) {}
  }

  void decrement() {
    if (state > 0) state--;
  }

  void reset() {
    state = 0;
  }

  Future<void> refresh() => _fetch();

  @override
  void dispose() {
    _timer?.cancel();
    _wsUnsub?.call(unsubscribeHeaders: {});
    super.dispose();
  }
}
