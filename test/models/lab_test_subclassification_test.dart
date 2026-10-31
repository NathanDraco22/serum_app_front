import 'package:flutter_test/flutter_test.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  group('LabTest Subclassification and Profile Parameter Tests', () {
    test('LabTestInDb parsea y serializa subclassification e isProfileParameter', () {
      final json = {
        'id': 'test-leuco-orina',
        'name': 'Leucocitos (Orina)',
        'code': 'LEU-U',
        'commercialCategory': 'Uroanálisis',
        'subclassification': 'Sedimento Microscópico',
        'isProfileParameter': true,
        'salePrice': 0,
        'dataType': 'qualitative',
        'qualitativeOptions': ['No se observó', 'Escasas', 'Moderadas', 'Abundantes'],
        'expectedQualitativeValue': 'No se observó',
        'createdAt': 1700000000000,
      };

      final labTest = LabTestInDb.fromJson(json);
      expect(labTest.subclassification, 'Sedimento Microscópico');
      expect(labTest.isProfileParameter, true);
      expect(labTest.name, 'Leucocitos (Orina)');

      final serialized = labTest.toJson();
      expect(serialized['subclassification'], 'Sedimento Microscópico');
      expect(serialized['isProfileParameter'], true);

      final copied = labTest.copyWith(
        subclassification: 'Examen Físico-Químico',
        isProfileParameter: false,
      );
      expect(copied.subclassification, 'Examen Físico-Químico');
      expect(copied.isProfileParameter, false);
      expect(copied.id, labTest.id);
    });

    test('CreateLabTest y UpdateLabTest soportan subclassification e isProfileParameter', () {
      final create = CreateLabTest(
        branchId: 'br-origin',
        name: 'Color (Orina)',
        commercialCategory: 'Uroanálisis',
        subclassification: 'Examen Físico-Químico',
        isProfileParameter: true,
      );
      final createJson = create.toJson();
      expect(createJson['subclassification'], 'Examen Físico-Químico');
      expect(createJson['isProfileParameter'], true);

      final update = UpdateLabTest(
        subclassification: 'Serie Roja',
        isProfileParameter: false,
      );
      final updateJson = update.toJson();
      expect(updateJson['subclassification'], 'Serie Roja');
      expect(updateJson['isProfileParameter'], false);
    });

    test('OrderTestResult e IncludedTest conservan y serializan subclassification', () {
      final result = OrderTestResult(
        labTestId: 'test-1',
        parameterName: 'Hemoglobina',
        medicalClassification: 'Hematología',
        subclassification: 'Serie Roja',
        dataType: 'numeric',
        unitOfMeasure: 'g/dL',
        resultValue: '14.5',
      );

      expect(result.subclassification, 'Serie Roja');
      final json = result.toJson();
      expect(json['subclassification'], 'Serie Roja');

      final parsed = OrderTestResult.fromJson(json);
      expect(parsed.subclassification, 'Serie Roja');
    });

    test('Fallback seguro para registros legacy sin subclassification o isProfileParameter', () {
      final legacyJson = {
        'id': 'legacy-test-1',
        'name': 'Glucosa',
        'createdAt': 1690000000000,
      };

      final parsed = LabTestInDb.fromJson(legacyJson);
      expect(parsed.subclassification, '');
      expect(parsed.isProfileParameter, false);
    });
  });
}
