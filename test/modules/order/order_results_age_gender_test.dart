import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/order/controllers/order_results_view_controller.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  final nowMs = DateTime.now().millisecondsSinceEpoch;

  OrderInDb buildOrder({
    required PatientInfo patientInfo,
    required List<ReferenceValue> references,
  }) {
    return OrderInDb(
      id: 'ORD-AGE-GENDER-001',
      patientId: 'PAT-1',
      branchId: 'branch-1',
      totalPrice: 10000,
      paidAmount: 0,
      status: 'pending',
      createdAt: nowMs,
      patientInfo: patientInfo,
      items: [
        OrderItem(
          labTestId: 'test-1',
          name: 'Prueba de prueba',
          salePriceApplied: 10000,
        ),
      ],
      results: [
        OrderTestResult(
          labTestId: 'test-1',
          parameterName: 'Prueba de prueba',
          dataType: 'numeric',
          unitOfMeasure: 'mg/dL',
          referenceValues: references,
        ),
      ],
    );
  }

  ReferenceValue ref({
    int minAgeDays = 0,
    int maxAgeDays = 43800,
    String gender = 'both',
    double minValue = 0,
    double maxValue = 100,
    bool useAge = false,
    bool useGender = false,
  }) {
    return ReferenceValue(
      patientType: 'general',
      gender: gender,
      minAgeDays: minAgeDays,
      maxAgeDays: maxAgeDays,
      minValue: minValue,
      maxValue: maxValue,
      useAge: useAge,
      useGender: useGender,
    );
  }

  group('OrderResultsViewController — edades y géneros', () {
    test('selecciona el rango de edad correcto cuando useAge está activo', () {
      final order = buildOrder(
        patientInfo: PatientInfo(
          name: 'Paciente 30',
          dateOfBirth: nowMs - (30 * 365 * 86400000),
          gender: 'M',
        ),
        references: [
          ref(minAgeDays: 0, maxAgeDays: 6570, minValue: 1, useAge: true),
          ref(minAgeDays: 6570, maxAgeDays: 21900, minValue: 2, useAge: true),
          ref(minAgeDays: 21900, maxAgeDays: 43800, minValue: 3, useAge: true),
        ],
      );

      final controller = OrderResultsViewController(order: order);
      final resolution = controller.findReferenceResolutionForPatient(
        controller.results.first,
      );

      expect(resolution.value?.minValue, 2);
      expect(resolution.evaluatedAge, isTrue);
      controller.dispose();
    });

    test('ignora la edad cuando useAge está apagado', () {
      final order = buildOrder(
        patientInfo: PatientInfo(
          name: 'Paciente 10',
          dateOfBirth: nowMs - (10 * 365 * 86400000),
          gender: 'F',
        ),
        references: [
          ref(minAgeDays: 6570, maxAgeDays: 43800, minValue: 5, useAge: false),
        ],
      );

      final controller = OrderResultsViewController(order: order);
      final resolution = controller.findReferenceResolutionForPatient(
        controller.results.first,
      );

      expect(resolution.value?.minValue, 5);
      controller.dispose();
    });

    test('selecciona el rango de género correcto cuando useGender está activo', () {
      final order = buildOrder(
        patientInfo: PatientInfo(
          name: 'Paciente femenino',
          dateOfBirth: nowMs - (30 * 365 * 86400000),
          gender: 'F',
        ),
        references: [
          ref(gender: 'male', minValue: 1, useGender: true),
          ref(gender: 'female', minValue: 2, useGender: true),
        ],
      );

      final controller = OrderResultsViewController(order: order);
      final resolution = controller.findReferenceResolutionForPatient(
        controller.results.first,
      );

      expect(resolution.value?.minValue, 2);
      expect(resolution.evaluatedGender, isTrue);
      controller.dispose();
    });

    test('devuelve null y no marca alerta cuando no hay rango aplicable', () {
      final order = buildOrder(
        patientInfo: PatientInfo(
          name: 'Paciente masculino',
          dateOfBirth: nowMs - (30 * 365 * 86400000),
          gender: 'M',
        ),
        references: [
          ref(gender: 'female', minValue: 1, useGender: true),
        ],
      );

      final controller = OrderResultsViewController(order: order);
      final result = controller.results.first;

      expect(controller.findReferenceValueForPatient(result), isNull);
      controller.onNumericChanged(result, '150');
      expect(controller.getAlertFlag(result), isNull);
      controller.dispose();
    });
  });
}
