class BasePatient {
  final String name;
  final int dateOfBirth;
  final String gender;
  final String phone;
  final String address;
  final String? email;
  final String? cardId;
  final String originBranch;

  BasePatient({
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.phone,
    required this.address,
    this.email,
    this.cardId,
    required this.originBranch,
  });
}

class CreatePatient extends BasePatient {
  CreatePatient({
    required super.name,
    required super.dateOfBirth,
    required super.gender,
    required super.phone,
    required super.address,
    super.email,
    super.cardId,
    required super.originBranch,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'phone': phone,
      'address': address,
      'email': email,
      'cardId': cardId,
      'originBranch': originBranch,
    };
  }
}

class UpdatePatient {
  final String? name;
  final int? dateOfBirth;
  final String? gender;
  final String? phone;
  final String? address;
  final String? email;
  final String? cardId;
  final String? originBranch;

  UpdatePatient({
    this.name,
    this.dateOfBirth,
    this.gender,
    this.phone,
    this.address,
    this.email,
    this.cardId,
    this.originBranch,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (gender != null) 'gender': gender,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (email != null) 'email': email,
      if (cardId != null) 'cardId': cardId,
      if (originBranch != null) 'originBranch': originBranch,
    };
  }
}

class PatientInDb extends BasePatient {
  final String id;
  final int createdAt;
  final int? updatedAt;
  final bool isDeleted;

  PatientInDb({
    required this.id,
    required super.name,
    required super.dateOfBirth,
    required super.gender,
    required super.phone,
    required super.address,
    super.email,
    super.cardId,
    required super.originBranch,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory PatientInDb.fromJson(Map<String, dynamic> json) {
    return PatientInDb(
      id: json['id'] as String,
      name: json['name'] as String,
      dateOfBirth: json['dateOfBirth'] as int,
      gender: json['gender'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      email: json['email'] as String?,
      cardId: json['cardId'] as String?,
      originBranch: json['originBranch'] as String? ?? '',
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
