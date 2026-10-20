import 'clinical_formula.dart';

/// Registro maestro de fórmulas analíticas y reglas de cálculo para el laboratorio clínico.
///
/// Todas las fórmulas implementadas provienen de los estándares médicos internacionales
/// (Índices Eritrocitarios de Wintrobe, Bioquímica Hepática, etc.) y operan de forma pura
/// sin depender de la UI de Flutter.
class ClinicalFormulasRegistry {
  /// Lista de fórmulas clínicas activas en el sistema.
  static final List<ClinicalFormula> formulas = [
    // -------------------------------------------------------------------------
    // 1. SERIE ROJA / HEMATOLOGÍA — ÍNDICES ERITROCITARIOS DE WINTROBE (1929)
    // -------------------------------------------------------------------------

    /// VCM (Volumen Corpuscular Medio)
    /// Fórmula: (Hematocrito * 10) / Eritrocitos (en millones)
    /// Unidades: um3 o fL (Femtolitros)
    ClinicalFormula(
      id: 'wintrobe_vcm',
      name: 'Volumen Corpuscular Medio (VCM)',
      targetCanonical: 'VCM',
      targetAliases: const [
        'VCM',
        'MCV',
        'Volumen Corpuscular Medio',
        'Volumen Eritrocitario Medio',
      ],
      requiredInputs: const ['HTC', 'ERI'],
      formulaDisplay: '(Hematocrito * 10) / Eritrocitos',
      decimalPlaces: 1,
      compute: (inputs) {
        final htc = inputs['HTC'];
        final eriRaw = inputs['ERI'];
        if (htc == null || eriRaw == null || eriRaw <= 0) return null;
        final eri = normalizeErythrocytesToMillions(eriRaw);
        if (eri <= 0) return null;
        return (htc * 10.0) / eri;
      },
    ),

    /// HCM (Hemoglobina Corpuscular Media)
    /// Fórmula: (Hemoglobina * 10) / Eritrocitos (en millones)
    /// Unidades: pg (Picogramos)
    ClinicalFormula(
      id: 'wintrobe_hcm',
      name: 'Hemoglobina Corpuscular Media (HCM)',
      targetCanonical: 'HCM',
      targetAliases: const [
        'HCM',
        'MCH',
        'Hemoglobina Corpuscular Media',
      ],
      requiredInputs: const ['HB', 'ERI'],
      formulaDisplay: '(Hemoglobina * 10) / Eritrocitos',
      decimalPlaces: 1,
      compute: (inputs) {
        final hb = inputs['HB'];
        final eriRaw = inputs['ERI'];
        if (hb == null || eriRaw == null || eriRaw <= 0) return null;
        final eri = normalizeErythrocytesToMillions(eriRaw);
        if (eri <= 0) return null;
        return (hb * 10.0) / eri;
      },
    ),

    /// CHCM (Concentración de Hemoglobina Corpuscular Media)
    /// Fórmula: (Hemoglobina * 100) / Hematocrito
    /// Unidades: g/dL
    ClinicalFormula(
      id: 'wintrobe_chcm',
      name: 'Concentración de Hb Corpuscular Media (CHCM)',
      targetCanonical: 'CHCM',
      targetAliases: const [
        'CHCM',
        'MCHC',
        'Concentración de Hemoglobina Corpuscular Media',
        'Concentracion de Hemoglobina Corpuscular Media',
      ],
      requiredInputs: const ['HB', 'HTC'],
      formulaDisplay: '(Hemoglobina * 100) / Hematocrito',
      decimalPlaces: 1,
      compute: (inputs) {
        final hb = inputs['HB'];
        final htc = inputs['HTC'];
        if (hb == null || htc == null || htc <= 0) return null;
        return (hb * 100.0) / htc;
      },
    ),

    /// Hemoglobina (Regla de los 3: Hematocrito / 3)
    /// Unidades: g/dL
    ClinicalFormula(
      id: 'hemoglobina_rule_of_three',
      name: 'Hemoglobina (Regla de los 3)',
      targetCanonical: 'HB',
      targetAliases: const [
        'HB',
        'HGB',
        'Hemoglobina',
        'Hemoglobin',
      ],
      requiredInputs: const ['HTC'],
      formulaDisplay: 'Hematocrito / 3',
      decimalPlaces: 1,
      compute: (inputs) {
        final htc = inputs['HTC'];
        if (htc == null || htc <= 0) return null;
        return htc / 3.0;
      },
    ),

    /// Eritrocitos / Glóbulos Rojos (Regla de los 3: Hemoglobina / 3 o Hematocrito / 9)
    /// Unidades: x mm3 (en escala millones con 3 decimales, ej. 5.000)
    ClinicalFormula(
      id: 'eritrocitos_rule_of_three',
      name: 'Eritrocitos (Regla de los 3)',
      targetCanonical: 'ERI',
      targetAliases: const [
        'ERI',
        'RBC',
        'Eritrocitos',
        'Eritrocito',
        'Hematíes',
        'Glóbulos Rojos',
      ],
      requiredInputs: const ['HTC'],
      formulaDisplay: 'Hemoglobina / 3',
      decimalPlaces: 3,
      compute: (inputs) {
        final hb = inputs['HB'];
        if (hb != null && hb > 0) {
          return hb / 3.0;
        }
        final htc = inputs['HTC'];
        if (htc != null && htc > 0) {
          return htc / 9.0;
        }
        return null;
      },
    ),

    // -------------------------------------------------------------------------
    // 2. BIOQUÍMICA / PERFIL HEPÁTICO
    // -------------------------------------------------------------------------

    /// Bilirrubina Indirecta
    /// Fórmula: Bilirrubina Total - Bilirrubina Directa
    /// Unidades: mg/dL
    ClinicalFormula(
      id: 'bilirrubina_indirecta',
      name: 'Bilirrubina Indirecta',
      targetCanonical: 'BIL-I',
      targetAliases: const [
        'BIL-I',
        'Bilirrubina Indirecta',
        'Bilirrubina no conjugada',
      ],
      requiredInputs: const ['BIL-T', 'BIL-D'],
      formulaDisplay: 'Bilirrubina Total - Bilirrubina Directa',
      decimalPlaces: 2,
      compute: (inputs) {
        final total = inputs['BIL-T'];
        final directa = inputs['BIL-D'];
        if (total == null || directa == null) return null;
        final diff = total - directa;
        return diff >= 0 ? diff : 0.0;
      },
    ),

    // -------------------------------------------------------------------------
    // 3. BIOQUÍMICA / PERFIL LIPÍDICO (FRIEDEWALD Y CASTELLI)
    // -------------------------------------------------------------------------

    /// Colesterol VLDL
    /// Fórmula: Triglicéridos / 5
    /// Unidades: mg/dL
    ClinicalFormula(
      id: 'lipidos_vldl',
      name: 'Colesterol VLDL',
      targetCanonical: 'VLDL',
      targetAliases: const [
        'VLDL',
        'c-VLDL',
        'Colesterol VLDL',
        'VLDL Colesterol',
        'Lipoproteína de muy baja densidad',
      ],
      requiredInputs: const ['TRIG'],
      formulaDisplay: 'Triglicéridos / 5',
      decimalPlaces: 1,
      compute: (inputs) {
        final trig = inputs['TRIG'];
        if (trig == null || trig < 0) return null;
        return trig / 5.0;
      },
    ),

    /// Colesterol LDL (Fórmula de Friedewald)
    /// Fórmula: Colesterol Total - Colesterol HDL - Colesterol VLDL (o Triglicéridos / 5)
    /// Unidades: mg/dL
    ClinicalFormula(
      id: 'lipidos_ldl',
      name: 'Colesterol LDL',
      targetCanonical: 'LDL',
      targetAliases: const [
        'LDL',
        'c-LDL',
        'Colesterol LDL',
        'LDL Colesterol',
        'Lipoproteína de baja densidad',
      ],
      requiredInputs: const ['COL-T', 'HDL'],
      formulaDisplay: 'Colesterol Total - HDL - VLDL',
      decimalPlaces: 1,
      compute: (inputs) {
        final col = inputs['COL-T'];
        final hdl = inputs['HDL'];
        if (col == null || hdl == null) return null;

        final vldl = inputs['VLDL'] ?? (inputs['TRIG'] != null ? inputs['TRIG']! / 5.0 : null);
        if (vldl == null) return null;

        final ldl = col - hdl - vldl;
        return ldl >= 0 ? ldl : 0.0;
      },
    ),

    /// Riesgo Coronario (Índice de Castelli I)
    /// Fórmula: Colesterol Total / Colesterol HDL
    /// Unidades: % o ratio
    ClinicalFormula(
      id: 'lipidos_riesgo_coronario',
      name: 'Riesgo Coronario',
      targetCanonical: 'RIESG-COR',
      targetAliases: const [
        'RIESG-COR',
        'Riesgo Coronario',
        'Índice de Castelli',
        'Indice de Castelli',
        'Castelli',
        'Castelli I',
        'Relación Colesterol/HDL',
        'Relacion Colesterol/HDL',
      ],
      requiredInputs: const ['COL-T', 'HDL'],
      formulaDisplay: 'Colesterol Total / HDL',
      decimalPlaces: 1,
      compute: (inputs) {
        final col = inputs['COL-T'];
        final hdl = inputs['HDL'];
        if (col == null || hdl == null || hdl <= 0) return null;
        return col / hdl;
      },
    ),
  ];

