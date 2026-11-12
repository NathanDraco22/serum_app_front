import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import '../../../tools/calculators/clinical_formula.dart';
import '../../../tools/calculators/clinical_formulas_registry.dart';
import '../../../tools/exports/pdf/templates/clinical_order_study_group.dart';
import '../../../tools/formatters/thousands_separator_input_formatter.dart';

class OrderResultsViewController extends ChangeNotifier {
  final OrderInDb order;
  final bool autoCalculateFormulas;

  late final List<OrderTestResult> _results;
  late final Map<String, bool> _visibilityMap;
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, String> _qualitativeValues;
  late final Map<String, String> _studyNameByTestId;
  late final TextEditingController notesController;
  late final List<OrderTestResult> _initialDraft;
  late final String _initialNotes;

  final Set<String> _autoCalculatedFieldIds = {};
  final Map<String, String> _autoCalculatedFormulas = {};
  final Set<String> _manuallyOverriddenFieldIds = {};
  bool _isEvaluatingCalculations = false;
  bool _isSubmitting = false;

  /// Resuelve la clave canónica estándar de un parámetro incorporando su contexto clínico
  /// (subclasificación, clasificación médica, tipo de dato y unidad de medida) para evitar colisiones multi-perfil.
  String? _resolveCanonical(OrderTestResult r) {
    return ClinicalFormulasRegistry.resolveCanonicalKey(
      r.parameterName,
      subclassification: r.subclassification,
      medicalClassification: r.medicalClassification,
      dataType: r.dataType,
      unitOfMeasure: r.unitOfMeasure,
    );
  }

  OrderResultsViewController({
    required this.order,
    this.autoCalculateFormulas = true,
  }) {
    _results = List.from(order.results);
    _visibilityMap = {
      for (var r in _results) r.labTestId: r.showInPrint,
    };
    _controllers = {};
    _qualitativeValues = {};
    _studyNameByTestId = {
      for (var r in _results) r.labTestId: ClinicalOrderGrouper.resolveStudyNameForResult(r, order),
    };
    notesController = TextEditingController(text: order.notes ?? '');

    for (var r in _results) {
      if (r.dataType == 'qualitative' || r.dataType == 'boolean') {
        final options = r.qualitativeOptions.isNotEmpty
            ? r.qualitativeOptions
            : ['Negativo', 'Positivo'];
        final initial = r.resultValue ?? r.expectedQualitativeValue;
        _qualitativeValues[r.labTestId] = (initial != null && options.contains(initial))
            ? initial
            : options.first;
      } else {
        final canonical = _resolveCanonical(r);
        final initial = r.resultValue?.trim() ?? '';
        // Serie Blanca: los 7 parámetros diferenciales tienen valor por defecto 0 si están vacíos
        if (autoCalculateFormulas &&
            canonical != null &&
            ClinicalFormulasRegistry.differentialKeys.contains(canonical) &&
            initial.isEmpty) {
          _controllers[r.labTestId] = TextEditingController(text: '0');
        } else {
          final formattedInitial = r.dataType == 'numeric' && initial.isNotEmpty
              ? ThousandsSeparatorInputFormatter.formatText(initial)
              : initial;
          _controllers[r.labTestId] = TextEditingController(text: formattedInitial);
        }
      }
    }

    if (autoCalculateFormulas) {
      // Restauración inteligente de campos autocalculados que ya vengan guardados
      _detectAndRestoreAutoCalculatedFields();

      // Evaluación inicial preventiva si la orden ya posee valores precargados
      _evaluateCalculations();
    }

    // Snapshot del estado inicial visible (incluye defaults y autocalculados).
    // Se usa para detectar cambios reales del usuario sin marcar como "sucio"
    // el simple hecho de abrir el diálogo.
    _initialDraft = generateUpdatedResults();
    _initialNotes = notesController.text.trim();
  }

