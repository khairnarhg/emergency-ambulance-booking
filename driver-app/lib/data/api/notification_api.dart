import 'package:driver_app/core/network/api_client.dart';
import 'package:driver_app/data/models/notification.dart';

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
    if (data is Map<String, dynamic> && data.containsKey('content')) {
      list = data['content'] as List<dynamic>;
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
    final response = await _client.dio.get('/notifications/unread-count');
    final data = response.data;
    if (data is int) return data;
    if (data is Map<String, dynamic>) {
      return data['count'] as int? ?? 0;
    }
    return 0;
  }

  Future<void> markAsRead(int id) async {
    await _client.dio.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _client.dio.post('/notifications/read-all');
  }
}