  /// Mapa de equivalencias para normalizar cualquier código o nombre ingresado
  /// a su clave canónica interna ('ERI', 'HB', 'HTC', 'BIL-T', etc.).
  static const Map<String, List<String>> _canonicalAliases = {
    'ERI': [
      'eri',
      'rbc',
      'eritrocitos',
      'eritrocito',
      'hematies',
      'hematíes',
      'globulos rojos',
      'glóbulos rojos',
      'recuento de eritrocitos',
    ],
    'HB': [
      'hb',
      'hgb',
      'hemoglobina',
      'hemoglobin',
    ],
    'HTC': [
      'htc',
      'hto',
      'hematocrito',
      'hematocrit',
    ],
    'VCM': [
      'vcm',
      'mcv',
      'volumen corpuscular medio',
      'volumen eritrocitario medio',
    ],
    'HCM': [
      'hcm',
      'mch',
      'hemoglobina corpuscular media',
    ],
    'CHCM': [
      'chcm',
      'mchc',
      'concentracion de hemoglobina corpuscular media',
      'concentración de hemoglobina corpuscular media',
    ],
    'BIL-T': [
      'bil-t',
      'bilirrubina total',
      'bilirrubinatotal',
      'total bilirubin',
    ],
    'BIL-D': [
      'bil-d',
      'bilirrubina directa',
      'bilirrubinadirecta',
      'direct bilirubin',
    ],
    'BIL-I': [
      'bil-i',
      'bilirrubina indirecta',
      'bilirrubinaindirecta',
      'indirect bilirubin',
    ],
    'SEG': [
      'seg',
      'segmentados',
      'neutrofilos segmentados',
      'neutrófilos segmentados',
    ],
    'LINF': [
      'linf',
      'linfocitos',
      'lymphocytes',
    ],
    'EOS': [
      'eos',
      'eosinofilos',
      'eosinófilos',
      'eosinophils',
    ],
    'MON': [
      'mon',
      'monocitos',
      'monocytes',
    ],
    'BAN': [
      'ban',
      'bandas',
      'abastonados',
    ],
    'BAS': [
      'bas',
      'basofilos',
      'basófilos',
      'basophils',
    ],
    'LINF-ATIP': [
      'linf-atip',
      'linfocitos atipicos',
      'linfocitos atípicos',
    ],
    'LEU': [
      'leu',
      'wbc',
      'leucocitos',
      'leucocito',
      'globulos blancos',
      'glóbulos blancos',
      'recuento de leucocitos',
    ],
    'PLAQ': [
      'plaq',
      'plt',
      'plaquetas',
      'plaqueta',
      'recuento de plaquetas',
    ],
    'COL-T': [
      'col-t',
      'col',
      'colesterol',
      'colesterol total',
      'colesteroltotal',
      'total cholesterol',
    ],
    'TRIG': [
      'trig',
      'trigliceridos',
      'triglicéridos',
      'triglycerides',
    ],
    'HDL': [
      'hdl',
      'c-hdl',
      'colesterol hdl',
      'colesterolhdl',
      'hdl colesterol',
      'hdl cholesterol',
    ],
    'LDL': [
      'ldl',
      'c-ldl',
      'colesterol ldl',
      'colesterolldl',
      'ldl colesterol',
      'ldl cholesterol',
    ],
    'VLDL': [
      'vldl',
      'c-vldl',
      'colesterol vldl',
      'colesterolvldl',
      'vldl colesterol',
      'vldl cholesterol',
    ],
    'RIESG-COR': [
      'riesg-cor',
      'riesgo coronario',
      'riesgocoronario',
      'indice de castelli',
      'índice de castelli',
      'castelli',
      'castelli i',
      'relacion colesterol/hdl',
      'relación colesterol/hdl',
    ],
  };

