import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/tools/exports/pdf/templates/clinical_comparison_pdf_template.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClinicalComparisonPdfTemplate & Delta Calculation Tests', () {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final pastMs = nowMs - (30 * 86400000); // 30 días atrás

    final mockOrder1 = OrderInDb(
      id: 'ord-base-100',
      patientId: 'pat-001',
      doctorId: 'doc-001',
      branchId: 'br-001',
      items: [
        OrderItem(
          labTestId: 'lt-bh',
          name: 'Biometría Hemática Completa',
          salePriceApplied: 30000,
        ),
      ],
      status: 'completed',
      totalPrice: 30000,
      paidAmount: 30000,
      createdAt: pastMs,
      results: [
        OrderTestResult(
          labTestId: 'lt-hb',
          parameterName: 'Hemoglobina',
          medicalClassification: 'Serie Roja',
          dataType: 'numeric',
          unitOfMeasure: 'g/dL',
          resultValue: '12.0',
          referenceValues: [
            ReferenceValue(
              patientType: 'general',
              gender: 'any',
              minAgeDays: 0,
              maxAgeDays: 36500,
              minValue: 12.0,
              maxValue: 16.0,
            ),
          ],
        ),
        OrderTestResult(
          labTestId: 'lt-htc',
          parameterName: 'Hematocrito',
          medicalClassification: 'Serie Roja',
          dataType: 'numeric',
          unitOfMeasure: '%',
          resultValue: '36.0',
          referenceValues: [
            ReferenceValue(
              patientType: 'general',
              gender: 'any',
              minAgeDays: 0,
              maxAgeDays: 36500,
              minValue: 36.0,
              maxValue: 48.0,
            ),
          ],
        ),
        OrderTestResult(
          labTestId: 'lt-wbc',
          parameterName: 'Leucocitos',
          medicalClassification: 'Serie Blanca',
          dataType: 'numeric',
          unitOfMeasure: 'mm3',
          resultValue: '8000',
          referenceValues: [
            ReferenceValue(
              patientType: 'general',
              gender: 'any',
              minAgeDays: 0,
              maxAgeDays: 36500,
              minValue: 4500,
              maxValue: 10000,
            ),
          ],
        ),
        OrderTestResult(
          labTestId: 'lt-plt',
          parameterName: 'Plaquetas',
          medicalClassification: 'Serie Plaquetaria',
          dataType: 'numeric',
          unitOfMeasure: 'mm3',
          resultValue: '200000',
          referenceValues: [
            ReferenceValue(
              patientType: 'general',
              gender: 'any',
              minAgeDays: 0,
              maxAgeDays: 36500,
              minValue: 150000,
              maxValue: 450000,
            ),
          ],
        ),
      ],
      patientInfo: PatientInfo(
        name: 'Ana María Morales',
        dateOfBirth: nowMs - (28 * 365 * 86400000),
        gender: 'F',
        cardId: '001-120596-0002F',
      ),
      doctorInfo: DoctorInfo(
        name: 'Dr. Alejandro Silva',
        specialty: 'Medicina Interna',
      ),
    );

    final mockOrder2 = OrderInDb(
      id: 'ord-evol-200',
      patientId: 'pat-001',
      doctorId: 'doc-001',
      branchId: 'br-001',
      items: [
        OrderItem(
          labTestId: 'lt-bh',
          name: 'Biometría Hemática Completa',
          salePriceApplied: 30000,
        ),
      ],
      status: 'completed',
      totalPrice: 30000,
      paidAmount: 30000,
      createdAt: nowMs,
      results: [
        OrderTestResult(
          labTestId: 'lt-hb',
          parameterName: 'Hemoglobina',
          medicalClassification: 'Serie Roja',
          dataType: 'numeric',
          unitOfMeasure: 'g/dL',
          resultValue: '13.5',
          referenceValues: [
            ReferenceValue(
              patientType: 'general',
              gender: 'any',
              minAgeDays: 0,
              maxAgeDays: 36500,
              minValue: 12.0,
              maxValue: 16.0,
            ),
          ],
        ),
        OrderTestResult(
          labTestId: 'lt-htc',
          parameterName: 'Hematocrito',
          medicalClassification: 'Serie Roja',
          dataType: 'numeric',
          unitOfMeasure: '%',
          resultValue: '40.5',
          referenceValues: [
            ReferenceValue(
              patientType: 'general',
              gender: 'any',
              minAgeDays: 0,
              maxAgeDays: 36500,
              minValue: 36.0,
              maxValue: 48.0,
            ),
          ],
        ),
        OrderTestResult(
          labTestId: 'lt-wbc',
          parameterName: 'Leucocitos',
          medicalClassification: 'Serie Blanca',
          dataType: 'numeric',
          unitOfMeasure: 'mm3',
          resultValue: '6800',
          referenceValues: [
            ReferenceValue(
              patientType: 'general',
              gender: 'any',
              minAgeDays: 0,
              maxAgeDays: 36500,
              minValue: 4500,
              maxValue: 10000,
            ),
          ],
        ),
        OrderTestResult(
          labTestId: 'lt-plt',
          parameterName: 'Plaquetas',
          medicalClassification: 'Serie Plaquetaria',
          dataType: 'numeric',
          unitOfMeasure: 'mm3',
          resultValue: '220000',
          referenceValues: [
            ReferenceValue(
              patientType: 'general',
              gender: 'any',
              minAgeDays: 0,
              maxAgeDays: 36500,
              minValue: 150000,
              maxValue: 450000,
            ),
          ],
        ),
      ],
      patientInfo: PatientInfo(
        name: 'Ana María Morales',
        dateOfBirth: nowMs - (28 * 365 * 86400000),
        gender: 'F',
        cardId: '001-120596-0002F',
      ),
      doctorInfo: DoctorInfo(
        name: 'Dr. Alejandro Silva',
        specialty: 'Medicina Interna',
      ),
    );

    final mockBranch = BranchInDb(
      id: 'br-001',
      name: 'Laboratorio Serum Central',
      address: 'Pista Suburbana Km 3',
      phone: '2255-0000',
      createdAt: nowMs,
    );

    test('Empareja resultados correctamente y calcula deltas analíticos', () {
      final rows = ClinicalComparisonPdfTemplate.buildComparisonRows(
        mockOrder1,
        mockOrder2,
      );

      expect(rows.length, equals(4));

      final hbRow = rows.firstWhere((r) => r.key == 'HB');
      expect(hbRow.baseNumeric, equals(12.0));
      expect(hbRow.comparisonNumeric, equals(13.5));
      expect(hbRow.deltaAbsolute, closeTo(1.5, 0.001));
      // (1.5 / 12.0) * 100 = 12.5%
      expect(hbRow.deltaPercentage, closeTo(12.5, 0.001));

      final wbcRow = rows.firstWhere((r) => r.key == 'LEU');
      expect(wbcRow.baseNumeric, equals(8000));
      expect(wbcRow.comparisonNumeric, equals(6800));
      expect(wbcRow.deltaAbsolute, closeTo(-1200, 0.001));
      // (-1200 / 8000) * 100 = -15.0%
      expect(wbcRow.deltaPercentage, closeTo(-15.0, 0.001));
    });

    test('Ordena cronológicamente sin importar el orden de los argumentos', () {
      // Pasando primero la orden reciente y luego la anterior
      final template = ClinicalComparisonPdfTemplate(
        order1: mockOrder2,
        order2: mockOrder1,
        branch: mockBranch,
      );

      expect(template.baseOrder.id, equals('ord-base-100'));
      expect(template.comparisonOrder.id, equals('ord-evol-200'));
    });

    test('Construye documento PDF comparativo sin excepciones y genera páginas', () async {
      final template = ClinicalComparisonPdfTemplate(
        order1: mockOrder1,
        order2: mockOrder2,
        branch: mockBranch,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });
  });
}
