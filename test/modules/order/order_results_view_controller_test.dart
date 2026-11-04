import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/order/controllers/order_results_view_controller.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  OrderInDb createTestOrder({
    List<OrderTestResult>? results,
    String? notes,
    int totalPrice = 25000,
    int paidAmount = 25000,
    String status = 'paid',
    PatientInfo? patientInfo,
  }) {
    return OrderInDb(
      id: 'ORD-TEST-VC-001',
      patientId: 'PAT-1234',
      branchId: 'branch-1',
      totalPrice: totalPrice,
      paidAmount: paidAmount,
      status: status,
      createdAt: 1700000000000,
      notes: notes,
      patientInfo: patientInfo ??
          PatientInfo(
            name: 'Juan Pérez',
            age: 35,
            gender: 'M',
            phone: '555-1234',
          ),
      items: [
        OrderItem(
          labTestId: 'test-bhc',
          name: 'Biometría Hemática Completa',
          salePriceApplied: 25000,
          originalPrice: 25000,
        ),
      ],
      results: results ??
          [
            OrderTestResult(
              labTestId: 'test-eri',
              parameterName: 'Eritrocitos',
              medicalClassification: 'Hematología',
              subclassification: 'Serie Roja',
              dataType: 'numeric',
              unitOfMeasure: 'xmm3',
              referenceValues: [
                ReferenceValue(
                  patientType: 'human',
                  gender: 'M',
                  minAgeDays: 0,
                  maxAgeDays: 36500,
                  minValue: 4.5,
                  maxValue: 5.9,
                ),
              ],
            ),
            OrderTestResult(
              labTestId: 'test-hb',
              parameterName: 'Hemoglobina',
              medicalClassification: 'Hematología',
              subclassification: 'Serie Roja',
              dataType: 'numeric',
              unitOfMeasure: 'g/dL',
              referenceValues: [
                ReferenceValue(
                  patientType: 'human',
                  gender: 'M',
                  minAgeDays: 0,
                  maxAgeDays: 36500,
                  minValue: 13.5,
                  maxValue: 17.5,
                ),
              ],
            ),
            OrderTestResult(
              labTestId: 'test-htc',
              parameterName: 'Hematocrito',
              medicalClassification: 'Hematología',
              subclassification: 'Serie Roja',
              dataType: 'numeric',
              unitOfMeasure: '%',
              referenceValues: [
                ReferenceValue(
                  patientType: 'human',
                  gender: 'M',
                  minAgeDays: 0,
                  maxAgeDays: 36500,
                  minValue: 41.0,
                  maxValue: 53.0,
                ),
              ],
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

  group('OrderResultsViewController — Inicialización y Estado Base', () {
    test('Inicializa controladores, mapa de visibilidad y notas correctamente', () {
      final order = createTestOrder(notes: 'Paciente en ayunas');
      final controller = OrderResultsViewController(order: order);

      expect(controller.order.id, equals('ORD-TEST-VC-001'));
      expect(controller.patientDisplayName, equals('Juan Pérez'));
      expect(controller.shortId, equals('T-VC-001'));
      expect(controller.notes, equals('Paciente en ayunas'));
      expect(controller.totalParametersCount, equals(6));
      expect(controller.completedParametersCount, equals(0));
      expect(controller.visibleParametersCount, equals(6));
      expect(controller.isSubmitting, isFalse);

      for (var r in controller.results) {
        expect(controller.isVisible(r.labTestId), isTrue);
        expect(controller.getController(r.labTestId), isNotNull);
      }

      controller.dispose();
    });

    test('Inicializa parámetros cualitativos y booleanos con opciones y defaults', () {
      final order = createTestOrder(
        results: [
          OrderTestResult(
            labTestId: 'test-vdrl',
            parameterName: 'VDRL / Sífilis',
            dataType: 'qualitative',
            qualitativeOptions: ['No reactivo', 'Reactivo'],
            expectedQualitativeValue: 'No reactivo',
            resultValue: null,
          ),
          OrderTestResult(
            labTestId: 'test-vih',
            parameterName: 'VIH 1 y 2 Rápida',
            dataType: 'qualitative',
            qualitativeOptions: ['Negativo', 'Positivo'],
            resultValue: 'Positivo',
          ),
        ],
      );

      final controller = OrderResultsViewController(order: order);

      expect(controller.getQualitativeValue('test-vdrl'), equals('No reactivo'));
      expect(controller.getQualitativeValue('test-vih'), equals('Positivo'));

      // Conmutar cualitativo
      controller.setQualitativeValue('test-vdrl', 'Reactivo');
      expect(controller.getQualitativeValue('test-vdrl'), equals('Reactivo'));

      controller.dispose();
    });

    test('Inicializa parámetros de diferencial leucocitario con "0" si están vacíos', () {
      final order = createTestOrder(
        results: [
          OrderTestResult(
            labTestId: 'test-seg',
            parameterName: 'Segmentados / Neutrófilos',
            dataType: 'numeric',
            unitOfMeasure: '%',
          ),
          OrderTestResult(
            labTestId: 'test-linf',
            parameterName: 'Linfocitos',
            dataType: 'numeric',
            unitOfMeasure: '%',
          ),
        ],
      );

      final controller = OrderResultsViewController(order: order);

      expect(controller.getController('test-seg')?.text, equals('0'));
      expect(controller.getController('test-linf')?.text, equals('0'));

      controller.dispose();
    });
  });

  group('OrderResultsViewController — Fórmulas Clínicas Reactivas', () {
    test('Cascada de la Serie Roja: Escritura en Hematocrito (HTC) autocalcula HB, ERI y Wintrobe', () {
      final order = createTestOrder();
      final controller = OrderResultsViewController(order: order);

      final htcResult = controller.results.firstWhere((r) => r.labTestId == 'test-htc');

      // Ingresar HTC = 45 %
      controller.onNumericChanged(htcResult, '45');

      // HB = 45 / 3 = 15
      expect(controller.getController('test-hb')?.text, equals('15'));
      expect(controller.isAutoCalculated('test-hb'), isTrue);
      expect(controller.getFormulaDisplay('test-hb'), equals('Hematocrito / 3'));

      // ERI = 15 / 3 = 5.000
      expect(controller.getController('test-eri')?.text, equals('5.000'));
      expect(controller.isAutoCalculated('test-eri'), isTrue);
      expect(controller.getFormulaDisplay('test-eri'), equals('Hemoglobina / 3'));

      // Wintrobe
      // VCM = (45 * 10) / 5 = 90
      expect(controller.getController('test-vcm')?.text, equals('90'));
      expect(controller.isAutoCalculated('test-vcm'), isTrue);

      // HCM = (15 * 10) / 5 = 30
      expect(controller.getController('test-hcm')?.text, equals('30'));
      expect(controller.isAutoCalculated('test-hcm'), isTrue);

      // CHCM = (15 * 100) / 45 = 33.3
      expect(controller.getController('test-chcm')?.text, equals('33.3'));
      expect(controller.isAutoCalculated('test-chcm'), isTrue);

      controller.dispose();
    });

    test('Re-escritura en Hematocrito desbloquea campos editados manualmente y recalcula la serie', () {
      final order = createTestOrder();
      final controller = OrderResultsViewController(order: order);

      final htcResult = controller.results.firstWhere((r) => r.labTestId == 'test-htc');
      final eriResult = controller.results.firstWhere((r) => r.labTestId == 'test-eri');

      // 1. HTC = 45
      controller.onNumericChanged(htcResult, '45');
      expect(controller.getController('test-eri')?.text, equals('5.000'));

      // 2. Modificar ERI manualmente a 4.850
      controller.onNumericChanged(eriResult, '4.850');
      expect(controller.isManuallyOverridden('test-eri'), isTrue);
      expect(controller.getController('test-eri')?.text, equals('4.850'));

      // 3. Re-escribir HTC = 36 %
      // Debe desbloquear ERI y recalcular: 36 / 9 = 4.000
      controller.onNumericChanged(htcResult, '36');

      expect(controller.isManuallyOverridden('test-eri'), isFalse);
      expect(controller.getController('test-eri')?.text, equals('4.000'));
      expect(controller.getController('test-hb')?.text, equals('12'));
      expect(controller.getController('test-vcm')?.text, equals('90'));

      controller.dispose();
    });

    test('Escritura directa en Hemoglobina (HB) autocalcula ERI sin alterar Hematocrito', () {
      final order = createTestOrder();
      final controller = OrderResultsViewController(order: order);

      final hbResult = controller.results.firstWhere((r) => r.labTestId == 'test-hb');

      // Ingresar HB = 15.0
      controller.onNumericChanged(hbResult, '15.0');

      // ERI = 15.0 / 3 = 5.000
      expect(controller.getController('test-eri')?.text, equals('5.000'));
      expect(controller.getController('test-htc')?.text, equals(''));

      // HCM = (15 * 10) / 5 = 30
      expect(controller.getController('test-hcm')?.text, equals('30'));

      controller.dispose();
    });

    test('Evaluación de Bilirrubina Indirecta (BIL-I = BIL-T - BIL-D)', () {
      final order = createTestOrder(
        results: [
          OrderTestResult(
            labTestId: 'test-bilt',
            parameterName: 'Bilirrubina Total',
            dataType: 'numeric',
            unitOfMeasure: 'mg/dL',
          ),
          OrderTestResult(
            labTestId: 'test-bild',
            parameterName: 'Bilirrubina Directa',
            dataType: 'numeric',
            unitOfMeasure: 'mg/dL',
          ),
          OrderTestResult(
            labTestId: 'test-bili',
            parameterName: 'Bilirrubina Indirecta',
            dataType: 'numeric',
            unitOfMeasure: 'mg/dL',
          ),
        ],
      );

      final controller = OrderResultsViewController(order: order);

      final bilt = controller.results.firstWhere((r) => r.labTestId == 'test-bilt');
      final bild = controller.results.firstWhere((r) => r.labTestId == 'test-bild');

      controller.onNumericChanged(bilt, '1.20');
      controller.onNumericChanged(bild, '0.30');

      // BIL-I = 1.20 - 0.30 = 0.90
      expect(controller.getController('test-bili')?.text, equals('0.90'));
      expect(controller.isAutoCalculated('test-bili'), isTrue);

      controller.dispose();
    });
  });

  group('OrderResultsViewController — Alertas Clínicas y Rangos Demográficos', () {
    test('Evalúa correctamente alertFlags H (Alto), L (Bajo) y Normal según demografía', () {
      final order = createTestOrder();
      final controller = OrderResultsViewController(order: order);

      final hbResult = controller.results.firstWhere((r) => r.labTestId == 'test-hb');

      // Rango referencia hombre: 13.5 - 17.5 g/dL
      // Valor normal: 15.0
      controller.onNumericChanged(hbResult, '15.0');
      expect(controller.getAlertFlag(hbResult), isNull);
      expect(controller.isAlert(hbResult), isFalse);

      // Valor alto (H): 19.0
      controller.onNumericChanged(hbResult, '19.0');
      expect(controller.getAlertFlag(hbResult), equals('H'));
      expect(controller.isAlert(hbResult), isTrue);

      // Valor bajo (L): 11.0
      controller.onNumericChanged(hbResult, '11.0');
      expect(controller.getAlertFlag(hbResult), equals('L'));
      expect(controller.isAlert(hbResult), isTrue);

      controller.dispose();
    });

    test('Alerta ABNORMAL en cualitativos que difieren del valor esperado', () {
      final order = createTestOrder(
        results: [
          OrderTestResult(
            labTestId: 'test-vdrl',
            parameterName: 'VDRL',
            dataType: 'qualitative',
            qualitativeOptions: ['No reactivo', 'Reactivo'],
            expectedQualitativeValue: 'No reactivo',
          ),
        ],
      );

      final controller = OrderResultsViewController(order: order);
      final r = controller.results.first;

      controller.setQualitativeValue('test-vdrl', 'No reactivo');
      expect(controller.getAlertFlag(r), isNull);
      expect(controller.alertCount, equals(0));

      controller.setQualitativeValue('test-vdrl', 'Reactivo');
      expect(controller.getAlertFlag(r), equals('ABNORMAL'));
      expect(controller.isAlert(r), isTrue);
      expect(controller.alertCount, equals(1));

      controller.dispose();
    });
  });

  group('OrderResultsViewController — Diferencial Leucocitario', () {
    test('Calcula la suma del diferencial y valida estrictamente el 100%', () {
      final order = createTestOrder(
        results: [
          OrderTestResult(
            labTestId: 'test-seg',
            parameterName: 'Segmentados',
            dataType: 'numeric',
            unitOfMeasure: '%',
          ),
          OrderTestResult(
            labTestId: 'test-linf',
            parameterName: 'Linfocitos',
            dataType: 'numeric',
            unitOfMeasure: '%',
          ),
          OrderTestResult(
            labTestId: 'test-eos',
            parameterName: 'Eosinófilos',
            dataType: 'numeric',
            unitOfMeasure: '%',
          ),
          OrderTestResult(
            labTestId: 'test-mon',
            parameterName: 'Monocitos',
            dataType: 'numeric',
            unitOfMeasure: '%',
          ),
        ],
      );

      final controller = OrderResultsViewController(order: order);

      // Inicialmente en 0 (suma 0%) -> no es 100%
      expect(controller.differentialSum, equals(0.0));
      expect(controller.isDifferentialValid, isFalse);

      final seg = controller.results.firstWhere((r) => r.labTestId == 'test-seg');
      final linf = controller.results.firstWhere((r) => r.labTestId == 'test-linf');
      final eos = controller.results.firstWhere((r) => r.labTestId == 'test-eos');
      final mon = controller.results.firstWhere((r) => r.labTestId == 'test-mon');

      // Configurar 60 + 30 + 5 + 5 = 100%
      controller.onNumericChanged(seg, '60');
      controller.onNumericChanged(linf, '30');
      controller.onNumericChanged(eos, '5');
      controller.onNumericChanged(mon, '5');

      expect(controller.differentialSum, equals(100.0));
      expect(controller.isDifferentialValid, isTrue);

      // Si suma 95%, debe ser inválido
      controller.onNumericChanged(mon, '0');
      expect(controller.differentialSum, equals(95.0));
      expect(controller.isDifferentialValid, isFalse);

      controller.dispose();
    });
  });

  group('OrderResultsViewController — Generación de DTOs Inmutables', () {
    test('generateUpdatedResults y generateUpdateOrder empaquetan datos y calculan nuevo estado', () {
      final order = createTestOrder(
        totalPrice: 20000,
        paidAmount: 20000,
        status: 'pending',
      );

      final controller = OrderResultsViewController(order: order);

      final hbResult = controller.results.firstWhere((r) => r.labTestId == 'test-hb');
      controller.onNumericChanged(hbResult, '14.5');
      controller.toggleVisibility('test-vcm', false);
      controller.notesController.text = 'Muestra procesada correctamente.';

      final updatedResults = controller.generateUpdatedResults();
      expect(updatedResults.length, equals(6));

      final updatedHb = updatedResults.firstWhere((r) => r.labTestId == 'test-hb');
      expect(updatedHb.resultValue, equals('14.5'));
      expect(updatedHb.showInPrint, isTrue);

      final updatedVcm = updatedResults.firstWhere((r) => r.labTestId == 'test-vcm');
      expect(updatedVcm.showInPrint, isFalse);

      final updateDto = controller.generateUpdateOrder();
      // Como totalPrice == paidAmount (20000 == 20000), el nuevo estado es 'paid'
      expect(updateDto.status, equals('paid'));
      expect(updateDto.notes, equals('Muestra procesada correctamente.'));
      expect(updateDto.results?.length, equals(6));

      controller.dispose();
    });
  });
}
