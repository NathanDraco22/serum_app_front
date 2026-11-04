import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import 'package:serum_app_front/src/modules/order/controllers/create_order_mediator.dart';
import 'package:serum_app_front/src/modules/order/controllers/create_order_view_controller.dart';
import 'package:serum_app_front/src/modules/order/view/create_order_screen.dart';
import 'package:serum_app_front/src/modules/order/widgets/order_cart_section.dart';
import 'package:serum_business/serum_business.dart';

class _FakeOrdersDataSource extends Fake implements OrdersDataSource {
  @override
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    return {'id': 'order_created_1', ...data};
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
  final List<Map<String, dynamic>> items;
  _FakeLabTestsDataSource({this.items = const []});

  @override
  Future<Map<String, dynamic>> getAllLabTests({String? branchId}) async {
    return {'data': items, 'count': items.length};
  }
}

class _FakeAppSessionCubit extends Cubit<AppSessionState> implements AppSessionCubit {
  _FakeAppSessionCubit() : super(const AppSessionState());

  @override
  String get currentBranchId => 'branch_1';

  @override
  String get currentBranchName => 'Sucursal Central';

  @override
  UserInDb? get user => UserInDb(
        id: 'u_admin',
        name: 'Administrador',
        username: 'admin',
        role: 'admin',
        accessLevel: 5,
        branches: ['branch_1'],
        isActive: true,
        isDeleted: false,
        createdAt: 0,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CreateOrderScreen & CreateOrderMediator Integration Tests', () {
    late OrdersRepository ordersRepo;
    late PatientsRepository patientsRepo;
    late DoctorsRepository doctorsRepo;
    late LabTestsRepository labTestsRepo;
    late _FakeAppSessionCubit fakeSessionCubit;

    final testItem = LabTestInDb(
      id: 'test_101',
      name: 'Hemoglobina Glicosilada',
      commercialCategory: 'Bioquímica',
      salePrice: 25000, // C$ 250.00
      salePrice2: 22000,
      createdAt: 0,
    );

    setUp(() {
      ordersRepo = OrdersRepository(_FakeOrdersDataSource());
      patientsRepo = PatientsRepository(_FakePatientsDataSource());
      doctorsRepo = DoctorsRepository(_FakeDoctorsDataSource());
      labTestsRepo = LabTestsRepository(
        _FakeLabTestsDataSource(items: [testItem.toJson()]),
      );
      fakeSessionCubit = _FakeAppSessionCubit();
    });

    Widget createTestApp() {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider<OrdersRepository>.value(value: ordersRepo),
          RepositoryProvider<PatientsRepository>.value(value: patientsRepo),
          RepositoryProvider<DoctorsRepository>.value(value: doctorsRepo),
          RepositoryProvider<LabTestsRepository>.value(value: labTestsRepo),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AppSessionCubit>.value(value: fakeSessionCubit),
            BlocProvider<ReadLabTestCubit>(
              create: (context) => ReadLabTestCubit(labTestsRepository: labTestsRepo)
                ..getAll(branchId: 'branch_1'),
            ),
          ],
          child: const MaterialApp(
            home: CreateOrderScreen(),
          ),
        ),
      );
    }

    testWidgets('CreateOrderMediator propaga correctamente el controlador a OrderCartSection', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = CreateOrderViewController();
      controller.toggleItem(testItem);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreateOrderMediator(
              viewController: controller,
              child: const SizedBox(
                width: 600,
                height: 900,
                child: OrderCartSection(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe leer el ítem del controlador automáticamente
      expect(find.text('Análisis en la Orden (1)'), findsOneWidget);
      expect(find.text('Hemoglobina Glicosilada'), findsOneWidget);
      expect(find.textContaining('250.00'), findsWidgets);

      // Mutación en el controlador se refleja reactivamente en el widget
      controller.editItemPrice(testItem.id, 20000, testItem.salePrice);
      await tester.pumpAndSettle();

      expect(find.text('Modificado'), findsOneWidget);
      expect(find.textContaining('200.00'), findsWidgets);

      controller.dispose();
    });

    testWidgets('CreateOrderScreen renderiza catálogo, carrito y reacciona a selección de análisis', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verificar elementos de encabezado
      expect(find.text('Nueva Orden Clínica'), findsOneWidget);
      expect(find.text('Sucursal Central'), findsOneWidget);
      expect(find.text('Nuevo Paciente'), findsOneWidget);
      expect(find.text('Nuevo Médico'), findsOneWidget);

      // Inicialmente el carrito está vacío
      expect(find.text('Análisis en la Orden (0)'), findsOneWidget);
      expect(find.text('No has agregado análisis'), findsOneWidget);

      // Tocar el análisis en el catálogo para agregarlo a la orden
      final testFinder = find.text('Hemoglobina Glicosilada');
      expect(testFinder, findsOneWidget);
      await tester.tap(testFinder);
      await tester.pumpAndSettle();

      // Debe agregarse al carrito
      expect(find.text('Análisis en la Orden (1)'), findsWidgets);
      expect(find.textContaining('250.00'), findsWidgets);

      // Tocar botón "Vaciar" en el carrito
      await tester.tap(find.text('Vaciar'));
      await tester.pumpAndSettle();

      expect(find.text('Vaciar Análisis y Servicios'), findsOneWidget);
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'Vaciar'),
      ));
      await tester.pumpAndSettle();

      // Vuelve a estar vacío
      expect(find.text('Análisis en la Orden (0)'), findsOneWidget);
      expect(find.text('No has agregado análisis'), findsOneWidget);
    });
  });
}
