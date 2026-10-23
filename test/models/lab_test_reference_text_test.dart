import 'package:flutter_test/flutter_test.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  group('LabTest & OrderTestResult referenceText Tests', () {
    const scaleText = '- Menor de 5.6%: Nivel no diabético\n'
        '- 5.7 - 6.4%: Nivel prediabético\n'
        '- Mayor de 6.5%: Diagnosticado diabético\n'
        '- NOTA: 4.5 - 8.4%: Metabolismo normal O Diabético Controlado\n'
        '- (Mayor de 8.5%: Diabético mal controlado o Metabolismo desequilibrado)';

    test('LabTestInDb parsea y serializa referenceText correctamente', () {
      final json = {
        'id': 'test-hba1c',
        'name': 'Glicohemoglobina A1c (HbA1c)',
        'code': 'HBA1C',
        'commercialCategory': 'Química Sanguínea',
        'salePrice': 2500,
        'salePrice2': 2000,
        'dataType': 'numeric',
        'unitOfMeasure': '%',
        'referenceText': scaleText,
        'createdAt': 1700000000000,
      };

      final labTest = LabTestInDb.fromJson(json);
      expect(labTest.referenceText, scaleText);
      expect(labTest.name, 'Glicohemoglobina A1c (HbA1c)');
      expect(labTest.code, 'HBA1C');

      final serialized = labTest.toJson();
      expect(serialized['referenceText'], scaleText);

      final copied = labTest.copyWith(referenceText: 'Nuevo texto');
      expect(copied.referenceText, 'Nuevo texto');
      expect(copied.id, labTest.id);
    });

    test('CreateLabTest y UpdateLabTest incluyen referenceText', () {
      final create = CreateLabTest(
        branchId: 'br-1',
        name: 'Glicohemoglobina A1c (HbA1c)',
        referenceText: scaleText,
      );
      expect(create.toJson()['referenceText'], scaleText);

      final update = UpdateLabTest(
        referenceText: scaleText,
      );
      expect(update.toJson()['referenceText'], scaleText);
    });

    test('IncludedTest y OrderTestResult conservan y serializan referenceText', () {
      final orderResult = OrderTestResult(
        labTestId: 'test-hba1c',
        parameterName: 'Glicohemoglobina A1c HbA1c',
        dataType: 'numeric',
        unitOfMeasure: '%',
        referenceText: scaleText,
        resultValue: '6.0',
      );

      expect(orderResult.referenceText, scaleText);

      final json = orderResult.toJson();
      expect(json['referenceText'], scaleText);

      final parsed = OrderTestResult.fromJson(json);
      expect(parsed.referenceText, scaleText);
      expect(parsed.resultValue, '6.0');
    });

    test('Fallback a cadena vacía cuando referenceText no viene en el JSON', () {
      final jsonWithoutRefText = {
        'id': 'test-glu',
        'name': 'Glucosa',
        'createdAt': 1700000000000,
      };

      final labTest = LabTestInDb.fromJson(jsonWithoutRefText);
      expect(labTest.referenceText, '');

      final result = OrderTestResult.fromJson({
        'labTestId': 'lt-1',
        'parameterName': 'Glucosa',
        'dataType': 'numeric',
      });
      expect(result.referenceText, '');
    });
  });
}
