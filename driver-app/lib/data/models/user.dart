class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final List<String> roles;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    List<String> parsedRoles;
    if (rolesRaw is List) {
      parsedRoles = rolesRaw.map((r) {
        if (r is Map<String, dynamic>) {
          return (r['name'] as String?) ?? r.toString();
        }
        return r.toString();
      }).toList();
    } else {
      parsedRoles = [];
    }

    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      roles: parsedRoles,
    );
  }

  bool get isDriver =>
      roles.any((r) => r.contains('DRIVER'));
}
