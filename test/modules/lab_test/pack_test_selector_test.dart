import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/lab_test/widgets/pack_test_selector.dart';
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

  final List<LabTestInDb> allTests = [testGlucosa, testColesterol];

  testWidgets('PackTestSelector muestra la sección superior de parámetros seleccionados con visor y acciones', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    List<String> selected = ['test-glu-1', 'test-col-2'];
    LabTestInDb? editedTest;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: PackTestSelector(
                  availableTests: allTests,
                  selectedTestIds: selected,
                  packSalePrice: 330.0,
                  useChildTestsPriceSum: true,
                  onSelectionChanged: (updated) {
                    setState(() {
                      selected = updated;
                    });
                  },
                  onEditTest: (test) {
                    editedTest = test;
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verificar encabezado de la sección superior
    expect(find.text('Parámetros y Análisis en este Perfil'), findsOneWidget);
    expect(find.text('2'), findsWidgets); // Contador de 2 seleccionados

    // 2. Verificar que muestra Glucosa con su resumen de referencia y badge
    expect(find.text('Glucosa'), findsWidgets);
    expect(find.text('GLU'), findsWidgets);
    expect(find.text('Parámetro'), findsWidgets); // isProfileParameter = true
    expect(find.text('Ref: 70 - 100 mg/dL'), findsOneWidget);

    // 3. Verificar que muestra Colesterol
    expect(find.text('Colesterol Total'), findsWidgets);
    expect(find.text('COL'), findsWidgets);
    expect(find.text('Ref: 0 - 200 mg/dL'), findsOneWidget);

    // 4. Verificar presencia del botón de edición con lápiz y pulsarlo
    final editButtons = find.byIcon(Icons.edit_outlined);
    expect(editButtons, findsWidgets);

    // Verificar presencia de handles de arrastre y flechas de orden
    expect(find.byIcon(Icons.drag_indicator_rounded), findsWidgets);
    expect(find.byIcon(Icons.arrow_drop_up_rounded), findsWidgets);
    expect(find.byIcon(Icons.arrow_drop_down_rounded), findsWidgets);

    // Hacer tap en el lápiz del primer parámetro (Glucosa)
    await tester.tap(editButtons.first);
    await tester.pumpAndSettle();
    expect(editedTest, isNotNull);
    expect(editedTest!.id, 'test-glu-1');
    expect(editedTest!.name, 'Glucosa');

    // 5. Verificar que al presionar el botón remover (remove_circle_outline) se quita de la selección
    final removeButtons = find.byIcon(Icons.remove_circle_outline);
    expect(removeButtons, findsWidgets);

    // Quitar el primer parámetro (Glucosa)
    await tester.tap(removeButtons.first);
    await tester.pumpAndSettle();

    expect(selected, ['test-col-2']);

    // 6. Verificar que la sección del catálogo inferior existe debajo del divisor
    expect(find.text('Agregar Más Análisis desde el Catálogo'), findsOneWidget);
  });

  testWidgets('PackTestSelector muestra banner informativo cuando no hay análisis seleccionados', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PackTestSelector(
            availableTests: allTests,
            selectedTestIds: const [],
            packSalePrice: 0.0,
            useChildTestsPriceSum: true,
            onSelectionChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Parámetros y Análisis en este Perfil'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    expect(
      find.text('Aún no hay análisis o parámetros asignados a este perfil. Búscalos en el catálogo inferior o haz clic en "Crear Parámetro en este Perfil".'),
      findsOneWidget,
    );
  });

  testWidgets('PackTestSelector reordena los parámetros correctamente usando las flechas de orden', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    List<String> selected = ['test-glu-1', 'test-col-2'];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: PackTestSelector(
                  availableTests: allTests,
                  selectedTestIds: selected,
                  packSalePrice: 330.0,
                  useChildTestsPriceSum: true,
                  onSelectionChanged: (updated) {
                    setState(() {
                      selected = updated;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Orden inicial: Glucosa (0), Colesterol (1)
    expect(selected, ['test-glu-1', 'test-col-2']);

    // Bajar Glucosa (primer botón de flecha abajo)
    final downButtons = find.byTooltip('Mover abajo');
    expect(downButtons, findsWidgets);

    await tester.tap(downButtons.first);
    await tester.pumpAndSettle();

    // Ahora Colesterol está de primero y Glucosa de segundo
    expect(selected, ['test-col-2', 'test-glu-1']);

    // Subir Glucosa (segundo botón de flecha arriba, ahora en posición 1)
    final upButtons = find.byTooltip('Mover arriba');
    expect(upButtons, findsWidgets);

    await tester.tap(upButtons.at(1));
    await tester.pumpAndSettle();

    // Restaurado al orden original
    expect(selected, ['test-glu-1', 'test-col-2']);
  });
}
