import 'package:serum_business/src/domain/models/shared/reference_value.dart';

class BaseLabTest {
  final String name;
  final String? code;
  final String commercialCategory;
  final int salePrice;
  final int salePrice2;
  final String currency;
  final bool isPack;
  final List<String> childTestIds;
  final String dataType;
  final String unitOfMeasure;
  final List<ReferenceValue> referenceValues;
  final List<String> qualitativeOptions;
  final String? expectedQualitativeValue;

  String get parameterName => name;
  String get medicalClassification => commercialCategory;

  BaseLabTest({
    required this.name,
    this.code,
    this.commercialCategory = '',
    this.salePrice = 0,
    this.salePrice2 = 0,
    this.currency = 'USD',
    this.isPack = false,
    this.childTestIds = const [],
    this.dataType = 'numeric',
    this.unitOfMeasure = '',
    this.referenceValues = const [],
    this.qualitativeOptions = const [],
    this.expectedQualitativeValue,
  });
}

class CreateLabTest extends BaseLabTest {
  CreateLabTest({
    required super.name,
    super.code,
    super.commercialCategory = '',
    super.salePrice = 0,
    super.salePrice2 = 0,
    super.currency = 'USD',
    super.isPack = false,
    super.childTestIds = const [],
    super.dataType = 'numeric',
    super.unitOfMeasure = '',
    super.referenceValues = const [],
    super.qualitativeOptions = const [],
    super.expectedQualitativeValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parameterName': name,
      'code': code,
      'commercialCategory': commercialCategory,
      'salePrice': salePrice,
      'salePrice2': salePrice2,
      'currency': currency,
      'isPack': isPack,
      'childTestIds': childTestIds,
      'dataType': dataType,
      'unitOfMeasure': unitOfMeasure,
      'referenceValues': referenceValues.map((e) => e.toJson()).toList(),
      'qualitativeOptions': qualitativeOptions,
      'expectedQualitativeValue': expectedQualitativeValue,
    };
  }
}

class UpdateLabTest {
  final String? name;
  final String? code;
  final String? commercialCategory;
  final int? salePrice;
  final int? salePrice2;
  final String? currency;
  final bool? isPack;
  final List<String>? childTestIds;
  final String? dataType;
  final String? unitOfMeasure;
  final List<ReferenceValue>? referenceValues;
  final List<String>? qualitativeOptions;
  final String? expectedQualitativeValue;

  UpdateLabTest({
    this.name,
    this.code,
    this.commercialCategory,
    this.salePrice,
    this.salePrice2,
    this.currency,
    this.isPack,
    this.childTestIds,
    this.dataType,
    this.unitOfMeasure,
    this.referenceValues,
    this.qualitativeOptions,
    this.expectedQualitativeValue,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (name != null) 'parameterName': name,
      if (code != null) 'code': code,
      if (commercialCategory != null) 'commercialCategory': commercialCategory,
      if (salePrice != null) 'salePrice': salePrice,
      if (salePrice2 != null) 'salePrice2': salePrice2,
      if (currency != null) 'currency': currency,
      if (isPack != null) 'isPack': isPack,
      if (childTestIds != null) 'childTestIds': childTestIds,
      if (dataType != null) 'dataType': dataType,
      if (unitOfMeasure != null) 'unitOfMeasure': unitOfMeasure,
      if (referenceValues != null)
        'referenceValues': referenceValues!.map((e) => e.toJson()).toList(),
      if (qualitativeOptions != null) 'qualitativeOptions': qualitativeOptions,
      if (expectedQualitativeValue != null)
        'expectedQualitativeValue': expectedQualitativeValue,
    };
  }
}

class LabTestInDb extends BaseLabTest {
  final String id;
  final int createdAt;
  final int? updatedAt;
  final bool isDeleted;

  LabTestInDb({
    required this.id,
    required super.name,
    super.code,
    super.commercialCategory = '',
    super.salePrice = 0,
    super.salePrice2 = 0,
    super.currency = 'USD',
    super.isPack = false,
    super.childTestIds = const [],
    super.dataType = 'numeric',
    super.unitOfMeasure = '',
    super.referenceValues = const [],
    super.qualitativeOptions = const [],
    super.expectedQualitativeValue,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory LabTestInDb.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] as String? ?? json['parameterName'] as String? ?? '';
    final rawCategory = json['commercialCategory'] as String? ?? json['medicalClassification'] as String? ?? '';
    return LabTestInDb(
      id: json['id'] as String,
      name: rawName,
      code: json['code'] as String?,
      commercialCategory: rawCategory,
      salePrice: (json['salePrice'] as num?)?.toInt() ?? 0,
      salePrice2: (json['salePrice2'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      isPack: json['isPack'] as bool? ?? false,
      childTestIds: (json['childTestIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      dataType: json['dataType'] as String? ?? 'numeric',
      unitOfMeasure: json['unitOfMeasure'] as String? ?? '',
      referenceValues: (json['referenceValues'] as List<dynamic>?)
              ?.map((e) => ReferenceValue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      qualitativeOptions: (json['qualitativeOptions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      expectedQualitativeValue: json['expectedQualitativeValue'] as String?,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