  /// Analiza los valores precargados en la orden (al abrir o reabrir el diálogo)
  /// y restaura el estado de `_autoCalculatedFieldIds`, `_autoCalculatedFormulas`
  /// y `_manuallyOverriddenFieldIds` según corresponda.
  void _detectAndRestoreAutoCalculatedFields() {
    final available = <String, double>{};
    for (var r in _results) {
      if (r.dataType == 'numeric') {
        final text = _controllers[r.labTestId]?.text.trim() ?? '';
        final val = ThousandsSeparatorInputFormatter.tryParseDouble(text);
        final canonical = _resolveCanonical(r);
        if (val != null && canonical != null) {
          available[canonical] = val;
        }
      }
    }

    // 1. Serie Roja: Hemoglobina, Hematocrito y Eritrocitos (independiente del orden en la lista)
    final htcVal = available['HTC'];
    final hbVal = available['HB'];
    final eriVal = available['ERI'];

    // Si ambos HTC y HB están presentes y cumplen la Regla de los 3 (HB = HTC / 3),
    // HTC se preserva siempre como insumo primario y HB se restaura como autocalculado.
    if (htcVal != null && htcVal > 0 && hbVal != null && hbVal > 0) {
      final expectedHb = htcVal / 3.0;
      if ((hbVal - expectedHb).abs() <= 0.15) {
        for (final r in _results) {
          if (_resolveCanonical(r) == 'HB') {
            _autoCalculatedFieldIds.add(r.labTestId);
            _autoCalculatedFormulas[r.labTestId] = 'Hematocrito / 3';
          }
        }
      }
    }

    // Eritrocitos: verificar si coincide con HB / 3 (o HTC / 9)
    if (eriVal != null && eriVal > 0) {
      final refBase = hbVal ?? (htcVal != null ? htcVal / 3.0 : null);
      if (refBase != null && refBase > 0) {
        final expectedEri = refBase / 3.0;
        if ((eriVal - expectedEri).abs() <= 0.05) {
          for (final r in _results) {
            if (_resolveCanonical(r) == 'ERI') {
              _autoCalculatedFieldIds.add(r.labTestId);
              _autoCalculatedFormulas[r.labTestId] = 'Hemoglobina / 3';
            }
          }
        }
      }
    }

    // 2. Fórmulas de ClinicalFormulasRegistry (Wintrobe, Lipídico, Bilirrubinas, BUN)
    for (final formula in ClinicalFormulasRegistry.formulas) {
      if (formula.targetCanonical == 'HB' ||
          formula.targetCanonical == 'HTC' ||
          formula.targetCanonical == 'ERI') {
        continue;
      }

      final computed = ClinicalFormulasRegistry.evaluateFormula(formula, available);
      if (computed != null) {
        final currentVal = available[formula.targetCanonical];
        if (currentVal != null) {
          final diff = (currentVal - computed.value).abs();
          final tolerance = formula.decimalPlaces == 2 ? 0.05 : 0.2;
          if (diff <= tolerance) {
            for (final targetResult in _results) {
              if (_resolveCanonical(targetResult) == formula.targetCanonical) {
                _autoCalculatedFieldIds.add(targetResult.labTestId);
                _autoCalculatedFormulas[targetResult.labTestId] = computed.formulaDisplay;
              }
            }
          }
        }
      }
    }

    // 3. Cualquier valor numérico ya guardado en la orden que NO sea autocalculado
    // (ej. HTC primario, HB o ERI medidos en equipo que difieren de la fórmula)
    // se registra en _manuallyOverriddenFieldIds para evitar ser sobreescrito accidentalmente.
    for (final r in _results) {
      if (r.dataType != 'numeric') continue;
      final savedText = r.resultValue?.trim() ?? '';
      if (savedText.isEmpty) continue;
      if (_autoCalculatedFieldIds.contains(r.labTestId)) continue;

      final canonical = _resolveCanonical(r);
      if (canonical != null && ClinicalFormulasRegistry.differentialKeys.contains(canonical)) {
        final val = ThousandsSeparatorInputFormatter.tryParseDouble(savedText) ?? 0.0;
        if (val <= 0) continue;
      }
      _manuallyOverriddenFieldIds.add(r.labTestId);
    }
  }

  // ---------------------------------------------------------------------------
  // Getters de Estado
  // ---------------------------------------------------------------------------

  List<OrderTestResult> get results => List.unmodifiable(_results);

  bool get isSubmitting => _isSubmitting;

  set isSubmitting(bool value) {
    if (_isSubmitting != value) {
      _isSubmitting = value;
      notifyListeners();
    }
  }

  bool get hasResults => _results.isNotEmpty;

  String get shortId => order.id.length > 8
      ? order.id.substring(order.id.length - 8).toUpperCase()
      : order.id.toUpperCase();

  String get patientDisplayName => order.patientInfo?.name ?? 'Paciente #${order.patientId}';

  String get examName => order.examName;

  String get notes => notesController.text.trim();

  // ---------------------------------------------------------------------------
  // Acceso a Parámetros Individuales
  // ---------------------------------------------------------------------------

  TextEditingController? getController(String labTestId) => _controllers[labTestId];

  String? getQualitativeValue(String labTestId) => _qualitativeValues[labTestId];

  bool isVisible(String labTestId) => _visibilityMap[labTestId] ?? true;

  bool isAutoCalculated(String labTestId) =>
      autoCalculateFormulas && _autoCalculatedFieldIds.contains(labTestId);

  String? getFormulaDisplay(String labTestId) =>
      autoCalculateFormulas ? _autoCalculatedFormulas[labTestId] : null;

  bool isManuallyOverridden(String labTestId) => _manuallyOverriddenFieldIds.contains(labTestId);

  // ---------------------------------------------------------------------------
  // Evaluación Clínica de Rangos y Alertas Demográficas
  // ---------------------------------------------------------------------------

  /// Edad del paciente en días a la fecha de la orden.
  ///
  /// Devuelve `null` cuando no hay fecha de nacimiento ni edad explícita.
  int? get patientAgeInDays {
    final patientInfo = order.patientInfo;
    if (patientInfo == null) return null;
    return ReferenceValueResolver.tryAgeInDaysAt(
      dateOfBirthMs: patientInfo.dateOfBirth,
      referenceDateMs: order.createdAt,
      fallbackAgeYears: patientInfo.explicitAge,
    );
  }

