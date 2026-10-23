import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/cubits/order_cubit/read_orders_cubit.dart';
import 'package:serum_app_front/src/cubits/order_cubit/write_orders_cubit.dart';
import 'package:serum_app_front/src/cubits/patient_cubit/read_patients_cubit.dart';
import 'package:serum_app_front/src/modules/order/view/order_screen.dart';
import 'package:serum_app_front/src/modules/order/widgets/orders_list.dart';
import 'package:serum_business/serum_business.dart';

class _FakeOrdersDataSource extends Fake implements OrdersDataSource {
  final Map<String, Map<String, dynamic>> _storage = {};

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
}

class _FakePatientsDataSource extends Fake implements PatientsDataSource {
  @override
  Future<Map<String, dynamic>> getAllPatients({String? originBranch}) async {
    return {'data': [], 'count': 0};
  }
}

class _FakeDoctorsDataSource extends Fake implements DoctorsDataSource {
  @override
  Future<Map<String, dynamic>> getAllDoctors({String? originBranch}) async {
    return {'data': [], 'count': 0};
  }
}

class _FakeLabTestsDataSource extends Fake implements LabTestsDataSource {
  @override
  Future<Map<String, dynamic>> getAllLabTests({String? branchId}) async {
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

  final sampleBlockedOrder = OrderInDb(
    id: 'ORD-001',
    patientId: 'PAT-1',
    branchId: 'branch-1',
    totalPrice: 35000,
    paidAmount: 0,
    status: 'pending',
    isBlocked: true,
    approval: OrderApproval(
      requiresApproval: true,
      isApproved: false,
      reason: 'Descuento no autorizado',
    ),
    createdAt: 1700000000000,
    items: [
      OrderItem(
        labTestId: 'test-1',
        name: 'Perfil Lipídico',
        salePriceApplied: 35000,
        originalPrice: 40000,
      ),
    ],
    results: [],
  );

  setUp(() {
    fakeOrdersDataSource = _FakeOrdersDataSource();
    ordersRepo = OrdersRepository(fakeOrdersDataSource);
    fakePatientsDataSource = _FakePatientsDataSource();
    patientsRepo = PatientsRepository(fakePatientsDataSource);
  });

  group('ReadOrderCubit.refreshOrder', () {
    test('obtiene la orden actualizada del repositorio y actualiza el estado local', () async {
      fakeOrdersDataSource.setOrder(sampleBlockedOrder.id, sampleBlockedOrder.toJson());
      final cubit = ReadOrderCubit(ordersRepository: ordersRepo);
      await cubit.getAll();

      expect(cubit.state, isA<ReadOrderSuccess>());
      final initialOrder = (cubit.state as ReadOrderSuccess).items.first;
      expect(initialOrder.isBlocked, isTrue);

      // Simular que el admin aprobó y desbloqueó la orden remotamente
      final updatedData = sampleBlockedOrder.toJson();
      updatedData['isBlocked'] = false;
      updatedData['approval'] = {
        'requiresApproval': true,
        'isApproved': true,
        'approvedBy': {'id': 'admin-1', 'name': 'Super Admin'},
        'approvedAt': 1700001000000,
        'reason': 'Aprobado desde móvil',
      };
      fakeOrdersDataSource.setOrder(sampleBlockedOrder.id, updatedData);

      // Ejecutar refreshOrder
      final refreshed = await cubit.refreshOrder(sampleBlockedOrder.id);
      expect(refreshed, isNotNull);
      expect(refreshed!.isBlocked, isFalse);
      expect(refreshed.approval?.isApproved, isTrue);
      expect(refreshed.approval?.approvedBy?.name, 'Super Admin');

      // Verificar que el estado emitido en el cubit tiene la orden desbloqueada
      final finalOrder = (cubit.state as ReadOrderSuccess).items.first;
      expect(finalOrder.isBlocked, isFalse);
      expect(finalOrder.approval?.isApproved, isTrue);

      await cubit.close();
    });
  });

  group('OrdersList Widget - Botón de Verificación / Sincronización', () {
    testWidgets('muestra el botón de sincronización en una orden bloqueada y actualiza al tocarlo', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      fakeOrdersDataSource.setOrder(sampleBlockedOrder.id, sampleBlockedOrder.toJson());
      final orderCubit = ReadOrderCubit(ordersRepository: ordersRepo);
      final writeCubit = WriteOrderCubit(ordersRepository: ordersRepo);
      final patientsCubit = ReadPatientCubit(patientsRepository: patientsRepo);

      await orderCubit.getAll();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<ReadOrderCubit>.value(value: orderCubit),
                BlocProvider<WriteOrderCubit>.value(value: writeCubit),
                BlocProvider<ReadPatientCubit>.value(value: patientsCubit),
              ],
              child: OrdersList(
                orders: [sampleBlockedOrder],
                onEditResults: (_) {},
                onPayOrder: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Debe mostrar el icono de sync para verificar si ya fue autorizada
      final syncButtonFinder = find.byTooltip('Verificar si ya fue autorizada remotamente');
      expect(syncButtonFinder, findsOneWidget);

      // Simular desbloqueo remoto en base de datos
      final unlockedData = sampleBlockedOrder.toJson();
      unlockedData['isBlocked'] = false;
      unlockedData['approval'] = {
        'requiresApproval': true,
        'isApproved': true,
        'approvedBy': {'id': 'admin-99', 'name': 'Dra. López'},
        'reason': 'Autorizado',
      };
      fakeOrdersDataSource.setOrder(sampleBlockedOrder.id, unlockedData);

      // Tocar el botón de verificación
      await tester.tap(syncButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Debe mostrar SnackBar de éxito
      expect(find.text('¡Orden #${sampleBlockedOrder.id} autorizada y desbloqueada!'), findsOneWidget);

      // El cubit ahora tiene la orden desbloqueada
      final currentOrder = (orderCubit.state as ReadOrderSuccess).items.first;
      expect(currentOrder.isBlocked, isFalse);
    });

    testWidgets('OrdersScreen tiene el botón de Actualizar órdenes en el encabezado', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      fakeOrdersDataSource.setOrder(sampleBlockedOrder.id, sampleBlockedOrder.toJson());
      final doctorsRepo = DoctorsRepository(_FakeDoctorsDataSource());
      final labTestsRepo = LabTestsRepository(_FakeLabTestsDataSource());
      final fakeSessionCubit = _FakeAppSessionCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<OrdersRepository>.value(value: ordersRepo),
              RepositoryProvider<PatientsRepository>.value(value: patientsRepo),
              RepositoryProvider<DoctorsRepository>.value(value: doctorsRepo),
              RepositoryProvider<LabTestsRepository>.value(value: labTestsRepo),
            ],
            child: BlocProvider<AppSessionCubit>.value(
              value: fakeSessionCubit,
              child: const OrdersScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar que el botón y el icono de refresco existen en el encabezado
      final refreshButtonFinder = find.byTooltip('Actualizar órdenes');
      expect(refreshButtonFinder, findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      // Tocar el botón de actualizar y comprobar que recarga órdenes sin error
      await tester.tap(refreshButtonFinder);
      await tester.pumpAndSettle();

      expect(refreshButtonFinder, findsOneWidget);
    });
  });
}
