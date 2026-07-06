import 'reference_value.dart';

class IncludedTest {
  final String labTestId;
  final String parameterName;
  final String medicalClassification;
  final String dataType;
  final String unitOfMeasure;
  final List<ReferenceValue> referenceValues;

  IncludedTest({
    required this.labTestId,
    required this.parameterName,
    required this.medicalClassification,
    required this.dataType,
    required this.unitOfMeasure,
    required this.referenceValues,
  });

  factory IncludedTest.fromJson(Map<String, dynamic> json) {
    return IncludedTest(
      labTestId: json['labTestId'] as String,
      parameterName: json['parameterName'] as String,
      medicalClassification: json['medicalClassification'] as String,
      dataType: json['dataType'] as String,
      unitOfMeasure: json['unitOfMeasure'] as String,
      referenceValues: (json['referenceValues'] as List<dynamic>)
          .map((e) => ReferenceValue.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'labTestId': labTestId,
      'parameterName': parameterName,
      'medicalClassification': medicalClassification,
      'dataType': dataType,
      'unitOfMeasure': unitOfMeasure,
      'referenceValues': referenceValues.map((e) => e.toJson()).toList(),
    };
  }
}
