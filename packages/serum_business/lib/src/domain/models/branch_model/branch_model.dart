class BaseBranch {
  final String name;
  final String address;
  final String phone;

  BaseBranch({
    required this.name,
    required this.address,
    required this.phone,
  });
}

class CreateBranch extends BaseBranch {
  CreateBranch({
    required super.name,
    required super.address,
    required super.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
    };
  }
}

class UpdateBranch {
  final String? name;
  final String? address;
  final String? phone;

  UpdateBranch({this.name, this.address, this.phone});

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
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
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
