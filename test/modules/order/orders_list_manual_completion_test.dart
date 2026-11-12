import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/cubits/order_cubit/read_orders_cubit.dart';
import 'package:serum_app_front/src/cubits/order_cubit/write_orders_cubit.dart';
import 'package:serum_app_front/src/cubits/patient_cubit/read_patients_cubit.dart';
import 'package:serum_app_front/src/modules/order/widgets/orders_list.dart';
import 'package:serum_business/serum_business.dart';

class _FakeOrdersDataSource extends Fake implements OrdersDataSource {
  final Map<String, Map<String, dynamic>> _storage = {};
  String? lastUpdatedId;
  Map<String, dynamic>? lastUpdatedData;
  String? lastFinalizedId;
  String? lastReopenedId;
  Map<String, dynamic>? lastReopenedData;

  void setOrder(String id, Map<String, dynamic> data) {
    _storage[id] = data;
  }

  @override
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    return _storage[orderId];
  }

  @override
  Future<Map<String, dynamic>> getAllOrders({OrderQueryParams? queryParams}) async {
    return {
      'data': _storage.values.toList(),
      'count': _storage.length,
    };
  }

  @override
  Future<Map<String, dynamic>?> updateOrderById(
    String orderId,
    Map<String, dynamic> order,
  ) async {
    lastUpdatedId = orderId;
    lastUpdatedData = order;
    if (_storage.containsKey(orderId)) {
      _storage[orderId]!.addAll(order);
      return _storage[orderId];
    }
    return order;
  }

  @override
  Future<Map<String, dynamic>> finalizeOrder(String orderId) async {
    lastFinalizedId = orderId;
    final data = _storage[orderId] ?? {'id': orderId};
    data['status'] = 'completed';
    return data;
  }

  @override
  Future<Map<String, dynamic>> reopenOrder(
    String orderId,
    Map<String, dynamic> body,
  ) async {
    lastReopenedId = orderId;
    lastReopenedData = body;
    final data = _storage[orderId] ?? {'id': orderId};
    data['status'] = 'in_review';
    return data;
  }
}

class _FakePatientsDataSource extends Fake implements PatientsDataSource {
  @override
  Future<Map<String, dynamic>> getAllPatients({String? originBranch}) async {
    return {'data': [], 'count': 0};
  }
}

class _FakeAppSessionCubit extends Cubit<AppSessionState> implements AppSessionCubit {
  _FakeAppSessionCubit()
      : super(
          AppSessionState(
            currentUser: UserInDb(
              id: 'user-1',
              username: 'bioanalista',
              name: 'Bioanalista',
              role: 'Operador',
              accessLevel: 3,
              createdAt: 0,
            ),
          ),
        );

  @override
  String get currentBranchId => 'branch-1';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeOrdersDataSource fakeOrdersDataSource;
  late OrdersRepository ordersRepo;
  late _FakePatientsDataSource fakePatientsDataSource;
  late PatientsRepository patientsRepo;
  late _FakeAppSessionCubit fakeSessionCubit;

  final sampleOrder = OrderInDb(
    id: 'ORD-100',
    patientId: 'PAT-1',
    branchId: 'branch-1',
    totalPrice: 15000,
    paidAmount: 15000,
    status: 'paid',
    items: [
      OrderItem(
        labTestId: 'lt-1',
        name: 'Biometría Hemática',
        salePriceApplied: 15000,
      ),
    ],
    createdAt: DateTime.now().millisecondsSinceEpoch,
    patientInfo: PatientInfo(
      name: 'María Delgado',
      gender: 'F',
      dateOfBirth: DateTime.now().millisecondsSinceEpoch - 30 * 365 * 86400000,
    ),
  );

  final reviewOrder = OrderInDb(
    id: 'ORD-200',
    patientId: 'PAT-1',
    branchId: 'branch-1',
    totalPrice: 15000,
    paidAmount: 15000,
    status: 'in_review',
    items: [
      OrderItem(
        labTestId: 'lt-1',
        name: 'Biometría Hemática',
        salePriceApplied: 15000,
      ),
    ],
    results: [
      OrderTestResult(
        labTestId: 'res-1',
        parameterName: 'Hemoglobina',
        dataType: 'numeric',
        resultValue: '14.2',
      ),
    ],
    createdAt: DateTime.now().millisecondsSinceEpoch,
    patientInfo: PatientInfo(name: 'María Delgado', gender: 'F'),
  );

