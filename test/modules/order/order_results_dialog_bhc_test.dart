import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/order_cubit/write_orders_cubit.dart';
import 'package:serum_app_front/src/modules/order/widgets/order_results_dialog.dart';
import 'package:serum_business/serum_business.dart';

class _FakeOrdersDataSource extends Fake implements OrdersDataSource {
  @override
  Future<Map<String, dynamic>?> updateOrderById(String orderId, Map<String, dynamic> order) async {
    return null;
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

  testWidgets('3. Escribir directamente en Hemoglobina (HB) autocalcula Eritrocitos (ERI) sin alterar Hematocrito',
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

    // Hematocrito NO se altera (permanece vacío porque se mide en centrífuga)
    expect(tester.widget<TextFormField>(textFormFields.at(2)).controller?.text, equals(''));

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
}
