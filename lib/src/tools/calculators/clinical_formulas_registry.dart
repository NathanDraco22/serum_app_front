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
    // 1. SERIE ROJA / HEMATOLOGÍA — ESTIMACIONES BASE Y REGLA DE LOS 3
    // -------------------------------------------------------------------------

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

    /// Hematocrito (Regla de los 3: Hemoglobina * 3)
    /// Unidades: %
    ClinicalFormula(
      id: 'hematocrito_rule_of_three',
      name: 'Hematocrito (Regla de los 3)',
      targetCanonical: 'HTC',
      targetAliases: const [
        'HTC',
        'HCT',
        'Hematocrito',
        'Hematocrit',
      ],
      requiredInputs: const ['HB'],
      formulaDisplay: 'Hemoglobina * 3',
      decimalPlaces: 1,
      compute: (inputs) {
        final hb = inputs['HB'];
        if (hb == null || hb <= 0) return null;
        return hb * 3.0;
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
      requiredInputs: const ['HB', 'HTC'],
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
    // 2. SERIE ROJA / HEMATOLOGÍA — ÍNDICES ERITROCITARIOS DE WINTROBE (1929)
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

    // -------------------------------------------------------------------------
    // 5. QUÍMICA SANGUÍNEA / FUNCIÓN RENAL — NITRÓGENO DE UREA (BUN)
    // -------------------------------------------------------------------------

    /// Nitrógeno de Urea (BUN)
    /// Fórmula: Urea * 0.47
    /// Unidades: mg/dL
    ClinicalFormula(
      id: 'nitrogeno_de_urea_bun',
      name: 'Nitrógeno de Urea (BUN)',
      targetCanonical: 'BUN',
      targetAliases: const [
        'BUN',
        'Nitrógeno de Urea (BUN)',
        'Nitrogeno de Urea (BUN)',
        'Nitrógeno de Urea',
        'Nitrogeno de Urea',
        'Nitrógeno Ureico',
        'Nitrogeno Ureico',
        'Nitrógeno Ureico en Sangre',
        'Nitrogeno Ureico en Sangre',
        'Blood Urea Nitrogen',
      ],
      requiredInputs: const ['UREA'],
      formulaDisplay: 'Urea * 0.47',
      decimalPlaces: 1,
      compute: (inputs) {
        final urea = inputs['UREA'];
        if (urea == null || urea <= 0) return null;
        return urea * 0.47;
      },
    ),
  ];

  /// Mapa de equivalencias para normalizar cualquier código o nombre ingresado
  /// a su clave canónica interna ('ERI', 'HB', 'HTC', 'BIL-T', etc.).
  static const Map<String, List<String>> _canonicalAliases = {
    'ERI': [
      'eri',
      'rbc',
      'r.b.c.',
      'eritrocitos',
      'eritrocito',
      'hematies',
      'hematíes',
      'globulos rojos',
      'glóbulos rojos',
      'recuento de eritrocitos',
      'recuento de globulos rojos',
      'recuento de glóbulos rojos',
      'conteo de eritrocitos',
      'conteo de globulos rojos',
      'conteo de glóbulos rojos',
      'recuento globular',
      'conteo globular',
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
    'BUN': [
      'bun',
      'nitrógeno de urea (bun)',
      'nitrogeno de urea (bun)',
      'nitrógeno de urea',
      'nitrogeno de urea',
      'nitrógeno ureico',
      'nitrogeno ureico',
      'nitrógeno ureico en sangre',
      'nitrogeno ureico en sangre',
      'blood urea nitrogen',
    ],
    'UREA': [
      'urea',
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

  /// Palabras clave de fluidos y muestras no sanguíneas que descartan
  /// que un parámetro pertenezca a la Serie Roja o Serie Blanca sanguínea.
  static const Set<String> _hematologyExclusionKeywords = {
    'sedimento',
    'urinario',
    'urinaria',
    'orina',
    'heces',
    'fecal',
    'fecales',
    'nasal',
    'nasales',
    'frotis',
    'vsg',
    'sedimentacion',
    'sedimentación',
    'monotest',
    'bacterias',
    'libres',
    'agrupados',
    'campo',
    'campos',
    'absoluto',
    'absolutos',
    'absoluta',
    'absolutas',
    'polimorfonucleares',
    'mononucleares',
    'wright',
    'reticulocitos',
    'moco',
    'glico',
    'glicosil',
    'glucosil',
    'a1c',
    'fetal',
    'electroforesis',
    'plasmatica',
    'plasmática',
  };

  /// Claves canónicas pertenecientes estrictamente a la hematología sanguínea.
  static const Set<String> _bloodHematologyKeys = {
    'ERI',
    'HB',
    'HTC',
    'VCM',
    'HCM',
    'CHCM',
    'LEU',
    'PLAQ',
    'SEG',
    'LINF',
    'EOS',
    'MON',
    'BAN',
    'BAS',
    'LINF-ATIP',
  };

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

  /// Resuelve la clave canónica estándar ('ERI', 'HB', etc.) a partir de un texto,
  /// incorporando contexto clínico opcional para evitar colisiones entre perfiles
  /// (ej. 'Eritrocitos (Sedimento Urinario)' vs 'Eritrocitos' de Serie Roja).
  ///
  /// Retorna `null` si el texto no corresponde a ningún parámetro conocido de fórmulas.
  static String? resolveCanonicalKey(
    String text, {
    String? subclassification,
    String? medicalClassification,
    String? dataType,
    String? unitOfMeasure,
  }) {
    final clean = text.trim().toLowerCase();
    if (clean.isEmpty) return null;

    // Validación preventiva por tipo de dato: todos los parámetros analíticos de cálculo
    // clínico (Serie Roja, diferencial, bioquímica, lípidos) son exclusivamente numéricos.
    if (dataType != null && dataType.isNotEmpty && dataType != 'numeric') {
      return null;
    }

    // 1. Coincidencia exacta con la clave canónica (ej. "VCM", "HB", "ERI")
    for (final key in _canonicalAliases.keys) {
      if (clean == key.toLowerCase()) {
        return _validateContextualMatch(
          key,
          clean,
          subclassification,
          medicalClassification,
          unitOfMeasure,
        );
      }
    }

    // 2. Coincidencia al inicio con delimitadores (ej. "VCM (Volumen Corpuscular Medio)", "ERI-")
    for (final key in _canonicalAliases.keys) {
      final keyLower = key.toLowerCase();
      if (clean.startsWith('$keyLower ') ||
          clean.startsWith('$keyLower(') ||
          clean.startsWith('$keyLower-') ||
          clean.contains('($keyLower)')) {
        return _validateContextualMatch(
          key,
          clean,
          subclassification,
          medicalClassification,
          unitOfMeasure,
        );
      }
    }

    // 3. Coincidencia de alias ordenados por mayor longitud con delimitación de palabra
    for (final item in _sortedAliases) {
      final alias = item.key;
      final key = item.value;

      // Coincidencia exacta del alias completo
      if (clean == alias) {
        return _validateContextualMatch(
          key,
          clean,
          subclassification,
          medicalClassification,
          unitOfMeasure,
        );
      }

      // Si el alias es corto (<= 4 caracteres, ej. 'eri', 'hb', 'mon', 'eos'), exigir delimitador estricto
      // para evitar falsos positivos dentro de palabras mayores (ej. 'bacterias', 'seriado', 'monotest').
      final bool matches;
      if (alias.length <= 4) {
        final pattern = RegExp('(^|[^a-zA-Z0-9áéíóúüñÁÉÍÓÚÜÑ])$alias([^a-zA-Z0-9áéíóúüñÁÉÍÓÚÜÑ]|\$)');
        matches = pattern.hasMatch(clean);
      } else {
        matches = clean.contains(alias);
      }

      if (matches) {
        final validated = _validateContextualMatch(
          key,
          clean,
          subclassification,
          medicalClassification,
          unitOfMeasure,
        );
        if (validated != null) return validated;
      }
    }

    return null;
  }

  /// Valida que la coincidencia encontrada no sea un falso positivo proveniente de
  /// otra muestra o perfil clínico (orina, heces, secreción nasal, etc.).
  static String? _validateContextualMatch(
    String key,
    String cleanText,
    String? subclassification,
    String? medicalClassification,
    String? unitOfMeasure,
  ) {
    if (_bloodHematologyKeys.contains(key)) {
      // 1. Descartar si el texto contiene palabras clave de exclusión hematológica
      for (final kw in _hematologyExclusionKeywords) {
        if (cleanText.contains(kw)) {
          return null;
        }
      }

      // 2. Descartar si la subclasificación pertenece a uroanálisis o coprología
      if (subclassification != null && subclassification.isNotEmpty) {
        final subLower = subclassification.toLowerCase();
        if (subLower.contains('sedimento') ||
            subLower.contains('orina') ||
            subLower.contains('uroan') ||
            subLower.contains('coprolog') ||
            subLower.contains('heces') ||
            subLower.contains('frotis')) {
          return null;
        }
      }

      // 3. Descartar si la clasificación médica es uroanálisis o coprología
      if (medicalClassification != null && medicalClassification.isNotEmpty) {
        final medLower = medicalClassification.toLowerCase();
        if (medLower.contains('uroan') ||
            medLower.contains('coprolog') ||
            medLower.contains('orina') ||
            medLower.contains('heces')) {
          return null;
        }
      }

      // 4. Para diferencial leucocitario porcentual: debe medirse en '%' (descartar recuentos absolutos o x campo)
      if (differentialKeys.contains(key)) {
        if (unitOfMeasure != null && unitOfMeasure.trim().isNotEmpty) {
          final cleanUnit = unitOfMeasure.trim().toLowerCase();
          if (!cleanUnit.contains('%') && !cleanUnit.contains('porc')) {
            return null;
          }
        }
      }

      // 5. Para Hemoglobina de Serie Roja (HB): descartar si la unidad es porcentual '%' o 'mmol' (ej. HbA1c)
      if (key == 'HB') {
        if (unitOfMeasure != null && unitOfMeasure.trim().isNotEmpty) {
          final cleanUnit = unitOfMeasure.trim().toLowerCase();
          if (cleanUnit.contains('%') || cleanUnit.contains('porc') || cleanUnit.contains('mmol')) {
            return null;
          }
        }
      }
    }

    // Para perfil lipídico: descartar muestras de orina o líquidos biológicos
    if (key == 'COL-T' || key == 'TRIG' || key == 'HDL' || key == 'LDL' || key == 'VLDL' || key == 'RIESG-COR') {
      if (cleanText.contains('orina') ||
          cleanText.contains('urinari') ||
          cleanText.contains('liquido') ||
          cleanText.contains('líquido') ||
          cleanText.contains('pleural') ||
          cleanText.contains('ascit') ||
          cleanText.contains('ascít') ||
          cleanText.contains('cefalorraqu') ||
          cleanText.contains('cefalorraquí')) {
        return null;
      }
    }

    // Para UREA y BUN sanguíneos: descartar si el texto hace referencia a orina o depuración
    if (key == 'BUN' || key == 'UREA') {
      if (cleanText.contains('orina') ||
          cleanText.contains('urinari') ||
          cleanText.contains('24h') ||
          cleanText.contains('24 horas') ||
          cleanText.contains('depuracion') ||
          cleanText.contains('depuración')) {
        return null;
      }
    }

    return key;
  }

  /// Busca si existe una fórmula que tenga como destino el parámetro dado (por nombre o código).
  static ClinicalFormula? findFormulaForTarget(
    String text, {
    String? subclassification,
    String? medicalClassification,
    String? dataType,
    String? unitOfMeasure,
  }) {
    final canonical = resolveCanonicalKey(
      text,
      subclassification: subclassification,
      medicalClassification: medicalClassification,
      dataType: dataType,
      unitOfMeasure: unitOfMeasure,
    );
    if (canonical == null) return null;
    for (final formula in formulas) {
      if (formula.targetCanonical == canonical) {
        return formula;
      }
    }
    return null;
  }

  /// Verifica si un parámetro es un campo potencialmente autocalculado.
  static bool isCalculatedTarget(
    String text, {
    String? subclassification,
    String? medicalClassification,
    String? dataType,
    String? unitOfMeasure,
  }) {
    return findFormulaForTarget(
          text,
          subclassification: subclassification,
          medicalClassification: medicalClassification,
          dataType: dataType,
          unitOfMeasure: unitOfMeasure,
        ) !=
        null;
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
    // Verificar que los insumos necesarios tengan valor numérico
    if (formula.id == 'eritrocitos_rule_of_three') {
      // Eritrocitos puede derivar de Hemoglobina o Hematocrito
      if (!availableCanonicalInputs.containsKey('HB') && !availableCanonicalInputs.containsKey('HTC')) {
        return null;
      }
    } else {
      for (final req in formula.requiredInputs) {
        if (!availableCanonicalInputs.containsKey(req)) {
          return null;
        }
      }
    }

    final computed = formula.compute(availableCanonicalInputs);
    if (computed == null || computed.isNaN || computed.isInfinite) {
      return null;
    }

    final String displayFormula;
    if (formula.id == 'eritrocitos_rule_of_three') {
      displayFormula = (availableCanonicalInputs['HB'] != null && availableCanonicalInputs['HB']! > 0)
          ? 'Hemoglobina / 3'
          : 'Hematocrito / 9';
    } else {
      displayFormula = formula.formulaDisplay;
    }

    return ClinicalCalculationResult(
      formulaId: formula.id,
      formulaName: formula.name,
      formulaDisplay: displayFormula,
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
      // Si el parámetro ya fue provisto explícitamente en los insumos, respetarlo y no sobreescribir
      if (availableInputs.containsKey(formula.targetCanonical)) {
        continue;
      }
      final res = evaluateFormula(formula, workingInputs);
      if (res != null) {
        results[formula.targetCanonical] = res;
        workingInputs[formula.targetCanonical] = res.value;
      }
    }

    return results;
  }
}
