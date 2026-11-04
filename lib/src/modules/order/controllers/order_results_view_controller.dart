import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import '../../../tools/calculators/clinical_formulas_registry.dart';
import '../../../tools/formatters/thousands_separator_input_formatter.dart';

class OrderResultsViewController extends ChangeNotifier {
  final OrderInDb order;

  late final List<OrderTestResult> _results;
  late final Map<String, bool> _visibilityMap;
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, String> _qualitativeValues;
  late final TextEditingController notesController;

  final Set<String> _autoCalculatedFieldIds = {};
  final Map<String, String> _autoCalculatedFormulas = {};
  final Set<String> _manuallyOverriddenFieldIds = {};
  bool _isEvaluatingCalculations = false;
  bool _isSubmitting = false;

  OrderResultsViewController({
    required this.order,
  }) {
    _results = List.from(order.results);
    _visibilityMap = {
      for (var r in _results) r.labTestId: r.showInPrint,
    };
    _controllers = {};
    _qualitativeValues = {};
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
        final canonical = ClinicalFormulasRegistry.resolveCanonicalKey(r.parameterName);
        final initial = r.resultValue?.trim() ?? '';
        // Serie Blanca: los 7 parámetros diferenciales tienen valor por defecto 0 si están vacíos
        if (canonical != null &&
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

    // Evaluación inicial preventiva si la orden ya posee valores precargados
    _evaluateCalculations();
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

  bool isAutoCalculated(String labTestId) => _autoCalculatedFieldIds.contains(labTestId);

  String? getFormulaDisplay(String labTestId) => _autoCalculatedFormulas[labTestId];

  bool isManuallyOverridden(String labTestId) => _manuallyOverriddenFieldIds.contains(labTestId);

  // ---------------------------------------------------------------------------
  // Evaluación Clínica de Rangos y Alertas Demográficas
  // ---------------------------------------------------------------------------

  /// Busca el valor de referencia apropiado según el sexo y demografía del paciente.
  ReferenceValue? findReferenceValueForPatient(OrderTestResult r) {
    if (r.referenceValues.isEmpty) return null;
    final patientInfo = order.patientInfo;
    if (patientInfo == null || r.referenceValues.length == 1) {
      return r.referenceValues.first;
    }
    final normalizedGender = (patientInfo.gender).toLowerCase();
    for (final ref in r.referenceValues) {
      final refGender = ref.gender.toLowerCase();
      final matchesGender =
          refGender.isEmpty ||
          refGender == 'both' ||
          refGender == 'todos' ||
          (refGender.startsWith('m') && normalizedGender.startsWith('m')) ||
          (refGender.startsWith('f') && normalizedGender.startsWith('f'));
      if (matchesGender) return ref;
    }
    return r.referenceValues.first;
  }

  /// Evalúa el flag de alerta médica de un resultado en tiempo real (H, L, ABNORMAL o null).
  String? getAlertFlag(OrderTestResult r) {
    if (r.dataType == 'qualitative' || r.dataType == 'boolean') {
      final val = _qualitativeValues[r.labTestId];
      if (val != null &&
          r.expectedQualitativeValue != null &&
          r.expectedQualitativeValue!.isNotEmpty &&
          val != r.expectedQualitativeValue) {
        return 'ABNORMAL';
      }
      return null;
    } else if (r.dataType == 'numeric') {
      final text = _controllers[r.labTestId]?.text.trim() ?? '';
      if (text.isEmpty) return null;
      final valDouble = ThousandsSeparatorInputFormatter.tryParseDouble(text);
      if (valDouble == null) return null;

      final ref = findReferenceValueForPatient(r);
      if (ref != null) {
        return ClinicalFormulasRegistry.evaluateAlertFlag(
          value: valDouble,
          minValue: ref.minValue,
          maxValue: ref.maxValue,
        );
      }
      return null;
    }
    return null;
  }

  bool isAlert(OrderTestResult r) {
    final alert = getAlertFlag(r);
    return alert == 'H' || alert == 'HIGH' || alert == 'L' || alert == 'LOW' || alert == 'ABNORMAL';
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

  /// Suma porcentual del diferencial leucocitario calculada en vivo sobre los parámetros presentes.
  double? get differentialSum {
    final availableCanonicalInputs = <String, double>{};
    for (var r in _results) {
      if (r.dataType != 'qualitative' && r.dataType != 'boolean') {
        final text = _controllers[r.labTestId]?.text.trim() ?? '';
        if (text.isNotEmpty) {
          final val = ThousandsSeparatorInputFormatter.tryParseDouble(text);
          if (val != null) {
            final canonical = ClinicalFormulasRegistry.resolveCanonicalKey(r.parameterName);
            if (canonical != null) {
              availableCanonicalInputs[canonical] = val;
            }
          }
        }
      }
    }
    return ClinicalFormulasRegistry.calculateLeukocyteDifferentialSum(availableCanonicalInputs);
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
    final controller = _controllers[r.labTestId];
    if (controller != null && controller.text != val) {
      controller.text = val;
    }

    final canonical = ClinicalFormulasRegistry.resolveCanonicalKey(r.parameterName);
    if (val.trim().isEmpty) {
      _manuallyOverriddenFieldIds.remove(r.labTestId);
    } else if (canonical != 'HTC') {
      // Si el usuario teclea en HB, ERI o índices de Wintrobe, se registra sobreescritura manual
      _manuallyOverriddenFieldIds.add(r.labTestId);
    } else if (canonical == 'HTC') {
      // Hematocrito es el disparador maestro de la Serie Roja:
      // Al escribir en él, se desbloquean los campos dependientes para que se recalculen siempre
      for (final other in _results) {
        final otherCanonical = ClinicalFormulasRegistry.resolveCanonicalKey(other.parameterName);
        if (otherCanonical == 'HB' ||
            otherCanonical == 'ERI' ||
            otherCanonical == 'VCM' ||
            otherCanonical == 'HCM' ||
            otherCanonical == 'CHCM') {
          _manuallyOverriddenFieldIds.remove(other.labTestId);
        }
      }
    }
    _autoCalculatedFieldIds.remove(r.labTestId);
    _autoCalculatedFormulas.remove(r.labTestId);

    _evaluateCalculations(triggeredTestId: r.labTestId);
    notifyListeners();
  }

  /// Evalúa en tiempo real las fórmulas clínicas aplicables según los parámetros presentes
  void _evaluateCalculations({String? triggeredTestId}) {
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
        final canonical = ClinicalFormulasRegistry.resolveCanonicalKey(r.parameterName);
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
            available[canonical] = val;
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
          triggeredCanonical = ClinicalFormulasRegistry.resolveCanonicalKey(
            triggeredResult.parameterName,
          );
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
          if (eriResult != null) {
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
        }
      } else if (triggeredCanonical == 'HB' && hbResult != null) {
        // Disparador directo de Hemoglobina (ej. captura sin Hematocrito o ajuste de HB)
        final hbVal = available['HB'];
        if (hbVal != null && hbVal > 0) {
          if (eriResult != null) {
            final isEriManual = _manuallyOverriddenFieldIds.contains(eriResult.labTestId);
            if (!isEriManual) {
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
      final computedResults = ClinicalFormulasRegistry.evaluateAll(available);

      final wintrobeKeys = [
        ?vcmResult,
        ?hcmResult,
        ?chcmResult,
      ];

      for (var r in wintrobeKeys) {
        final canonical = ClinicalFormulasRegistry.resolveCanonicalKey(r.parameterName);
        if (canonical == null) continue;
        if (r.labTestId == triggeredTestId) continue;

        // Solo sobreescribir si no fue modificado manualmente por el usuario
        if (!_manuallyOverriddenFieldIds.contains(r.labTestId) &&
            computedResults.containsKey(canonical)) {
          final calc = computedResults[canonical]!;
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
      }

      // =========================================================================
      // 3. EVALUACIÓN DE OTRAS FÓRMULAS DEL SISTEMA (Ej. Bilirrubinas)
      // =========================================================================
      for (var r in _results) {
        final canonical = ClinicalFormulasRegistry.resolveCanonicalKey(r.parameterName);
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
            final currentText = controller.text.trim();
            final wasAuto = _autoCalculatedFieldIds.contains(r.labTestId);

            if (currentText.isEmpty || wasAuto) {
              final formatted = ThousandsSeparatorInputFormatter.formatText(calc.formattedValue);
              if (controller.text != formatted) {
                controller.text = formatted;
              }
              _autoCalculatedFieldIds.add(r.labTestId);
              _autoCalculatedFormulas[r.labTestId] = calc.formulaDisplay;
            }
          }
        }
      }
    } finally {
      _isEvaluatingCalculations = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Generación de DTOs Inmutables para Persistencia
  // ---------------------------------------------------------------------------

  /// Genera la lista inmutable [OrderTestResult] con los valores actuales, alertas
  /// calculadas y visibilidad de impresión.
  List<OrderTestResult> generateUpdatedResults() {
    return _results.map((r) {
      String? val;
      String? alert;

      if (r.dataType == 'qualitative' || r.dataType == 'boolean') {
        val = _qualitativeValues[r.labTestId];
        if (r.expectedQualitativeValue != null &&
            r.expectedQualitativeValue!.isNotEmpty &&
            val != r.expectedQualitativeValue) {
          alert = 'ABNORMAL';
        }
      } else {
        val = _controllers[r.labTestId]?.text.trim();
        if (r.dataType == 'numeric' &&
            val != null &&
            val.isNotEmpty &&
            r.referenceValues.isNotEmpty) {
          final valDouble = ThousandsSeparatorInputFormatter.tryParseDouble(val);
          if (valDouble != null) {
            final ref = findReferenceValueForPatient(r);
            if (ref != null) {
              alert = ClinicalFormulasRegistry.evaluateAlertFlag(
                value: valDouble,
                minValue: ref.minValue,
                maxValue: ref.maxValue,
              );
            }
          }
        }
      }

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

  /// Genera el DTO inmutable [UpdateOrder] calculando el nuevo estado de la orden
  /// de acuerdo a su estado actual y saldo pagado.
  UpdateOrder generateUpdateOrder() {
    final updatedResults = generateUpdatedResults();

    final totalPrice = order.totalPrice > 0 ? order.totalPrice : order.salePriceApplied;
    final isFullyPaid = totalPrice > 0
        ? (order.paidAmount >= totalPrice)
        : (order.status == 'paid');

    final String newStatus;
    if (order.status == 'completed') {
      newStatus = 'completed';
    } else if (isFullyPaid) {
      newStatus = 'paid';
    } else if (order.paidAmount > 0) {
      newStatus = 'partiallyPaid';
    } else {
      newStatus = 'pending';
    }

    return UpdateOrder(
      status: newStatus,
      results: updatedResults,
      notes: notesController.text.trim(),
    );
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
