import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/order/widgets/order_catalog_section.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  final sampleIndividualTest = LabTestInDb(
    id: 'test-glucose',
    name: 'Glucosa en Sangre',
    commercialCategory: 'Química Clínica',
    salePrice: 15000,
    isPack: false,
    isProfileParameter: false,
    createdAt: 0,
  );

  final samplePackTest = LabTestInDb(
    id: 'pack-bhc',
    name: 'Biometría Hemática Completa',
    commercialCategory: 'Hematología',
    salePrice: 35000,
    isPack: true,
    childTestIds: ['test-vcm', 'test-leuko'],
    isProfileParameter: false,
    createdAt: 0,
  );

  final sampleProfileParamTest = LabTestInDb(
    id: 'test-vcm',
    name: 'Volumen Corpuscular Medio (VCM)',
    commercialCategory: 'Hematología',
    subclassification: 'Serie Roja',
    salePrice: 5000,
    isPack: false,
    isProfileParameter: true,
    createdAt: 0,
  );

  Widget buildTestWidget({
    required List<LabTestInDb> allLabTests,
    List<LabTestInDb> selectedItems = const [],
    void Function(LabTestInDb)? onToggleItem,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: OrderCatalogSection(
          allLabTests: allLabTests,
          isLoading: false,
          selectedItems: selectedItems,
          onToggleItem: onToggleItem ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('Oculta parametros de perfil por defecto al cargar el catalogo de crear orden', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      buildTestWidget(
        allLabTests: [sampleIndividualTest, samplePackTest, sampleProfileParamTest],
      ),
    );
    await tester.pumpAndSettle();

    // Glucosa y BHC deben estar visibles
    expect(find.text('Glucosa en Sangre'), findsOneWidget);
    expect(find.text('Biometría Hemática Completa'), findsOneWidget);

    // VCM (parámetro de perfil) debe estar OCULTO por defecto
    expect(find.text('Volumen Corpuscular Medio (VCM)'), findsNothing);

    // Debe existir el chip "Ocultar parámetros de perfil" y estar seleccionado
    final filterChipFinder = find.widgetWithText(FilterChip, 'Ocultar parámetros de perfil');
    expect(filterChipFinder, findsOneWidget);

    final FilterChip chip = tester.widget(filterChipFinder);
    expect(chip.selected, isTrue);

    // Contador disponible: 2 (Glucosa y Pack)
    expect(find.text('2 disponibles'), findsOneWidget);
  });

  testWidgets('Al desmarcar "Ocultar parámetros de perfil" se muestran los parámetros con su badge', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      buildTestWidget(
        allLabTests: [sampleIndividualTest, samplePackTest, sampleProfileParamTest],
      ),
    );
    await tester.pumpAndSettle();

    // Desmarcar el chip
    final filterChipFinder = find.widgetWithText(FilterChip, 'Ocultar parámetros de perfil');
    await tester.tap(filterChipFinder);
    await tester.pumpAndSettle();

    // Ahora VCM debe ser visible
    expect(find.text('Volumen Corpuscular Medio (VCM)'), findsOneWidget);
    // Y debe contener el badge identificador PARÁMETRO
    expect(find.text('PARÁMETRO'), findsOneWidget);
    // Contador disponible sube a 3
    expect(find.text('3 disponibles'), findsOneWidget);
  });

  testWidgets('Filtro Individuales excluye parametros de perfil', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      buildTestWidget(
        allLabTests: [sampleIndividualTest, samplePackTest, sampleProfileParamTest],
      ),
    );
    await tester.pumpAndSettle();

    // Seleccionar filtro "Individuales"
    final individualChip = find.widgetWithText(ChoiceChip, 'Individuales');
    await tester.tap(individualChip);
    await tester.pumpAndSettle();

    // Solo debe verse Glucosa (el pack y el parámetro de perfil están excluidos)
    expect(find.text('Glucosa en Sangre'), findsOneWidget);
    expect(find.text('Biometría Hemática Completa'), findsNothing);
    expect(find.text('Volumen Corpuscular Medio (VCM)'), findsNothing);
    expect(find.text('1 disponibles'), findsOneWidget);
  });

  test('OrderFormDialog omite parametros de perfil en las opciones de venta', () {
    final tests = [sampleIndividualTest, samplePackTest, sampleProfileParamTest];
    final available = tests.where((t) => !t.isProfileParameter).toList();

    expect(available.length, 2);
    expect(available.any((t) => t.id == 'test-glucose'), isTrue);
    expect(available.any((t) => t.id == 'pack-bhc'), isTrue);
    expect(available.any((t) => t.id == 'test-vcm'), isFalse);
  });
}
