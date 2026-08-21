import 'package:serum_business/src/domain/models/shared/included_test.dart';
import 'package:serum_business/src/domain/models/shared/reference_value.dart';

class OrderTestResult extends IncludedTest {
  final String? resultValue;
  final String? alertFlag;

  OrderTestResult({
    required super.labTestId,
    required super.parameterName,
    super.medicalClassification = '',
    required super.dataType,
    super.unitOfMeasure = '',
    super.referenceValues = const [],
    super.qualitativeOptions = const [],
    super.expectedQualitativeValue,
    this.resultValue,
    this.alertFlag,
  });

  factory OrderTestResult.fromJson(Map<String, dynamic> json) {
    return OrderTestResult(
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
      resultValue: json['resultValue'] as String?,
      alertFlag: json['alertFlag'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'resultValue': resultValue,
      'alertFlag': alertFlag,
    };
  }
}
