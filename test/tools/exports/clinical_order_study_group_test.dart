import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/tools/exports/pdf/templates/clinical_order_study_group.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  group('ClinicalOrderGrouper Tests', () {
    test('Agrupa orden con múltiples packs (Biometría, EGO, EGH) y prueba individual usando parentExamName', () {
      final order = OrderInDb(
        id: 'ord-multi-01',
        patientId: 'pat-1',
        branchId: 'br-1',
        createdAt: 1700000000000,
        items: [
          OrderItem(labTestId: 'BHC', name: 'Biometría Hemática Completa', salePriceApplied: 30000, isPack: true),
          OrderItem(labTestId: 'EGO', name: 'Examen General de Orina', salePriceApplied: 15000, isPack: true),
          OrderItem(labTestId: 'EGH', name: 'Examen General de Heces', salePriceApplied: 15000, isPack: true),
          OrderItem(labTestId: 'GLU', name: 'Glucosa', salePriceApplied: 5000, isPack: false),
        ],
        results: [
          // Parámetros de Biometría
          OrderTestResult(
            labTestId: 'HB',
            parameterName: 'Hemoglobina',
            subclassification: 'Serie Roja',
            dataType: 'numeric',
            parentExamName: 'Biometría Hemática Completa',
            resultValue: '14.5',
          ),
          OrderTestResult(
            labTestId: 'LEU',
            parameterName: 'Leucocitos',
            subclassification: 'Serie Blanca',
            dataType: 'numeric',
            parentExamName: 'Biometría Hemática Completa',
            resultValue: '7500',
          ),
          // Parámetros de EGO
          OrderTestResult(
            labTestId: 'COL-ORI',
            parameterName: 'Color',
            subclassification: 'Examen Físico-Químico',
            dataType: 'qualitative',
            parentExamName: 'Examen General de Orina',
            resultValue: 'Amarillo',
          ),
          OrderTestResult(
            labTestId: 'LEU-ORI',
            parameterName: 'Leucocitos (Orina)',
            subclassification: 'Sedimento Microscópico',
            dataType: 'text',
            parentExamName: 'Examen General de Orina',
            resultValue: '0 - 2 x campo',
          ),
          // Parámetros de EGH
          OrderTestResult(
            labTestId: 'COL-HEC',
            parameterName: 'Color (Heces)',
            subclassification: 'Examen Físico',
            dataType: 'qualitative',
            parentExamName: 'Examen General de Heces',
            resultValue: 'Café',
          ),
          OrderTestResult(
            labTestId: 'PAR-HEC',
            parameterName: 'Parásitos',
            subclassification: 'Examen Microscópico',
            dataType: 'text',
            parentExamName: 'Examen General de Heces',
            resultValue: 'No se observan',
          ),
          // Glucosa individual
          OrderTestResult(
            labTestId: 'GLU',
            parameterName: 'Glucosa en Ayunas',
            subclassification: '',
            dataType: 'numeric',
            parentExamName: 'Glucosa',
            resultValue: '90',
          ),
        ],
      );

      final studyGroups = ClinicalOrderGrouper.groupResultsByStudy(order);

      expect(studyGroups.length, 4);

      // 1. Biometría
      expect(studyGroups[0].studyTitle, 'BIOMETRÍA HEMÁTICA COMPLETA');
      expect(studyGroups[0].clinicalArea, 'HEMATOLOGÍA');
      expect(studyGroups[0].subclassificationGroups.containsKey('SERIE ROJA'), isTrue);
      expect(studyGroups[0].subclassificationGroups.containsKey('SERIE BLANCA'), isTrue);
      expect(studyGroups[0].subclassificationGroups['SERIE ROJA']!.length, 1);
      expect(studyGroups[0].subclassificationGroups['SERIE BLANCA']!.length, 1);

      // 2. EGO
      expect(studyGroups[1].studyTitle, 'EXAMEN GENERAL DE ORINA');
      expect(studyGroups[1].clinicalArea, 'UROANÁLISIS');
      expect(studyGroups[1].subclassificationGroups.containsKey('EXAMEN FÍSICO-QUÍMICO'), isTrue);
      expect(studyGroups[1].subclassificationGroups.containsKey('SEDIMENTO MICROSCÓPICO'), isTrue);

      // 3. EGH
      expect(studyGroups[2].studyTitle, 'EXAMEN GENERAL DE HECES');
      expect(studyGroups[2].clinicalArea, 'COPROLOGÍA');
      expect(studyGroups[2].subclassificationGroups.containsKey('EXAMEN FÍSICO'), isTrue);
      expect(studyGroups[2].subclassificationGroups.containsKey('EXAMEN MICROSCÓPICO'), isTrue);

      // 4. Glucosa
      expect(studyGroups[3].studyTitle, 'GLUCOSA');
      expect(studyGroups[3].clinicalArea, 'QUÍMICA CLÍNICA');
      expect(studyGroups[3].subclassificationGroups['']!.length, 1);

      // Área global es LABORATORIO CLÍNICO porque son disciplinas mixtas
      final overallArea = ClinicalOrderGrouper.determineOverallClinicalArea(studyGroups);
      expect(overallArea, 'LABORATORIO CLÍNICO');
    });

    test('Agrupa orden multi-estudio legada sin parentExamName mediante casación inteligente', () {
      final legacyOrder = OrderInDb(
        id: 'ord-legacy-01',
        patientId: 'pat-1',
        branchId: 'br-1',
        createdAt: 1700000000000,
        items: [
          OrderItem(labTestId: 'BHC', name: 'Biometría Hemática Completa', salePriceApplied: 30000, isPack: true),
          OrderItem(labTestId: 'EGO', name: 'Examen General de Orina', salePriceApplied: 15000, isPack: true),
        ],
        results: [
          OrderTestResult(
            labTestId: 'HB',
            parameterName: 'Hemoglobina',
            medicalClassification: 'Hematología',
            subclassification: 'Serie Roja',
            dataType: 'numeric',
            parentExamName: null, // Legacy
            resultValue: '13.8',
          ),
          OrderTestResult(
            labTestId: 'COL-ORI',
            parameterName: 'Color',
            medicalClassification: 'Uroanálisis',
            subclassification: 'Examen Físico-Químico',
            dataType: 'qualitative',
            parentExamName: null, // Legacy
            resultValue: 'Amarillo',
          ),
        ],
      );

      final studyGroups = ClinicalOrderGrouper.groupResultsByStudy(legacyOrder);

      expect(studyGroups.length, 2);
      expect(studyGroups[0].studyTitle, 'BIOMETRÍA HEMÁTICA COMPLETA');
      expect(studyGroups[0].subclassificationGroups['SERIE ROJA']!.first.parameterName, 'Hemoglobina');

      expect(studyGroups[1].studyTitle, 'EXAMEN GENERAL DE ORINA');
      expect(studyGroups[1].subclassificationGroups['EXAMEN FÍSICO-QUÍMICO']!.first.parameterName, 'Color');
    });

    test('Orden de un solo estudio asigna área homogénea en la cabecera', () {
      final singleOrder = OrderInDb(
        id: 'ord-single-01',
        patientId: 'pat-1',
        branchId: 'br-1',
        createdAt: 1700000000000,
        items: [
          OrderItem(labTestId: 'BHC', name: 'Biometría Hemática Completa', salePriceApplied: 30000, isPack: true),
        ],
        results: [
          OrderTestResult(
            labTestId: 'HB',
            parameterName: 'Hemoglobina',
            subclassification: 'Serie Roja',
            dataType: 'numeric',
            resultValue: '14.0',
          ),
        ],
      );

      final studyGroups = ClinicalOrderGrouper.groupResultsByStudy(singleOrder);
      expect(studyGroups.length, 1);
      final overallArea = ClinicalOrderGrouper.determineOverallClinicalArea(studyGroups);
      expect(overallArea, 'HEMATOLOGÍA');
    });
  });
}
