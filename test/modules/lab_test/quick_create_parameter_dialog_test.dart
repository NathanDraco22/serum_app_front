import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/lab_test/widgets/quick_create_parameter_dialog.dart';
import 'package:serum_business/serum_business.dart';

String? _fieldText(WidgetTester tester, String key) {
  return tester.widget<TextFormField>(find.byKey(ValueKey(key))).controller?.text;
}

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

  testWidgets(
    'QuickCreateParameterDialog crea un parámetro interno con clasificación y subclasificación',
    (tester) async {
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
    },
  );

  testWidgets(
    'QuickCreateParameterDialog.showEdit pre-llena los datos y actualiza un parámetro existente',
    (tester) async {
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

      // El editor de rangos inicia colapsado en edición y muestra el resumen.
      expect(find.text('Rangos de referencia'), findsOneWidget);
      expect(find.text('1 rango configurado'), findsOneWidget);
      expect(find.byKey(const ValueKey('ref_max_value_0')), findsNothing);

      // Expandir el editor de rangos
      await tester.tap(find.text('Rangos de referencia'));
      await tester.pumpAndSettle();

      expect(find.text('Rango 1'), findsOneWidget);
      expect(_fieldText(tester, 'ref_min_value_0'), '70');
      expect(_fieldText(tester, 'ref_max_value_0'), '100');

      // Modificar el rango máximo de 100 a 110
      await tester.enterText(
        find.byKey(const ValueKey('ref_max_value_0')),
        '110',
      );
      await tester.pumpAndSettle();

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
      expect(refs, hasLength(1));
      expect(refs.first['minValue'], 70.0);
      expect(refs.first['maxValue'], 110.0);
      expect(refs.first['ageUnit'], 'years');
      expect(refs.first['useAge'], false);
      expect(refs.first['useGender'], false);

      // Verificar resultado devuelto por showEdit
      expect(result, isNotNull);
      expect(result!.id, 'test-glucosa-1');
    },
  );

  testWidgets(
    'QuickCreateParameterDialog permite guardar notas de referencia (referenceText) en parámetros numéricos',
    (tester) async {
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
    },
  );

  testWidgets(
    'QuickCreateParameterDialog en modo cualitativo usa DropdownButtonFormField para valor esperado y guarda notas de referencia',
    (tester) async {
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
      expect(fakeDataSource.lastCreated!['qualitativeOptions'], [
        'No reactivo',
        'Reactivo débil',
        'Reactivo',
      ]);
      expect(fakeDataSource.lastCreated!['expectedQualitativeValue'], 'No reactivo');
      expect(
        fakeDataSource.lastCreated!['referenceText'],
        'Confirmar muestras reactivas mediante FTA-ABS',
      );
      expect(result, isNotNull);
    },
  );

  testWidgets(
    'QuickCreateParameterDialog.showEdit precarga dropdown cualitativo y notas de referencia',
    (tester) async {
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
    },
  );

  testWidgets(
    'QuickCreateParameterDialog muestra el editor de rangos numéricos y envía ageUnit y flags',
    (tester) async {
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

      // El bloque aparece expandido por defecto en un parámetro nuevo.
      expect(find.text('Rangos de referencia'), findsOneWidget);
      expect(find.text('1 rango configurado'), findsOneWidget);
      expect(find.text('Rango 1'), findsOneWidget);

      // Al cambiar a cualitativo el bloque se oculta.
      await tester.tap(find.text('Cualitativo / Lista'));
      await tester.pumpAndSettle();
      expect(find.text('Rangos de referencia'), findsNothing);

      // Al volver a numérico el bloque se recrea expandido.
      await tester.tap(find.text('Numérico'));
      await tester.pumpAndSettle();
      expect(find.text('Rangos de referencia'), findsOneWidget);
      expect(find.text('Rango 1'), findsOneWidget);

      // Activar "Rangos por edad" muestra el dropdown de unidad de edad.
      final ageSwitch = find.descendant(
        of: find.byKey(const ValueKey('ref_use_age')),
        matching: find.byType(Switch),
      );
      await tester.ensureVisible(ageSwitch);
      await tester.pumpAndSettle();
      await tester.tap(ageSwitch);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ref_age_unit_0')),
          matching: find.byType(DropdownButtonFormField<String>),
        ),
        findsOneWidget,
      );

      // Activar también "Rangos por género" para validar ambos flags.
      final genderSwitch = find.descendant(
        of: find.byKey(const ValueKey('ref_use_gender')),
        matching: find.byType(Switch),
      );
      await tester.ensureVisible(genderSwitch);
      await tester.pumpAndSettle();
      await tester.tap(genderSwitch);
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextFormField, 'Nombre del Parámetro *');
      await tester.ensureVisible(nameField);
      await tester.pumpAndSettle();
      await tester.enterText(nameField, 'Glucosa Rápida');

      await tester.tap(find.text('Crear y Agregar'));
      await tester.pumpAndSettle();

      expect(fakeDataSource.lastCreated, isNotNull);
      final refs = fakeDataSource.lastCreated!['referenceValues'] as List;
      expect(refs, hasLength(1));
      final ref = refs.first as Map<String, dynamic>;
      expect(ref['patientType'], 'general');
      expect(ref['gender'], 'both');
      expect(ref['minAgeDays'], 0);
      expect(ref['maxAgeDays'], 36500);
      expect(ref['minValue'], 0.0);
      expect(ref['maxValue'], 100.0);
      expect(ref['ageUnit'], 'years');
      expect(ref['useAge'], true);
      expect(ref['useGender'], true);
      expect(result, isNotNull);
      expect(result!.referenceValues.single.useAge, isTrue);
      expect(result!.referenceValues.single.useGender, isTrue);
      expect(result!.referenceValues.single.ageUnit, 'years');
    },
  );

  testWidgets(
    'QuickCreateParameterDialog.showEdit conserva múltiples rangos y sus flags al editar',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final existingParameter = LabTestInDb(
        id: 'test-multiple-ranges',
        name: 'Hemoglobina por Edad',
        code: 'HB',
        commercialCategory: 'Hematología',
        subclassification: 'Serie Roja',
        salePrice: 0,
        salePrice2: 0,
        costPrice: 0,
        currency: 'USD',
        isPack: false,
        useChildTestsPriceSum: false,
        childTestIds: const [],
        dataType: 'numeric',
        unitOfMeasure: 'g/dL',
        referenceValues: [
          ReferenceValue(
            patientType: 'general',
            gender: 'male',
            minAgeDays: 0,
            maxAgeDays: 365,
            minValue: 12.0,
            maxValue: 16.0,
            ageUnit: 'months',
            useAge: true,
            useGender: true,
          ),
          ReferenceValue(
            patientType: 'general',
            gender: 'female',
            minAgeDays: 365,
            maxAgeDays: 7300,
            minValue: 11.0,
            maxValue: 15.0,
            ageUnit: 'years',
            useAge: true,
            useGender: true,
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
                    child: const Text('Editar Múltiples Rangos'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Editar Múltiples Rangos'));
      await tester.pumpAndSettle();

      // Colapsado por defecto, pero con el resumen de rangos.
      expect(find.text('2 rangos configurados'), findsOneWidget);
      expect(find.text('Rango 1'), findsNothing);

      await tester.tap(find.text('Rangos de referencia'));
      await tester.pumpAndSettle();

      expect(find.text('Rango 1'), findsOneWidget);
      expect(find.text('Rango 2'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ref_age_unit_0')),
          matching: find.byType(DropdownButtonFormField<String>),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ref_age_unit_1')),
          matching: find.byType(DropdownButtonFormField<String>),
        ),
        findsOneWidget,
      );

      expect(_fieldText(tester, 'ref_max_value_0'), '16');
      await tester.enterText(
        find.byKey(const ValueKey('ref_max_value_0')),
        '16.5',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar Cambios'));
      await tester.pumpAndSettle();

      expect(fakeDataSource.lastUpdated, isNotNull);
      final refs = fakeDataSource.lastUpdated!['referenceValues'] as List;
      expect(refs, hasLength(2));

      final first = refs[0] as Map<String, dynamic>;
      expect(first['maxValue'], 16.5);
      expect(first['gender'], 'male');
      expect(first['ageUnit'], 'months');
      expect(first['useAge'], true);
      expect(first['useGender'], true);

      final second = refs[1] as Map<String, dynamic>;
      expect(second['minValue'], 11.0);
      expect(second['maxValue'], 15.0);
      expect(second['gender'], 'female');
      expect(second['ageUnit'], 'years');
      expect(second['useAge'], true);
      expect(second['useGender'], true);
      expect(result, isNotNull);
      expect(result!.referenceValues, hasLength(2));
    },
  );
}
