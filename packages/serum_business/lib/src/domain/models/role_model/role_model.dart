class BaseRole {
  final String name;
  final int accessLevel;
  final String? description;

  BaseRole({
    required this.name,
    this.accessLevel = 3,
    this.description,
  });
}

class CreateRole extends BaseRole {
  CreateRole({
    required super.name,
    super.accessLevel = 3,
    super.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'accessLevel': accessLevel,
      'description': description,
    };
  }
}

class UpdateRole {
  final String? name;
  final int? accessLevel;
  final String? description;

  UpdateRole({
    this.name,
    this.accessLevel,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (accessLevel != null) 'accessLevel': accessLevel,
      if (description != null) 'description': description,
    };
  }
}

class RoleInDb extends BaseRole {
  final String id;
  final int createdAt;
  final int? updatedAt;
  final bool isDeleted;

  RoleInDb({
    required this.id,
    required super.name,
    super.accessLevel = 3,
    super.description,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory RoleInDb.fromJson(Map<String, dynamic> json) {
    return RoleInDb(
      id: json['id'] as String,
      name: json['name'] as String,
      accessLevel: json['accessLevel'] as int? ?? 3,
      description: json['description'] as String?,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
