import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/lab_test/widgets/pack_composition_editor_dialog.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  final testGlucosa = LabTestInDb(
    id: 'test-glu-1',
    name: 'Glucosa',
    code: 'GLU',
    commercialCategory: 'Química Sanguínea',
    subclassification: 'Química Básica',
    salePrice: 15000,
    salePrice2: 0,
    costPrice: 5000,
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
        minValue: 70,
        maxValue: 100,
      ),
    ],
    qualitativeOptions: const [],
    referenceText: '',
    isProfileParameter: true,
    createdAt: 1000,
    isDeleted: false,
  );

  final testColesterol = LabTestInDb(
    id: 'test-col-2',
    name: 'Colesterol Total',
    code: 'COL',
    commercialCategory: 'Química Sanguínea',
    subclassification: 'Lípidos',
    salePrice: 18000,
    salePrice2: 0,
    costPrice: 6000,
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
        minValue: 0,
        maxValue: 200,
      ),
    ],
    qualitativeOptions: const [],
    referenceText: '',
    isProfileParameter: false,
    createdAt: 2000,
    isDeleted: false,
  );

  final testTrigliceridos = LabTestInDb(
    id: 'test-trig-3',
    name: 'Triglicéridos',
    code: 'TRIG',
    commercialCategory: 'Química Sanguínea',
    subclassification: 'Lípidos',
    salePrice: 20000,
    salePrice2: 0,
    costPrice: 7000,
    currency: 'USD',
    isPack: false,
    useChildTestsPriceSum: false,
    childTestIds: const [],
    dataType: 'numeric',
    unitOfMeasure: 'mg/dL',
    referenceValues: const [],
    qualitativeOptions: const [],
    referenceText: '',
    isProfileParameter: true,
    createdAt: 2500,
    isDeleted: false,
  );

  final testHemograma = LabTestInDb(
    id: 'test-hemo-4',
    name: 'Hemoglobina',
    code: 'HB',
    commercialCategory: 'Hematología',
    subclassification: 'Serie Roja',
    salePrice: 12000,
    salePrice2: 0,
    costPrice: 4000,
    currency: 'USD',
    isPack: false,
    useChildTestsPriceSum: false,
    childTestIds: const [],
    dataType: 'numeric',
    unitOfMeasure: 'g/dL',
    referenceValues: const [],
    qualitativeOptions: const [],
    referenceText: '',
    isProfileParameter: false,
    createdAt: 3000,
    isDeleted: false,
  );

  final List<LabTestInDb> allTests = [
    testGlucosa,
    testColesterol,
    testTrigliceridos,
    testHemograma,
  ];

  Widget buildTestDialog({
    List<String> initialSelected = const [],
    String packName = 'Perfil Lipídico',
    double packSalePrice = 300.0,
    bool useChildTestsPriceSum = false,
    Future<LabTestInDb?> Function()? onQuickCreate,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () async {
                  await PackCompositionEditorDialog.show(
                    context,
                    availableTests: allTests,
                    initialSelectedIds: initialSelected,
                    packName: packName,
                    packSalePrice: packSalePrice,
                    useChildTestsPriceSum: useChildTestsPriceSum,
                    branchId: 'branch_1',
                    onQuickCreateParameter: onQuickCreate,
                  );
                },
                child: const Text('Abrir Editor'),
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets(
    'PackCompositionEditorDialog se abre y renderiza ambos paneles con sus componentes',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestDialog(initialSelected: ['test-col-2']),
      );
      await tester.pumpAndSettle();

      // Abrir el diálogo
      await tester.tap(find.text('Abrir Editor'));
      await tester.pumpAndSettle();

      // Verificar cabecera
      expect(find.text('Editor de Composición del Perfil Clínico'), findsOneWidget);
      expect(find.text('Configurando: Perfil Lipídico'), findsOneWidget);

      // Panel Izquierdo: Catálogo y buscador
      expect(find.text('Catálogo Disponible'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Crear Parámetro'), findsOneWidget);

      // Panel Derecho: Composición actual
      expect(find.text('Contenido del Perfil'), findsOneWidget);
      expect(find.text('1.'), findsOneWidget);
      // 'Colesterol Total' debe aparecer tanto en el catálogo (izq) como en la lista (der)
      expect(find.text('Colesterol Total'), findsAtLeast(1));

      // Botón footer
      expect(find.text('Aplicar Selección (1)'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    },
  );

  testWidgets(
    'Panel Izquierdo filtra por búsqueda de texto reactivamente',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestDialog());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Editor'));
      await tester.pumpAndSettle();

      // Inicialmente se muestran las 4 pruebas en el catálogo
      expect(find.text('Mostrando 4 de 4'), findsOneWidget);

      // Escribir en la barra de búsqueda
      await tester.enterText(find.byType(TextField), 'GLU');
      await tester.pumpAndSettle();

      expect(find.text('Mostrando 1 de 4'), findsOneWidget);
      expect(find.text('Glucosa'), findsOneWidget);
      expect(find.text('Hemoglobina'), findsNothing);
    },
  );

  testWidgets(
    'Panel Izquierdo permite añadir pruebas con clic y actualiza el Panel Derecho',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestDialog(initialSelected: []));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Editor'));
      await tester.pumpAndSettle();

      // Panel derecho inicialmente vacío
      expect(find.text('Aún no hay análisis en este perfil.'), findsOneWidget);
      expect(find.text('Aplicar Selección (0)'), findsOneWidget);

      // Añadir Glucosa haciendo tap en su fila del catálogo
      final gluFinder = find.widgetWithText(InkWell, 'Glucosa');
      expect(gluFinder, findsOneWidget);
      await tester.tap(gluFinder);
      await tester.pumpAndSettle();

      // Ahora el panel derecho tiene 1 elemento
      expect(find.text('Aún no hay análisis en este perfil.'), findsNothing);
      expect(find.text('1.'), findsOneWidget);
      expect(find.text('Aplicar Selección (1)'), findsOneWidget);

      // En el catálogo izquierdo debe mostrar el badge 'Agregado'
      expect(find.text('Agregado'), findsOneWidget);
    },
  );

  testWidgets(
    'Panel Derecho permite reordenar y quitar elementos',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestDialog(initialSelected: ['test-glu-1', 'test-col-2']),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Editor'));
      await tester.pumpAndSettle();

      expect(find.text('Aplicar Selección (2)'), findsOneWidget);
      expect(find.text('1.'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);

      // Mover el primer elemento abajo usando la flecha ▼
      final downArrowFinder = find.byIcon(Icons.arrow_drop_down_rounded);
      expect(downArrowFinder, findsAtLeast(1));
      await tester.tap(downArrowFinder.first);
      await tester.pumpAndSettle();

      // Quitar todos los elementos
      final clearAllFinder = find.text('Quitar todos');
      expect(clearAllFinder, findsOneWidget);
      await tester.tap(clearAllFinder);
      await tester.pumpAndSettle();

      expect(find.text('Aún no hay análisis en este perfil.'), findsOneWidget);
      expect(find.text('Aplicar Selección (0)'), findsOneWidget);
    },
  );

  testWidgets(
    'Crear Parámetro al Vuelo agrega el nuevo parámetro al catálogo y a la selección',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final newParam = LabTestInDb(
        id: 'new-param-99',
        name: 'VCM Eritrocitario',
        code: 'VCM',
        commercialCategory: 'Hematología',
        subclassification: 'Índices Eritrocitarios',
        salePrice: 0,
        isPack: false,
        dataType: 'numeric',
        unitOfMeasure: 'fL',
        isProfileParameter: true,
        createdAt: 9999,
      );

      await tester.pumpWidget(
        buildTestDialog(
          initialSelected: [],
          onQuickCreate: () async => newParam,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Editor'));
      await tester.pumpAndSettle();

      // Pulsar "Crear Parámetro"
      await tester.tap(find.text('Crear Parámetro'));
      await tester.pumpAndSettle();

      // Debe aparecer en el panel derecho y en el contador
      expect(find.text('VCM Eritrocitario'), findsAtLeast(1));
      expect(find.text('Aplicar Selección (1)'), findsOneWidget);
    },
  );

  testWidgets(
    'Cancelar cierra el diálogo sin retornar cambios y Aplicar Selección retorna la lista',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      List<String>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await PackCompositionEditorDialog.show(
                        context,
                        availableTests: allTests,
                        initialSelectedIds: ['test-glu-1'],
                        packSalePrice: 150.0,
                        branchId: 'branch_1',
                      );
                    },
                    child: const Text('Abrir Diálogo'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Probar Cancelar
      await tester.tap(find.text('Abrir Diálogo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(result, isNull);

      // 2. Probar Aplicar Selección
      await tester.tap(find.text('Abrir Diálogo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aplicar Selección (1)'));
      await tester.pumpAndSettle();

      expect(result, equals(['test-glu-1']));
    },
  );
}
