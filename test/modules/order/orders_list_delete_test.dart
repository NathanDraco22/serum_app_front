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
  String? lastDeletedId;

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
  Future<Map<String, dynamic>?> deleteOrderById(String orderId) async {
    lastDeletedId = orderId;
    return _storage.remove(orderId);
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
    id: 'ORD-999',
    patientId: 'PAT-1',
    branchId: 'branch-1',
    totalPrice: 15000,
    paidAmount: 0,
    status: 'pending',
    isBlocked: false,
    createdAt: 1700000000000,
    items: [
      OrderItem(
        labTestId: 'test-1',
        name: 'Hemograma Completo',
        salePriceApplied: 15000,
        originalPrice: 15000,
      ),
    ],
    results: [],
  );

  setUp(() {
    fakeOrdersDataSource = _FakeOrdersDataSource();
    ordersRepo = OrdersRepository(fakeOrdersDataSource);
    fakePatientsDataSource = _FakePatientsDataSource();
    patientsRepo = PatientsRepository(fakePatientsDataSource);
    fakeSessionCubit = _FakeAppSessionCubit();
  });

  Widget buildTestWidget({required List<OrderInDb> orders}) {
    return MaterialApp(
      home: MultiBlocProvider(
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
        child: Scaffold(
          body: OrdersList(
            orders: orders,
            onEditResults: (_) {},
            onPayOrder: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('muestra ConfirmDeleteDialog con temporizador al presionar eliminar orden', (tester) async {
    fakeOrdersDataSource.setOrder(sampleOrder.id, sampleOrder.toJson());

    await tester.pumpWidget(buildTestWidget(orders: [sampleOrder]));
    await tester.pumpAndSettle();

    // El botón de eliminar orden debe estar visible porque status es 'pending' y paidAmount == 0
    final deleteButtonFinder = find.byTooltip('Eliminar Orden');
    expect(deleteButtonFinder, findsOneWidget);

    // Pulsar botón de eliminar
    await tester.tap(deleteButtonFinder);
    await tester.pump();

    // Debe mostrar ConfirmDeleteDialog con su título, mensaje e itemName
    expect(find.byType(ConfirmDeleteDialog), findsOneWidget);
    expect(find.text('Eliminar Orden'), findsOneWidget);
    expect(find.textContaining('¿Está seguro de eliminar esta orden del sistema?'), findsOneWidget);
    expect(find.textContaining('Orden #ORD-999'), findsOneWidget);

    // Durante el temporizador, el botón de confirmar debe mostrar la cuenta regresiva o estar deshabilitado
    // ConfirmDeleteDialog muestra 'Eliminar (5s)' inicialmente
    expect(find.textContaining('(5s)'), findsOneWidget);

    // Intentar tocar el botón de eliminar antes de tiempo no debe eliminar la orden
    await tester.tap(find.textContaining('Eliminar (5s)'));
    await tester.pump();
    expect(fakeOrdersDataSource.lastDeletedId, isNull);

    // Avanzar el temporizador 5 segundos
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('(4s)'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    // Ahora la cuenta regresiva terminó y el botón muestra solo 'Eliminar' habilitado
    expect(find.text('Eliminar'), findsOneWidget);

    // Pulsar botón Eliminar ahora que terminó el conteo
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    // La orden debió ser borrada en el repositorio
    expect(fakeOrdersDataSource.lastDeletedId, equals('ORD-999'));
    expect(find.byType(ConfirmDeleteDialog), findsNothing);
  });
}
