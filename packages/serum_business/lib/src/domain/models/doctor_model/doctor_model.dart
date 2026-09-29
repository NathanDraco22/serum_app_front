class BaseDoctor {
  final String name;
  final String specialty;
  final String phone;
  final String? email;
  final String? cardId;
  final String originBranch;

  BaseDoctor({
    required this.name,
    required this.specialty,
    required this.phone,
    this.email,
    this.cardId,
    required this.originBranch,
  });
}

class CreateDoctor extends BaseDoctor {
  CreateDoctor({
    required super.name,
    required super.specialty,
    required super.phone,
    super.email,
    super.cardId,
    required super.originBranch,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'specialty': specialty,
      'phone': phone,
      'email': email,
      'cardId': cardId,
      'originBranch': originBranch,
    };
  }
}

class UpdateDoctor {
  final String? name;
  final String? specialty;
  final String? phone;
  final String? email;
  final String? cardId;
  final String? originBranch;

  UpdateDoctor({
    this.name,
    this.specialty,
    this.phone,
    this.email,
    this.cardId,
    this.originBranch,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (specialty != null) 'specialty': specialty,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (cardId != null) 'cardId': cardId,
      if (originBranch != null) 'originBranch': originBranch,
    };
  }
}

class DoctorInDb extends BaseDoctor {
  final String id;
  final int createdAt;
  final int? updatedAt;
  final bool isDeleted;

  DoctorInDb({
    required this.id,
    required super.name,
    required super.specialty,
    required super.phone,
    super.email,
    super.cardId,
    required super.originBranch,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory DoctorInDb.fromJson(Map<String, dynamic> json) {
    return DoctorInDb(
      id: json['id'] as String,
      name: json['name'] as String,
      specialty: json['specialty'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      cardId: json['cardId'] as String?,
      originBranch: json['originBranch'] as String? ?? '',
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
