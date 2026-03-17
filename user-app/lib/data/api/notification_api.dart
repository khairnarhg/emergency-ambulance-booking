import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../models/notification.dart';

final notificationApiProvider = Provider<NotificationApi>((ref) {
  return NotificationApi(ref.read(apiClientProvider));
});

class NotificationApi {
  final ApiClient _client;

  NotificationApi(this._client);

  Future<List<AppNotification>> getNotifications({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.dio.get(
      '/notifications',
      queryParameters: {'page': page, 'size': size},
    );
    final data = response.data;
    List<dynamic> list;
    if (data is Map && data.containsKey('data')) {
      final d = data['data'];
      if (d is List) {
        list = d;
      } else if (d is Map && d.containsKey('content')) {
        list = d['content'] as List<dynamic>;
      } else {
        list = [];
      }
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }
    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    try {
      final response =
          await _client.dio.get('/notifications/unread-count');
      final data = response.data;
      if (data is Map) {
        return (data['count'] as num?)?.toInt() ??
            (data['data'] as num?)?.toInt() ??
            0;
      }
      if (data is num) return data.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markRead(int id) async {
    await _client.dio.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _client.dio.patch('/notifications/read-all');
  }
}
