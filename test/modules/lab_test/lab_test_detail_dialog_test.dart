import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/lab_test/widgets/lab_test_detail_dialog.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  final testGlucosa = LabTestInDb(
    id: 'test-glu-1',
    name: 'Glucosa en Sangre',
    code: 'GLU',
    commercialCategory: 'Química Sanguínea',
    subclassification: 'Metabolismo',
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
    referenceText: 'Muestra en ayunas de 8 horas.',
    isProfileParameter: false,
    createdAt: 1000,
    isDeleted: false,
  );

  final testHiv = LabTestInDb(
    id: 'test-hiv-2',
    name: 'VIH 1+2 Prueba Rápida',
    code: 'VIH',
    commercialCategory: 'Inmunología',
    subclassification: 'Serología',
    salePrice: 20000,
    salePrice2: 0,
    costPrice: 8000,
    currency: 'USD',
    isPack: false,
    useChildTestsPriceSum: false,
    childTestIds: const [],
    dataType: 'qualitative',
    unitOfMeasure: '',
    referenceValues: const [],
    qualitativeOptions: const ['No Reactivo', 'Reactivo'],
    expectedQualitativeValue: 'No Reactivo',
    referenceText: '',
    isProfileParameter: false,
    createdAt: 2000,
    isDeleted: false,
  );

  final testColesterol = LabTestInDb(
    id: 'test-col-3',
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
    isProfileParameter: true,
    createdAt: 3000,
    isDeleted: false,
  );

  final packChequeo = LabTestInDb(
    id: 'pack-chequeo-1',
    name: 'Perfil Metabólico Básico',
    code: 'PERF-MET',
    commercialCategory: 'Perfiles Clínicos',
    subclassification: 'Checkup',
    salePrice: 45000,
    salePrice2: 0,
    costPrice: 15000,
    currency: 'USD',
    isPack: true,
    useChildTestsPriceSum: false,
    childTestIds: const ['test-col-3', 'test-glu-1', 'test-hiv-2'],
    dataType: 'numeric',
    unitOfMeasure: '',
    referenceValues: const [],
    qualitativeOptions: const [],
    referenceText: '',
    isProfileParameter: false,
    createdAt: 4000,
    isDeleted: false,
  );

  final allTests = [testGlucosa, testHiv, testColesterol, packChequeo];

  Widget buildDialog(LabTestInDb test, {void Function(LabTestInDb)? onEditPrice}) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        body: Center(
          child: LabTestDetailDialog(
            labTest: test,
            allLabTests: allTests,
            onEditPrice: onEditPrice,
          ),
        ),
      ),
    );
  }

  testWidgets('Renderiza detalles de prueba individual numérica correctamente', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildDialog(testGlucosa));
    await tester.pumpAndSettle();

    expect(find.text('Glucosa en Sangre'), findsOneWidget);
    expect(find.text('INDIVIDUAL'), findsOneWidget);
    expect(find.text('Clave / Código: GLU'), findsOneWidget);
    expect(find.text('Valores y Rangos de Referencia'), findsOneWidget);
    expect(find.text('70.0 - 100.0 mg/dL'), findsOneWidget);
    expect(find.text('Muestra en ayunas de 8 horas.'), findsOneWidget);
  });

  testWidgets('Renderiza detalles de prueba individual cualitativa correctamente', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildDialog(testHiv));
    await tester.pumpAndSettle();

    expect(find.text('VIH 1+2 Prueba Rápida'), findsOneWidget);
    expect(find.text('Configuración Cualitativa'), findsOneWidget);
    expect(find.text('No Reactivo, Reactivo'), findsOneWidget);
    expect(find.text('No Reactivo'), findsOneWidget);
  });

  testWidgets('Renderiza pack y sus tests hijos con orden preservado y tiles de expansión', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildDialog(packChequeo));
    await tester.pumpAndSettle();

    // Título y badges del pack
    expect(find.text('Perfil Metabólico Básico'), findsOneWidget);
    expect(find.text('PACK / PERFIL'), findsOneWidget);
    expect(find.text('Análisis Incluidos (3)'), findsOneWidget);

    // Los 3 tests hijos deben estar visibles en el orden especificado en childTestIds:
    // 1. Colesterol Total, 2. Glucosa en Sangre, 3. VIH 1+2 Prueba Rápida
    expect(find.text('Colesterol Total'), findsOneWidget);
    expect(find.text('Glucosa en Sangre'), findsOneWidget);
    expect(find.text('VIH 1+2 Prueba Rápida'), findsOneWidget);

    // Inicialmente los detalles internos de valores de referencia no deben estar visibles
    expect(find.text('70.0 - 100.0 mg/dL'), findsNothing);

    // Expandir el segundo test hijo (Glucosa en Sangre)
    final glucosaTile = find.byKey(const ValueKey('pack_child_test_test-glu-1'));
    expect(glucosaTile, findsOneWidget);

    await tester.tap(glucosaTile);
    await tester.pumpAndSettle();

    // Ahora los valores de referencia de Glucosa deben ser visibles dentro del ExpansionTile
    expect(find.text('70.0 - 100.0 mg/dL'), findsOneWidget);
    expect(find.text('Muestra en ayunas de 8 horas.'), findsOneWidget);
  });

  testWidgets('Expande un test hijo cualitativo dentro de un pack y muestra sus opciones', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildDialog(packChequeo));
    await tester.pumpAndSettle();

    // Expandir el tercer test hijo (VIH)
    final hivTile = find.byKey(const ValueKey('pack_child_test_test-hiv-2'));
    expect(hivTile, findsOneWidget);

    await tester.tap(hivTile);
    await tester.pumpAndSettle();

    expect(find.text('Configuración Cualitativa'), findsOneWidget);
    expect(find.text('No Reactivo, Reactivo'), findsOneWidget);
    expect(find.text('No Reactivo'), findsOneWidget);
  });
}