  /// Evalúa clínicamente un resultado con el pipeline compartido de negocio.
  ClinicalEvaluationResult evaluateResult(
    OrderTestResult result, {
    String? resultValue,
  }) {
    final patient = order.patientInfo;
    return const ClinicalEvaluationService().evaluate(
      ClinicalEvaluationInput(
        dateOfBirthMs: patient?.dateOfBirth ?? 0,
        explicitAgeYears: patient?.explicitAge,
        referenceDateMs: order.createdAt,
        gender: patient?.gender ?? '',
        dataType: result.dataType,
        resultValue: resultValue ?? getLiveResultValue(result),
        expectedQualitativeValue: result.expectedQualitativeValue,
        referenceValues: result.referenceValues,
      ),
    );
  }

  /// Obtiene el valor capturado en vivo para un resultado.
  String? getLiveResultValue(OrderTestResult result) {
    if (result.dataType == 'qualitative' || result.dataType == 'boolean') {
      return _qualitativeValues[result.labTestId];
    }
    return _controllers[result.labTestId]?.text.trim();
  }

  /// Resuelve el rango de referencia aplicable según edad y género.
  ReferenceResolution findReferenceResolutionForPatient(OrderTestResult r) {
    return evaluateResult(r).referenceResolution;
  }

  /// Busca el valor de referencia apropiado según la demografía del paciente.
  ReferenceValue? findReferenceValueForPatient(OrderTestResult r) {
    return evaluateResult(r).referenceResolution.value;
  }

  /// Evalúa el flag de alerta médica de un resultado en tiempo real (H, L, ABNORMAL o null).
  String? getAlertFlag(OrderTestResult r) {
    return evaluateResult(r).alertFlag;
  }

  bool isAlert(OrderTestResult r) {
    return evaluateResult(r).hasAlert;
  }

  // ---------------------------------------------------------------------------
  // Getters Derivados y Métricas en Tiempo Real
  // ---------------------------------------------------------------------------

  int get totalParametersCount => _results.length;

  int get completedParametersCount {
    int count = 0;
    for (var r in _results) {
      if (r.dataType == 'qualitative' || r.dataType == 'boolean') {
        if (_qualitativeValues[r.labTestId]?.isNotEmpty ?? false) count++;
      } else {
        final text = _controllers[r.labTestId]?.text.trim() ?? '';
        if (text.isNotEmpty) count++;
      }
    }
    return count;
  }

  int get visibleParametersCount => _visibilityMap.values.where((v) => v).length;

  int get alertCount {
    int count = 0;
    for (var r in _results) {
      if (isAlert(r)) count++;
    }
    return count;
  }

  /// Suma porcentual del diferencial leucocitario calculada en vivo sobre los parámetros presentes y visibles.
  double? get differentialSum {
    final availableCanonicalInputs = <String, double>{};
    for (var r in _results) {
      if (r.dataType != 'qualitative' && r.dataType != 'boolean' && isVisible(r.labTestId)) {
        final text = _controllers[r.labTestId]?.text.trim() ?? '';
        if (text.isNotEmpty) {
          final val = ThousandsSeparatorInputFormatter.tryParseDouble(text);
          if (val != null) {
            final canonical = _resolveCanonical(r);
            if (canonical != null) {
              availableCanonicalInputs[canonical] = val;
            }
          }
        }
      }
    }
    return ClinicalFormulasRegistry.calculateLeukocyteDifferentialSum(availableCanonicalInputs);
  }

  /// Indica si el usuario ha iniciado la captura de la Serie Blanca / diferencial leucocitario
  /// (al menos un parámetro visible del diferencial es > 0, fue editado a mano con valor != 0,
  /// o ya se capturó el conteo de Leucocitos totales `LEU` en la orden).
  bool get hasDifferentialStarted {
    bool hasVisibleDifferential = false;
    for (var r in _results) {
      if (!isVisible(r.labTestId)) continue;
      final canonical = _resolveCanonical(r);
      if (canonical != null && ClinicalFormulasRegistry.differentialKeys.contains(canonical)) {
        hasVisibleDifferential = true;
        final text = _controllers[r.labTestId]?.text.trim() ?? '';
        final val = ThousandsSeparatorInputFormatter.tryParseDouble(text) ?? 0.0;
        if (val > 0) return true;
        if (_manuallyOverriddenFieldIds.contains(r.labTestId) && text.isNotEmpty && val != 0.0) {
          return true;
        }
      }
    }

    if (!hasVisibleDifferential) return false;

    // Si hay diferencial visible y el analista ya ingresó el conteo de Leucocitos (LEU),
    // la Serie Blanca está activa y el diferencial no puede quedarse en 0%.
    for (var r in _results) {
      if (!isVisible(r.labTestId)) continue;
      if (_resolveCanonical(r) == 'LEU') {
        final text = _controllers[r.labTestId]?.text.trim() ?? '';
        final val = ThousandsSeparatorInputFormatter.tryParseDouble(text) ?? 0.0;
        if (val > 0) return true;
      }
    }

    return false;
  }

  /// Indica si el diferencial leucocitario es matemáticamente válido (suma exactamente 100%).
  bool get isDifferentialValid => ClinicalFormulasRegistry.isDifferentialValid(differentialSum);

  // ---------------------------------------------------------------------------
  // Mutaciones de Estado y Cálculo Reactivo
  // ---------------------------------------------------------------------------

