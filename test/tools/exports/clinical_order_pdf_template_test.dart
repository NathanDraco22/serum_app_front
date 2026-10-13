import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/tools/exports/pdf/templates/clinical_order_pdf_template.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SingleClinicalOrderTemplate Tests', () {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final mockOrder = OrderInDb(
      id: 'ord-12345678',
      patientId: 'pat-1',
      doctorId: 'doc-1',
      branchId: 'br-1',
      items: [
        OrderItem(
          labTestId: 'lt-1',
          name: 'Perfil Lipídico Completo',
          salePriceApplied: 35000,
        ),
      ],
      status: 'completed',
      totalPrice: 35000,
      paidAmount: 35000,
      results: [
        OrderTestResult(
          labTestId: 'lt-1',
          parameterName: 'Colesterol Total',
          medicalClassification: 'Bioquímica',
          dataType: 'numeric',
          unitOfMeasure: 'mg/dL',
          referenceValues: [
            ReferenceValue(
              patientType: 'general',
              gender: 'any',
              minAgeDays: 0,
              maxAgeDays: 36500,
              minValue: 100,
              maxValue: 200,
            ),
          ],
          qualitativeOptions: [],
          resultValue: '185',
        ),
      ],
      createdAt: nowMs,
      patientInfo: PatientInfo(
        name: 'Carlos Mendoza',
        dateOfBirth: nowMs - (30 * 365 * 86400000),
        gender: 'M',
        phone: '555-0192',
        address: 'Av. Siempre Viva 123',
      ),
      doctorInfo: DoctorInfo(
        name: 'Dr. Roberto Gómez',
        specialty: 'Medicina Interna',
        phone: '555-9988',
      ),
    );

    test('Construye PDF correctamente cuando la sucursal no tiene imageUrl', () async {
      final branchWithoutImage = BranchInDb(
        id: 'br-1',
        name: 'Laboratorio Clínico Serum Matriz',
        address: 'Calle Principal 456',
        phone: 'PBX 2222-0000',
        imageUrl: null,
        createdAt: nowMs,
      );

      final template = SingleClinicalOrderTemplate(
        order: mockOrder,
        branch: branchWithoutImage,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('Construye PDF correctamente cuando la sucursal tiene imageUrl', () async {
      final branchWithImage = BranchInDb(
        id: 'br-1',
        name: 'Laboratorio Clínico Serum Matriz',
        address: 'Calle Principal 456',
        phone: 'PBX 2222-0000',
        imageUrl: 'https://example.com/logo_non_existent.jpg',
        createdAt: nowMs,
      );

      final template = SingleClinicalOrderTemplate(
        order: mockOrder,
        branch: branchWithImage,
      );

      // Si la URL no es accesible en test, se gestiona y no arroja excepción no capturada
      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('Construye PDF correctamente con valores nulos (fallbacks de guion) y caracteres especiales', () async {
      final branch = BranchInDb(
        id: 'br-1',
        name: 'Laboratorio Clínico Serum',
        address: 'Calle 10',
        phone: 'PBX 2222',
        createdAt: nowMs,
      );

      final orderWithNulls = OrderInDb(
        id: 'ord-nulls-unicode',
        patientId: mockOrder.patientId,
        doctorId: mockOrder.doctorId,
        branchId: mockOrder.branchId,
        items: mockOrder.items,
        status: mockOrder.status,
        totalPrice: mockOrder.totalPrice,
        paidAmount: mockOrder.paidAmount,
        createdAt: nowMs,
        patientInfo: mockOrder.patientInfo,
        doctorInfo: mockOrder.doctorInfo,
        results: [
          OrderTestResult(
            labTestId: 'lt-unicode',
            parameterName: 'Prueba Especial con Símbolos (≥, ≤, µ, °C, —)',
            medicalClassification: 'Inmunología',
            dataType: 'numeric',
            unitOfMeasure: '', // Dispara el fallback '-'
            referenceValues: [],
            qualitativeOptions: [],
            resultValue: null, // Dispara el fallback '-'
          ),
        ],
      );

      final template = SingleClinicalOrderTemplate(
        order: orderWithNulls,
        branch: branch,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });
  });
}
