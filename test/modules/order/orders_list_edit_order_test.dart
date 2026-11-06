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
  @override
  Future<Map<String, dynamic>> getAllOrders({OrderQueryParams? queryParams}) async {
    return {'data': [], 'count': 0};
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
  late OrdersRepository ordersRepo;
  late PatientsRepository patientsRepo;

  setUp(() {
    ordersRepo = OrdersRepository(_FakeOrdersDataSource());
    patientsRepo = PatientsRepository(_FakePatientsDataSource());
  });

  Widget createWidgetUnderTest({
    required List<OrderInDb> orders,
    required void Function(OrderInDb) onEditOrder,
  }) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AppSessionCubit>(create: (_) => _FakeAppSessionCubit()),
          BlocProvider<ReadOrderCubit>(create: (_) => ReadOrderCubit(ordersRepository: ordersRepo)),
          BlocProvider<WriteOrderCubit>(create: (_) => WriteOrderCubit(ordersRepository: ordersRepo)),
          BlocProvider<ReadPatientCubit>(create: (_) => ReadPatientCubit(patientsRepository: patientsRepo)),
        ],
        child: Scaffold(
          body: OrdersList(
            orders: orders,
            onEditResults: (_) {},
            onPayOrder: (_) {},
            onEditOrder: onEditOrder,
          ),
        ),
      ),
    );
  }

  OrderInDb makeOrder({
    required String id,
    int paidAmount = 0,
    String status = 'pending',
  }) {
    return OrderInDb(
      id: id,
      branchId: 'branch-1',
      patientId: 'patient-1',
      patientInfo: PatientInfo(name: 'Juan Perez'),
      items: [
        OrderItem(
          labTestId: 'test-1',
          name: 'Glucosa',
          salePriceApplied: 10000,
          originalPrice: 10000,
        ),
      ],
      totalPrice: 10000,
      paidAmount: paidAmount,
      status: status,
      createdAt: 1700000000000,
    );
  }

  testWidgets('Muestra botón de Modificar Orden cuando no está pagada ni completada', (tester) async {
    OrderInDb? editedOrder;
    final pendingOrder = makeOrder(id: 'ord-1', paidAmount: 0, status: 'pending');

    await tester.pumpWidget(createWidgetUnderTest(
      orders: [pendingOrder],
      onEditOrder: (order) => editedOrder = order,
    ));
    await tester.pumpAndSettle();

    final editButton = find.byTooltip('Modificar Orden (Agregar / Quitar Exámenes)');
    expect(editButton, findsOneWidget);

    await tester.tap(editButton);
    await tester.pumpAndSettle();

    expect(editedOrder?.id, 'ord-1');
  });

  testWidgets('Oculta botón de Modificar Orden si la orden ya tiene pagos registrados', (tester) async {
    final paidOrder = makeOrder(id: 'ord-2', paidAmount: 5000, status: 'partiallyPaid');

    await tester.pumpWidget(createWidgetUnderTest(
      orders: [paidOrder],
      onEditOrder: (_) {},
    ));
    await tester.pumpAndSettle();

    final editButton = find.byTooltip('Modificar Orden (Agregar / Quitar Exámenes)');
    expect(editButton, findsNothing);
  });

  testWidgets('Oculta botón de Modificar Orden si la orden ya está completada', (tester) async {
    final completedOrder = makeOrder(id: 'ord-3', paidAmount: 0, status: 'completed');

    await tester.pumpWidget(createWidgetUnderTest(
      orders: [completedOrder],
      onEditOrder: (_) {},
    ));
    await tester.pumpAndSettle();

    final editButton = find.byTooltip('Modificar Orden (Agregar / Quitar Exámenes)');
    expect(editButton, findsNothing);
  });

  testWidgets('Oculta botón de Modificar Orden si la orden está cancelada', (tester) async {
    final cancelledOrder = makeOrder(id: 'ord-4', paidAmount: 0, status: 'cancelled');

    await tester.pumpWidget(createWidgetUnderTest(
      orders: [cancelledOrder],
      onEditOrder: (_) {},
    ));
    await tester.pumpAndSettle();

    final editButton = find.byTooltip('Modificar Orden (Agregar / Quitar Exámenes)');
    expect(editButton, findsNothing);
  });
}
