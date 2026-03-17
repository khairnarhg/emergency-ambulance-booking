import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../data/api/notification_api.dart';
import '../data/models/notification.dart';

final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  final api = ref.read(notificationApiProvider);
  return api.getNotifications();
});

final unreadCountProvider = StateNotifierProvider<UnreadCountNotifier, int>(
  (ref) => UnreadCountNotifier(ref.read(notificationApiProvider)),
);

class UnreadCountNotifier extends StateNotifier<int> {
  final NotificationApi _api;
  Timer? _timer;

  UnreadCountNotifier(this._api) : super(0) {
    _fetch();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(
      const Duration(seconds: AppConstants.notificationPollIntervalSeconds),
      (_) => _fetch(),
    );
  }

  Future<void> _fetch() async {
    try {
      final count = await _api.getUnreadCount();
      state = count;
    } catch (_) {
      // Silently fail for badge count
    }
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
    super.dispose();
  }
}
