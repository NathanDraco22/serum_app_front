import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:serum_app_front/src/cubits/order_cubit/write_orders_cubit.dart';
import 'package:serum_app_front/src/modules/order/widgets/cancel_order_dialog.dart';
import 'package:serum_business/serum_business.dart';

class _FakeOrdersRepo extends Fake implements OrdersRepository {
  Object? errorToThrow;
  String? capturedOrderId;
  String? capturedReason;

  @override
  Future<OrderInDb?> deleteOrderById(String orderId, {String? reason}) async {
    capturedOrderId = orderId;
    capturedReason = reason;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return OrderInDb(
      id: orderId,
      patientId: 'PAT-1',
      branchId: 'branch-1',
      totalPrice: 10000,
      paidAmount: 0,
      status: 'cancelled',
      isDeleted: true,
      cancellationReason: reason,
      createdAt: 1700000000000,
    );
  }
}

void main() {
  testWidgets(
    'CancelOrderDialog muestra advertencia de reversión, exige motivo y retorna trim',
    (tester) async {
      String? dialogResult;
      final paidOrder = OrderInDb(
        id: 'ORD-100',
        patientId: 'PAT-1',
        branchId: 'branch-1',
        totalPrice: 15000,
        paidAmount: 15000,
        status: 'pending',
        createdAt: 1700000000000,
        items: [
          OrderItem(
            labTestId: 't-1',
            name: 'Perfil Lipídico',
            salePriceApplied: 15000,
            originalPrice: 15000,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  dialogResult = await CancelOrderDialog.show(
                    context,
                    order: paidOrder,
                    patientName: 'Juan Pérez',
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Anular Orden y Revertir Pagos'), findsOneWidget);
      expect(
        find.textContaining('Se revertirá el saldo en el turno de caja abierto'),
        findsOneWidget,
      );

      // Intentar confirmar sin motivo
      await tester.tap(find.text('Anular Orden'));
      await tester.pump();
      expect(
        find.text('El motivo de la anulación es obligatorio.'),
        findsOneWidget,
      );
      expect(dialogResult, isNull);

      // Ingresar motivo con espacios y confirmar
      await tester.enterText(find.byType(TextField), '  Error de paciente  ');
      await tester.tap(find.text('Anular Orden'));
      await tester.pumpAndSettle();

      expect(dialogResult, equals('Error de paciente'));
    },
  );

  test('WriteOrderCubit.delete envía reason y humaniza errores de caja', () async {
    final repo = _FakeOrdersRepo();
    final cubit = WriteOrderCubit(ordersRepository: repo);

    await cubit.delete('ORD-1', reason: 'Cancelación solicitada');
    expect(repo.capturedOrderId, equals('ORD-1'));
    expect(repo.capturedReason, equals('Cancelación solicitada'));
    expect(cubit.state, isA<OrderDeleted>());

    repo.errorToThrow = Exception('CASH_SHIFT_NOT_OPEN');
    await cubit.delete('ORD-1', reason: 'Motivo');
    expect(cubit.state, isA<WriteOrderError>());
    expect(
      (cubit.state as WriteOrderError).message,
      contains('turno de caja donde se registró el pago ya está cerrado'),
    );

    repo.errorToThrow = Exception('INSUFFICIENT_METHOD_BALANCE');
    await cubit.delete('ORD-1', reason: 'Motivo');
    expect(cubit.state, isA<WriteOrderError>());
    expect(
      (cubit.state as WriteOrderError).message,
      contains('no tiene saldo suficiente en el método de pago original'),
    );

    await cubit.close();
  });
}
