import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/tools/calculators/clinical_formulas_registry.dart';

void main() {
  group('ClinicalFormulasRegistry — Pruebas de Fórmulas Clínicas y BHC', () {
    test('1. Cascada de Serie Roja desde Hematocrito (Regla de los 3 e Índices de Wintrobe)', () {
      // Parámetro base: Hematocrito = 45 %
      final inputs = {
        'HTC': 45.0,
      };

      final results = ClinicalFormulasRegistry.evaluateAll(inputs);

      // Hemoglobina = Hematocrito / 3 = 15.0 g/dL
      expect(results['HB'], isNotNull);
      expect(results['HB']!.value, 15.0);
      expect(results['HB']!.formattedValue, '15');

      // Eritrocitos = Hematocrito / 9 = 5.000 millones
      expect(results['ERI'], isNotNull);
      expect(results['ERI']!.value, closeTo(5.0, 0.001));
      expect(results['ERI']!.formattedValue, '5.000');
    });

    test('2. Índices de Wintrobe con Serie Roja Completa (Valores Canónicos)', () {
      final inputs = {
        'HTC': 45.0, // Hematocrito: 45 %
        'HB': 15.0,  // Hemoglobina: 15.0 g/dL
        'ERI': 5.0,  // Eritrocitos: 5.000 x mm3
      };

      final results = ClinicalFormulasRegistry.evaluateAll(inputs);

      // VCM = (45 * 10) / 5.0 = 90
      expect(results['VCM'], isNotNull);
      expect(results['VCM']!.value, 90.0);
      expect(results['VCM']!.formattedValue, '90');

      // HCM = (15.0 * 10) / 5.0 = 30
      expect(results['HCM'], isNotNull);
      expect(results['HCM']!.value, 30.0);
      expect(results['HCM']!.formattedValue, '30');

      // CHCM = (15.0 * 100) / 45 = 33.3333...
      expect(results['CHCM'], isNotNull);
      expect(results['CHCM']!.value, closeTo(33.33, 0.05));
      expect(results['CHCM']!.formattedValue, '33.3');
    });

    test('3. Normalización de Escala de Eritrocitos (Millones vs Miles vs Unidades)', () {
      expect(ClinicalFormulasRegistry.normalizeErythrocytesToMillions(5.0), 5.0);
      expect(ClinicalFormulasRegistry.normalizeErythrocytesToMillions(5000.0), 5.0);
      expect(ClinicalFormulasRegistry.normalizeErythrocytesToMillions(5000000.0), 5.0);

      // Evaluación de VCM con eritrocitos en formato miles (5000)
      final inputsMiles = {
        'HTC': 45.0,
        'ERI': 5000.0,
      };
      final resultsMiles = ClinicalFormulasRegistry.evaluateAll(inputsMiles);
      expect(resultsMiles['VCM']?.value, 90.0);
    });

    test('4. Sobreescritura Manual de Hemoglobina y Recálculo de Índices', () {
      // Caso patológico: Hematocrito 45% pero Hemoglobina medida manualmente en 12.0 g/dL (hipocromía)
      final inputs = {
        'HTC': 45.0,
        'HB': 12.0,
        'ERI': 5.0,
      };

      final results = ClinicalFormulasRegistry.evaluateAll(inputs);

      // VCM se mantiene constante (45 * 10 / 5) = 90
      expect(results['VCM']!.value, 90.0);

      // HCM disminuye: (12.0 * 10) / 5.0 = 24.0
      expect(results['HCM']!.value, 24.0);
      expect(results['HCM']!.formattedValue, '24');

      // CHCM disminuye: (12.0 * 100) / 45 = 26.666...
      expect(results['CHCM']!.value, closeTo(26.67, 0.05));
      expect(results['CHCM']!.formattedValue, '26.7');
    });

    test('5. Caso Real de Perfil Hepático (Bilirrubina Indirecta)', () {
      final inputs = {
        'BIL-T': 0.4,
        'BIL-D': 0.3,
      };

      final results = ClinicalFormulasRegistry.evaluateAll(inputs);
      expect(results['BIL-I']?.value, closeTo(0.1, 0.001));
      expect(results['BIL-I']?.formattedValue, '0.10');
    });

    test('6. Resolución de Claves Canónicas por Códigos y Nombres en Español', () {
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Hematocrito'), 'HTC');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('HTC'), 'HTC');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('HTO'), 'HTC');

      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Hemoglobina'), 'HB');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('HB'), 'HB');

      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Eritrocitos'), 'ERI');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('ERI'), 'ERI');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Recuento de eritrocitos'), 'ERI');

      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Leucocitos'), 'LEU');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('LEU'), 'LEU');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Glóbulos Blancos'), 'LEU');

      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Plaquetas'), 'PLAQ');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('PLAQ'), 'PLAQ');

      expect(ClinicalFormulasRegistry.resolveCanonicalKey('VCM (Volumen Corpuscular Medio)'), 'VCM');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('HCM (Hemoglobina Corpuscular Media)'), 'HCM');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('CHCM'), 'CHCM');

      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Glucosa'), isNull);
    });

    test('7. Casos Borde: División por Cero y Datos Incompletos', () {
      final inputsCero = {
        'ERI': 0.0,
        'HB': 14.0,
        'HTC': 42.0,
      };

      final resultsCero = ClinicalFormulasRegistry.evaluateAll(inputsCero);
      expect(resultsCero['VCM'], isNull);
      expect(resultsCero['HCM'], isNull);
      expect(resultsCero['CHCM'], isNotNull);
    });

    test('8. Validación del Conteo Diferencial Leucocitario (Exactamente 100%)', () {
      final inputsCorrecto = {
        'SEG': 58.0,
        'LINF': 42.0,
        'EOS': 0.0,
        'MON': 0.0,
        'BAN': 0.0,
        'BAS': 0.0,
        'LINF-ATIP': 0.0,
      };

      final total = ClinicalFormulasRegistry.calculateLeukocyteDifferentialSum(inputsCorrecto);
      expect(total, 100.0);
      expect(ClinicalFormulasRegistry.isDifferentialValid(total), isTrue);

      final inputsIncompleto = {
        'SEG': 50.0,
        'LINF': 40.0,
        'EOS': 0.0,
      };
      final totalIncompleto = ClinicalFormulasRegistry.calculateLeukocyteDifferentialSum(inputsIncompleto);
      expect(totalIncompleto, 90.0);
      expect(ClinicalFormulasRegistry.isDifferentialValid(totalIncompleto), isFalse);

      expect(ClinicalFormulasRegistry.isDifferentialValid(null), isTrue);
    });

    test('9. Evaluación de Flags de Alerta Fuera de Rango (H / L)', () {
      // Linfocitos = 42 con rango 20.0 - 40.0 -> H
      expect(
        ClinicalFormulasRegistry.evaluateAlertFlag(value: 42.0, minValue: 20.0, maxValue: 40.0),
        'H',
      );

      // Hematocrito = 32.0 con rango 36.0 - 50.0 -> L
      expect(
        ClinicalFormulasRegistry.evaluateAlertFlag(value: 32.0, minValue: 36.0, maxValue: 50.0),
        'L',
      );

      // Hematocrito = 45.0 con rango 36.0 - 50.0 -> null (normal)
      expect(
        ClinicalFormulasRegistry.evaluateAlertFlag(value: 45.0, minValue: 36.0, maxValue: 50.0),
        isNull,
      );
    });
  });
}
