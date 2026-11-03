import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/order/widgets/order_results_dialogs/parameter_card.dart';
import 'package:serum_app_front/src/widgets/dialogs/viewers/clinical_order_viewer.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyBranch = BranchInDb(
    id: 'branch-1',
    name: 'Laboratorio Clínico Serum',
    address: 'Calle Médica 123',
    phone: 'PBX: 2222-0000',
    createdAt: 1700000000000,
  );

  group('ParameterCard Texto Libre (dataType: text) Tests', () {
    testWidgets('renderiza TextField multilínea y omite caja de referencia si referenceText está vacío',
        (tester) async {
      final textResult = OrderTestResult(
        labTestId: 'test-obs',
        parameterName: 'Observaciones de Sedimento Urinario',
        dataType: 'text',
        unitOfMeasure: '',
        referenceText: '',
      );

      final controller = TextEditingController(text: 'Se observan leucocitos abundantes');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParameterCard(
              result: textResult,
              alert: null,
              isAlert: false,
              isReadOnly: false,
              controller: controller,
              qualitativeValue: null,
              onQualitativeChanged: (_) {},
              onNumericChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Observaciones de Sedimento Urinario'), findsOneWidget);
      // Al no tener referenceText, no debe aparecer el contenedor referencial dummy
      expect(find.text('ESCALA REFERENCIAL'), findsNothing);
      expect(find.text('VALOR ESPERADO'), findsNothing);

      // Verificamos que el TextField interno sea multilínea
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.minLines, 3);
      expect(textField.maxLines, isNull);
      expect(textField.keyboardType, TextInputType.multiline);
      expect(textField.textInputAction, TextInputAction.newline);
    });

    testWidgets('renderiza caja de referencia y campo multilínea si referenceText está presente',
        (tester) async {
      final textResult = OrderTestResult(
        labTestId: 'test-biop',
        parameterName: 'Diagnóstico Histopatológico',
        dataType: 'text',
        unitOfMeasure: '',
        referenceText: 'Criterio OMS: Grado I a III según atipia celular.',
      );

      final controller = TextEditingController(text: 'Fragmento compatible con lesión benigna.');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParameterCard(
              result: textResult,
              alert: null,
              isAlert: false,
              isReadOnly: false,
              controller: controller,
              qualitativeValue: null,
              onQualitativeChanged: (_) {},
              onNumericChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Diagnóstico Histopatológico'), findsOneWidget);
      expect(find.text('ESCALA REFERENCIAL'), findsOneWidget);
      expect(find.text('Criterio OMS: Grado I a III según atipia celular.'), findsOneWidget);

      final textFieldFinder = find.byType(TextField);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.minLines, 3);
      expect(textField.maxLines, isNull);
      expect(textField.keyboardType, TextInputType.multiline);
    });
  });

  group('ClinicalOrderViewer Texto Libre (dataType: text) Tests', () {
    testWidgets('despliega examen con resultados de texto libre a ancho completo y multilínea',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const longDiagnosis =
          'Los cortes histológicos examinados muestran piel con epidermis ortoqueratótica que contiene una proliferación epitelial crateriforme.\n'
          'Bordes quirúrgicos laterales y profundos libres de lesión neoplásica.\n'
          'No se identifican émbolos tumorales endovasculares ni invasión perineural.';

      final orderWithText = OrderInDb(
        id: 'ord-txt-99',
        patientId: 'pat-1',
        branchId: 'branch-1',
        status: 'completed',
        totalPrice: 4000,
        paidAmount: 4000,
        createdAt: 1700000000000,
        patientInfo: PatientInfo(
          name: 'Roberto Gómez',
          dateOfBirth: DateTime.now().millisecondsSinceEpoch - (40 * 365 * 86400000),
          gender: 'M',
        ),
        doctorInfo: DoctorInfo(name: 'Dr. Estrada'),
        items: [
          OrderItem(
            labTestId: 'lt-biopsia',
            name: 'ESTUDIO HISTOPATOLÓGICO DE BIOPSIA',
            salePriceApplied: 4000,
            originalPrice: 4000,
          ),
        ],
        results: [
          OrderTestResult(
            labTestId: 'lt-desc-macro',
            parameterName: 'Descripción Macroscópica',
            medicalClassification: 'Anatomía Patológica',
            dataType: 'text',
            resultValue: 'Espécimen elíptico fijado en formalina que mide 2.0 x 1.2 x 0.5 cm.',
          ),
          OrderTestResult(
            labTestId: 'lt-diag-micro',
            parameterName: 'Diagnóstico Histopatológico',
            medicalClassification: 'Anatomía Patológica',
            dataType: 'text',
            resultValue: longDiagnosis,
            referenceText: 'Gradación según clasificación internacional de tumores cutáneos.',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalOrderViewer(
              order: orderWithText,
              branch: dummyBranch,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar el título del estudio
      expect(find.text('ESTUDIO HISTOPATOLÓGICO DE BIOPSIA'), findsOneWidget);

      // Al no haber pruebas numéricas, no se muestran los encabezados tabulares rígidos
      expect(find.text('Nombre del Test'), findsNothing);

      // Debe mostrar los nombres de los parámetros descriptivos
      expect(find.text('Descripción Macroscópica'), findsOneWidget);
      expect(find.text('Diagnóstico Histopatológico'), findsOneWidget);

      // Debe mostrar el texto completo multilínea
      expect(find.text('Espécimen elíptico fijado en formalina que mide 2.0 x 1.2 x 0.5 cm.'), findsOneWidget);
      expect(find.text(longDiagnosis), findsOneWidget);

      // Debe mostrar el criterio de referencia
      expect(
        find.text('Criterio / Valor de Referencia: Gradación según clasificación internacional de tumores cutáneos.'),
        findsOneWidget,
      );

      // Ningún error de overflow ocurrió
      expect(tester.takeException(), isNull);
    });

    testWidgets('despliega examen mixto con tabla de pruebas numéricas y bloque de texto libre',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mixedOrder = OrderInDb(
        id: 'ord-ego-100',
        patientId: 'pat-2',
        branchId: 'branch-1',
        status: 'completed',
        totalPrice: 2000,
        paidAmount: 2000,
        createdAt: 1700000000000,
        patientInfo: PatientInfo(
          name: 'Elena Morales',
          dateOfBirth: DateTime.now().millisecondsSinceEpoch - (28 * 365 * 86400000),
          gender: 'F',
        ),
        doctorInfo: DoctorInfo(name: 'Dra. Sandoval'),
        items: [
          OrderItem(
            labTestId: 'lt-ego',
            name: 'EXAMEN GENERAL DE ORINA (EGO)',
            salePriceApplied: 2000,
            originalPrice: 2000,
          ),
        ],
        results: [
          OrderTestResult(
            labTestId: 'lt-ph',
            parameterName: 'pH Urinario',
            medicalClassification: 'Examen Físico-Químico',
            dataType: 'numeric',
            unitOfMeasure: '',
            referenceValues: [
              ReferenceValue(
                patientType: 'general',
                gender: 'both',
                minAgeDays: 0,
                maxAgeDays: 43800,
                minValue: 5.0,
                maxValue: 7.5,
              ),
            ],
            resultValue: '6.5',
          ),
          OrderTestResult(
            labTestId: 'lt-obs-ego',
            parameterName: 'Observaciones Microscópicas',
            medicalClassification: 'Examen Microscópico',
            dataType: 'text',
            resultValue: 'Sedimento urinario con escasas células epiteliales descamativas, leucocitos 1-3 por campo.\nNo se observan cilindros ni bacterias abundantes.',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalOrderViewer(
              order: mixedOrder,
              branch: dummyBranch,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debe mostrar encabezados tabulares porque existe pH Urinario
      expect(find.text('Nombre del Test'), findsOneWidget);
      expect(find.text('Resultado'), findsOneWidget);
      expect(find.text('Valores de Referencia'), findsOneWidget);

      // Parámetro numérico en la tabla
      expect(find.text('pH Urinario'), findsOneWidget);
      expect(find.text('6.5'), findsOneWidget);
      expect(find.text('5.0 - 7.5'), findsOneWidget);

      // Parámetro de texto libre en bloque de ancho completo
      expect(find.text('Observaciones Microscópicas'), findsOneWidget);
      expect(
        find.text('Sedimento urinario con escasas células epiteliales descamativas, leucocitos 1-3 por campo.\nNo se observan cilindros ni bacterias abundantes.'),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
