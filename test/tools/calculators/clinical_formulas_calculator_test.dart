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

      // Índices de Wintrobe derivados automáticamente en cascada completa
      expect(results['VCM'], isNotNull);
      expect(results['VCM']!.value, 90.0);
      expect(results['HCM'], isNotNull);
      expect(results['HCM']!.value, 30.0);
      expect(results['CHCM'], isNotNull);
      expect(results['CHCM']!.value, closeTo(33.33, 0.05));
    });

    test('1.b. Cálculo de Eritrocitos e Índices directamente desde Hemoglobina sola', () {
      final inputs = {
        'HB': 15.0,
      };

      final results = ClinicalFormulasRegistry.evaluateAll(inputs);

      // Eritrocitos = Hemoglobina / 3 = 5.000 millones
      expect(results['ERI'], isNotNull);
      expect(results['ERI']!.value, closeTo(5.0, 0.001));
      expect(results['ERI']!.formattedValue, '5.000');
      expect(results['ERI']!.formulaDisplay, 'Hemoglobina / 3');

      // Hematocrito = Hemoglobina * 3 = 45.0
      expect(results['HTC'], isNotNull);
      expect(results['HTC']!.value, 45.0);

      // HCM = (15.0 * 10) / 5.0 = 30
      expect(results['HCM'], isNotNull);
      expect(results['HCM']!.value, 30.0);

      // Con Hematocrito autocalculado, VCM y CHCM se completan
      expect(results['VCM'], isNotNull);
      expect(results['VCM']!.value, 90.0);
      expect(results['CHCM'], isNotNull);
      expect(results['CHCM']!.value, closeTo(33.3, 0.1));
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

      // Parámetros de otros perfiles y fluidos (deben aislarse y no colisionar con Serie Roja / Blanca)
      expect(
        ClinicalFormulasRegistry.resolveCanonicalKey(
          'Eritrocitos (Sedimento Urinario)',
          subclassification: 'Sedimento Microscópico',
          medicalClassification: 'Uroanálisis',
          dataType: 'text',
        ),
        isNull,
      );
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Eritrocitos (Sedimento Urinario)'), isNull);
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Hemoglobina (Heces)'), isNull);
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Leucocitos (Orina)'), isNull);
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Leucocitos Libres'), isNull);
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Eritrosedimentación (VSG)'), isNull);
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Bacterias'), isNull);
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Monotest (Mononucleosis Infecciosa)'), isNull);
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

    test('10. Bioquímica / Perfil Lipídico: Caso Real de Laboratorio', () {
      // Datos reales extraídos de la fotografía del paciente:
      // Colesterol Total: 170 mg/dL, Triglicéridos: 98 mg/dL, HDL: 58 mg/dL
      final inputs = {
        'COL-T': 170.0,
        'TRIG': 98.0,
        'HDL': 58.0,
      };

      final results = ClinicalFormulasRegistry.evaluateAll(inputs);

      // 1. VLDL = 98 / 5 = 19.6
      expect(results['VLDL'], isNotNull);
      expect(results['VLDL']!.value, 19.6);
      expect(results['VLDL']!.formattedValue, '19.6');
      expect(results['VLDL']!.formulaDisplay, 'Triglicéridos / 5');

      // 2. LDL = 170 - 58 - 19.6 = 92.4
      expect(results['LDL'], isNotNull);
      expect(results['LDL']!.value, 92.4);
      expect(results['LDL']!.formattedValue, '92.4');
      expect(results['LDL']!.formulaDisplay, 'Colesterol Total - HDL - VLDL');

      // 3. Riesgo Coronario = 170 / 58 = 2.931... -> formateado a 1 decimal: '2.9'
      expect(results['RIESG-COR'], isNotNull);
      expect(results['RIESG-COR']!.formattedValue, '2.9');
      expect(results['RIESG-COR']!.formulaDisplay, 'Colesterol Total / HDL');

      // Caso exacto de reporte clínico: COL-T = 207, TRIG = 92, HDL = 43
      final inputsCasoReal = {
        'COL-T': 207.0,
        'TRIG': 92.0,
        'HDL': 43.0,
      };
      final resultsCasoReal = ClinicalFormulasRegistry.evaluateAll(inputsCasoReal);
      // VLDL = 92 / 5 = 18.4
      expect(resultsCasoReal['VLDL']!.formattedValue, '18.4');
      // LDL = 207 - 43 - 18.4 = 145.6
      expect(resultsCasoReal['LDL']!.formattedValue, '145.6');
      // Riesgo Coronario = 207 / 43 = 4.81395... -> '4.8'
      expect(resultsCasoReal['RIESG-COR']!.formattedValue, '4.8');
    });

    test('11. Resolución Canónica de Alias de Perfil Lipídico', () {
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Colesterol'), 'COL-T');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Colesterol Total'), 'COL-T');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('COL-T'), 'COL-T');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Triglicéridos'), 'TRIG');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Trigliceridos'), 'TRIG');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('TRIG'), 'TRIG');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('HDL'), 'HDL');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Colesterol HDL'), 'HDL');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('c-HDL'), 'HDL');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('LDL'), 'LDL');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Colesterol LDL'), 'LDL');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('c-LDL'), 'LDL');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('VLDL'), 'VLDL');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Colesterol VLDL'), 'VLDL');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('c-VLDL'), 'VLDL');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Riesgo Coronario'), 'RIESG-COR');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Índice de Castelli'), 'RIESG-COR');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Castelli'), 'RIESG-COR');
    });

    test('12. Casos Borde de Perfil Lipídico (División por Cero y Datos Incompletos)', () {
      // HDL = 0.0 -> no debe fallar con división por cero
      final inputsHdlCero = {
        'COL-T': 200.0,
        'TRIG': 150.0,
        'HDL': 0.0,
      };

      final resultsHdlCero = ClinicalFormulasRegistry.evaluateAll(inputsHdlCero);
      expect(resultsHdlCero['VLDL'], isNotNull);
      expect(resultsHdlCero['VLDL']!.value, 30.0);
      expect(resultsHdlCero['RIESG-COR'], isNull); // Protegido contra div por 0

      // Falta Triglicéridos -> calcula Riesgo Coronario pero no VLDL ni LDL
      final inputsSinTrig = {
        'COL-T': 200.0,
        'HDL': 50.0,
      };

      final resultsSinTrig = ClinicalFormulasRegistry.evaluateAll(inputsSinTrig);
      expect(resultsSinTrig['RIESG-COR'], isNotNull);
      expect(resultsSinTrig['RIESG-COR']!.formattedValue, '4'); // 200 / 50 = 4.0
      expect(resultsSinTrig['VLDL'], isNull);
      expect(resultsSinTrig['LDL'], isNull);
    });

    test('13. Función Renal: Autocálculo de BUN a partir de Urea (Urea * 0.47)', () {
      // Caso 1: Paciente de muestra (Urea = 38)
      final inputs1 = {'UREA': 38.0};
      final results1 = ClinicalFormulasRegistry.evaluateAll(inputs1);

      expect(results1['BUN'], isNotNull);
      expect(results1['BUN']!.value, closeTo(17.86, 0.001));
      expect(results1['BUN']!.formattedValue, '17.9');
      expect(results1['BUN']!.formulaDisplay, 'Urea * 0.47');

      // Caso 2: Entero exacto (Urea = 100 -> 47.0 -> formateado '47')
      final inputs2 = {'UREA': 100.0};
      final results2 = ClinicalFormulasRegistry.evaluateAll(inputs2);
      expect(results2['BUN'], isNotNull);
      expect(results2['BUN']!.value, 47.0);
      expect(results2['BUN']!.formattedValue, '47');

      // Caso 3: Valores límite (Urea = 0 o negativo no calculan)
      expect(ClinicalFormulasRegistry.evaluateAll({'UREA': 0.0})['BUN'], isNull);
      expect(ClinicalFormulasRegistry.evaluateAll({})['BUN'], isNull);
    });

    test('14. Resolución Canónica de Alias de BUN y Urea', () {
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('BUN'), 'BUN');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Nitrógeno de Urea (BUN)'), 'BUN');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Nitrogeno de Urea (BUN)'), 'BUN');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Nitrógeno de Urea'), 'BUN');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Nitrógeno Ureico'), 'BUN');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Blood Urea Nitrogen'), 'BUN');

      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Urea'), 'UREA');
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('UREA'), 'UREA');

      // Exclusión estricta de fluidos y orina
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Urea en Orina de 24 Horas'), isNull);
      expect(ClinicalFormulasRegistry.resolveCanonicalKey('Depuración de Urea'), isNull);
    });

    test('15. Aislamiento Estricto de Parámetros Especiales (EOS-SANG, PMN-NEUT, COLIN, Líquidos)', () {
      // Eosinófilos Absolutos en Sangre (EOS-SANG) no debe confundirse con diferencial porcentual (EOS)
      expect(
        ClinicalFormulasRegistry.resolveCanonicalKey(
          'Eosinófilos Absolutos en Sangre',
          subclassification: 'Serie Blanca',
          medicalClassification: 'Hematología',
          unitOfMeasure: 'mm3',
          dataType: 'numeric',
        ),
        isNull,
      );

      // Eosinófilos en Moco Nasal
      expect(
        ClinicalFormulasRegistry.resolveCanonicalKey(
          'Eosinófilos en Moco Nasal',
          subclassification: 'Frotis Sanguíneo',
          medicalClassification: 'Hematología',
          unitOfMeasure: '%',
          dataType: 'numeric',
        ),
        isNull,
      );

      // Polimorfonucleares Neutrófilos (PMN-NEUT) en heces no debe resolver como SEG
      expect(
        ClinicalFormulasRegistry.resolveCanonicalKey(
          'Polimorfonucleares Neutrófilos',
          subclassification: 'Examen Microscópico',
          medicalClassification: 'Coprología',
          unitOfMeasure: '%',
          dataType: 'numeric',
        ),
        isNull,
      );

      // Mononucleares Eosinófilos (MN-EOS) en heces no debe resolver como EOS
      expect(
        ClinicalFormulasRegistry.resolveCanonicalKey(
          'Mononucleares Eosinófilos',
          subclassification: 'Examen Microscópico',
          medicalClassification: 'Coprología',
          unitOfMeasure: '%',
          dataType: 'numeric',
        ),
        isNull,
      );

      // Colinesterasa Sérica (COLIN) no debe resolver como Colesterol Total (COL-T)
      expect(
        ClinicalFormulasRegistry.resolveCanonicalKey(
          'Colinesterasa Sérica',
          subclassification: 'Función Hepática',
          medicalClassification: 'Química Sanguínea',
          unitOfMeasure: 'U/L',
          dataType: 'numeric',
        ),
        isNull,
      );

      // Colesterol en Líquido Pleural no debe resolver como COL-T
      expect(
        ClinicalFormulasRegistry.resolveCanonicalKey(
          'Colesterol en Líquido Pleural',
          subclassification: 'Líquidos Biológicos',
          medicalClassification: 'Química Sanguínea',
          unitOfMeasure: 'mg/dL',
          dataType: 'numeric',
        ),
        isNull,
      );

      // Glicohemoglobina A1c (HbA1c) y variantes no deben resolver como Hemoglobina (HB) de Serie Roja
      expect(
        ClinicalFormulasRegistry.resolveCanonicalKey(
          'Glicohemoglobina A1c (HbA1c)',
          subclassification: 'Control Glucémico',
          medicalClassification: 'Química Sanguínea',
          unitOfMeasure: '%',
          dataType: 'numeric',
        ),
        isNull,
      );
      expect(
        ClinicalFormulasRegistry.resolveCanonicalKey('Hemoglobina Glicosilada (HbA1c)'),
        isNull,
      );
      expect(
        ClinicalFormulasRegistry.resolveCanonicalKey('Hemoglobina Glucosilada'),
        isNull,
      );
      expect(
        ClinicalFormulasRegistry.resolveCanonicalKey('Electroforesis de Hemoglobina'),
        isNull,
      );
      expect(
        ClinicalFormulasRegistry.isCalculatedTarget('Glicohemoglobina A1c (HbA1c)', unitOfMeasure: '%'),
        isFalse,
      );
      expect(
        ClinicalFormulasRegistry.isCalculatedTarget('Eritrocitos (Sedimento Urinario)'),
        isFalse,
      );
    });
  });
}
