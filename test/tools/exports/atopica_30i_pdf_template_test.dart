import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/tools/exports/pdf/templates/atopica_30i_helper.dart';
import 'package:serum_app_front/src/tools/exports/pdf/templates/atopica_30i_pdf_template.dart';
import 'package:serum_app_front/src/widgets/dialogs/viewers/clinical_order_viewer.dart';
import 'package:serum_business/serum_business.dart';

BranchInDb _testBranch() => BranchInDb(
  id: 'branch-1',
  name: 'Laboratorio Clínico Serum',
  address: 'Managua',
  phone: '2222-0000',
  createdAt: 1700000000000,
);

PatientInfo _testPatient() => PatientInfo(
  name: 'OLIMPIA PRAVIA JARQUIN',
  dateOfBirth: 1000000000000,
  gender: 'F',
);

OrderInDb _atopicaOrder() {
  final results = <OrderTestResult>[
    for (var i = 0; i < Atopica30iHelper.orderedAllergenPrefixes.length; i++)
      OrderTestResult(
        labTestId: 'lt-$i',
        parameterName: '${Atopica30iHelper.orderedAllergenPrefixes[i]} Alergeno $i',
        medicalClassification: 'Inmunología',
        subclassification: 'Alergias',
        parentExamName: 'Atópica 30-I (Panel de Alergias)',
        dataType: 'numeric',
        unitOfMeasure: 'kU/L',
        resultValue: Atopica30iHelper.orderedAllergenPrefixes[i] == 'd01'
            ? '11'
            : (Atopica30iHelper.orderedAllergenPrefixes[i] == 'gx7' ? '0.52' : '<0.15'),
      ),
  ];

  return OrderInDb(
    id: 'ord-atop-001',
    branchId: 'branch-1',
    patientId: 'pat-1',
    patientInfo: _testPatient(),
    results: results,
    createdAt: 1731800000000,
  );
}

OrderInDb _standardOrder() {
  return OrderInDb(
    id: 'ord-std-001',
    branchId: 'branch-1',
    patientId: 'pat-1',
    patientInfo: _testPatient(),
    results: [
      OrderTestResult(
        labTestId: 'lt-glu',
        parameterName: 'Glucosa',
        medicalClassification: 'Química Sanguínea',
        dataType: 'numeric',
        unitOfMeasure: 'mg/dL',
        resultValue: '92',
      ),
    ],
    createdAt: 1731800000000,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SpecialReportRegistry detecta Atópica 30-I solo cuando corresponde', () {
    final stdFormats = SpecialReportRegistry.resolveAvailableFormats(_standardOrder());
    expect(stdFormats.length, 1);
    expect(stdFormats.first.id, SpecialReportFormat.standard.id);

    final atopFormats = SpecialReportRegistry.resolveAvailableFormats(_atopicaOrder());
    expect(atopFormats.length, 2);
    expect(atopFormats.first.id, SpecialReportFormat.atopica30i.id);
    expect(atopFormats.last.id, SpecialReportFormat.standard.id);
  });

  test('Atopica30iHelper calcula Clases IgE 0..6 y escala creciente', () {
    expect(Atopica30iHelper.computeIgeClass('<0.15'), 0);
    expect(Atopica30iHelper.computeIgeClass('0.30'), 0);
    expect(Atopica30iHelper.computeIgeClass('0.35'), 1);
    expect(Atopica30iHelper.computeIgeClass('0.52'), 1);
    expect(Atopica30iHelper.computeIgeClass('1.5'), 2);
    expect(Atopica30iHelper.computeIgeClass('11'), 3);
    expect(Atopica30iHelper.computeIgeClass('25'), 4);
    expect(Atopica30iHelper.computeIgeClass('75'), 5);
    expect(Atopica30iHelper.computeIgeClass('120'), 6);
    expect(Atopica30iHelper.computeIgeClass(''), isNull);

    final f0 = Atopica30iHelper.computeScaleFraction('<0.15');
    final f1 = Atopica30iHelper.computeScaleFraction('0.52');
    final f3 = Atopica30iHelper.computeScaleFraction('11');
    final f6 = Atopica30iHelper.computeScaleFraction('100');
    expect(f0, 0.0);
    expect(f1, greaterThan(f0));
    expect(f3, greaterThan(f1));
    expect(f6, 1.0);
  });

  test('Atopica30iPdfTemplate genera un PDF válido de 1 página', () async {
    final template = Atopica30iPdfTemplate(
      order: _atopicaOrder(),
      branch: _testBranch(),
      patientInfo: _testPatient(),
    );

    final doc = await template.buildDocument();
    final bytes = await doc.save();
    expect(bytes, isNotEmpty);
  });

  testWidgets('ClinicalOrderViewer muestra dropdown solo cuando existe formato especial y permite alternar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: ClinicalOrderViewer(
          key: const ValueKey('standard'),
          order: _standardOrder(),
          branch: _testBranch(),
          patientInfo: _testPatient(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Especial: Atópica 30-I'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: ClinicalOrderViewer(
          key: const ValueKey('atopica'),
          order: _atopicaOrder(),
          branch: _testBranch(),
          patientInfo: _testPatient(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Especial: Atópica 30-I'), findsOneWidget);
    expect(find.text('Test (Alergias): Atópica 30-I'), findsOneWidget);

    await tester.tap(find.text('Especial: Atópica 30-I'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Formato Estándar').last);
    await tester.pumpAndSettle();

    expect(find.text('Test (Alergias): Atópica 30-I'), findsNothing);
    expect(find.text('Formato Estándar'), findsOneWidget);
  });
}
