class BaseUser {
  final String username;
  final String password;
  final String name;
  final String? email;
  final String? phone;
  final String role;
  final List<String> branches;
  final bool isActive;
  final bool isInternal;

  BaseUser({
    required this.username,
    this.password = '',
    required this.name,
    this.email,
    this.phone,
    required this.role,
    this.branches = const [],
    this.isActive = true,
    this.isInternal = false,
  });
}

class CreateUser extends BaseUser {
  CreateUser({
    required super.username,
    super.password = '',
    required super.name,
    super.email,
    super.phone,
    required super.role,
    super.branches = const [],
    super.isActive = true,
    super.isInternal = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'branches': branches,
      'isActive': isActive,
      'isInternal': isInternal,
    };
  }
}

class UpdateUser {
  final String? username;
  final String? password;
  final String? name;
  final String? email;
  final String? phone;
  final String? role;
  final List<String>? branches;
  final bool? isActive;
  final bool? isInternal;

  UpdateUser({
    this.username,
    this.password,
    this.name,
    this.email,
    this.phone,
    this.role,
    this.branches,
    this.isActive,
    this.isInternal,
  });

  Map<String, dynamic> toJson() {
    return {
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (role != null) 'role': role,
      if (branches != null) 'branches': branches,
      if (isActive != null) 'isActive': isActive,
      if (isInternal != null) 'isInternal': isInternal,
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
    super.password = '',
    required super.name,
    super.email,
    super.phone,
    required super.role,
    super.branches = const [],
    super.isActive = true,
    super.isInternal = false,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory UserInDb.fromJson(Map<String, dynamic> json) {
    return UserInDb(
      id: json['id'] as String,
      username: json['username'] as String,
      password: (json['password'] as String?) ?? '',
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      branches: (json['branches'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
      isInternal: json['isInternal'] as bool? ?? false,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}

