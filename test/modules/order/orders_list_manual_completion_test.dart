import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/cubits/order_cubit/read_orders_cubit.dart';
import 'package:serum_app_front/src/cubits/order_cubit/write_orders_cubit.dart';
import 'package:serum_app_front/src/cubits/patient_cubit/read_patients_cubit.dart';
import 'package:serum_app_front/src/modules/order/widgets/orders_list.dart';
import 'package:serum_app_front/src/widgets/dialogs/confirm_delete_dialog.dart';
import 'package:serum_business/serum_business.dart';

class _FakeOrdersDataSource extends Fake implements OrdersDataSource {
  final Map<String, Map<String, dynamic>> _storage = {};
  String? lastUpdatedId;
  Map<String, dynamic>? lastUpdatedData;

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
}

class _FakePatientsDataSource extends Fake implements PatientsDataSource {
  @override
  Future<Map<String, dynamic>> getAllPatients({String? originBranch}) async {
    return {'data': [], 'count': 0};
  }
}

class _FakeAppSessionCubit extends Cubit<AppSessionState> implements AppSessionCubit {
  _FakeAppSessionCubit() : super(const AppSessionState());

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

  setUp(() {
    fakeOrdersDataSource = _FakeOrdersDataSource();
    fakeOrdersDataSource.setOrder(sampleOrder.id, sampleOrder.toJson());
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

  testWidgets('Tapping status icon shows ConfirmDeleteDialog with 5s countdown to complete order',
      (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(
        orders: [sampleOrder],
        onEditResults: (_) {},
      ),
    );
    await tester.pump();

    // Find the CircleAvatar status icon
    final avatar = find.byType(CircleAvatar).first;
    await tester.tap(avatar);
    await tester.pump();

    // Confirm dialog is displayed
    expect(find.byType(ConfirmDeleteDialog), findsOneWidget);
    expect(find.text('Completar Orden Médica'), findsOneWidget);
    expect(find.text('Marcar como Completada (5s)'), findsOneWidget);

    // Wait 5 seconds for countdown to expire
    await tester.pump(const Duration(seconds: 5));

    expect(find.text('Marcar como Completada'), findsOneWidget);

    // Tap confirm button
    await tester.tap(find.text('Marcar como Completada'));
    await tester.pumpAndSettle();

    // Verify order was updated to completed
    expect(fakeOrdersDataSource.lastUpdatedId, 'ORD-100');
    expect(fakeOrdersDataSource.lastUpdatedData?['status'], 'completed');
  });
}
