import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/order_cubit/write_orders_cubit.dart';
import 'package:serum_app_front/src/modules/order/widgets/order_results_dialog.dart';
import 'package:serum_business/serum_business.dart';

class _FakeOrdersDataSource extends Fake implements OrdersDataSource {
  int updateCount = 0;
  Map<String, dynamic>? lastPayload;

  @override
  Future<Map<String, dynamic>?> updateOrderById(String orderId, Map<String, dynamic> order) async {
    updateCount++;
    lastPayload = order;
    return {
      'id': orderId,
      'patientId': 'PAT-1',
      'branchId': 'branch-1',
      'totalPrice': 20000,
      'paidAmount': 20000,
      'status': order['status'] ?? 'completed',
      'createdAt': 1700000000000,
      'items': [],
      'results': order['results'] ?? [],
      'notes': order['notes'] ?? '',
    };
  }
}

void main() {
  late _FakeOrdersDataSource fakeOrdersDataSource;
  late OrdersRepository ordersRepo;
  late WriteOrderCubit writeOrderCubit;

  final sampleOrder = OrderInDb(
    id: 'ORD-TEST-123',
    patientId: 'PAT-1',
    branchId: 'branch-1',
    totalPrice: 20000,
    paidAmount: 20000,
    status: 'paid',
    createdAt: 1700000000000,
    items: [
      OrderItem(
        labTestId: 'test-glu',
        name: 'Química Sanguínea',
        salePriceApplied: 20000,
        originalPrice: 20000,
      ),
    ],
    results: [
      OrderTestResult(
        labTestId: 'test-glu',
        parameterName: 'Glucosa',
        medicalClassification: 'Bioquímica',
        dataType: 'numeric',
        unitOfMeasure: 'mg/dL',
        referenceValues: [
          ReferenceValue(
            patientType: 'human',
            gender: 'both',
            minAgeDays: 0,
            maxAgeDays: 36500,
            minValue: 70.0,
            maxValue: 100.0,
          ),
        ],
        resultValue: '85',
      ),
      OrderTestResult(
        labTestId: 'test-col',
        parameterName: 'Colesterol Total',
        medicalClassification: 'Bioquímica',
        dataType: 'numeric',
        unitOfMeasure: 'mg/dL',
        referenceValues: [
          ReferenceValue(
            patientType: 'human',
            gender: 'both',
            minAgeDays: 0,
            maxAgeDays: 36500,
            minValue: 0.0,
            maxValue: 200.0,
          ),
        ],
        resultValue: '175',
      ),
    ],
  );

  setUp(() {
    fakeOrdersDataSource = _FakeOrdersDataSource();
    ordersRepo = OrdersRepository(fakeOrdersDataSource);
    writeOrderCubit = WriteOrderCubit(ordersRepository: ordersRepo);
  });

  tearDown(() {
    writeOrderCubit.close();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<WriteOrderCubit>.value(
          value: writeOrderCubit,
          child: OrderResultsDialog(order: sampleOrder),
        ),
      ),
    );
  }

  testWidgets('Focus avanza al campo de Descripción con Enter en el último resultado sin guardar prematuramente',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verificamos que se renderice el diálogo con el nuevo título de la sección de notas
    expect(find.text('Descripción / Observaciones del Bioanalista'), findsOneWidget);

    // Identificamos los campos de texto
    // Hay 2 parámetros numéricos + 1 campo de descripción/notas = 3 TextFormFields
    final textFormFields = find.byType(TextFormField);
    expect(textFormFields, findsNWidgets(3));

    final firstField = textFormFields.at(0);
    final secondField = textFormFields.at(1);
    final notesField = textFormFields.at(2);

    // 1. Simular Enter en el primer campo (Glucosa)
    await tester.showKeyboard(firstField);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    // 2. Simular Enter en el segundo campo (Colesterol - último parámetro)
    await tester.showKeyboard(secondField);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    // 3. Comprobación crítica: NO se debió invocar el guardado prematuro
    expect(fakeOrdersDataSource.updateCount, equals(0));

    // 4. Comprobación de Foco: El campo de notas/descripción debe tener el foco activo
    final notesEditableText = find.descendant(
      of: notesField,
      matching: find.byType(EditableText),
    );
    expect(notesEditableText, findsOneWidget);
    final EditableText editableWidget = tester.widget<EditableText>(notesEditableText);
    expect(editableWidget.focusNode.hasFocus, isTrue);

    // 5. El usuario puede escribir en el campo de descripción libremente
    await tester.enterText(notesField, 'Muestra en condiciones óptimas. Sin hemólisis.');
    await tester.pumpAndSettle();

    // 6. Al pulsar el botón explícito de guardar resultados, se procesa la actualización
    final saveButton = find.byType(ElevatedButton);
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(fakeOrdersDataSource.updateCount, equals(1));
    expect(fakeOrdersDataSource.lastPayload?['notes'], equals('Muestra en condiciones óptimas. Sin hemólisis.'));
  });
}
