import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/cubits/order_cubit/write_orders_cubit.dart';
import 'package:serum_app_front/src/modules/order/widgets/order_pay_dialog.dart';
import 'package:serum_business/serum_business.dart';

class _FakeOrdersDataSource extends Fake implements OrdersDataSource {
  Map<String, dynamic>? lastPayBody;
  String? lastOrderId;

  @override
  Future<Map<String, dynamic>> payOrder(String orderId, Map<String, dynamic> body) async {
    lastOrderId = orderId;
    lastPayBody = body;
    final amount = (body['amount'] as num?)?.toInt() ?? 0;
    return {
      'id': orderId,
      'patientId': 'p1',
      'branchId': 'b1',
      'totalPrice': 10000,
      'paidAmount': amount,
      'status': amount >= 10000 ? 'paid' : 'partiallyPaid',
      'createdAt': 1000,
    };
  }
}

class _FakeAppSessionCubit extends Cubit<AppSessionState> implements AppSessionCubit {
  _FakeAppSessionCubit({CashShiftInDb? shift})
      : super(AppSessionState(
          activeShift: shift ??
              CashShiftInDb(
                id: 'shift-10',
                userId: 'u1',
                branchId: 'b1',
                userName: 'Operador Cajero',
                initialBalance: 50000,
                openedAt: 1000,
                createdAt: 1000,
                status: 'OPEN',
              ),
          currentUser: UserInDb(
            id: 'u1',
            username: 'cajero',
            name: 'Operador Cajero',
            role: 'Operador',
            createdAt: 1000,
          ),
        ));

  @override
  CashShiftInDb? get activeShift => state.activeShift;

  @override
  UserInDb? get user => state.currentUser;

  @override
  Future<void> fetchActiveShift([String? branchId]) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeOrdersDataSource fakeOrdersDataSource;
  late OrdersRepository ordersRepo;
  late WriteOrderCubit writeOrderCubit;
  late _FakeAppSessionCubit fakeSessionCubit;

  final testOrder = OrderInDb(
    id: 'ORD-999',
    patientId: 'patient-1',
    branchId: 'b1',
    items: [
      OrderItem(labTestId: 'T1', name: 'Hemograma Completo', salePriceApplied: 10000),
    ],
    totalPrice: 10000, // $100.00
    paidAmount: 0,
    createdAt: 1000,
  );

  setUp(() {
    fakeOrdersDataSource = _FakeOrdersDataSource();
    ordersRepo = OrdersRepository(fakeOrdersDataSource);
    writeOrderCubit = WriteOrderCubit(ordersRepository: ordersRepo);
    fakeSessionCubit = _FakeAppSessionCubit();
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppSessionCubit>.value(value: fakeSessionCubit),
        BlocProvider<WriteOrderCubit>.value(value: writeOrderCubit),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: OrderPayDialog(order: testOrder),
        ),
      ),
    );
  }

  group('OrderPayDialog Tests', () {
    testWidgets('Campos de transferencia aparecen condicionalmente al seleccionar Transferencia',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Por defecto está en Efectivo; no debe haber campos de transferencia
      expect(find.text('Datos de la Transferencia Bancaria'), findsNothing);
      expect(find.text('Número de Transferencia / Referencia *'), findsNothing);
      expect(find.text('BAC'), findsNothing);

      // Cambiar método de pago a Transferencia
      final dropdownFinder = find.byType(DropdownButtonFormField<String>);
      expect(dropdownFinder, findsOneWidget);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Seleccionar opción Transferencia del menú
      final transferItemFinder = find.text('Transferencia').last;
      await tester.tap(transferItemFinder);
      await tester.pumpAndSettle();

      // Verificar que ahora se muestra el bloque de transferencia bancaria
      expect(find.text('Datos de la Transferencia Bancaria'), findsOneWidget);
      expect(find.text('Número de Transferencia / Referencia *'), findsOneWidget);
      expect(find.text('Banco *'), findsOneWidget);

      // Verificar que los 6 bancos de selección rápida estén presentes
      expect(find.text('BAC'), findsOneWidget);
      expect(find.text('LAFISE'), findsOneWidget);
      expect(find.text('BANPRO'), findsOneWidget);
      expect(find.text('FICOHSA'), findsOneWidget);
      expect(find.text('BDF'), findsOneWidget);
      expect(find.text('AVANZ'), findsOneWidget);
    });

    testWidgets('Tocar chip de banco rápido auto-completa el banco y valida envío de pago',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Cambiar a Transferencia
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transferencia').last);
      await tester.pumpAndSettle();

      // Seleccionar banco rápido BAC
      await tester.tap(find.text('BAC'));
      await tester.pumpAndSettle();

      // Verificar que el campo Banco tenga el valor 'BAC'
      expect(find.widgetWithText(TextFormField, 'BAC'), findsOneWidget);

      // Escribir número de transferencia
      final refField = find.widgetWithText(TextFormField, 'Número de Transferencia / Referencia *');
      await tester.enterText(refField, 'TRF-123456');
      await tester.pumpAndSettle();

      // Pulsar Registrar Pago
      final submitButton = find.text('Registrar Pago');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Validar que se invocó payOrder con los datos de transferencia y banco
      expect(fakeOrdersDataSource.lastOrderId, 'ORD-999');
      expect(fakeOrdersDataSource.lastPayBody, isNotNull);
      expect(fakeOrdersDataSource.lastPayBody!['paymentMethod'], 'transfer');
      expect(fakeOrdersDataSource.lastPayBody!['bank'], 'BAC');
      expect(fakeOrdersDataSource.lastPayBody!['referenceNumber'], 'TRF-123456');
    });
  });
}
