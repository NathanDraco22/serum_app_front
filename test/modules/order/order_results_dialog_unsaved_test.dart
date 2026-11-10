import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/order_cubit/write_orders_cubit.dart';
import 'package:serum_app_front/src/modules/order/widgets/order_results_dialog.dart';
import 'package:serum_business/serum_business.dart';

class _FakeOrdersDataSource extends Fake implements OrdersDataSource {
  @override
  Future<Map<String, dynamic>?> updateOrderById(
    String orderId,
    Map<String, dynamic> order,
  ) async {
    return {
      'id': orderId,
      'patientId': 'PAT-1',
      'branchId': 'branch-1',
      'totalPrice': 10000,
      'paidAmount': 10000,
      'status': 'paid',
      'createdAt': 1700000000000,
      'items': [],
      'results': order['results'] ?? [],
    };
  }
}

OrderInDb _buildOrder() {
  return OrderInDb(
    id: 'ORD-UNSAVED-01',
    patientId: 'PAT-1',
    branchId: 'branch-1',
    totalPrice: 10000,
    paidAmount: 10000,
    status: 'paid',
    createdAt: 1700000000000,
    results: [
      OrderTestResult(
        labTestId: 'test-glu',
        parameterName: 'Glucosa',
        dataType: 'numeric',
        unitOfMeasure: 'mg/dL',
      ),
    ],
  );
}

void main() {
  testWidgets('Cerrar con cambios pide confirmación y conserva los valores si se sigue editando', (
    tester,
  ) async {
    final order = _buildOrder();
    final writeCubit = WriteOrderCubit(
      ordersRepository: OrdersRepository(_FakeOrdersDataSource()),
    );
    addTearDown(writeCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                key: const Key('open-results'),
                onPressed: () => showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => BlocProvider.value(
                    value: writeCubit,
                    child: OrderResultsDialog(order: order),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-results')));
    await tester.pumpAndSettle();
    expect(find.byType(OrderResultsDialog), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '95');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    expect(find.text('Descartar cambios'), findsOneWidget);

    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();
    expect(find.byType(OrderResultsDialog), findsOneWidget);
    final field = tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(field.controller?.text, '95');
  });

  testWidgets('Cerrar sin cambios no muestra confirmación', (tester) async {
    final order = _buildOrder();
    final writeCubit = WriteOrderCubit(
      ordersRepository: OrdersRepository(_FakeOrdersDataSource()),
    );
    addTearDown(writeCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                key: const Key('open-results'),
                onPressed: () => showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => BlocProvider.value(
                    value: writeCubit,
                    child: OrderResultsDialog(order: order),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-results')));
    await tester.pumpAndSettle();
    expect(find.byType(OrderResultsDialog), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    expect(find.text('Descartar cambios'), findsNothing);
    expect(find.byType(OrderResultsDialog), findsNothing);
  });
}
