class AppNotification {
  final int id;
  final String title;
  final String body;
  final bool isRead;
  final String? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String,
        body: json['body'] as String,
        isRead: json['isRead'] as bool? ?? false,
        createdAt: json['createdAt'] as String?,
      );
}

class UnreadCountResponse {
  final int count;

  const UnreadCountResponse({required this.count});

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) =>
      UnreadCountResponse(count: (json['count'] as num?)?.toInt() ?? 0);
}