  /// Normaliza el valor de eritrocitos a escala millones (ej. 5.0).
  /// Si se ingresó en unidades absolutas (ej. 5,000,000) o en miles (ej. 5,000),
  /// lo convierte a millones para su uso en las fórmulas de Wintrobe.
  static double normalizeErythrocytesToMillions(double eri) {
    if (eri > 100000) {
      return eri / 1000000.0;
    } else if (eri > 100) {
      return eri / 1000.0;
    }
    return eri;
  }

  /// Claves canónicas que integran el diferencial leucocitario porcentual (deben sumar 100%).
  static const List<String> differentialKeys = [
    'SEG',
    'LINF',
    'EOS',
    'MON',
    'BAN',
    'BAS',
    'LINF-ATIP',
  ];

  /// Computa la suma total de los porcentajes del diferencial leucocitario.
  /// Retorna `null` si ninguno de los parámetros diferenciales está presente.
  static double? calculateLeukocyteDifferentialSum(Map<String, double> availableInputs) {
    double total = 0.0;
    bool hasAny = false;
    for (final key in differentialKeys) {
      if (availableInputs.containsKey(key)) {
        hasAny = true;
        total += availableInputs[key]!;
      }
    }
    return hasAny ? total : null;
  }

  /// Valida si el diferencial leucocitario está completo y suma exactamente el 100%.
  /// Si el diferencial tiene algún valor ingresado, la suma debe ser igual a 100% (tolerancia ±0.05).
  static bool isDifferentialValid(double? sum) {
    if (sum == null) return true;
    return (sum - 100.0).abs() < 0.05;
  }

