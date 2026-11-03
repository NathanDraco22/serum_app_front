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

class _FakeDoctorsDataSource extends Fake implements DoctorsDataSource {
  final List<Map<String, dynamic>> doctors = [
    {
      'id': 'doc-123',
      'name': 'Dra. María Elena Ramos',
      'specialty': 'Pediatría',
      'phone': '8888-9999',
      'cardId': 'MED-1234',
      'email': 'maria@example.com',
      'originBranch': 'branch-1',
    }
  ];

  @override
  Future<Map<String, dynamic>> getAllDoctors({String? originBranch}) async {
    return {'data': doctors, 'count': doctors.length};
  }

  @override
  Future<Map<String, dynamic>> searchDoctorsByText(String text, {String? originBranch}) async {
    return {'data': doctors, 'count': doctors.length};
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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateOrder serialization tests', () {
    test('clearDoctor: true serializa doctorId y doctorInfo como null', () {
      final update = UpdateOrder(clearDoctor: true);
      final json = update.toJson();
      expect(json.containsKey('doctorId'), isTrue);
      expect(json['doctorId'], isNull);
      expect(json.containsKey('doctorInfo'), isTrue);
      expect(json['doctorInfo'], isNull);
    });

    test('Asignación de médico serializa los valores correctamente', () {
      final update = UpdateOrder(
        doctorId: 'doc-999',
        doctorInfo: DoctorInfo(
          name: 'Dr. Roberto Mendoza',
          specialty: 'Cardiología',
          phone: '12345678',
        ),
      );
      final json = update.toJson();
      expect(json['doctorId'], equals('doc-999'));
      expect(json['doctorInfo']['name'], equals('Dr. Roberto Mendoza'));
      expect(json['doctorInfo']['specialty'], equals('Cardiología'));
    });
  });

  group('OrdersList Doctor Tag Tests', () {
    late _FakeOrdersDataSource fakeOrdersDataSource;
    late _FakePatientsDataSource fakePatientsDataSource;
    late _FakeDoctorsDataSource fakeDoctorsDataSource;
    late OrdersRepository ordersRepository;
    late PatientsRepository patientsRepository;
    late DoctorsRepository doctorsRepository;
    late WriteOrderCubit writeOrderCubit;
    late ReadOrderCubit readOrderCubit;
    late ReadPatientCubit readPatientCubit;
    late _FakeAppSessionCubit fakeAppSessionCubit;

    setUp(() {
      fakeOrdersDataSource = _FakeOrdersDataSource();
      fakePatientsDataSource = _FakePatientsDataSource();
      fakeDoctorsDataSource = _FakeDoctorsDataSource();

      ordersRepository = OrdersRepository(fakeOrdersDataSource);
      patientsRepository = PatientsRepository(fakePatientsDataSource);
      doctorsRepository = DoctorsRepository(fakeDoctorsDataSource);

      writeOrderCubit = WriteOrderCubit(ordersRepository: ordersRepository);
      readOrderCubit = ReadOrderCubit(ordersRepository: ordersRepository);
      readPatientCubit = ReadPatientCubit(patientsRepository: patientsRepository);
      fakeAppSessionCubit = _FakeAppSessionCubit();
    });

    tearDown(() async {
      await writeOrderCubit.close();
      await readOrderCubit.close();
      await readPatientCubit.close();
      await fakeAppSessionCubit.close();
    });

    Widget buildTestWidget(List<OrderInDb> orders) {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider<OrdersRepository>.value(value: ordersRepository),
          RepositoryProvider<PatientsRepository>.value(value: patientsRepository),
          RepositoryProvider<DoctorsRepository>.value(value: doctorsRepository),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<WriteOrderCubit>.value(value: writeOrderCubit),
            BlocProvider<ReadOrderCubit>.value(value: readOrderCubit),
            BlocProvider<ReadPatientCubit>.value(value: readPatientCubit),
            BlocProvider<AppSessionCubit>.value(value: fakeAppSessionCubit),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: OrdersList(
                orders: orders,
                onEditResults: (_) {},
                onPayOrder: (_) {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Muestra tag de "Sin médico remitente" cuando la orden no tiene doctor', (tester) async {
      final orderWithoutDoctor = OrderInDb(
        id: 'ord-100',
        patientId: 'pat-1',
        branchId: 'branch-1',
        patientInfo: PatientInfo(name: 'Juan Pérez', age: 30),
        doctorId: null,
        doctorInfo: null,
        items: [
          OrderItem(
            labTestId: 'lt-1',
            name: 'Biometría Hemática',
            salePriceApplied: 25000,
          ),
        ],
        totalPrice: 25000,
        paidAmount: 25000,
        status: 'pending',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidget(buildTestWidget([orderWithoutDoctor]));
      await tester.pumpAndSettle();

      expect(find.text('Sin médico remitente (Click para asignar)'), findsOneWidget);
      expect(find.byIcon(Icons.person_add_alt_1_outlined), findsOneWidget);
    });

    testWidgets('Muestra tag con nombre de médico cuando la orden tiene doctor asignado', (tester) async {
      final orderWithDoctor = OrderInDb(
        id: 'ord-200',
        patientId: 'pat-2',
        branchId: 'branch-1',
        patientInfo: PatientInfo(name: 'Ana López', age: 25),
        doctorId: 'doc-123',
        doctorInfo: DoctorInfo(name: 'Dra. María Elena Ramos', specialty: 'Pediatría'),
        items: [
          OrderItem(
            labTestId: 'lt-2',
            name: 'Glucosa en Ayunas',
            salePriceApplied: 15000,
          ),
        ],
        totalPrice: 15000,
        paidAmount: 15000,
        status: 'pending',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidget(buildTestWidget([orderWithDoctor]));
      await tester.pumpAndSettle();

      expect(find.text('Médico: Dra. María Elena Ramos'), findsOneWidget);
      expect(find.byIcon(Icons.medical_services_outlined), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('Desvincular médico muestra confirmación y envía UpdateOrder(clearDoctor: true)', (tester) async {
      final orderWithDoctor = OrderInDb(
        id: 'ord-300',
        patientId: 'pat-3',
        branchId: 'branch-1',
        patientInfo: PatientInfo(name: 'Carlos Gómez', age: 40),
        doctorId: 'doc-123',
        doctorInfo: DoctorInfo(name: 'Dra. María Elena Ramos', specialty: 'Pediatría'),
        items: [
          OrderItem(
            labTestId: 'lt-3',
            name: 'Perfil Lipídico',
            salePriceApplied: 35000,
          ),
        ],
        totalPrice: 35000,
        paidAmount: 35000,
        status: 'pending',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      fakeOrdersDataSource.setOrder('ord-300', orderWithDoctor.toJson());

      await tester.pumpWidget(buildTestWidget([orderWithDoctor]));
      await tester.pumpAndSettle();

      // Pulsar la 'x' para desvincular
      final closeButtonFinder = find.byIcon(Icons.close);
      expect(closeButtonFinder, findsOneWidget);
      await tester.tap(closeButtonFinder);
      await tester.pumpAndSettle();

      // Verificar que se abrió el diálogo de confirmación
      expect(find.text('Quitar Médico Remitente'), findsOneWidget);
      expect(find.text('Quitar Médico'), findsOneWidget);

      // Confirmar la acción
      await tester.tap(find.text('Quitar Médico'));
      await tester.pumpAndSettle();

      // Verificar que se llamó a updateOrderById con los campos en null
      expect(fakeOrdersDataSource.lastUpdatedId, equals('ord-300'));
      expect(fakeOrdersDataSource.lastUpdatedData?['doctorId'], isNull);
      expect(fakeOrdersDataSource.lastUpdatedData?['doctorInfo'], isNull);
    });
  });
}
