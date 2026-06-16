/// Modelo de usuario para la gestión de administración.
class User {
  final int id;
  final String username;
  final String email;
  final String role; // "USER" o "ADMIN"
  final String? passwordHash; // Solo presente al obtener el detalle

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.passwordHash,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? 0) is int
          ? (json['id'] ?? 0) as int
          : int.tryParse('${json['id']}') ?? 0,
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'USER').toString().toUpperCase(),
      passwordHash: json['password_hash']?.toString(),
    );
  }

  /// Body para crear/actualizar (no incluye id).
  Map<String, dynamic> toUpdateJson() => {
        'username': username,
        'email': email,
        'role': role,
      };

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? role,
    String? passwordHash,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }
}

