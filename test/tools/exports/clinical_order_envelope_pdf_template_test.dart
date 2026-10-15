import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:serum_app_front/src/tools/exports/pdf/templates/clinical_order_envelope_pdf_template.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClinicalOrderEnvelopePdfTemplate Tests', () {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final mockOrderWithDoctor = OrderInDb(
      id: 'ord-87654321',
      patientId: 'pat-1',
      doctorId: 'doc-1',
      branchId: 'br-1',
      items: [
        OrderItem(
          labTestId: 'lt-1',
          name: 'Biometría Hemática Completa',
          salePriceApplied: 25000,
        ),
      ],
      status: 'completed',
      totalPrice: 25000,
      paidAmount: 25000,
      results: [],
      createdAt: nowMs,
      patientInfo: PatientInfo(
        name: 'Adela Duarte',
        dateOfBirth: nowMs - (30 * 365 * 86400000),
        gender: 'F',
        phone: '555-4321',
      ),
      doctorInfo: DoctorInfo(
        name: 'Kirla Arauz',
        specialty: 'Medicina General',
      ),
    );

    final mockOrderWithoutDoctor = OrderInDb(
      id: 'ord-87654322',
      patientId: 'pat-2',
      doctorId: null,
      branchId: 'br-1',
      items: [],
      status: 'completed',
      totalPrice: 0,
      paidAmount: 0,
      results: [],
      createdAt: nowMs,
      patientInfo: PatientInfo(
        name: 'Carlos Ruiz',
        dateOfBirth: nowMs - (25 * 365 * 86400000),
        gender: 'M',
        phone: '555-9876',
      ),
      doctorInfo: null,
    );

    final branch = BranchInDb(
      id: 'br-1',
      name: 'Biomedic',
      address: 'Consultorio Médico De Especialidades Divino Niño, de Unión FENOSA 1 C y 75 vrs al Norte, Matagalpa, Nicaragua.',
      phone: '8783-4873',
      imageUrl: null,
      createdAt: nowMs,
    );

    test('Construye sobre PDF en formato vertical (10.5 cm x 24.0 cm) con rotación a 90°', () async {
      final template = ClinicalOrderEnvelopePdfTemplate(
        order: mockOrderWithDoctor,
        branch: branch,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.length, equals(1));
      expect(bytes.isNotEmpty, isTrue);

      final page = doc.document.pdfPageList.pages.first;
      // Ancho físico: 10.5 cm (~297.6 pt), Alto físico: 24.0 cm (~680.3 pt)
      expect(page.pageFormat.width, closeTo(10.5 * PdfPageFormat.cm, 0.1));
      expect(page.pageFormat.height, closeTo(24.0 * PdfPageFormat.cm, 0.1));
    });

    test('Construye sobre PDF sin médico (omite CON ATENCION A) y con opción rotate180', () async {
      final template = ClinicalOrderEnvelopePdfTemplate(
        order: mockOrderWithoutDoctor,
        branch: branch,
        rotate180: true,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.length, equals(1));
      expect(bytes.isNotEmpty, isTrue);
    });

    test('Construye sobre PDF con sucursal que incluye email, facebook e isoLogoUrl', () async {
      final fullBranch = BranchInDb(
        id: 'br-full',
        name: 'Laboratorio Central',
        address: 'Calle Real 100',
        phone: '2222-3333',
        email: 'central@laboratorio.com',
        facebook: 'facebook.com/labcentral',
        isoLogoUrl: null, // Sin red remota real en test pero probando el modelo
        createdAt: nowMs,
      );

      final template = ClinicalOrderEnvelopePdfTemplate(
        order: mockOrderWithDoctor,
        branch: fullBranch,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.length, equals(1));
      expect(bytes.isNotEmpty, isTrue);
    });
  });
}
