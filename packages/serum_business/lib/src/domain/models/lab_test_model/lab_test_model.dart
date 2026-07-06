import 'package:serum_business/src/domain/models/shared/reference_value.dart';

class BaseLabTest {
  final String parameterName;
  final String medicalClassification;
  final String dataType;
  final String unitOfMeasure;
  final List<ReferenceValue> referenceValues;

  BaseLabTest({
    required this.parameterName,
    required this.medicalClassification,
    required this.dataType,
    required this.unitOfMeasure,
    this.referenceValues = const [],
  });
}

class CreateLabTest extends BaseLabTest {
  CreateLabTest({
    required super.parameterName,
    required super.medicalClassification,
    required super.dataType,
    required super.unitOfMeasure,
    super.referenceValues = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'parameterName': parameterName,
      'medicalClassification': medicalClassification,
      'dataType': dataType,
      'unitOfMeasure': unitOfMeasure,
      'referenceValues': referenceValues.map((e) => e.toJson()).toList(),
    };
  }
}

class UpdateLabTest {
  final String? parameterName;
  final String? medicalClassification;
  final String? dataType;
  final String? unitOfMeasure;
  final List<ReferenceValue>? referenceValues;

  UpdateLabTest({
    this.parameterName,
    this.medicalClassification,
    this.dataType,
    this.unitOfMeasure,
    this.referenceValues,
  });

  Map<String, dynamic> toJson() {
    return {
      if (parameterName != null) 'parameterName': parameterName,
      if (medicalClassification != null) 'medicalClassification': medicalClassification,
      if (dataType != null) 'dataType': dataType,
      if (unitOfMeasure != null) 'unitOfMeasure': unitOfMeasure,
      if (referenceValues != null)
        'referenceValues': referenceValues!.map((e) => e.toJson()).toList(),
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
    required super.parameterName,
    required super.medicalClassification,
    required super.dataType,
    required super.unitOfMeasure,
    super.referenceValues = const [],
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory LabTestInDb.fromJson(Map<String, dynamic> json) {
    return LabTestInDb(
      id: json['id'] as String,
      parameterName: json['parameterName'] as String,
      medicalClassification: json['medicalClassification'] as String,
      dataType: json['dataType'] as String,
      unitOfMeasure: json['unitOfMeasure'] as String,
      referenceValues: (json['referenceValues'] as List<dynamic>?)
              ?.map((e) => ReferenceValue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
