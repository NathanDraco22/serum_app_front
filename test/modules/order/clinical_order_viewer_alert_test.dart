import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/widgets/dialogs/viewers/clinical_order_viewer.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final nowMs = DateTime.now().millisecondsSinceEpoch;

  OrderInDb buildOrder({
    required String? savedAlertFlag,
    required String resultValue,
    required List<ReferenceValue> referenceValues,
    String referenceText = '',
    PatientInfo? patientInfo,
  }) {
    return OrderInDb(
      id: 'ORD-ALERT-VIEWER-01',
      patientId: 'PAT-1',
      branchId: 'branch-1',
      totalPrice: 10000,
      paidAmount: 10000,
      status: 'completed',
      createdAt: nowMs,
      patientInfo:
          patientInfo ??
          PatientInfo(
            name: 'Paciente Masculino',
            dateOfBirth: nowMs - (30 * 365 * 86400000),
            gender: 'M',
          ),
      items: [
        OrderItem(
          labTestId: 'lt-glucosa',
          name: 'Glucosa en Suero',
          salePriceApplied: 10000,
        ),
      ],
      results: [
        OrderTestResult(
          labTestId: 'lt-glucosa',
          parameterName: 'Glucosa',
          medicalClassification: 'Química Sanguínea',
          dataType: 'numeric',
          unitOfMeasure: 'mg/dL',
          referenceValues: referenceValues,
          referenceText: referenceText,
          resultValue: resultValue,
          alertFlag: savedAlertFlag,
        ),
      ],
    );
  }

  ReferenceValue reference({
    String gender = 'both',
    double minValue = 70,
    double maxValue = 100,
    bool useGender = false,
  }) {
    return ReferenceValue(
      patientType: 'general',
      gender: gender,
      minAgeDays: 0,
      maxAgeDays: 36500,
      minValue: minValue,
      maxValue: maxValue,
      useGender: useGender,
    );
  }

  Future<void> pumpViewer(WidgetTester tester, OrderInDb order) {
    final branch = BranchInDb(
      id: 'branch-1',
      name: 'Laboratorio Clínico Serum',
      address: 'Sede Principal',
      phone: '2222-0000',
      createdAt: nowMs,
    );

    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClinicalOrderViewerContent(
              order: order,
              branch: branch,
              patientInfo: order.patientInfo!,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Muestra H con triángulo hacia arriba separado de la unidad', (
    tester,
  ) async {
    final order = buildOrder(
      savedAlertFlag: 'HIGH',
      resultValue: '150',
      referenceValues: [reference()],
    );

    await pumpViewer(tester, order);
    await tester.pumpAndSettle();

    expect(find.text('H'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('clinical-alert-arrow-H')),
      findsOneWidget,
    );

    final arrowRect = tester.getRect(
      find.byKey(const ValueKey('clinical-alert-arrow-H')),
    );
    final unitRect = tester.getRect(find.text('mg/dL'));
    expect(unitRect.left - arrowRect.right, greaterThanOrEqualTo(6.0));
  });

  testWidgets('Muestra L con triángulo hacia abajo', (tester) async {
    final order = buildOrder(
      savedAlertFlag: 'LOW',
      resultValue: '40',
      referenceValues: [reference()],
    );

    await pumpViewer(tester, order);
    await tester.pumpAndSettle();

    expect(find.text('L'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('clinical-alert-arrow-L')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('clinical-alert-arrow-H')),
      findsNothing,
    );
  });

  testWidgets('No muestra H/L guardados cuando el resolvedor no encuentra rango', (tester) async {
    final order = buildOrder(
      savedAlertFlag: 'HIGH',
      resultValue: '150',
      referenceValues: [
        reference(gender: 'female', useGender: true),
      ],
    );

    await pumpViewer(tester, order);
    await tester.pumpAndSettle();

    expect(find.text('H'), findsNothing);
    expect(find.text('L'), findsNothing);
    expect(find.text('Sin rango para esta edad/género'), findsOneWidget);
  });

  testWidgets('Mantiene Sin rango como etiqueta principal aunque exista referenceText', (
    tester,
  ) async {
    final order = buildOrder(
      savedAlertFlag: 'HIGH',
      resultValue: '150',
      referenceValues: [
        reference(gender: 'female', useGender: true),
      ],
      referenceText: 'Escala institucional: 70 - 100 mg/dL',
    );

    await pumpViewer(tester, order);
    await tester.pumpAndSettle();

    expect(find.text('H'), findsNothing);
    expect(find.textContaining('Sin rango para esta edad/género'), findsOneWidget);
    expect(find.textContaining('Escala institucional: 70 - 100 mg/dL'), findsOneWidget);
  });

  testWidgets('Muestra 0 días en lugar de N/D para un recién nacido', (tester) async {
    final order = buildOrder(
      savedAlertFlag: null,
      resultValue: '80',
      referenceValues: [reference()],
      patientInfo: PatientInfo(
        name: 'Recién nacido',
        dateOfBirth: nowMs,
        gender: 'M',
      ),
    );

    await pumpViewer(tester, order);
    await tester.pumpAndSettle();

    expect(find.textContaining('0 días'), findsOneWidget);
    expect(find.textContaining('N/D'), findsNothing);
  });

  testWidgets('Recalcula H cuando el valor está alto y el flag guardado era NORMAL', (
    tester,
  ) async {
    final order = buildOrder(
      savedAlertFlag: 'NORMAL',
      resultValue: '150',
      referenceValues: [reference()],
    );

    await pumpViewer(tester, order);
    await tester.pumpAndSettle();

    expect(find.text('H'), findsOneWidget);
  });

  testWidgets('No muestra H guardado cuando el valor actual está dentro del rango', (tester) async {
    final order = buildOrder(
      savedAlertFlag: 'HIGH',
      resultValue: '80',
      referenceValues: [reference()],
    );

    await pumpViewer(tester, order);
    await tester.pumpAndSettle();

    expect(find.text('H'), findsNothing);
  });
}
