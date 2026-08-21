import 'reference_value.dart';

class IncludedTest {
  final String labTestId;
  final String parameterName;
  final String medicalClassification;
  final String dataType;
  final String unitOfMeasure;
  final List<ReferenceValue> referenceValues;
  final List<String> qualitativeOptions;
  final String? expectedQualitativeValue;

  IncludedTest({
    required this.labTestId,
    required this.parameterName,
    this.medicalClassification = '',
    required this.dataType,
    this.unitOfMeasure = '',
    this.referenceValues = const [],
    this.qualitativeOptions = const [],
    this.expectedQualitativeValue,
  });

  factory IncludedTest.fromJson(Map<String, dynamic> json) {
    return IncludedTest(
      labTestId: json['labTestId'] as String? ?? '',
      parameterName: json['parameterName'] as String? ?? json['testName'] as String? ?? '',
      medicalClassification: json['medicalClassification'] as String? ?? '',
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
      'qualitativeOptions': qualitativeOptions,
      'expectedQualitativeValue': expectedQualitativeValue,
    };
  }
}
