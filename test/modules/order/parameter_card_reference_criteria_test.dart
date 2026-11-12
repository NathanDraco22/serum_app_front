import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/order/controllers/order_results_view_controller.dart';
import 'package:serum_app_front/src/modules/order/widgets/order_results_dialogs/parameter_card.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  const dayMs = 86400000;

  OrderInDb buildOrder({
    required PatientInfo patient,
    required List<ReferenceValue> references,
  }) {
    return OrderInDb(
      id: 'ord-criteria',
      patientId: 'pat-criteria',
      branchId: 'branch-1',
      createdAt: nowMs,
      patientInfo: patient,
      items: [
        OrderItem(
          labTestId: 'test-1',
          name: 'VSG',
          salePriceApplied: 10000,
        ),
      ],
      results: [
        OrderTestResult(
          labTestId: 'test-1',
          parameterName: 'VSG',
          dataType: 'numeric',
          unitOfMeasure: 'mm/h',
          referenceValues: references,
        ),
      ],
    );
  }

  Widget buildCard(OrderResultsViewController controller) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ParameterCard(
            result: controller.results.first,
            viewController: controller,
            controller: TextEditingController(),
            onToggleVisibility: (_) {},
            onNumericChanged: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('muestra FEMENINO cuando el rango usa género', (tester) async {
    final order = buildOrder(
      patient: PatientInfo(
        name: 'Paciente femenina',
        dateOfBirth: nowMs - (30 * 365 * dayMs),
        gender: 'F',
      ),
      references: [
        ReferenceValue(
          patientType: 'general',
          gender: 'male',
          minAgeDays: 0,
          maxAgeDays: 43800,
          minValue: 1,
          maxValue: 10,
          useGender: true,
        ),
        ReferenceValue(
          patientType: 'general',
          gender: 'female',
          minAgeDays: 0,
          maxAgeDays: 43800,
          minValue: 10,
          maxValue: 25,
          useGender: true,
        ),
      ],
    );
    final controller = OrderResultsViewController(order: order);

    await tester.pumpWidget(buildCard(controller));

    expect(find.text('FEMENINO'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('muestra el rango de edad con la unidad configurada', (tester) async {
    final order = buildOrder(
      patient: PatientInfo(
        name: 'Paciente adulta',
        dateOfBirth: nowMs - (30 * 365 * dayMs),
        gender: 'F',
      ),
      references: [
        ReferenceValue(
          patientType: 'general',
          gender: 'both',
          minAgeDays: 18 * 365,
          maxAgeDays: 39 * 365,
          minValue: 10,
          maxValue: 25,
          ageUnit: 'years',
          useAge: true,
        ),
      ],
    );
    final controller = OrderResultsViewController(order: order);

    await tester.pumpWidget(buildCard(controller));

    expect(find.text('18 - 39 años'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('muestra género y edad cuando el rango usa ambos', (tester) async {
    final order = buildOrder(
      patient: PatientInfo(
        name: 'Paciente adulta',
        dateOfBirth: nowMs - (30 * 365 * dayMs),
        gender: 'F',
      ),
      references: [
        ReferenceValue(
          patientType: 'general',
          gender: 'female',
          minAgeDays: 18 * 365,
          maxAgeDays: 39 * 365,
          minValue: 10,
          maxValue: 25,
          ageUnit: 'years',
          useAge: true,
          useGender: true,
        ),
      ],
    );
    final controller = OrderResultsViewController(order: order);

    await tester.pumpWidget(buildCard(controller));

    expect(find.text('FEMENINO'), findsOneWidget);
    expect(find.text('18 - 39 años'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('no muestra criterios cuando el rango es general', (tester) async {
    final order = buildOrder(
      patient: PatientInfo(
        name: 'Paciente adulta',
        dateOfBirth: nowMs - (30 * 365 * dayMs),
        gender: 'F',
      ),
      references: [
        ReferenceValue(
          patientType: 'general',
          gender: 'both',
          minAgeDays: 0,
          maxAgeDays: 43800,
          minValue: 10,
          maxValue: 25,
        ),
      ],
    );
    final controller = OrderResultsViewController(order: order);

    await tester.pumpWidget(buildCard(controller));

    expect(find.text('FEMENINO'), findsNothing);
    expect(find.text('18 - 39 años'), findsNothing);
    controller.dispose();
  });
}
