import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/lab_test/widgets/quick_create_parameter_dialog.dart';
import 'package:serum_business/serum_business.dart';

class _FakeLabTestsDataSource extends Fake implements LabTestsDataSource {
  Map<String, dynamic>? lastCreated;
  Map<String, dynamic>? lastUpdated;

  @override
  Future<Map<String, dynamic>> createLabTest(Map<String, dynamic> labTest) async {
    final copy = Map<String, dynamic>.from(labTest);
    copy['id'] = 'new-test-${DateTime.now().millisecondsSinceEpoch}';
    copy['createdAt'] = DateTime.now().millisecondsSinceEpoch;
    copy['isDeleted'] = false;
    lastCreated = copy;
    return copy;
  }

  @override
  Future<Map<String, dynamic>?> updateLabTestById(
    String labTestId,
    Map<String, dynamic> labTest,
  ) async {
    final copy = Map<String, dynamic>.from(labTest);
    copy['id'] = labTestId;
    copy['createdAt'] = DateTime.now().millisecondsSinceEpoch;
    copy['isDeleted'] = false;
    lastUpdated = copy;
    return copy;
  }
}

void main() {
  late _FakeLabTestsDataSource fakeDataSource;
  late LabTestsRepository repository;

  setUp(() {
    fakeDataSource = _FakeLabTestsDataSource();
    repository = LabTestsRepository(fakeDataSource);
  });

  testWidgets('QuickCreateParameterDialog crea un parámetro interno con clasificación y subclasificación', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    LabTestInDb? result;

    await tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider<LabTestsRepository>.value(
          value: repository,
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await QuickCreateParameterDialog.show(
                      context,
                      initialCategory: 'Uroanálisis',
                      initialSubclassification: 'Examen Físico-Químico',
                      branchId: 'br-123',
                    );
                  },
                  child: const Text('Abrir Diálogo'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Abrir el diálogo
    await tester.tap(find.text('Abrir Diálogo'));
    await tester.pumpAndSettle();

    expect(find.text('Crear Parámetro de Perfil'), findsOneWidget);
    expect(find.text('Uroanálisis'), findsOneWidget);
    expect(find.text('Examen Físico-Químico'), findsOneWidget);

    // Ingresar nombre
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del Parámetro *'),
      'Color',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Código / Abreviatura'),
      'COL',
    );

    // Cambiar a Cualitativo
    await tester.tap(find.text('Cualitativo / Lista'));
    await tester.pumpAndSettle();

    // Guardar
    await tester.tap(find.text('Crear y Agregar'));
    await tester.pumpAndSettle();

    // Verificar llamada al repositorio
    expect(fakeDataSource.lastCreated, isNotNull);
    expect(fakeDataSource.lastCreated!['name'], 'Color');
    expect(fakeDataSource.lastCreated!['code'], 'COL');
    expect(fakeDataSource.lastCreated!['commercialCategory'], 'Uroanálisis');
    expect(fakeDataSource.lastCreated!['subclassification'], 'Examen Físico-Químico');
    expect(fakeDataSource.lastCreated!['isProfileParameter'], true);
    expect(fakeDataSource.lastCreated!['dataType'], 'qualitative');

    // Verificar resultado devuelto por showDialog
    expect(result, isNotNull);
    expect(result!.name, 'Color');
    expect(result!.isProfileParameter, true);
    expect(result!.subclassification, 'Examen Físico-Químico');
  });

  testWidgets('QuickCreateParameterDialog.showEdit pre-llena los datos y actualiza un parámetro existente', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final existingParameter = LabTestInDb(
      id: 'test-glucosa-1',
      name: 'Glucosa Basal',
      code: 'GLU',
      commercialCategory: 'Química Sanguínea',
      subclassification: 'Química Básica',
      salePrice: 0,
      salePrice2: 0,
      costPrice: 0,
      currency: 'USD',
      isPack: false,
      useChildTestsPriceSum: false,
      childTestIds: const [],
      dataType: 'numeric',
      unitOfMeasure: 'mg/dL',
      referenceValues: [
        ReferenceValue(
          patientType: 'general',
          gender: 'both',
          minAgeDays: 0,
          maxAgeDays: 36500,
          minValue: 70.0,
          maxValue: 100.0,
        ),
      ],
      qualitativeOptions: const [],
      referenceText: '',
      isProfileParameter: true,
      createdAt: 1000,
      isDeleted: false,
    );

    LabTestInDb? result;

    await tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider<LabTestsRepository>.value(
          value: repository,
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await QuickCreateParameterDialog.showEdit(
                      context,
                      parameter: existingParameter,
                      branchId: 'br-123',
                    );
                  },
                  child: const Text('Editar Parámetro'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Abrir el diálogo en modo edición
    await tester.tap(find.text('Editar Parámetro'));
    await tester.pumpAndSettle();

    expect(find.text('Editar Parámetro: Glucosa Basal'), findsOneWidget);
    expect(find.text('Química Sanguínea'), findsOneWidget);
    expect(find.text('Química Básica'), findsOneWidget);

    // Verificar que los campos estén precargados
    expect(find.text('Glucosa Basal'), findsOneWidget);
    expect(find.text('GLU'), findsOneWidget);
    expect(find.text('70.0'), findsOneWidget);
    expect(find.text('100.0'), findsOneWidget);

    // Modificar el rango máximo de 100.0 a 110.0
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Máximo de Referencia'),
      '110',
    );

    // Guardar cambios
    expect(find.text('Guardar Cambios'), findsOneWidget);
    await tester.tap(find.text('Guardar Cambios'));
    await tester.pumpAndSettle();

    // Verificar llamada al repositorio updateLabTestById
    expect(fakeDataSource.lastUpdated, isNotNull);
    expect(fakeDataSource.lastUpdated!['id'], 'test-glucosa-1');
    expect(fakeDataSource.lastUpdated!['name'], 'Glucosa Basal');
    expect(fakeDataSource.lastUpdated!['code'], 'GLU');
    expect(fakeDataSource.lastUpdated!['commercialCategory'], 'Química Sanguínea');
    expect(fakeDataSource.lastUpdated!['subclassification'], 'Química Básica');
    expect(fakeDataSource.lastUpdated!['referenceValues'], isNotEmpty);
    final refs = fakeDataSource.lastUpdated!['referenceValues'] as List;
    expect(refs.first['maxValue'], 110.0);

    // Verificar resultado devuelto por showEdit
    expect(result, isNotNull);
    expect(result!.id, 'test-glucosa-1');
  });

  testWidgets('QuickCreateParameterDialog permite guardar notas de referencia (referenceText) en parámetros numéricos', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    LabTestInDb? result;

    await tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider<LabTestsRepository>.value(
          value: repository,
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await QuickCreateParameterDialog.show(
                      context,
                      initialCategory: 'Química Sanguínea',
                      initialSubclassification: 'Química Básica',
                      branchId: 'br-123',
                    );
                  },
                  child: const Text('Abrir Diálogo'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir Diálogo'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del Parámetro *'),
      'Hemoglobina Glicosilada',
    );

    // Ingresar notas de referencia en modo numérico
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Notas de Referencia / Escala Explicativa (Opcional)'),
      '- Menor de 5.7%: Normal\n- 5.7 a 6.4%: Prediabetes\n- 6.5% o mayor: Diabetes',
    );

    await tester.tap(find.text('Crear y Agregar'));
    await tester.pumpAndSettle();

    expect(fakeDataSource.lastCreated, isNotNull);
    expect(fakeDataSource.lastCreated!['name'], 'Hemoglobina Glicosilada');
    expect(
      fakeDataSource.lastCreated!['referenceText'],
      '- Menor de 5.7%: Normal\n- 5.7 a 6.4%: Prediabetes\n- 6.5% o mayor: Diabetes',
    );
    expect(result, isNotNull);
    expect(result!.referenceText, contains('Prediabetes'));
  });

  testWidgets('QuickCreateParameterDialog en modo cualitativo usa DropdownButtonFormField para valor esperado y guarda notas de referencia', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    LabTestInDb? result;

    await tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider<LabTestsRepository>.value(
          value: repository,
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await QuickCreateParameterDialog.show(
                      context,
                      initialCategory: 'Inmunología',
                      initialSubclassification: 'Serología',
                      branchId: 'br-123',
                    );
                  },
                  child: const Text('Abrir Diálogo'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir Diálogo'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del Parámetro *'),
      'VDRL',
    );

    // Cambiar a Cualitativo
    await tester.tap(find.text('Cualitativo / Lista'));
    await tester.pumpAndSettle();

    // Dropdown para valor esperado debe existir
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(3)); // Cat, Sub, Expected

    // Ingresar opciones personalizadas
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Opciones posibles (separadas por coma) *'),
      'No reactivo, Reactivo débil, Reactivo',
    );
    await tester.pumpAndSettle();

    // Seleccionar 'No reactivo' en el dropdown de valor esperado
    final expectedDropdownFinder = find.byKey(const ValueKey('dialog_expected_No reactivo'));
    expect(expectedDropdownFinder, findsOneWidget);

    // Ingresar notas de referencia
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Notas de Referencia / Escala Explicativa (Opcional)'),
      'Confirmar muestras reactivas mediante FTA-ABS',
    );

    await tester.tap(find.text('Crear y Agregar'));
    await tester.pumpAndSettle();

    expect(fakeDataSource.lastCreated, isNotNull);
    expect(fakeDataSource.lastCreated!['name'], 'VDRL');
    expect(fakeDataSource.lastCreated!['dataType'], 'qualitative');
    expect(fakeDataSource.lastCreated!['qualitativeOptions'], ['No reactivo', 'Reactivo débil', 'Reactivo']);
    expect(fakeDataSource.lastCreated!['expectedQualitativeValue'], 'No reactivo');
    expect(fakeDataSource.lastCreated!['referenceText'], 'Confirmar muestras reactivas mediante FTA-ABS');
    expect(result, isNotNull);
  });

  testWidgets('QuickCreateParameterDialog.showEdit precarga dropdown cualitativo y notas de referencia', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final qualitativeParameter = LabTestInDb(
      id: 'test-vdrl-1',
      name: 'VDRL Cualitativo',
      code: 'VDRL',
      commercialCategory: 'Inmunología',
      subclassification: 'Serología',
      salePrice: 0,
      salePrice2: 0,
      costPrice: 0,
      currency: 'USD',
      isPack: false,
      useChildTestsPriceSum: false,
      childTestIds: const [],
      dataType: 'qualitative',
      unitOfMeasure: '',
      referenceValues: const [],
      qualitativeOptions: const ['No reactivo', 'Reactivo'],
      expectedQualitativeValue: 'No reactivo',
      referenceText: 'Nota original de serología',
      isProfileParameter: true,
      createdAt: 1000,
      isDeleted: false,
    );

    LabTestInDb? result;

    await tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider<LabTestsRepository>.value(
          value: repository,
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await QuickCreateParameterDialog.showEdit(
                      context,
                      parameter: qualitativeParameter,
                      branchId: 'br-123',
                    );
                  },
                  child: const Text('Editar Cualitativo'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Editar Cualitativo'));
    await tester.pumpAndSettle();

    // Dropdown precargado con 'No reactivo'
    expect(find.byKey(const ValueKey('dialog_expected_No reactivo')), findsOneWidget);
    expect(find.text('Nota original de serología'), findsOneWidget);

    // Modificar notas de referencia
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Notas de Referencia / Escala Explicativa (Opcional)'),
      'Nota actualizada de serología clínica',
    );

    await tester.tap(find.text('Guardar Cambios'));
    await tester.pumpAndSettle();

    expect(fakeDataSource.lastUpdated, isNotNull);
    expect(fakeDataSource.lastUpdated!['id'], 'test-vdrl-1');
    expect(fakeDataSource.lastUpdated!['expectedQualitativeValue'], 'No reactivo');
    expect(fakeDataSource.lastUpdated!['referenceText'], 'Nota actualizada de serología clínica');
    expect(result, isNotNull);
  });
}