  /// Alterna o establece la visibilidad de impresión para un parámetro específico.
  void toggleVisibility(String labTestId, [bool? show]) {
    final current = _visibilityMap[labTestId] ?? true;
    _visibilityMap[labTestId] = show ?? !current;
    notifyListeners();
  }

  /// Actualiza el valor de un parámetro cualitativo o booleano.
  void setQualitativeValue(String labTestId, String val) {
    _qualitativeValues[labTestId] = val;
    notifyListeners();
  }

  /// Aplica texto de atajo rápido predefinido y notifica el cambio.
  void applyPresetText(String labTestId, String preset) {
    final controller = _controllers[labTestId];
    if (controller != null) {
      controller.text = preset;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: preset.length),
      );
    }
    final r = _results.cast<OrderTestResult?>().firstWhere(
      (item) => item?.labTestId == labTestId,
      orElse: () => null,
    );
    if (r != null) {
      onNumericChanged(r, preset);
    }
  }

  /// Procesa el cambio en un campo numérico o de texto libre, sincronizando el controlador,
  /// detectando sobreescrituras manuales y disparando el motor de fórmulas clínicas reactivas.
  void onNumericChanged(OrderTestResult r, String val) {
    if (!autoCalculateFormulas) {
      final controller = _controllers[r.labTestId];
      if (controller != null && controller.text != val) {
        controller.text = val;
      }
      notifyListeners();
      return;
    }
    final controller = _controllers[r.labTestId];
    if (controller != null && controller.text != val) {
      controller.text = val;
    }

    final canonical = _resolveCanonical(r);
    if (val.trim().isEmpty) {
      _manuallyOverriddenFieldIds.remove(r.labTestId);
      _autoCalculatedFieldIds.remove(r.labTestId);
      _autoCalculatedFormulas.remove(r.labTestId);
    } else {
      // 1. Hematocrito: disparador maestro de la Serie Roja
      if (canonical == 'HTC') {
        _manuallyOverriddenFieldIds.add(r.labTestId);
        for (final other in _results) {
          final otherCanonical = _resolveCanonical(other);
          if (otherCanonical == 'HB' ||
              otherCanonical == 'ERI' ||
              otherCanonical == 'VCM' ||
              otherCanonical == 'HCM' ||
              otherCanonical == 'CHCM') {
            _manuallyOverriddenFieldIds.remove(other.labTestId);
          }
        }
      }
      // 2. Hemoglobina: cálculo bidireccional hacia HTC (solo si HTC no fue ingresado a mano) y hacia ERI y Wintrobe
      else if (canonical == 'HB') {
        _manuallyOverriddenFieldIds.add(r.labTestId);
        for (final other in _results) {
          final otherCanonical = _resolveCanonical(other);
          // Si HTC ya fue ingresado a mano por el analista, NO se desbloquea ni sobreescribe
          if (otherCanonical == 'HTC') {
            if (!_manuallyOverriddenFieldIds.contains(other.labTestId)) {
              _manuallyOverriddenFieldIds.remove(other.labTestId);
            }
          } else if (otherCanonical == 'ERI' ||
              otherCanonical == 'VCM' ||
              otherCanonical == 'HCM' ||
              otherCanonical == 'CHCM') {
            _manuallyOverriddenFieldIds.remove(other.labTestId);
          }
        }
      }
      // 3. Eritrocitos: si el usuario lo digita manualmente, desbloquea Wintrobe
      else if (canonical == 'ERI') {
        _manuallyOverriddenFieldIds.add(r.labTestId);
        for (final other in _results) {
          final otherCanonical = _resolveCanonical(other);
          if (otherCanonical == 'VCM' || otherCanonical == 'HCM' || otherCanonical == 'CHCM') {
            _manuallyOverriddenFieldIds.remove(other.labTestId);
          }
        }
      }
      // 4. Colesterol Total, Triglicéridos y HDL son disparadores del Perfil Lipídico:
      else if (canonical == 'COL-T' || canonical == 'TRIG' || canonical == 'HDL') {
        for (final other in _results) {
          final otherCanonical = _resolveCanonical(other);
          if (otherCanonical == 'VLDL' ||
              otherCanonical == 'LDL' ||
              otherCanonical == 'RIESG-COR') {
            _manuallyOverriddenFieldIds.remove(other.labTestId);
          }
        }
      }
      // 5. Bilirrubina Total y Directa son disparadores de la Indirecta:
      else if (canonical == 'BIL-T' || canonical == 'BIL-D') {
        for (final other in _results) {
          final otherCanonical = _resolveCanonical(other);
          if (otherCanonical == 'BIL-I') {
            _manuallyOverriddenFieldIds.remove(other.labTestId);
          }
        }
      }
      // 6. Urea es disparador de Nitrógeno de Urea (BUN):
      else if (canonical == 'UREA') {
        for (final other in _results) {
          final otherCanonical = _resolveCanonical(other);
          if (otherCanonical == 'BUN') {
            _manuallyOverriddenFieldIds.remove(other.labTestId);
          }
        }
      }

      // Si el usuario teclea en un campo derivado o individual, se marca como sobreescritura manual
      if (canonical != 'HTC' &&
          canonical != 'HB' &&
          canonical != 'ERI' &&
          canonical != 'COL-T' &&
          canonical != 'TRIG' &&
          canonical != 'HDL' &&
          canonical != 'BIL-T' &&
          canonical != 'BIL-D' &&
          canonical != 'UREA') {
        if (canonical != null && ClinicalFormulasRegistry.differentialKeys.contains(canonical)) {
          final parsed = ThousandsSeparatorInputFormatter.tryParseDouble(val) ?? 0.0;
          if (parsed == 0.0) {
            _manuallyOverriddenFieldIds.remove(r.labTestId);
          } else {
            _manuallyOverriddenFieldIds.add(r.labTestId);
          }
        } else {
          _manuallyOverriddenFieldIds.add(r.labTestId);
        }
      }
    }
    _autoCalculatedFieldIds.remove(r.labTestId);
    _autoCalculatedFormulas.remove(r.labTestId);

    if (autoCalculateFormulas) {
      _evaluateCalculations(triggeredTestId: r.labTestId);
    }
    notifyListeners();
  }

  /// Evalúa en tiempo real las fórmulas clínicas aplicables según los parámetros presentes
  void _evaluateCalculations({String? triggeredTestId}) {
    if (!autoCalculateFormulas) return;
    if (_isEvaluatingCalculations) return;
    _isEvaluatingCalculations = true;

    try {
      final available = <String, double>{};
      OrderTestResult? htcResult;
      OrderTestResult? hbResult;
      OrderTestResult? eriResult;
      OrderTestResult? vcmResult;
      OrderTestResult? hcmResult;
      OrderTestResult? chcmResult;

      for (var r in _results) {
        final canonical = _resolveCanonical(r);
        if (canonical != null) {
          if (canonical == 'HTC') htcResult = r;
          if (canonical == 'HB') hbResult = r;
          if (canonical == 'ERI') eriResult = r;
          if (canonical == 'VCM') vcmResult = r;
          if (canonical == 'HCM') hcmResult = r;
          if (canonical == 'CHCM') chcmResult = r;

          final text = _controllers[r.labTestId]?.text.trim() ?? '';
          final val = ThousandsSeparatorInputFormatter.tryParseDouble(text);
          if (val != null) {
            // Un campo autocalculado previamente por el sistema NO debe insertarse en available
            // a menos que haya sido sobreescrito manualmente por el usuario. Esto garantiza
            // que evaluateAll siempre recalcule el valor con los insumos disparadores más recientes
            // (evitando quedar congelado en estados intermedios mientras el usuario escribe).
            final wasAuto = _autoCalculatedFieldIds.contains(r.labTestId);
            final isManual = _manuallyOverriddenFieldIds.contains(r.labTestId);
            if (!wasAuto || isManual) {
              available[canonical] = val;
            }
          }
        }
      }

      // Identificar si el campo disparador es Hematocrito, Hemoglobina, Eritrocitos, etc.
      String? triggeredCanonical;
      if (triggeredTestId != null) {
        final triggeredResult = _results.cast<OrderTestResult?>().firstWhere(
          (r) => r?.labTestId == triggeredTestId,
          orElse: () => null,
        );
        if (triggeredResult != null) {
          triggeredCanonical = _resolveCanonical(triggeredResult);
        }
      }

      // =========================================================================
      // 1. CASCADA DE LA SERIE ROJA (DISPARADOR PRINCIPAL: HEMATOCRITO)
      // =========================================================================
      if (triggeredCanonical == 'HTC' && htcResult != null) {
        final htcVal = available['HTC'];
        if (htcVal != null && htcVal > 0) {
          // A) Hemoglobina = Hematocrito / 3 (1 decimal)
          if (hbResult != null) {
            final approxHb = htcVal / 3.0;
            final formattedHb = ClinicalFormulasRegistry.formatClinicalValue(approxHb, 1);
            _controllers[hbResult.labTestId]?.text = ThousandsSeparatorInputFormatter.formatText(
              formattedHb,
            );
            available['HB'] = approxHb;
            _autoCalculatedFieldIds.add(hbResult.labTestId);
            _autoCalculatedFormulas[hbResult.labTestId] = 'Hematocrito / 3';
          }

          // B) Eritrocitos = Hemoglobina / 3 (o Hematocrito / 9) (3 decimales en millones)
          if (eriResult != null && !_manuallyOverriddenFieldIds.contains(eriResult.labTestId)) {
            final currentHb = available['HB'] ?? (htcVal / 3.0);
            final approxEri = currentHb / 3.0;
            final formattedEri = ClinicalFormulasRegistry.formatClinicalValue(approxEri, 3);
            _controllers[eriResult.labTestId]?.text = ThousandsSeparatorInputFormatter.formatText(
              formattedEri,
            );
            available['ERI'] = approxEri;
            _autoCalculatedFieldIds.add(eriResult.labTestId);
            _autoCalculatedFormulas[eriResult.labTestId] = 'Hemoglobina / 3';
          }
        } else if (htcVal == null) {
          // Si HTC fue vaciado, limpiar campos derivados de Serie Roja si eran automáticos
          if (hbResult != null && _autoCalculatedFieldIds.contains(hbResult.labTestId)) {
            _controllers[hbResult.labTestId]?.text = '';
            _autoCalculatedFieldIds.remove(hbResult.labTestId);
            _autoCalculatedFormulas.remove(hbResult.labTestId);
            available.remove('HB');
          }
          if (eriResult != null && _autoCalculatedFieldIds.contains(eriResult.labTestId)) {
            _controllers[eriResult.labTestId]?.text = '';
            _autoCalculatedFieldIds.remove(eriResult.labTestId);
            _autoCalculatedFormulas.remove(eriResult.labTestId);
            available.remove('ERI');
          }
        }
      } else if (triggeredCanonical == 'HB' && hbResult != null) {
        // Disparador de Hemoglobina (cálculo bidireccional: HTC = HB * 3, ERI = HB / 3)
        final hbVal = available['HB'];
        if (hbVal != null && hbVal > 0) {
          // A) Hematocrito = Hemoglobina * 3 (1 decimal)
          // SOLO si HTC está vacío o si NO fue ingresado manualmente por el usuario
          final htcIsManual =
              htcResult != null && _manuallyOverriddenFieldIds.contains(htcResult.labTestId);
          final htcIsEmpty =
              htcResult == null || (_controllers[htcResult.labTestId]?.text.trim().isEmpty ?? true);
          if (htcResult != null && (htcIsEmpty || !htcIsManual)) {
            final approxHtc = hbVal * 3.0;
            final formattedHtc = ClinicalFormulasRegistry.formatClinicalValue(approxHtc, 1);
            _controllers[htcResult.labTestId]?.text = ThousandsSeparatorInputFormatter.formatText(
              formattedHtc,
            );
            available['HTC'] = approxHtc;
            _autoCalculatedFieldIds.add(htcResult.labTestId);
            _autoCalculatedFormulas[htcResult.labTestId] = 'Hemoglobina * 3';
          }

          // B) Eritrocitos = Hemoglobina / 3 (3 decimales en millones)
          if (eriResult != null && !_manuallyOverriddenFieldIds.contains(eriResult.labTestId)) {
            final approxEri = hbVal / 3.0;
            final formattedEri = ClinicalFormulasRegistry.formatClinicalValue(approxEri, 3);
            _controllers[eriResult.labTestId]?.text = ThousandsSeparatorInputFormatter.formatText(
              formattedEri,
            );
            available['ERI'] = approxEri;
            _autoCalculatedFieldIds.add(eriResult.labTestId);
            _autoCalculatedFormulas[eriResult.labTestId] = 'Hemoglobina / 3';
          }
        } else if (hbVal == null) {
          // Si HB fue vaciado, limpiar HTC si era automático
          if (htcResult != null && _autoCalculatedFieldIds.contains(htcResult.labTestId)) {
            _controllers[htcResult.labTestId]?.text = '';
            _autoCalculatedFieldIds.remove(htcResult.labTestId);
            _autoCalculatedFormulas.remove(htcResult.labTestId);
            available.remove('HTC');
          }
          if (eriResult != null && _autoCalculatedFieldIds.contains(eriResult.labTestId)) {
            _controllers[eriResult.labTestId]?.text = '';
            _autoCalculatedFieldIds.remove(eriResult.labTestId);
            _autoCalculatedFormulas.remove(eriResult.labTestId);
            available.remove('ERI');
          }
        }
      } else if (triggeredTestId == null) {
        // Evaluación preventiva al abrir modal con valores preexistentes
        final htcVal = available['HTC'];
        final hbVal = available['HB'];
        if (htcVal != null && htcVal > 0) {
          if (hbResult != null && (_controllers[hbResult.labTestId]?.text.trim().isEmpty ?? true)) {
            final approxHb = htcVal / 3.0;
            final formattedHb = ClinicalFormulasRegistry.formatClinicalValue(approxHb, 1);
            _controllers[hbResult.labTestId]?.text = ThousandsSeparatorInputFormatter.formatText(
              formattedHb,
            );
            available['HB'] = approxHb;
            _autoCalculatedFieldIds.add(hbResult.labTestId);
            _autoCalculatedFormulas[hbResult.labTestId] = 'Hematocrito / 3';
          }
          if (eriResult != null &&
              (_controllers[eriResult.labTestId]?.text.trim().isEmpty ?? true)) {
            final currentHb = available['HB'] ?? (htcVal / 3.0);
            final approxEri = currentHb / 3.0;
            final formattedEri = ClinicalFormulasRegistry.formatClinicalValue(approxEri, 3);
            _controllers[eriResult.labTestId]?.text = ThousandsSeparatorInputFormatter.formatText(
              formattedEri,
            );
            available['ERI'] = approxEri;
            _autoCalculatedFieldIds.add(eriResult.labTestId);
            _autoCalculatedFormulas[eriResult.labTestId] = 'Hemoglobina / 3';
          }
        } else if (hbVal != null && hbVal > 0) {
          if (htcResult != null &&
              (_controllers[htcResult.labTestId]?.text.trim().isEmpty ?? true)) {
            final approxHtc = hbVal * 3.0;
            final formattedHtc = ClinicalFormulasRegistry.formatClinicalValue(approxHtc, 1);
            _controllers[htcResult.labTestId]?.text = ThousandsSeparatorInputFormatter.formatText(
              formattedHtc,
            );
            available['HTC'] = approxHtc;
            _autoCalculatedFieldIds.add(htcResult.labTestId);
            _autoCalculatedFormulas[htcResult.labTestId] = 'Hemoglobina * 3';
          }
          if (eriResult != null &&
              (_controllers[eriResult.labTestId]?.text.trim().isEmpty ?? true)) {
            final approxEri = hbVal / 3.0;
            final formattedEri = ClinicalFormulasRegistry.formatClinicalValue(approxEri, 3);
            _controllers[eriResult.labTestId]?.text = ThousandsSeparatorInputFormatter.formatText(
              formattedEri,
            );
            available['ERI'] = approxEri;
            _autoCalculatedFieldIds.add(eriResult.labTestId);
            _autoCalculatedFormulas[eriResult.labTestId] = 'Hemoglobina / 3';
          }
        }
      }

      // =========================================================================
      // 2. RECÁLCULO DINÁMICO DE ÍNDICES DE WINTROBE (VCM, HCM, CHCM)
      // =========================================================================
      // Para Wintrobe se utilizan estrictamente los valores presentes en los controladores
      // de HTC, HB y ERI tras el Bloque 1, evitando que evaluateAll invente valores
      // intermedios en memoria si el usuario vació explícitamente un campo en la UI.
      final redSeriesActualInputs = <String, double>{};
      for (final entry in [
        MapEntry('HTC', htcResult),
        MapEntry('HB', hbResult),
        MapEntry('ERI', eriResult),
      ]) {
        final res = entry.value;
        if (res != null) {
          final txt = _controllers[res.labTestId]?.text.trim() ?? '';
          final v = ThousandsSeparatorInputFormatter.tryParseDouble(txt);
          if (v != null && v > 0) {
            redSeriesActualInputs[entry.key] = v;
          }
        }
      }

      final wintrobeKeys = [
        ?vcmResult,
        ?hcmResult,
        ?chcmResult,
      ];

      for (var r in wintrobeKeys) {
        final canonical = _resolveCanonical(r);
        if (canonical == null) continue;
        if (r.labTestId == triggeredTestId) continue;

        final formula = ClinicalFormulasRegistry.formulas.cast<ClinicalFormula?>().firstWhere(
          (f) => f?.targetCanonical == canonical,
          orElse: () => null,
        );
        final calc = formula != null
            ? ClinicalFormulasRegistry.evaluateFormula(formula, redSeriesActualInputs)
            : null;

        if (calc != null) {
          // Solo sobreescribir si no fue modificado manualmente por el usuario
          if (!_manuallyOverriddenFieldIds.contains(r.labTestId)) {
            final controller = _controllers[r.labTestId];
            if (controller != null) {
              final formatted = ThousandsSeparatorInputFormatter.formatText(calc.formattedValue);
              if (controller.text != formatted) {
                controller.text = formatted;
              }
              _autoCalculatedFieldIds.add(r.labTestId);
              _autoCalculatedFormulas[r.labTestId] = calc.formulaDisplay;
            }
          }
        } else {
          // Si no se puede calcular (por insumo vaciado) y era autocalculado, limpiar
          if (_autoCalculatedFieldIds.contains(r.labTestId) &&
              !_manuallyOverriddenFieldIds.contains(r.labTestId)) {
            _controllers[r.labTestId]?.text = '';
            _autoCalculatedFieldIds.remove(r.labTestId);
            _autoCalculatedFormulas.remove(r.labTestId);
          }
        }
      }

      // =========================================================================
      // 3. EVALUACIÓN DE OTRAS FÓRMULAS DEL SISTEMA (Ej. Lipídico, Bilirrubinas, BUN)
      // =========================================================================
      final computedResults = ClinicalFormulasRegistry.evaluateAll(available);
      for (var r in _results) {
        final canonical = _resolveCanonical(r);
        if (canonical == null) continue;
        if (r.labTestId == triggeredTestId) continue;
        if (canonical == 'HTC' ||
            canonical == 'HB' ||
            canonical == 'ERI' ||
            canonical == 'VCM' ||
            canonical == 'HCM' ||
            canonical == 'CHCM') {
          continue; // Ya gestionados por la Serie Roja
        }

        if (computedResults.containsKey(canonical)) {
          final calc = computedResults[canonical]!;
          final controller = _controllers[r.labTestId];
          if (controller != null) {
            final isManual = _manuallyOverriddenFieldIds.contains(r.labTestId);

            // Siempre recalcular si el usuario no ha forzado una sobreescritura manual en este campo
            if (!isManual) {
              final formatted = ThousandsSeparatorInputFormatter.formatText(calc.formattedValue);
              if (controller.text != formatted) {
                controller.text = formatted;
              }
              _autoCalculatedFieldIds.add(r.labTestId);
              _autoCalculatedFormulas[r.labTestId] = calc.formulaDisplay;
            }
          }
        } else {
          // Si no se puede calcular (por insumo vaciado) y era autocalculado, limpiar
          if (_autoCalculatedFieldIds.contains(r.labTestId) &&
              !_manuallyOverriddenFieldIds.contains(r.labTestId)) {
            final controller = _controllers[r.labTestId];
            if (controller != null && controller.text.isNotEmpty) {
              controller.text = '';
            }
            _autoCalculatedFieldIds.remove(r.labTestId);
            _autoCalculatedFormulas.remove(r.labTestId);
          }
        }
      }
    } finally {
      _isEvaluatingCalculations = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Agrupación y Métricas de Perfiles Clínicos
  // ---------------------------------------------------------------------------

  /// Obtiene el nombre del estudio o pack asignado al parámetro.
  String getStudyName(OrderTestResult r) {
    return _studyNameByTestId[r.labTestId] ??
        (r.parentExamName?.trim().isNotEmpty == true
            ? r.parentExamName!.trim()
            : (order.items.isNotEmpty ? order.items.first.name : 'Estudio Clínico'));
  }

  /// Evalúa si el resultado individual ya tiene un valor capturado.
  bool isResultCompleted(OrderTestResult r) {
    if (r.dataType == 'qualitative' || r.dataType == 'boolean') {
      final val = getQualitativeValue(r.labTestId);
      return val != null && val.trim().isNotEmpty;
    }
    final c = getController(r.labTestId);
    return c != null && c.text.trim().isNotEmpty;
  }

  /// Obtiene el total de parámetros completados para un estudio dado.
  int getStudyCompletedCount(String studyTitle) {
    final upper = studyTitle.toUpperCase();
    return _results
        .where((r) => getStudyName(r).toUpperCase() == upper && isResultCompleted(r))
        .length;
  }

  /// Obtiene la cantidad total de parámetros que pertenecen a un estudio dado.
  int getStudyTotalCount(String studyTitle) {
    final upper = studyTitle.toUpperCase();
    return _results.where((r) => getStudyName(r).toUpperCase() == upper).length;
  }

  /// Indica si la orden contiene más de un estudio o perfil clínico.
  bool get hasMultipleStudies {
    final uniqueStudies = _results.map((r) => getStudyName(r).toUpperCase()).toSet();
    return uniqueStudies.length > 1;
  }

  // ---------------------------------------------------------------------------
  // Generación de DTOs Inmutables para Persistencia
  // ---------------------------------------------------------------------------

  /// Genera la lista inmutable [OrderTestResult] con los valores actuales, alertas
  /// calculadas y visibilidad de impresión.
  List<OrderTestResult> generateUpdatedResults() {
    return _results.map((r) {
      String? val;

      if (r.dataType == 'qualitative' || r.dataType == 'boolean') {
        val = _qualitativeValues[r.labTestId];
      } else {
        val = _controllers[r.labTestId]?.text.trim();
      }

      final alert = evaluateResult(r, resultValue: val).alertFlag;

      return OrderTestResult(
        labTestId: r.labTestId,
        parameterName: r.parameterName,
        medicalClassification: r.medicalClassification,
        subclassification: r.subclassification,
        dataType: r.dataType,
        unitOfMeasure: r.unitOfMeasure,
        referenceValues: r.referenceValues,
        qualitativeOptions: r.qualitativeOptions,
        expectedQualitativeValue: r.expectedQualitativeValue,
        referenceText: r.referenceText,
        parentExamName: r.parentExamName,
        resultValue: val,
        alertFlag: alert,
        showInPrint: _visibilityMap[r.labTestId] ?? true,
      );
    }).toList();
  }

  /// Genera el DTO inmutable [UpdateOrder] para guardar los resultados.
  ///
  /// El estado financiero ya no se envía: el backend lo calcula a partir de
  /// `paidAmount`. El estado clínico solo cambia si la orden ya estaba
  /// completada o si el backend detecta que todos los resultados están listos
  /// y la orden está pagada.
  UpdateOrder generateUpdateOrder() {
    final updatedResults = generateUpdatedResults();

    return UpdateOrder(
      results: updatedResults,
      notes: notesController.text.trim(),
    );
  }

  /// Indica si hay cambios sin guardar en resultados o notas.
  /// Compara contra el estado inicial visible (no contra la orden persistida),
  /// para no marcar como cambio los defaults cualitativos o los autocalculados.
  bool get hasUnsavedChanges {
    if (notesController.text.trim() != _initialNotes) return true;
    final current = generateUpdatedResults();
    if (current.length != _initialDraft.length) return true;
    for (var i = 0; i < current.length; i++) {
      final currentResult = current[i];
      final initialResult = _initialDraft[i];
      if (currentResult.labTestId != initialResult.labTestId) return true;
      if ((currentResult.resultValue ?? '').trim() != (initialResult.resultValue ?? '').trim()) {
        return true;
      }
      if (currentResult.showInPrint != initialResult.showInPrint) return true;
    }
    return false;
  }

  /// Construye una copia de la orden con los valores actuales del diálogo,
  /// sin persistirlos. Se usa para previsualizar el informe sin cerrar la captura.
  OrderInDb buildPreviewOrder() {
    return OrderInDb.fromJson({
      ...order.toJson(),
      'results': generateUpdatedResults().map((r) => r.toJson()).toList(),
      'notes': notes,
    });
  }

  // ---------------------------------------------------------------------------
  // Liberación de Recursos
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    notesController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
