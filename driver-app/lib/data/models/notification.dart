class AppNotification {
  final int id;
  final String? title;
  final String? body;
  final bool read;
  final String? createdAt;

  const AppNotification({
    required this.id,
    this.title,
    this.body,
    required this.read,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      title: json['title'] as String?,
      body: json['body'] as String?,
      read: json['read'] as bool? ?? false,
      createdAt: json['createdAt'] as String?,
    );
  }
}
