import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/order_cubit/write_orders_cubit.dart';
import 'package:serum_app_front/src/modules/order/widgets/order_results_dialog.dart';
import 'package:serum_business/serum_business.dart';

class _FakeOrdersDataSource extends Fake implements OrdersDataSource {
  Map<String, dynamic>? lastUpdatedPayload;

  @override
  Future<Map<String, dynamic>?> updateOrderById(String orderId, Map<String, dynamic> order) async {
    lastUpdatedPayload = order;
    return {
      'id': orderId,
      'patientId': 'PAT-1',
      'branchId': 'branch-1',
      'totalPrice': 20000,
      'paidAmount': 20000,
      'salePriceApplied': 20000,
      'originalPrice': 20000,
      'status': 'paid',
      'createdAt': 1700000000000,
      'patientInfo': {
        'name': 'Paciente PAT-1',
        'gender': 'male',
        'age': '30',
        'phone': '12345678',
        'address': '',
      },
      'items': [],
      'results': order['results'] ?? [],
    };
  }
}

void main() {
  late _FakeOrdersDataSource fakeOrdersDataSource;
  late OrdersRepository ordersRepo;
  late WriteOrderCubit writeOrderCubit;

  OrderInDb createBhcOrder({
    String? eriVal,
    String? hbVal,
    String? htcVal,
  }) {
    return OrderInDb(
      id: 'ORD-TEST-BHC-01',
      patientId: 'PAT-1',
      branchId: 'branch-1',
      totalPrice: 20000,
      paidAmount: 20000,
      status: 'paid',
      createdAt: 1700000000000,
      items: [
        OrderItem(
          labTestId: 'test-bhc',
          name: 'Biometría Hemática Completa',
          salePriceApplied: 20000,
          originalPrice: 20000,
          isPack: true,
        ),
      ],
      results: [
        OrderTestResult(
          labTestId: 'test-eri',
          parameterName: 'Eritrocitos',
          medicalClassification: 'Hematología',
          subclassification: 'Serie Roja',
          dataType: 'numeric',
          unitOfMeasure: 'xmm3',
          resultValue: eriVal,
        ),
        OrderTestResult(
          labTestId: 'test-hb',
          parameterName: 'Hemoglobina',
          medicalClassification: 'Hematología',
          subclassification: 'Serie Roja',
          dataType: 'numeric',
          unitOfMeasure: 'g/dL',
          resultValue: hbVal,
        ),
        OrderTestResult(
          labTestId: 'test-htc',
          parameterName: 'Hematocrito',
          medicalClassification: 'Hematología',
          subclassification: 'Serie Roja',
          dataType: 'numeric',
          unitOfMeasure: '%',
          resultValue: htcVal,
        ),
        OrderTestResult(
          labTestId: 'test-vcm',
          parameterName: 'VCM (Volumen Corpuscular Medio)',
          medicalClassification: 'Hematología',
          subclassification: 'Serie Roja',
          dataType: 'numeric',
          unitOfMeasure: 'fL',
        ),
        OrderTestResult(
          labTestId: 'test-hcm',
          parameterName: 'HCM (Hemoglobina Corpuscular Media)',
          medicalClassification: 'Hematología',
          subclassification: 'Serie Roja',
          dataType: 'numeric',
          unitOfMeasure: 'pg',
        ),
        OrderTestResult(
          labTestId: 'test-chcm',
          parameterName: 'CHCM (Concentración de Hemoglobina Corpuscular Media)',
          medicalClassification: 'Hematología',
          subclassification: 'Serie Roja',
          dataType: 'numeric',
          unitOfMeasure: 'g/dL',
        ),
      ],
    );
  }

  setUp(() {
    fakeOrdersDataSource = _FakeOrdersDataSource();
    ordersRepo = OrdersRepository(fakeOrdersDataSource);
    writeOrderCubit = WriteOrderCubit(ordersRepository: ordersRepo);
  });

  tearDown(() {
    writeOrderCubit.close();
  });

  Widget buildTestWidget(OrderInDb order) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<WriteOrderCubit>.value(
          value: writeOrderCubit,
          child: OrderResultsDialog(order: order),
        ),
      ),
    );
  }

  testWidgets('1. Escritura en Hematocrito (HTC) autocalcula en cascada Hemoglobina, Eritrocitos e Índices',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final order = createBhcOrder();
    await tester.pumpWidget(buildTestWidget(order));
    await tester.pumpAndSettle();

    final textFormFields = find.byType(TextFormField);

    // Escribir HTC = 45 %
    await tester.enterText(textFormFields.at(2), '45');
    await tester.pumpAndSettle();

    // HB = 45 / 3 = 15
    final hbController = tester.widget<TextFormField>(textFormFields.at(1)).controller;
    expect(hbController?.text, equals('15'));

    // ERI = 45 / 9 = 5.000
    final eriController = tester.widget<TextFormField>(textFormFields.at(0)).controller;
    expect(eriController?.text, equals('5.000'));

    // Scroll en ListView para visualizar los índices de Wintrobe
    final listView = find.byType(ListView);
    await tester.drag(listView, const Offset(0, -400));
    await tester.pumpAndSettle();

    // Buscar campos de VCM, HCM y CHCM por sus textos en ParameterCard
    expect(find.text('90'), findsOneWidget); // VCM
    expect(find.text('30'), findsOneWidget); // HCM
    expect(find.text('33.3'), findsOneWidget); // CHCM
  });

  testWidgets('2. Re-escritura en Hematocrito recalcula Eritrocitos y toda la serie sin omitirla',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final order = createBhcOrder();
    await tester.pumpWidget(buildTestWidget(order));
    await tester.pumpAndSettle();

    final textFormFields = find.byType(TextFormField);

    // Paso 1: Escribir HTC = 45
    await tester.enterText(textFormFields.at(2), '45');
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(textFormFields.at(0)).controller?.text, equals('5.000'));

    // Paso 2: Editar ERI manualmente (ej. 4.850)
    await tester.enterText(textFormFields.at(0), '4.850');
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(textFormFields.at(0)).controller?.text, equals('4.850'));

    // Paso 3: Re-escribir Hematocrito (HTC = 36 %)
    // NO debe omitir el recálculo: debe actualizarse a 36 / 9 = 4.000
    await tester.enterText(textFormFields.at(2), '36');
    await tester.pumpAndSettle();

    expect(tester.widget<TextFormField>(textFormFields.at(0)).controller?.text, equals('4.000'));
    expect(tester.widget<TextFormField>(textFormFields.at(1)).controller?.text, equals('12'));
    expect(tester.widget<TextFormField>(textFormFields.at(3)).controller?.text, equals('90'));
  });

  testWidgets('3. Escribir directamente en Hemoglobina (HB) autocalcula Hematocrito (HTC), Eritrocitos (ERI) e Índices',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final order = createBhcOrder();
    await tester.pumpWidget(buildTestWidget(order));
    await tester.pumpAndSettle();

    final textFormFields = find.byType(TextFormField);

    // Escribir únicamente en Hemoglobina = 15.0
    await tester.enterText(textFormFields.at(1), '15.0');
    await tester.pumpAndSettle();

    // Eritrocitos debe calcularse como 15 / 3 = 5.000
    expect(tester.widget<TextFormField>(textFormFields.at(0)).controller?.text, equals('5.000'));

    // Hematocrito se autocalcula bidireccionalmente por Regla de los 3 (15.0 * 3 = 45)
    expect(tester.widget<TextFormField>(textFormFields.at(2)).controller?.text, equals('45'));

    // Scroll para visualizar HCM
    final listView = find.byType(ListView);
    await tester.drag(listView, const Offset(0, -300));
    await tester.pumpAndSettle();

    // HCM se autocalcula (15 * 10 / 5 = 30)
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('4. Evaluación preventiva al abrir modal con valores precargados de Hematocrito',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Orden que ya tiene HTC guardado pero ERI vacío
    final order = createBhcOrder(htcVal: '42');
    await tester.pumpWidget(buildTestWidget(order));
    await tester.pumpAndSettle();

    final textFormFields = find.byType(TextFormField);

    // HB = 42 / 3 = 14
    expect(tester.widget<TextFormField>(textFormFields.at(1)).controller?.text, equals('14'));

    // ERI = 42 / 9 = 4.667
    expect(tester.widget<TextFormField>(textFormFields.at(0)).controller?.text, equals('4.667'));
  });

  testWidgets(
      '5. Orden multi-perfil (BHC + EGO) autocalcula Eritrocitos en Serie Roja sin sobreescribir ni desviar hacia Sedimento Urinario, y persiste al guardar',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final multiOrder = OrderInDb(
      id: 'ORD-TEST-MULTI-01',
      patientId: 'PAT-1',
      branchId: 'branch-1',
      totalPrice: 40000,
      paidAmount: 40000,
      status: 'paid',
      createdAt: 1700000000000,
      items: [
        OrderItem(
          labTestId: 'test-bhc',
          name: 'Biometría Hemática Completa',
          salePriceApplied: 25000,
          originalPrice: 25000,
          isPack: true,
        ),
        OrderItem(
          labTestId: 'test-ego',
          name: 'Examen General de Orina',
          salePriceApplied: 15000,
          originalPrice: 15000,
          isPack: true,
        ),
      ],
      results: [
        // 1. Serie Roja (BHC)
        OrderTestResult(
          labTestId: 'test-eri-bhc',
          parameterName: 'Eritrocitos',
          medicalClassification: 'Hematología',
          subclassification: 'Serie Roja',
          dataType: 'numeric',
          unitOfMeasure: 'xmm3',
        ),
        OrderTestResult(
          labTestId: 'test-hb-bhc',
          parameterName: 'Hemoglobina',
          medicalClassification: 'Hematología',
          subclassification: 'Serie Roja',
          dataType: 'numeric',
          unitOfMeasure: 'g/dL',
        ),
        OrderTestResult(
          labTestId: 'test-htc-bhc',
          parameterName: 'Hematocrito',
          medicalClassification: 'Hematología',
          subclassification: 'Serie Roja',
          dataType: 'numeric',
          unitOfMeasure: '%',
        ),
        OrderTestResult(
          labTestId: 'test-vcm-bhc',
          parameterName: 'VCM (Volumen Corpuscular Medio)',
          medicalClassification: 'Hematología',
          subclassification: 'Serie Roja',
          dataType: 'numeric',
          unitOfMeasure: 'fL',
        ),
        // 2. Sedimento Urinario (EGO) - Tipo text con nombre similar
        OrderTestResult(
          labTestId: 'test-eri-ego',
          parameterName: 'Eritrocitos (Sedimento Urinario)',
          medicalClassification: 'Uroanálisis',
          subclassification: 'Sedimento Microscópico',
          dataType: 'text',
          unitOfMeasure: 'x Campos',
        ),
        OrderTestResult(
          labTestId: 'test-leu-ego',
          parameterName: 'Leucocitos Libres',
          medicalClassification: 'Uroanálisis',
          subclassification: 'Sedimento Microscópico',
          dataType: 'text',
          unitOfMeasure: 'x Campos',
        ),
      ],
    );

    await tester.pumpWidget(buildTestWidget(multiOrder));
    await tester.pumpAndSettle();

    final textFormFields = find.byType(TextFormField);

    // Escribir HTC = 45 % en el campo de Hematocrito (índice 2: test-htc-bhc)
    await tester.enterText(textFormFields.at(2), '45');
    await tester.pumpAndSettle();

    // 1. Verificar que Eritrocitos de BHC (test-eri-bhc, índice 0) se autocalculó a 5.000
    final eriBhcController = tester.widget<TextFormField>(textFormFields.at(0)).controller;
    expect(eriBhcController?.text, equals('5.000'));

    // 2. Verificar que Hemoglobina de BHC (test-hb-bhc, índice 1) se autocalculó a 15
    final hbBhcController = tester.widget<TextFormField>(textFormFields.at(1)).controller;
    expect(hbBhcController?.text, equals('15'));

    // Scroll en ListView para traer a la vista los parámetros de Sedimento Urinario y el botón Guardar
    final listView = find.byType(ListView);
    await tester.drag(listView, const Offset(0, -600));
    await tester.pumpAndSettle();

    // 3. Guardar resultados presionando el botón "Guardar Resultados"
    final saveButton = find.widgetWithText(ElevatedButton, 'Guardar Resultados');
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 4. Verificar que el payload persistido contenga test-eri-bhc con valor '5.000'
    final payload = fakeOrdersDataSource.lastUpdatedPayload;
    expect(payload, isNotNull);
    final resultsPayload = (payload!['results'] as List).cast<Map<String, dynamic>>();

    final eriSaved = resultsPayload.firstWhere((r) => r['labTestId'] == 'test-eri-bhc');
    expect(eriSaved['resultValue'], equals('5.000'));

    // 5. Verificar que Eritrocitos (Sedimento Urinario) de EGO permanezca intacto y no contaminado
    final eriEgoSaved = resultsPayload.firstWhere((r) => r['labTestId'] == 'test-eri-ego');
    expect(eriEgoSaved['resultValue'] == null || eriEgoSaved['resultValue'] == '', isTrue);
    expect(eriEgoSaved['resultValue'], equals(''));
  });

  testWidgets(
      '6. Perfil Lipídico: Recálculo continuo en vivo de Riesgo Coronario al teclear paso a paso (ej. 4 -> 43 en HDL no se congela en 51.8)',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final lipidOrder = OrderInDb(
      id: 'ORD-TEST-LIPID-01',
      patientId: 'PAT-1',
      branchId: 'branch-1',
      totalPrice: 30000,
      paidAmount: 30000,
      status: 'paid',
      createdAt: 1700000000000,
      items: [
        OrderItem(
          labTestId: 'test-perfil-lip',
          name: 'Perfil Lipídico',
          salePriceApplied: 30000,
          originalPrice: 30000,
          isPack: true,
        ),
      ],
      results: [
        OrderTestResult(
          labTestId: 'test-col-t',
          parameterName: 'Colesterol Total',
          medicalClassification: 'Química Sanguínea',
          subclassification: 'Perfil Lipídico',
          dataType: 'numeric',
          unitOfMeasure: 'mg/dL',
        ),
        OrderTestResult(
          labTestId: 'test-trig',
          parameterName: 'Triglicéridos',
          medicalClassification: 'Química Sanguínea',
          subclassification: 'Perfil Lipídico',
          dataType: 'numeric',
          unitOfMeasure: 'mg/dL',
        ),
        OrderTestResult(
          labTestId: 'test-hdl',
          parameterName: 'Colesterol HDL',
          medicalClassification: 'Química Sanguínea',
          subclassification: 'Perfil Lipídico',
          dataType: 'numeric',
          unitOfMeasure: 'mg/dL',
        ),
        OrderTestResult(
          labTestId: 'test-ldl',
          parameterName: 'Colesterol LDL',
          medicalClassification: 'Química Sanguínea',
          subclassification: 'Perfil Lipídico',
          dataType: 'numeric',
          unitOfMeasure: 'mg/dL',
        ),
        OrderTestResult(
          labTestId: 'test-vldl',
          parameterName: 'Colesterol VLDL',
          medicalClassification: 'Química Sanguínea',
          subclassification: 'Perfil Lipídico',
          dataType: 'numeric',
          unitOfMeasure: 'mg/dL',
        ),
        OrderTestResult(
          labTestId: 'test-riesg-cor',
          parameterName: 'Riesgo Coronario',
          medicalClassification: 'Química Sanguínea',
          subclassification: 'Perfil Lipídico',
          dataType: 'numeric',
          unitOfMeasure: '%',
        ),
      ],
    );

    await tester.pumpWidget(buildTestWidget(lipidOrder));
    await tester.pumpAndSettle();

    final textFormFields = find.byType(TextFormField);

    // 1. Escribir Colesterol Total = 207
    await tester.enterText(textFormFields.at(0), '207');
    await tester.pumpAndSettle();

    // 2. Escribir Triglicéridos = 92 -> VLDL = 92 / 5 = 18.4
    await tester.enterText(textFormFields.at(1), '92');
    await tester.pumpAndSettle();

    // 3. Simular primer golpe de tecla en HDL: teclear '4'
    // En ese instante: 207 / 4 = 51.75 -> 51.8
    await tester.enterText(textFormFields.at(2), '4');
    await tester.pumpAndSettle();

    // Scroll para ver los campos autocalculados de Riesgo Coronario, VLDL y LDL
    final listView = find.byType(ListView);
    await tester.drag(listView, const Offset(0, -400));
    await tester.pumpAndSettle();

    // En el paso intermedio con HDL = 4, Riesgo Coronario muestra 51.8
    expect(find.text('51.8'), findsOneWidget);

    // 4. Regresar el scroll hacia arriba para escribir en HDL
    await tester.drag(listView, const Offset(0, 400));
    await tester.pumpAndSettle();

    // Completar escritura en HDL: teclear '43'
    final textFormFieldsTop = find.byType(TextFormField);
    await tester.enterText(textFormFieldsTop.at(2), '43');
    await tester.pumpAndSettle();

    // Scroll hacia abajo para verificar los campos derivados actualizados
    await tester.drag(listView, const Offset(0, -400));
    await tester.pumpAndSettle();

    // Debe haberse recalculado de inmediato a 207 / 43 = 4.81... -> '4.8', NUNCA quedarse congelado en 51.8
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('51.8'), findsNothing);

    // 5. Verificar que VLDL (18.4) y LDL (207 - 43 - 18.4 = 145.6) también están calculados correctamente
    expect(find.text('18.4'), findsOneWidget);
    expect(find.text('145.6'), findsOneWidget);
  });

  testWidgets(
      '7. Nitrógeno de Urea (Pack NU): Escribir Urea (38) autocalcula BUN (17.9) en vivo y re-escribir actualiza sin congelarse',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final nuOrder = OrderInDb(
      id: 'order-nu-1',
      branchId: 'branch-1',
      patientId: 'patient-nu',
      totalPrice: 25000,
      paidAmount: 25000,
      status: 'pending',
      createdAt: 1700000000000,
      items: [
        OrderItem(
          labTestId: 'test-nu',
          name: 'Nitrógeno de Urea (BUN)',
          salePriceApplied: 25000,
          originalPrice: 25000,
          isPack: true,
        ),
      ],
      results: [
        OrderTestResult(
          labTestId: 'test-bun',
          parameterName: 'Nitrógeno de Urea (BUN)',
          medicalClassification: 'Química Sanguínea',
          subclassification: 'Función Renal',
          dataType: 'numeric',
          unitOfMeasure: 'mg/dL',
          referenceText: '6 - 23 mg/dL',
        ),
        OrderTestResult(
          labTestId: 'test-urea',
          parameterName: 'Urea',
          medicalClassification: 'Química Sanguínea',
          subclassification: 'Función Renal',
          dataType: 'numeric',
          unitOfMeasure: 'mg/dL',
          referenceText: '10 - 50 mg/dL',
        ),
      ],
    );

    await tester.pumpWidget(buildTestWidget(nuOrder));
    await tester.pumpAndSettle();

    final textFormFields = find.byType(TextFormField);
    // Index 0: Nitrógeno de Urea (BUN)
    // Index 1: Urea

    // 1. Escribir Urea = 38 (caso real del reporte clínico)
    await tester.enterText(textFormFields.at(1), '38');
    await tester.pumpAndSettle();

    // BUN se debe autocalcular instantáneamente: 38 * 0.47 = 17.86 -> '17.9'
    expect(tester.widget<TextFormField>(textFormFields.at(0)).controller?.text, equals('17.9'));
    expect(find.text('Auto ⚡'), findsOneWidget);
    expect(find.byTooltip('Calculado automáticamente: Urea * 0.47'), findsOneWidget);

    // 2. Re-escribir Urea = 100
    await tester.enterText(textFormFields.at(1), '100');
    await tester.pumpAndSettle();

    // BUN se actualiza de inmediato a 100 * 0.47 = 47
    expect(tester.widget<TextFormField>(textFormFields.at(0)).controller?.text, equals('47'));

    // 3. Sobreescritura manual de BUN = 20
    await tester.enterText(textFormFields.at(0), '20');
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(textFormFields.at(0)).controller?.text, equals('20'));
  });

  testWidgets(
      '8. Eosinófilos Absolutos en Sangre (EOS-SANG) no contamina el diferencial y permite guardar la orden',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final order = OrderInDb(
      id: 'order-eos-sang',
      branchId: 'branch-1',
      patientId: 'patient-eos',
      totalPrice: 15000,
      paidAmount: 15000,
      status: 'pending',
      createdAt: 1700000000000,
      items: [
        OrderItem(
          labTestId: 'test-eos-sang',
          name: 'Eosinófilos Absolutos en Sangre',
          salePriceApplied: 15000,
          originalPrice: 15000,
        ),
      ],
      results: [
        OrderTestResult(
          labTestId: 'test-eos-sang-result',
          parameterName: 'Eosinófilos Absolutos en Sangre',
          medicalClassification: 'Hematología',
          subclassification: 'Serie Blanca',
          dataType: 'numeric',
          unitOfMeasure: 'mm3',
          referenceText: '50 - 500 mm3',
        ),
      ],
    );

    await tester.pumpWidget(buildTestWidget(order));
    await tester.pumpAndSettle();

    final textFormFields = find.byType(TextFormField);

    // Ingresar 250 mm3
    await tester.enterText(textFormFields.at(0), '250');
    await tester.pumpAndSettle();

    // Guardar resultados
    final saveButton = find.widgetWithText(ElevatedButton, 'Guardar Resultados');
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Debe guardar exitosamente sin ser bloqueado por error de diferencial al 100%
    final payload = fakeOrdersDataSource.lastUpdatedPayload;
    expect(payload, isNotNull);
    final resultsPayload = (payload!['results'] as List).cast<Map<String, dynamic>>();
    expect(resultsPayload.first['resultValue'], equals('250'));
  });

  testWidgets(
      '9. Orden combinada (BHC + Glicohemoglobina A1c HbA1c): Escribir Hematocrito o HbA1c no causa colisión cruzada',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final order = OrderInDb(
      id: 'order-bhc-hba1c',
      branchId: 'branch-1',
      patientId: 'patient-diab',
      totalPrice: 45000,
      paidAmount: 45000,
      status: 'pending',
      createdAt: 1700000000000,
      items: [],
      results: [
        OrderTestResult(
          labTestId: 'test-eri',
          parameterName: 'Eritrocitos',
          medicalClassification: 'Hematología',
          subclassification: 'Serie Roja',
          dataType: 'numeric',
          unitOfMeasure: 'xmm3',
        ),
        OrderTestResult(
          labTestId: 'test-hb',
          parameterName: 'Hemoglobina',
          medicalClassification: 'Hematología',
          subclassification: 'Serie Roja',
          dataType: 'numeric',
          unitOfMeasure: 'g/dL',
        ),
        OrderTestResult(
          labTestId: 'test-htc',
          parameterName: 'Hematocrito',
          medicalClassification: 'Hematología',
          subclassification: 'Serie Roja',
          dataType: 'numeric',
          unitOfMeasure: '%',
        ),
        OrderTestResult(
          labTestId: 'test-hba1c',
          parameterName: 'Glicohemoglobina A1c (HbA1c)',
          medicalClassification: 'Química Sanguínea',
          subclassification: 'Control Glucémico',
          dataType: 'numeric',
          unitOfMeasure: '%',
        ),
      ],
    );

    await tester.pumpWidget(buildTestWidget(order));
    await tester.pumpAndSettle();

    final textFormFields = find.byType(TextFormField);

    // 1. Escribir Hematocrito = 42 % (índice 2)
    await tester.enterText(textFormFields.at(2), '42');
    await tester.pumpAndSettle();

    // Hemoglobina de BHC (índice 1) debe ser 14 y Eritrocitos (índice 0) debe ser 4.667
    expect(tester.widget<TextFormField>(textFormFields.at(1)).controller?.text, equals('14'));
    expect(tester.widget<TextFormField>(textFormFields.at(0)).controller?.text, equals('4.667'));
    // HbA1c (índice 3) debe permanecer vacío
    expect(tester.widget<TextFormField>(textFormFields.at(3)).controller?.text, equals(''));

    // 2. Escribir HbA1c = 6.5 % (índice 3)
    await tester.enterText(textFormFields.at(3), '6.5');
    await tester.pumpAndSettle();

    // Regresar el scroll al inicio para verificar que la Serie Roja de la BHC permanezca intacta
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();

    // La Serie Roja de la BHC debe permanecer intacta (HB=14, ERI=4.667, HTC=42)
    expect(tester.widget<TextFormField>(textFormFields.at(1)).controller?.text, equals('14'));
    expect(tester.widget<TextFormField>(textFormFields.at(0)).controller?.text, equals('4.667'));
    expect(tester.widget<TextFormField>(textFormFields.at(2)).controller?.text, equals('42'));
  });

  testWidgets(
      '10. Cuando autoCalculateFormulas es false, OrderResultsDialog oculta la alerta de diferencial en la barra de resumen y permite guardar',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final order = OrderInDb(
      id: 'order-manual-diff',
      branchId: 'branch-1',
      patientId: 'PAT-1',
      totalPrice: 20000,
      paidAmount: 20000,
      status: 'paid',
      createdAt: 1700000000000,
      items: [],
      results: [
        OrderTestResult(
          labTestId: 'test-seg',
          parameterName: 'Segmentados',
          medicalClassification: 'Hematología',
          subclassification: 'Serie Blanca',
          dataType: 'numeric',
          unitOfMeasure: '%',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<WriteOrderCubit>.value(
            value: writeOrderCubit,
            child: OrderResultsDialog(
              order: order,
              autoCalculateFormulas: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textFormFields = find.byType(TextFormField);
    await tester.enterText(textFormFields.at(0), '62.5');
    await tester.pumpAndSettle();

    // No debe mostrarse la advertencia "(Debe sumar 100%)" en la barra de resumen
    expect(find.textContaining('Debe sumar 100%'), findsNothing);
  });
}
