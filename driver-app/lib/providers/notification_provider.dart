import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_handler.dart';
import 'package:driver_app/core/network/websocket_service.dart';
import 'package:driver_app/providers/auth_provider.dart';
import 'package:driver_app/data/api/notification_api.dart';
import 'package:driver_app/data/models/notification.dart';

final notificationApiProvider = Provider<NotificationApi>((ref) {
  return NotificationApi(ref.read(apiClientProvider));
});

class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationApi _api;
  final WebSocketService _wsService;
  StompUnsubscribe? _notifUnsub;

  NotificationNotifier(this._api, this._wsService)
      : super(const NotificationState());

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final notifications = await _api.getNotifications();
      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final count = await _api.getUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (_) {}
  }

  Future<void> markAsRead(int id) async {
    try {
      await _api.markAsRead(id);
      state = state.copyWith(
        notifications: state.notifications.map((n) {
          if (n.id == id) {
            return AppNotification(
              id: n.id,
              title: n.title,
              body: n.body,
              read: true,
              createdAt: n.createdAt,
            );
          }
          return n;
        }).toList(),
        unreadCount: (state.unreadCount - 1).clamp(0, 999),
      );
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _api.markAllRead();
      state = state.copyWith(
        notifications: state.notifications
            .map((n) => AppNotification(
                  id: n.id,
                  title: n.title,
                  body: n.body,
                  read: true,
                  createdAt: n.createdAt,
                ))
            .toList(),
        unreadCount: 0,
      );
    } catch (_) {}
  }

  void subscribeToNotifications(int driverId) {
    _notifUnsub?.call();
    _notifUnsub = _wsService.subscribe(
      '/topic/notifications/driver/$driverId',
      (data) {
        final notification = AppNotification.fromJson(data);
        state = state.copyWith(
          notifications: [notification, ...state.notifications],
          unreadCount: state.unreadCount + 1,
        );
      },
    );
  }

  void unsubscribeFromNotifications() {
    _notifUnsub?.call();
    _notifUnsub = null;
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(
    ref.read(notificationApiProvider),
    ref.read(websocketServiceProvider),
  );
});
