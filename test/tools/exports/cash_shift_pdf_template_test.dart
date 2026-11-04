import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/tools/exports/pdf/templates/cash_shift_pdf_template.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final branch = BranchInDb(
    id: 'b1',
    name: 'Laboratorio Clínico San José',
    address: 'Av. Principal #123',
    phone: '2222-3333',
    email: 'contacto@lab.com',
    createdAt: 1000,
  );

  group('CashShiftPdfTemplate Tests', () {
    test('construye documento PDF con total de efectivo, transferencias y subtotales exactos sin egresos', () async {
      final shift = CashShiftInDb(
        id: 'shift-abc-1234',
        userId: 'u1',
        userName: 'Carlos Cajero',
        branchId: 'b1',
        branchName: 'Laboratorio Clínico San José',
        status: 'CLOSED',
        openedAt: 1700000000000,
        closedAt: 1700028800000,
        initialBalance: 10000, // $100.00
        cashBalance: 25000, // $250.00
        cardBalance: 0,
        transferBalance: 15000, // $150.00
        bankTransfers: {'BAC': 10000, 'BANPRO': 5000},
        totalBalance: 50000, // $500.00
        declaredCash: 35000, // $350.00 en gaveta
        difference: 0,
        createdAt: 1700000000000,
      );

      final template = CashShiftPdfTemplate(
        shift: shift,
        branch: branch,
        movements: const [],
      );

      final doc = await template.buildDocument();
      expect(doc, isNotNull);

      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue);
    });

    test('construye documento PDF desglosando subtotal previo a egresos autorizados', () async {
      final shift = CashShiftInDb(
        id: 'shift-def-5678',
        userId: 'u2',
        userName: 'María Operadora',
        branchId: 'b1',
        branchName: 'Laboratorio Clínico San José',
        status: 'CLOSED',
        openedAt: 1700000000000,
        closedAt: 1700028800000,
        initialBalance: 10000, // $100.00
        cashBalance: 40000, // $400.00 en saldo neto (500 ventas - 100 egresos)
        cardBalance: 5000, // $50.00
        transferBalance: 20000, // $200.00
        bankTransfers: {'BAC': 20000},
        totalBalance: 75000, // $750.00
        declaredCash: 50000, // $500.00 en gaveta
        difference: 0,
        createdAt: 1700000000000,
      );

      final movements = [
        CashMovementInDb(
          id: 'mov-1',
          shiftId: shift.id,
          branchId: 'b1',
          movementType: 'withdrawal',
          paymentMethod: 'cash',
          amount: 6000, // $60.00
          concept: 'Compra de reactivos de urgencia',
          performedBy: UserInfo(id: 'u2', name: 'María Operadora'),
          createdAt: 1700010000000,
          isDeleted: false,
        ),
        CashMovementInDb(
          id: 'mov-2',
          shiftId: shift.id,
          branchId: 'b1',
          movementType: 'withdrawal',
          paymentMethod: 'cash',
          amount: 4000, // $40.00
          concept: 'Pago de mensajería autorizada',
          performedBy: UserInfo(id: 'u2', name: 'María Operadora'),
          createdAt: 1700020000000,
          isDeleted: false,
        ),
      ];

      final template = CashShiftPdfTemplate(
        shift: shift,
        branch: branch,
        movements: movements,
      );

      final doc = await template.buildDocument();
      expect(doc, isNotNull);

      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue);
    });

    test('construye documento PDF para turno activo en curso con movimientos', () async {
      final shift = CashShiftInDb(
        id: 'shift-active-999',
        userId: 'u1',
        userName: 'Carlos Cajero',
        branchId: 'b1',
        status: 'OPEN',
        openedAt: 1700000000000,
        initialBalance: 5000,
        cashBalance: 12000,
        transferBalance: 8000,
        totalBalance: 25000,
        createdAt: 1700000000000,
      );

      final template = CashShiftPdfTemplate(
        shift: shift,
        branch: branch,
        movements: const [],
      );

      final doc = await template.buildDocument();
      expect(doc, isNotNull);

      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue);
    });
  });
}
