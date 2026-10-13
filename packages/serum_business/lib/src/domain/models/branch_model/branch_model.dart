class BaseBranch {
  final String name;
  final String address;
  final String phone;
  final String? imageUrl;

  BaseBranch({
    required this.name,
    required this.address,
    required this.phone,
    this.imageUrl,
  });
}

class CreateBranch extends BaseBranch {
  CreateBranch({
    required super.name,
    required super.address,
    required super.phone,
    super.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

class UpdateBranch {
  final String? name;
  final String? address;
  final String? phone;
  final String? imageUrl;

  UpdateBranch({
    this.name,
    this.address,
    this.phone,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

class BranchInDb extends BaseBranch {
  final String id;
  final int createdAt;
  final int? updatedAt;
  final bool isDeleted;

  BranchInDb({
    required this.id,
    required super.name,
    required super.address,
    required super.phone,
    super.imageUrl,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory BranchInDb.fromJson(Map<String, dynamic> json) {
    return BranchInDb(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}

