import 'package:serum_business/serum_business.dart';


class OrderTestResult extends IncludedTest {
  final String? resultValue;
  final String? alertFlag;

  OrderTestResult({required super.labTestId, required super.parameterName, required super.medicalClassification, required super.dataType, required super.unitOfMeasure, required super.referenceValues, this.resultValue, this.alertFlag});

  factory OrderTestResult.fromJson(Map<String, dynamic> json) {
    return OrderTestResult(
      labTestId: json['labTestId'] as String,
      parameterName: json['parameterName'] as String,
      medicalClassification: json['medicalClassification'] as String,
      dataType: json['dataType'] as String,
      unitOfMeasure: json['unitOfMeasure'] as String,
      referenceValues: (json['referenceValues'] as List<dynamic>).map((e) => ReferenceValue.fromJson(e as Map<String, dynamic>)).toList(),
      resultValue: json['resultValue'] as String?,
      alertFlag: json['alertFlag'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {...super.toJson(), 'resultValue': resultValue, 'alertFlag': alertFlag};
  }
}
