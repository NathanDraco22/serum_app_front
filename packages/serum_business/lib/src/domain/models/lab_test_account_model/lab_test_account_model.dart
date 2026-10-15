import 'commercial_model.dart';
export 'commercial_model.dart';

class BaseLabTestAccount {
  final String branchId;
  final String labTestId;
  final LabTestCommercial commercial;

  BaseLabTestAccount({
    required this.branchId,
    required this.labTestId,
    required this.commercial,
  });
}

class CreateLabTestAccount extends BaseLabTestAccount {
  CreateLabTestAccount({
    required super.branchId,
    required super.labTestId,
    required super.commercial,
  });

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'labTestId': labTestId,
      'commercial': commercial.toJson(),
    };
  }
}

class UpdateLabTestCommercial {
  final int? salePrice;
  final int? salePrice2;
  final int? costPrice;
  final String? currency;

  UpdateLabTestCommercial({
    this.salePrice,
    this.salePrice2,
    this.costPrice,
    this.currency,
  });

  Map<String, dynamic> toJson() {
    return {
      if (salePrice != null) 'salePrice': salePrice,
      if (salePrice2 != null) 'salePrice2': salePrice2,
      if (costPrice != null) 'costPrice': costPrice,
      if (currency != null) 'currency': currency,
    };
  }
}

class LabTestAccountInDb extends BaseLabTestAccount {
  final String id;
  final int createdAt;
  final int? updatedAt;
  final bool isDeleted;

  LabTestAccountInDb({
    required this.id,
    required super.branchId,
    required super.labTestId,
    required super.commercial,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory LabTestAccountInDb.fromJson(Map<String, dynamic> json) {
    return LabTestAccountInDb(
      id: json['id'] as String,
      branchId: json['branchId'] as String,
      labTestId: json['labTestId'] as String,
      commercial: json['commercial'] != null
          ? LabTestCommercial.fromJson(
              json['commercial'] as Map<String, dynamic>)
          : LabTestCommercial(),
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
