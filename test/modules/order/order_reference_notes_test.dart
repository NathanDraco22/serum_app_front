import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/order_cubit/write_orders_cubit.dart';
import 'package:serum_app_front/src/modules/order/widgets/order_results_dialog.dart';
import 'package:serum_app_front/src/widgets/dialogs/viewers/clinical_order_viewer.dart';
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
      'totalPrice': 2500,
      'paidAmount': 2500,
      'status': order['status'] ?? 'completed',
      'createdAt': 1700000000000,
      'items': [],
      'results': order['results'] ?? [],
      'notes': order['notes'] ?? '',
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeOrdersDataSource fakeDataSource;
  late OrdersRepository ordersRepo;
  late WriteOrderCubit writeOrderCubit;

  const testScaleText = '- Menor de 5.6%: Nivel no diabético\n- 5.7 - 6.4%: Nivel prediabético\n- Mayor de 6.5%: Diagnosticado diabético';

  final hba1cOrder = OrderInDb(
    id: 'ORD-HBA1C-99',
    patientId: 'PAT-1',
    branchId: 'branch-1',
    totalPrice: 2500,
    paidAmount: 2500,
    status: 'paid',
    createdAt: 1700000000000,
    patientInfo: PatientInfo(
      name: 'Maribel Lopez',
      dateOfBirth: DateTime.now().millisecondsSinceEpoch - (50 * 365 * 86400000),
      gender: 'F',
    ),
    doctorInfo: DoctorInfo(name: 'Dra. Morales'),
    items: [
      OrderItem(
        labTestId: 'lt-hba1c',
        name: 'Glicohemoglobina A1c',
        salePriceApplied: 2500,
        originalPrice: 2500,
      ),
    ],
    results: [
      OrderTestResult(
        labTestId: 'lt-hba1c',
        parameterName: 'Glicohemoglobina A1c HbA1c',
        medicalClassification: 'Química Sanguínea',
        dataType: 'numeric',
        unitOfMeasure: '%',
        referenceValues: [
          ReferenceValue(
            patientType: 'general',
            gender: 'both',
            minAgeDays: 0,
            maxAgeDays: 43800,
            minValue: 4.0,
            maxValue: 5.6,
          ),
        ],
        referenceText: testScaleText,
        resultValue: '5.8',
      ),
    ],
  );

  setUp(() {
    fakeDataSource = _FakeOrdersDataSource();
    ordersRepo = OrdersRepository(fakeDataSource);
    writeOrderCubit = WriteOrderCubit(ordersRepository: ordersRepo);
  });

  tearDown(() {
    writeOrderCubit.close();
  });

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<WriteOrderCubit>.value(
          value: writeOrderCubit,
          child: child,
        ),
      ),
    );
  }

  testWidgets('OrderResultsDialog preserva referenceText al guardar resultados', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        OrderResultsDialog(order: hba1cOrder),
      ),
    );
    await tester.pumpAndSettle();

    // Guardar resultados
    final submitButton = find.byType(ElevatedButton);
    expect(submitButton, findsOneWidget);
    await tester.tap(submitButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(fakeDataSource.updateCount, 1);
    expect(fakeDataSource.lastPayload, isNotNull);
    final resultsPayload = fakeDataSource.lastPayload!['results'] as List<dynamic>;
    expect(resultsPayload.length, 1);
    final firstResult = resultsPayload.first as Map<String, dynamic>;
    expect(firstResult['referenceText'], testScaleText);
  });

  testWidgets('ClinicalOrderViewerContent despliega sección NOTAS DE REFERENCIA', (tester) async {
    final sampleBranch = BranchInDb(
      id: 'branch-1',
      name: 'Laboratorio Clínico Serum',
      address: 'Sede Principal',
      phone: '2222-0000',
      createdAt: 1700000000000,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClinicalOrderViewerContent(
              order: hba1cOrder,
              branch: sampleBranch,
              patientInfo: hba1cOrder.patientInfo!,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NOTAS DE REFERENCIA:'), findsOneWidget);
    expect(find.textContaining('Menor de 5.6%: Nivel no diabético'), findsOneWidget);
  });

  testWidgets('ClinicalOrderViewerContent despliega Bioanalista Representante en la firma si está configurado', (tester) async {
    final branchWithBio = BranchInDb(
      id: 'branch-1',
      name: 'Laboratorio Clínico Serum',
      address: 'Sede Principal',
      phone: '2222-0000',
      bioanalyst: BranchBioanalyst(
        name: 'Lic. Joselin Lopez',
        title: 'TECNOLOGO MEDICO',
        code: 'Codigo MINSA 88027',
      ),
      createdAt: 1700000000000,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClinicalOrderViewerContent(
              order: hba1cOrder,
              branch: branchWithBio,
              patientInfo: hba1cOrder.patientInfo!,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lic. Joselin Lopez'), findsOneWidget);
    expect(find.text('TECNOLOGO MEDICO'), findsOneWidget);
    expect(find.text('Codigo MINSA 88027'), findsOneWidget);
    expect(find.text('Responsable de Laboratorio'), findsNothing);
  });

  testWidgets('ClinicalOrderViewerContent despliega Responsable de Laboratorio si la sucursal no tiene bioanalista', (tester) async {
    final branchWithoutBio = BranchInDb(
      id: 'branch-1',
      name: 'Laboratorio Clínico Serum',
      address: 'Sede Principal',
      phone: '2222-0000',
      createdAt: 1700000000000,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClinicalOrderViewerContent(
              order: hba1cOrder,
              branch: branchWithoutBio,
              patientInfo: hba1cOrder.patientInfo!,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Responsable de Laboratorio'), findsOneWidget);
    expect(find.text('Firma y Sello de Validación Clínica'), findsOneWidget);
    expect(find.text('Lic. Joselin Lopez'), findsNothing);
  });
}
