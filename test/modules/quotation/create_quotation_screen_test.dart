import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import 'package:serum_app_front/src/modules/quotation/controllers/create_quotation_mediator.dart';
import 'package:serum_app_front/src/modules/quotation/controllers/create_quotation_view_controller.dart';
import 'package:serum_app_front/src/modules/quotation/view/create_quotation_screen.dart';
import 'package:serum_app_front/src/modules/quotation/widgets/quotation_cart_section.dart';
import 'package:serum_business/serum_business.dart';

class _FakeQuotationsDataSource extends Fake implements QuotationsDataSource {
  @override
  Future<Map<String, dynamic>> createQuotation(Map<String, dynamic> data) async {
    return {'id': 'quote_created_1', ...data};
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
  String get currentBranchDisplayName => 'Sucursal Central';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CreateQuotationScreen & CreateQuotationMediator Integration Tests', () {
    late QuotationsRepository quotationsRepo;
    late PatientsRepository patientsRepo;
    late DoctorsRepository doctorsRepo;
    late LabTestsRepository labTestsRepo;
    late _FakeAppSessionCubit fakeSessionCubit;

    final testItem = LabTestInDb(
      id: 'test_201',
      name: 'Perfil Tiroideo Completo',
      commercialCategory: 'Inmunología',
      salePrice: 45000, // C$ 450.00
      salePrice2: 40000,
      createdAt: 0,
    );

    setUp(() {
      quotationsRepo = QuotationsRepository(_FakeQuotationsDataSource());
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
          RepositoryProvider<QuotationsRepository>.value(value: quotationsRepo),
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
            home: CreateQuotationScreen(),
          ),
        ),
      );
    }

    testWidgets('CreateQuotationMediator propaga correctamente el controlador a QuotationCartSection', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = CreateQuotationViewController();
      controller.toggleItem(testItem);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreateQuotationMediator(
              viewController: controller,
              child: const SizedBox(
                width: 600,
                height: 900,
                child: QuotationCartSection(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe leer el ítem del controlador automáticamente
      expect(find.text('Análisis Cotizados (1)'), findsOneWidget);
      expect(find.text('Perfil Tiroideo Completo'), findsOneWidget);
      expect(find.textContaining('450.00'), findsWidgets);

      // Cambiar tarifa a P2
      controller.changeItemPriceLevel(testItem.id, 2);
      await tester.pumpAndSettle();

      expect(find.text('P2'), findsOneWidget);
      expect(find.textContaining('400.00'), findsWidgets);

      controller.dispose();
    });

    testWidgets('CreateQuotationScreen renderiza catálogo, carrito y reacciona a selección de análisis', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Encabezado
      expect(find.text('Nueva Cotización de Análisis'), findsOneWidget);
      expect(find.text('Sucursal Central'), findsOneWidget);

      // Carrito inicialmente vacío
      expect(find.text('Análisis Cotizados (0)'), findsOneWidget);
      expect(find.text('No has agregado análisis al presupuesto'), findsOneWidget);

      // Tocar análisis en el catálogo para agregarlo
      final testFinder = find.text('Perfil Tiroideo Completo');
      expect(testFinder, findsOneWidget);
      await tester.tap(testFinder);
      await tester.pumpAndSettle();

      // Debe aparecer en el carrito
      expect(find.text('Análisis Cotizados (1)'), findsWidgets);
      expect(find.textContaining('450.00'), findsWidgets);

      // Presionar vaciar
      await tester.tap(find.text('Vaciar'));
      await tester.pumpAndSettle();

      expect(find.text('Vaciar Cotización'), findsOneWidget);
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'Vaciar'),
      ));
      await tester.pumpAndSettle();

      // Vuelve a estar vacío
      expect(find.text('Análisis Cotizados (0)'), findsOneWidget);
      expect(find.text('No has agregado análisis al presupuesto'), findsOneWidget);
    });
  });
}