  /// Evalúa el flag médico de un resultado numérico contra sus rangos de referencia:
  /// - 'H': Por encima del valor máximo (High / Alto).
  /// - 'L': Por debajo del valor mínimo (Low / Bajo).
  /// - null: Dentro del rango normal o sin rangos.
  static String? evaluateAlertFlag({
    required double value,
    required double minValue,
    required double maxValue,
  }) {
    if (value > maxValue) return 'H';
    if (value < minValue) return 'L';
    return null;
  }

  /// Lista aplanada de pares (alias, claveCanonica) ordenada por longitud de alias descendente,
  /// garantizando que frases compuestas (ej. 'hemoglobina corpuscular media') se evalúen
  /// antes que términos más genéricos (ej. 'hemoglobina').
  static final List<MapEntry<String, String>> _sortedAliases = () {
    final list = <MapEntry<String, String>>[];
    for (final entry in _canonicalAliases.entries) {
      // Agregar la clave canónica misma
      list.add(MapEntry(entry.key.toLowerCase(), entry.key));
      for (final alias in entry.value) {
        list.add(MapEntry(alias.trim().toLowerCase(), entry.key));
      }
    }
    // Ordenar de mayor a menor longitud de texto
    list.sort((a, b) => b.key.length.compareTo(a.key.length));
    return list;
  }();

