class BaseUser {
  final String username;
  final String password;
  final String name;
  final String? email;
  final String role;
  final List<String> branches;

  BaseUser({
    required this.username,
    required this.password,
    required this.name,
    this.email,
    required this.role,
    this.branches = const [],
  });
}

class CreateUser extends BaseUser {
  CreateUser({
    required super.username,
    required super.password,
    required super.name,
    super.email,
    required super.role,
    super.branches = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'name': name,
      'email': email,
      'role': role,
      'branches': branches,
    };
  }
}

class UpdateUser {
  final String? username;
  final String? password;
  final String? name;
  final String? email;
  final String? role;
  final List<String>? branches;

  UpdateUser({
    this.username,
    this.password,
    this.name,
    this.email,
    this.role,
    this.branches,
  });

  Map<String, dynamic> toJson() {
    return {
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (role != null) 'role': role,
      if (branches != null) 'branches': branches,
    };
  }
}

class UserInDb extends BaseUser {
  final String id;
  final int createdAt;
  final int? updatedAt;
  final bool isDeleted;

  UserInDb({
    required this.id,
    required super.username,
    required super.password,
    required super.name,
    super.email,
    required super.role,
    super.branches = const [],
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory UserInDb.fromJson(Map<String, dynamic> json) {
    return UserInDb(
      id: json['id'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      role: json['role'] as String,
      branches: (json['branches'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
