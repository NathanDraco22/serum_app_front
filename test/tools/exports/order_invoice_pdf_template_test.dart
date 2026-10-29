import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/tools/exports/pdf/templates/order_invoice_pdf_template.dart';
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

  group('OrderInvoicePdfTemplate & OrderService Tests', () {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final mockOrder = OrderInDb(
      id: 'ord-999',
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
      services: [
        OrderService(
          id: 'srv-1',
          name: 'Servicio a Domicilio',
          price: 10000,
        ),
      ],
      totalPrice: 35000,
      paidAmount: 20000,
      status: 'pending',
      createdAt: nowMs,
      patientInfo: PatientInfo(
        name: 'Ana María Gómez',
        dateOfBirth: nowMs - (25 * 365 * 86400000),
        gender: 'F',
        phone: '8888-9999',
        cardId: '001-010199-0001A',
      ),
      doctorInfo: DoctorInfo(
        name: 'Dr. Alejandro Solís',
        specialty: 'Pediatría',
      ),
    );

    final mockBranch = BranchInDb(
      id: 'br-1',
      name: 'Laboratorio Clínico Serum',
      address: 'Pista Suburbana, Edificio Médico 2do Piso',
      phone: 'PBX 2222-1234',
      createdAt: nowMs,
    );

    final mockReceipts = [
      ReceiptInDb(
        id: 'rec-1',
        receiptNumber: 'REC-0001',
        orderId: 'ord-999',
        branchId: 'br-1',
        amount: 20000,
        paymentMethod: 'cash',
        concept: 'Abono inicial 50%',
        performedBy: UserInfo(id: 'usr-1', name: 'Cajera 1'),
        createdAt: nowMs,
      ),
    ];

    test('Serialización y deserialización de OrderService en OrderInDb', () {
      final json = mockOrder.toJson();
      expect(json['items'], isNotNull);
      expect((json['items'] as List).length, 1);

      final orderRestored = OrderInDb.fromJson({
        'id': 'ord-999',
        'patientId': 'pat-1',
        'branchId': 'br-1',
        'items': [
          {
            'labTestId': 'lt-1',
            'name': 'Biometría Hemática Completa',
            'salePriceApplied': 25000,
          }
        ],
        'services': [
          {
            'id': 'srv-1',
            'name': 'Servicio a Domicilio',
            'price': 10000,
          }
        ],
        'totalPrice': 35000,
        'paidAmount': 20000,
        'createdAt': nowMs,
      });

      expect(orderRestored.services.length, 1);
      expect(orderRestored.services.first.name, 'Servicio a Domicilio');
      expect(orderRestored.services.first.price, 10000);
      expect(orderRestored.totalPrice, 35000);
    });

    test('Construye documento PDF de Comprobante de Factura con pruebas, servicios y abonos', () async {
      final template = OrderInvoicePdfTemplate(
        order: mockOrder,
        branch: mockBranch,
        receipts: mockReceipts,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('Construye documento PDF de Comprobante de Factura sin recibos previos', () async {
      final template = OrderInvoicePdfTemplate(
        order: mockOrder,
        branch: mockBranch,
        receipts: const [],
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('Construye documento PDF de Comprobante de Factura con descuentos aplicados', () async {
      final orderWithDiscount = OrderInDb(
        id: 'ord-disc-pdf',
        patientId: 'pat-1',
        branchId: 'br-1',
        createdAt: nowMs,
        items: [
          OrderItem(
            labTestId: 'lt-1',
            name: 'Glucosa',
            salePriceApplied: 30000,
          )
        ],
        discounts: [
          OrderDiscount(
            description: 'Tercera Edad',
            type: 'percentage',
            value: 10.0,
            appliedAmount: 3000,
          )
        ],
        totalPrice: 27000,
      );

      final template = OrderInvoicePdfTemplate(
        order: orderWithDiscount,
        branch: mockBranch,
        receipts: const [],
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('Construye documento PDF de Comprobante de Factura con sucursal que posee isoLogoUrl', () async {
      final branchWithIsoLogo = BranchInDb(
        id: 'br-iso',
        name: 'Laboratorio Clínico San José',
        address: 'Plaza Central 123',
        phone: 'PBX 2222-9999',
        isoLogoUrl: 'https://example.com/images/isologo.png',
        createdAt: nowMs,
      );

      final template = OrderInvoicePdfTemplate(
        order: mockOrder,
        branch: branchWithIsoLogo,
        receipts: mockReceipts,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('Construye documento PDF de Comprobante de Factura con sucursal que posee logoUrl', () async {
      final branchWithLogo = BranchInDb(
        id: 'br-logo',
        name: 'Laboratorio Clínico Diagnóstica',
        address: 'Av. Universitaria 45',
        phone: 'PBX 2222-8888',
        logoUrl: 'https://example.com/images/logo.png',
        createdAt: nowMs,
      );

      final template = OrderInvoicePdfTemplate(
        order: mockOrder,
        branch: branchWithLogo,
        receipts: mockReceipts,
      );

      final doc = await template.buildDocument();
      final bytes = await doc.save();

      expect(doc.document.pdfPageList.pages.isNotEmpty, isTrue);
      expect(bytes.isNotEmpty, isTrue);
    });
  });
}
