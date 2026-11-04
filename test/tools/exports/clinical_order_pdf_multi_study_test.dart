import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/tools/exports/pdf/templates/clinical_order_pdf_template.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async => '.',
    );
  });

  group('ClinicalOrderPdfTemplate Multi-Study Tests', () {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    test('Construye PDF con múltiples estudios (Biometría, EGO, EGH y Glucosa) separando cada estudio con sus subseries', () async {
      final multiOrder = OrderInDb(
        id: 'ord-multi-studies-pdf',
        patientId: 'pat-1',
        branchId: 'br-1',
        createdAt: nowMs,
        items: [
          OrderItem(labTestId: 'BHC', name: 'Biometría Hemática Completa', salePriceApplied: 30000, isPack: true),
          OrderItem(labTestId: 'EGO', name: 'Examen General de Orina', salePriceApplied: 15000, isPack: true),
          OrderItem(labTestId: 'EGH', name: 'Examen General de Heces', salePriceApplied: 15000, isPack: true),
          OrderItem(labTestId: 'GLU', name: 'Glucosa', salePriceApplied: 5000, isPack: false),
        ],
        results: [
          OrderTestResult(
            labTestId: 'HB',
            parameterName: 'Hemoglobina',
            subclassification: 'Serie Roja',
            dataType: 'numeric',
            parentExamName: 'Biometría Hemática Completa',
            resultValue: '14.0',
            unitOfMeasure: 'g/dL',
          ),
          OrderTestResult(
            labTestId: 'LEU',
            parameterName: 'Leucocitos',
            subclassification: 'Serie Blanca',
            dataType: 'numeric',
            parentExamName: 'Biometría Hemática Completa',
            resultValue: '7500',
            unitOfMeasure: 'x mm3',
          ),
          OrderTestResult(
            labTestId: 'COL-ORI',
            parameterName: 'Color',
            subclassification: 'Examen Físico-Químico',
            dataType: 'qualitative',
            parentExamName: 'Examen General de Orina',
            resultValue: 'Amarillo',
          ),
          OrderTestResult(
            labTestId: 'SED-ORI',
            parameterName: 'Sedimento',
            subclassification: 'Sedimento Microscópico',
            dataType: 'text',
            parentExamName: 'Examen General de Orina',
            resultValue: 'Escaso',
          ),
          OrderTestResult(
            labTestId: 'COL-HEC',
            parameterName: 'Color',
            subclassification: 'Examen Físico',
            dataType: 'qualitative',
            parentExamName: 'Examen General de Heces',
            resultValue: 'Pardo',
          ),
          OrderTestResult(
            labTestId: 'PAR-HEC',
            parameterName: 'Parásitos',
            subclassification: 'Examen Microscópico',
            dataType: 'text',
            parentExamName: 'Examen General de Heces',
            resultValue: 'No se observan',
          ),
          OrderTestResult(
            labTestId: 'GLU',
            parameterName: 'Glucosa en Ayunas',
            subclassification: '',
            dataType: 'numeric',
            parentExamName: 'Glucosa',
            resultValue: '92',
            unitOfMeasure: 'mg/dL',
          ),
        ],
        patientInfo: PatientInfo(
          name: 'María Alejandra Ramos',
          dateOfBirth: nowMs - (28 * 365 * 86400000),
          gender: 'F',
        ),
      );

      final branch = BranchInDb(
        id: 'br-1',
        name: 'Laboratorio Clínico Serum',
        address: 'Sede Central',
        phone: 'PBX 2222',
        createdAt: nowMs,
      );

      final template = SingleClinicalOrderTemplate(
        order: multiOrder,
        branch: branch,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('Construye PDF con Perfil Reumático y PCR con sub-parámetros de texto libre indentados', () async {
      final rheumOrder = OrderInDb(
        id: 'ord-rheum-pdf',
        patientId: 'pat-2',
        branchId: 'br-1',
        createdAt: nowMs,
        items: [
          OrderItem(labTestId: 'PERF-REUM', name: 'Perfil Reumático', salePriceApplied: 110000, isPack: true),
        ],
        results: [
          // Factor Reumatoide
          OrderTestResult(
            labTestId: 'FR-CUAL',
            parameterName: 'Factor Reumatoide',
            subclassification: 'Enfermedades Autoinmunes',
            dataType: 'qualitative',
            parentExamName: 'Perfil Reumático',
            resultValue: 'Positivo',
            expectedQualitativeValue: 'Negativo',
          ),
          OrderTestResult(
            labTestId: 'FR-TIT',
            parameterName: 'Título',
            subclassification: 'Enfermedades Autoinmunes',
            dataType: 'text',
            parentExamName: 'Perfil Reumático',
            resultValue: '1:80',
          ),
          OrderTestResult(
            labTestId: 'FR-CONC',
            parameterName: 'Concentración',
            subclassification: 'Enfermedades Autoinmunes',
            dataType: 'text',
            parentExamName: 'Perfil Reumático',
            unitOfMeasure: 'UI/mL',
            resultValue: '32.0',
            referenceText: '< 14.0 UI/mL (Negativo)',
          ),
          // Proteína C Reactiva
          OrderTestResult(
            labTestId: 'PCR-CUAL',
            parameterName: 'Proteína C Reactiva',
            subclassification: 'Enfermedades Autoinmunes',
            dataType: 'qualitative',
            parentExamName: 'Perfil Reumático',
            resultValue: 'Positivo',
            expectedQualitativeValue: 'Negativo',
          ),
          OrderTestResult(
            labTestId: 'PCR-TIT',
            parameterName: 'Título',
            subclassification: 'Enfermedades Autoinmunes',
            dataType: 'text',
            parentExamName: 'Perfil Reumático',
            resultValue: '1:40',
          ),
          OrderTestResult(
            labTestId: 'PCR-CONC',
            parameterName: 'Concentración',
            subclassification: 'Enfermedades Autoinmunes',
            dataType: 'text',
            parentExamName: 'Perfil Reumático',
            unitOfMeasure: 'mg/L',
            resultValue: '24',
            referenceText: '< 6.0 mg/L',
          ),
          // Antiestreptolisina O
          OrderTestResult(
            labTestId: 'ASLO-CUAL',
            parameterName: 'Antiestreptolisina O',
            subclassification: 'Enfermedades Autoinmunes',
            dataType: 'qualitative',
            parentExamName: 'Perfil Reumático',
            resultValue: 'Negativo',
            expectedQualitativeValue: 'Negativo',
          ),
          OrderTestResult(
            labTestId: 'ASLO-TIT',
            parameterName: 'Título',
            subclassification: 'Enfermedades Autoinmunes',
            dataType: 'text',
            parentExamName: 'Perfil Reumático',
            resultValue: '-',
          ),
          OrderTestResult(
            labTestId: 'ASLO-CONC',
            parameterName: 'Concentración',
            subclassification: 'Enfermedades Autoinmunes',
            dataType: 'text',
            parentExamName: 'Perfil Reumático',
            unitOfMeasure: 'UI/mL',
            resultValue: '< 200',
            referenceText: '< 200 UI/mL',
          ),
        ],
        patientInfo: PatientInfo(
          name: 'Carlos Mendoza',
          dateOfBirth: nowMs - (45 * 365 * 86400000),
          gender: 'M',
        ),
      );

      final branch = BranchInDb(
        id: 'br-1',
        name: 'Laboratorio Clínico Serum',
        address: 'Sede Central',
        phone: 'PBX 2222',
        createdAt: nowMs,
      );

      final template = SingleClinicalOrderTemplate(
        order: rheumOrder,
        branch: branch,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });
  });
}