  /// Resuelve la clave canónica estándar ('ERI', 'HB', etc.) a partir de un texto.
  /// Retorna `null` si el texto no corresponde a ningún parámetro conocido de fórmulas.
  static String? resolveCanonicalKey(String text) {
    final clean = text.trim().toLowerCase();

    // 1. Coincidencia exacta con la clave canónica (ej. "VCM", "HB")
    for (final key in _canonicalAliases.keys) {
      if (clean == key.toLowerCase()) return key;
    }

    // 2. Coincidencia al inicio con paréntesis (ej. "VCM (Volumen Corpuscular Medio)")
    for (final key in _canonicalAliases.keys) {
      final keyLower = key.toLowerCase();
      if (clean.startsWith('$keyLower ') ||
          clean.startsWith('$keyLower(') ||
          clean.startsWith('$keyLower-') ||
          clean.contains('($keyLower)')) {
        return key;
      }
    }

    // 3. Coincidencia de alias ordenados por mayor longitud (evita colisiones como 'hemoglobina' en 'HCM')
    for (final item in _sortedAliases) {
      if (clean == item.key || clean.contains(item.key)) {
        return item.value;
      }
    }

    return null;
  }

  /// Busca si existe una fórmula que tenga como destino el parámetro dado (por nombre o código).
  static ClinicalFormula? findFormulaForTarget(String text) {
    for (final formula in formulas) {
      if (formula.matchesTarget(text)) {
        return formula;
      }
    }
    return null;
  }

  /// Verifica si un parámetro es un campo potencialmente autocalculado.
  static bool isCalculatedTarget(String text) {
    return findFormulaForTarget(text) != null;
  }

  /// Formatea un valor numérico clínico:
  /// - Para eritrocitos (3 decimales), respeta estrictamente los 3 decimales (ej. '5.000').
  /// - Si es entero exacto (ej. 90.0, 30.0), lo formatea sin decimales superfluos ('90', '30').
  /// - De lo contrario, respeta el número de decimales clínicos requeridos (ej. '33.3', '0.10').
  static String formatClinicalValue(double val, int decimals) {
    if (decimals == 3) {
      return val.toStringAsFixed(3);
    }
    if (val == val.roundToDouble() && decimals <= 1) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(decimals);
  }

  /// Evalúa una fórmula específica sobre un conjunto de valores canónicos disponibles.
  /// Retorna un [ClinicalCalculationResult] si el cómputo fue exitoso, o `null` si faltan datos.
  static ClinicalCalculationResult? evaluateFormula(
    ClinicalFormula formula,
    Map<String, double> availableCanonicalInputs,
  ) {
    // Verificar que todos los insumos necesarios tengan valor numérico
    for (final req in formula.requiredInputs) {
      if (!availableCanonicalInputs.containsKey(req)) {
        return null;
      }
    }

    final computed = formula.compute(availableCanonicalInputs);
    if (computed == null || computed.isNaN || computed.isInfinite) {
      return null;
    }

    return ClinicalCalculationResult(
      formulaId: formula.id,
      formulaName: formula.name,
      formulaDisplay: formula.formulaDisplay,
      value: computed,
      formattedValue: formatClinicalValue(computed, formula.decimalPlaces),
    );
  }

  /// Evalúa todas las fórmulas que aplican para los parámetros provistos.
  /// [availableInputs]: Mapa de clave canónica ('ERI', 'HB', etc.) -> valor numérico.
  /// Retorna un mapa indexado por la clave canónica destino ('VCM', 'HCM', etc.).
  static Map<String, ClinicalCalculationResult> evaluateAll(
    Map<String, double> availableInputs,
  ) {
    final results = <String, ClinicalCalculationResult>{};
    final workingInputs = Map<String, double>.from(availableInputs);

    for (final formula in formulas) {
      final res = evaluateFormula(formula, workingInputs);
      if (res != null) {
        results[formula.targetCanonical] = res;
        workingInputs[formula.targetCanonical] = res.value;
      }
    }

    return results;
  }
}
