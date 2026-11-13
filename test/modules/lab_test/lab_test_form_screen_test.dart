import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import 'package:serum_app_front/src/cubits/lab_test_cubit/write_lab_tests_cubit.dart';
import 'package:serum_app_front/src/modules/lab_test/controllers/lab_test_form_mediator.dart';
import 'package:serum_app_front/src/modules/lab_test/view/lab_test_form_screen.dart';
import 'package:serum_app_front/src/modules/lab_test/widgets/sections/lab_test_general_info_section.dart';
import 'package:serum_app_front/src/modules/lab_test/widgets/sections/lab_test_pack_children_section.dart';
import 'package:serum_app_front/src/modules/lab_test/widgets/sections/lab_test_pricing_section.dart';
import 'package:serum_app_front/src/modules/lab_test/widgets/sections/lab_test_reference_values_section.dart';
import 'package:serum_business/serum_business.dart';

class _FakeLabTestsDataSource extends Fake implements LabTestsDataSource {
  final List<Map<String, dynamic>> items;
  Map<String, dynamic>? lastCreated;

  _FakeLabTestsDataSource({this.items = const []});

  @override
  Future<Map<String, dynamic>> getAllLabTests({String? branchId}) async {
    return {'data': items, 'count': items.length};
  }

  @override
  Future<Map<String, dynamic>> createLabTest(Map<String, dynamic> labTest) async {
    final copy = Map<String, dynamic>.from(labTest);
    copy['id'] = 'new-test-created-1';
    copy['createdAt'] = DateTime.now().millisecondsSinceEpoch;
    copy['isDeleted'] = false;
    lastCreated = copy;
    return copy;
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
  late _FakeLabTestsDataSource fakeDataSource;
  late LabTestsRepository repository;
  late ReadLabTestCubit readLabTestCubit;
  late WriteLabTestCubit writeLabTestCubit;
  late _FakeAppSessionCubit sessionCubit;

  setUp(() {
    fakeDataSource = _FakeLabTestsDataSource(
      items: [
        {
          'id': 'test-1',
          'name': 'Glucosa',
          'commercialCategory': 'Química Sanguínea',
          'subclassification': 'General',
          'salePrice': 1000,
          'salePrice2': 0,
          'costPrice': 0,
          'currency': 'USD',
          'isPack': false,
          'useChildTestsPriceSum': false,
          'childTestIds': [],
          'dataType': 'numeric',
          'unitOfMeasure': 'mg/dL',
          'referenceValues': [],
          'qualitativeOptions': [],
          'referenceText': '',
          'isProfileParameter': false,
          'createdAt': 0,
          'updatedAt': 0,
        },
        {
          'id': 'pack-pcr',
          'name': 'Proteína C Reactiva (PCR)',
          'commercialCategory': 'Inmunología',
          'subclassification': 'Enfermedades Autoinmunes',
          'salePrice': 28000,
          'salePrice2': 0,
          'costPrice': 0,
          'currency': 'USD',
          'isPack': true,
          'useChildTestsPriceSum': true,
          'childTestIds': ['test-1'],
          'dataType': 'numeric',
          'unitOfMeasure': '',
          'referenceValues': [],
          'qualitativeOptions': [],
          'referenceText': '',
          'isProfileParameter': false,
          'createdAt': 0,
          'updatedAt': 0,
        },
      ],
    );
    repository = LabTestsRepository(fakeDataSource);
    readLabTestCubit = ReadLabTestCubit(labTestsRepository: repository);
    writeLabTestCubit = WriteLabTestCubit(labTestsRepository: repository);
    sessionCubit = _FakeAppSessionCubit();
  });

  tearDown(() {
    readLabTestCubit.close();
    writeLabTestCubit.close();
    sessionCubit.close();
  });

  Widget buildTestWidget({LabTestInDb? labTest}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppSessionCubit>.value(value: sessionCubit),
        BlocProvider<ReadLabTestCubit>.value(value: readLabTestCubit),
        BlocProvider<WriteLabTestCubit>.value(value: writeLabTestCubit),
      ],
      child: MaterialApp(
        home: LabTestFormScreen(labTest: labTest),
      ),
    );
  }

  testWidgets('LabTestFormScreen se renderiza con Mediator y subsecciones individuales', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Comprobar presencia del Mediator en el árbol
    expect(find.byType(LabTestFormMediator), findsOneWidget);

    // Comprobar presencia de las subsecciones
    expect(find.byType(LabTestGeneralInfoSection), findsOneWidget);
    expect(find.byType(LabTestPricingSection), findsOneWidget);
    expect(find.byType(LabTestReferenceValuesSection), findsOneWidget);

    // Por defecto es individual, la sección de pack no debe mostrar contenido interno
    expect(find.text('Composición del Perfil / Pack'), findsNothing);

    // Título y AppBar
    expect(find.text('Registrar Nueva Prueba / Pack'), findsOneWidget);
    expect(find.text('Configurando Parámetro Clínico Individual'), findsOneWidget);
  });

  testWidgets('El campo Unidad de Medida permite escribir libremente y conserva el cursor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final controller =
        tester.widget<LabTestFormMediator>(find.byType(LabTestFormMediator)).viewController;
    final unitField = find.byWidgetPredicate(
      (widget) => widget is TextFormField && widget.controller == controller.unitController,
    );
    expect(unitField, findsOneWidget);

    await tester.ensureVisible(unitField);
    await tester.pumpAndSettle();
    await tester.enterText(unitField, 'UI/L');
    await tester.pump();

    expect(controller.unitOfMeasure, 'UI/L');
    expect(controller.unitController.text, 'UI/L');
    expect(
      controller.unitController.selection,
      const TextSelection.collapsed(offset: 4),
    );

    final chip = find.widgetWithText(ActionChip, 'g/dL');
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pump();

    expect(controller.unitOfMeasure, 'g/dL');
    expect(controller.unitController.text, 'g/dL');
    expect(
      controller.unitController.selection,
      const TextSelection.collapsed(offset: 4),
    );
  });

  testWidgets(
    'Conmutar modalidad a Pack actualiza Mediator y despliega LabTestPackChildrenSection',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Obtener controlador desde el mediator
      final mediatorFinder = find.byType(LabTestFormMediator);
      final mediatorWidget = tester.widget<LabTestFormMediator>(mediatorFinder);
      final controller = mediatorWidget.viewController;

      // Cambiar a pack mediante el controlador
      controller.setIsPack(true);
      await tester.pumpAndSettle();

      // Subtítulo debe cambiar reactivamente
      expect(find.text('Configurando Paquete Comercial (Pack de Análisis)'), findsOneWidget);

      // Sección de pack debe estar visible
      expect(find.byType(LabTestPackChildrenSection), findsOneWidget);
      expect(find.text('Composición del Perfil / Pack'), findsOneWidget);

      // Sección de rangos de referencia no debe estar visible
      expect(find.text('Configuración Analítica y Rangos de Referencia'), findsNothing);
    },
  );

  testWidgets('Submit despacha DTO a WriteLabTestCubit cuando el formulario es válido', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final mediatorFinder = find.byType(LabTestFormMediator);
    final mediatorWidget = tester.widget<LabTestFormMediator>(mediatorFinder);
    final controller = mediatorWidget.viewController;

    // Rellenar datos
    controller.nameController.text = 'Perfil Hepático';
    controller.codeController.text = 'HEP-01';
    controller.priceController.text = '25.00';
    controller.unitController.text = 'mg/dL';
    await tester.pumpAndSettle();

    // Presionar el botón guardar
    final saveButton = find.text('Registrar Prueba');
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(fakeDataSource.lastCreated, isNotNull);
    expect(fakeDataSource.lastCreated!['name'], 'Perfil Hepático');
    expect(fakeDataSource.lastCreated!['code'], 'HEP-01');
    expect(fakeDataSource.lastCreated!['salePrice'], 2500);
  });

  testWidgets(
    'LabTestFormScreen permite seleccionar otros packs de forma segura y excluye al pack en edición',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Cargar catálogo inicial
      await readLabTestCubit.getAll(branchId: 'branch_1');

      // 1. Al crear un pack nuevo (labTest == null), otros packs como 'pack-pcr' deben estar disponibles
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final mediatorFinder = find.byType(LabTestFormMediator);
      final mediatorWidget = tester.widget<LabTestFormMediator>(mediatorFinder);
      mediatorWidget.viewController.setIsPack(true);
      await tester.pumpAndSettle();

      final packSectionFinder = find.byType(LabTestPackChildrenSection);
      expect(packSectionFinder, findsOneWidget);

      final packSection = tester.widget<LabTestPackChildrenSection>(packSectionFinder);
      final availableIds = packSection.allAvailableTests.map((t) => t.id).toList();

      // Debe incluir tanto 'test-1' (atómico) como 'pack-pcr' (otro pack seguro)
      expect(availableIds, containsAll(['test-1', 'pack-pcr']));

      // 2. Al editar 'pack-pcr', el ciclo guard debe excluir 'pack-pcr' de sus propios disponibles
      final existingPack = LabTestInDb(
        id: 'pack-pcr',
        name: 'Proteína C Reactiva (PCR)',
        isPack: true,
        childTestIds: ['test-1'],
        createdAt: 0,
      );

      await tester.pumpWidget(buildTestWidget(labTest: existingPack));
      await tester.pumpAndSettle();

      final editSection = tester.widget<LabTestPackChildrenSection>(
        find.byType(LabTestPackChildrenSection),
      );
      final editAvailableIds = editSection.allAvailableTests.map((t) => t.id).toList();

      expect(editAvailableIds.contains('test-1'), isTrue);
      expect(editAvailableIds.contains('pack-pcr'), isFalse); // Excluido por anti-cycle guard
    },
  );
}