  final completedOrder = OrderInDb(
    id: 'ORD-300',
    patientId: 'PAT-1',
    branchId: 'branch-1',
    totalPrice: 15000,
    paidAmount: 15000,
    status: 'completed',
    items: [
      OrderItem(
        labTestId: 'lt-1',
        name: 'Biometría Hemática',
        salePriceApplied: 15000,
      ),
    ],
    results: [
      OrderTestResult(
        labTestId: 'res-1',
        parameterName: 'Hemoglobina',
        dataType: 'numeric',
        resultValue: '14.2',
      ),
    ],
    createdAt: DateTime.now().millisecondsSinceEpoch,
    finalizedAt: DateTime.now().millisecondsSinceEpoch,
    finalizedBy: UserInfo(id: 'user-1', name: 'Bioanalista'),
    patientInfo: PatientInfo(name: 'María Delgado', gender: 'F'),
  );

  setUp(() {
    fakeOrdersDataSource = _FakeOrdersDataSource();
    fakeOrdersDataSource.setOrder(sampleOrder.id, sampleOrder.toJson());
    fakeOrdersDataSource.setOrder(reviewOrder.id, reviewOrder.toJson());
    fakeOrdersDataSource.setOrder(completedOrder.id, completedOrder.toJson());
    ordersRepo = OrdersRepository(fakeOrdersDataSource);

    fakePatientsDataSource = _FakePatientsDataSource();
    patientsRepo = PatientsRepository(fakePatientsDataSource);

    fakeSessionCubit = _FakeAppSessionCubit();
  });

  Widget createWidgetUnderTest({
    required List<OrderInDb> orders,
    required Function(OrderInDb) onEditResults,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppSessionCubit>.value(value: fakeSessionCubit),
        BlocProvider<ReadPatientCubit>(
          create: (_) => ReadPatientCubit(patientsRepository: patientsRepo),
        ),
        BlocProvider<ReadOrderCubit>(
          create: (_) => ReadOrderCubit(ordersRepository: ordersRepo),
        ),
        BlocProvider<WriteOrderCubit>(
          create: (_) => WriteOrderCubit(ordersRepository: ordersRepo),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: OrdersList(
            orders: orders,
            onEditResults: onEditResults,
            onPayOrder: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('Does not show "Imprimir Sobre" button in OrdersList', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(
        orders: [sampleOrder],
        onEditResults: (_) {},
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Imprimir Sobre'), findsNothing);
    expect(find.byIcon(Icons.mail_outline), findsNothing);
  });

  testWidgets('Results button opens onEditResults for all orders', (tester) async {
    OrderInDb? editedOrder;
    await tester.pumpWidget(
      createWidgetUnderTest(
        orders: [sampleOrder],
        onEditResults: (order) {
          editedOrder = order;
        },
      ),
    );
    await tester.pump();

    final resultsButton = find.byTooltip('Capturar / Editar Resultados');
    expect(resultsButton, findsOneWidget);

    await tester.tap(resultsButton);
    await tester.pump();

    expect(editedOrder, isNotNull);
    expect(editedOrder!.id, 'ORD-100');
  });

  testWidgets('Shows Finalizar Orden for in_review orders and calls finalize', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(
        orders: [reviewOrder],
        onEditResults: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('EN REVISIÓN'), findsOneWidget);
    final finalizeButton = find.widgetWithText(FilledButton, 'Finalizar Orden');
    expect(finalizeButton, findsOneWidget);

    await tester.tap(finalizeButton);
    await tester.pumpAndSettle();

    expect(find.text('Finalizar Orden Médica'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Finalizar Orden'),
      ),
    );
    await tester.pumpAndSettle();

    expect(fakeOrdersDataSource.lastFinalizedId, 'ORD-200');
  });

  testWidgets('Tapping completed status opens reopen dialog and sends reason', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(
        orders: [completedOrder],
        onEditResults: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ORDEN COMPLETADA'), findsOneWidget);

    await tester.tap(find.byTooltip('Orden completada (clic para reabrir)').first);
    await tester.pumpAndSettle();

    expect(find.text('Reabrir Orden Médica'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Corrección de hemoglobina');
    await tester.tap(find.text('Reabrir Orden'));
    await tester.pumpAndSettle();

    expect(fakeOrdersDataSource.lastReopenedId, 'ORD-300');
    expect(
      fakeOrdersDataSource.lastReopenedData?['reason'],
      'Corrección de hemoglobina',
    );
  });
}
