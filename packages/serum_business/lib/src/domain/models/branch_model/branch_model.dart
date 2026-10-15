class BaseBranch {
  final String name;
  final String address;
  final String phone;
  final String? email;
  final String? facebook;
  final String? logoUrl;
  final String? imageUrl;
  final String? isoLogoUrl;

  BaseBranch({
    required this.name,
    required this.address,
    required this.phone,
    this.email,
    this.facebook,
    this.logoUrl,
    this.imageUrl,
    this.isoLogoUrl,
  });

  /// Logotipo efectivo de la sucursal (símbolo o icono).
  /// Si `logoUrl` no está definido, realiza fallback al `imageUrl` previo.
  String? get effectiveLogo =>
      (logoUrl != null && logoUrl!.trim().isNotEmpty)
          ? logoUrl
          : ((imageUrl != null && imageUrl!.trim().isNotEmpty) ? imageUrl : null);

  /// IsoLogo efectivo de la sucursal (símbolo + nombre comercial integrado).
  /// Si `isoLogoUrl` no está definido, realiza fallback a `effectiveLogo`.
  String? get effectiveIsoLogo =>
      (isoLogoUrl != null && isoLogoUrl!.trim().isNotEmpty)
          ? isoLogoUrl
          : effectiveLogo;
}

class CreateBranch extends BaseBranch {
  CreateBranch({
    required super.name,
    required super.address,
    required super.phone,
    super.email,
    super.facebook,
    super.logoUrl,
    super.imageUrl,
    super.isoLogoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      if (email != null) 'email': email,
      if (facebook != null) 'facebook': facebook,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (isoLogoUrl != null) 'isoLogoUrl': isoLogoUrl,
    };
  }
}

class UpdateBranch {
  final String? name;
  final String? address;
  final String? phone;
  final String? email;
  final String? facebook;
  final String? logoUrl;
  final String? imageUrl;
  final String? isoLogoUrl;

  UpdateBranch({
    this.name,
    this.address,
    this.phone,
    this.email,
    this.facebook,
    this.logoUrl,
    this.imageUrl,
    this.isoLogoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (facebook != null) 'facebook': facebook,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (isoLogoUrl != null) 'isoLogoUrl': isoLogoUrl,
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
    super.email,
    super.facebook,
    super.logoUrl,
    super.imageUrl,
    super.isoLogoUrl,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory BranchInDb.fromJson(Map<String, dynamic> json) {
    final rawLogoUrl = json['logoUrl'] as String?;
    final rawImageUrl = json['imageUrl'] as String?;

    return BranchInDb(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      facebook: json['facebook'] as String?,
      logoUrl: rawLogoUrl ?? rawImageUrl,
      imageUrl: rawImageUrl ?? rawLogoUrl,
      isoLogoUrl: json['isoLogoUrl'] as String?,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}

