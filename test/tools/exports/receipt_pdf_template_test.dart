import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/tools/exports/pdf/templates/receipt_pdf_template.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReceiptPdfTemplate Tests', () {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final mockBranch = BranchInDb(
      id: 'branch-central',
      name: 'Laboratorio Clínico San Rafael',
      address: 'Avenida Bolivar #123',
      phone: '2222-3333',
      createdAt: nowMs,
    );

    final mockReceiptWithoutOrder = ReceiptInDb(
      id: 'rec-001',
      receiptNumber: 'REC-2026-0001',
      orderId: 'ord-12345678',
      orderNumber: 'ORD-1001',
      branchId: 'branch-central',
      shiftId: 'shift-99',
      registerId: 'reg-01',
      amount: 15000, // 150.00
      paymentMethod: 'cash',
      concept: 'Pago total de examen clínico',
      performedBy: UserInfo(id: 'usr-1', name: 'Laura Cajera'),
      patientName: 'Roberto Mendoza',
      createdAt: nowMs,
    );

    final mockOrder = OrderInDb(
      id: 'ord-12345678',
      patientId: 'pat-1',
      branchId: 'branch-central',
      totalPrice: 40000, // 400.00
      paidAmount: 25000, // 250.00 ya pagado
      status: 'pending',
      createdAt: nowMs,
      patientInfo: PatientInfo(
        name: 'Roberto Mendoza',
        dateOfBirth: nowMs - (40 * 365 * 86400000),
        gender: 'M',
        phone: '555-1234',
      ),
    );

    test('Construye documento PDF válido sin orden asociada', () async {
      final template = ReceiptPdfTemplate(
        receipt: mockReceiptWithoutOrder,
        branch: mockBranch,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(bytes, isNotEmpty);
      expect(doc.document.pdfPageList.pages.length, 1);
    });

    test('Construye documento PDF válido con orden y cálculo de saldos', () async {
      final template = ReceiptPdfTemplate(
        receipt: mockReceiptWithoutOrder,
        branch: mockBranch,
        order: mockOrder,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(bytes, isNotEmpty);
      expect(doc.document.pdfPageList.pages.length, 1);
    });

    test('Maneja diferentes métodos de pago y paciente por defecto', () async {
      for (final method in ['card', 'transfer', 'cash', 'other']) {
        final r = ReceiptInDb(
          id: 'rec-test-$method',
          receiptNumber: 'REC-$method',
          orderId: 'ord-99',
          branchId: 'branch-central',
          amount: 5000,
          paymentMethod: method,
          performedBy: UserInfo(id: 'usr-2', name: 'Cajero 2'),
          patientName: null,
          createdAt: nowMs,
        );

        final template = ReceiptPdfTemplate(
          receipt: r,
          branch: mockBranch,
        );

        final doc = await template.buildDocument();
        final bytes = await doc.save();
        expect(bytes, isNotEmpty);
      }
    });
  });
}
