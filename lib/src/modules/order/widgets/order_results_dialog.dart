import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/order_cubit/write_orders_cubit.dart';
import '../../../widgets/dialogs/viewers/clinical_order_viewer.dart';
import '../../../widgets/dialogs/viewers/patient_info_dialog.dart';
import '../../../tools/calculators/clinical_formulas_registry.dart';
import '../../../tools/formatters/thousands_separator_input_formatter.dart';
import 'order_results_dialogs/order_results_header.dart';
import 'order_results_dialogs/order_results_summary_bar.dart';
import 'order_results_dialogs/parameter_card.dart';
import 'order_results_dialogs/order_results_footer.dart';

/// Diálogo principal orquestador para la captura, cálculo reactivo y guardado de resultados de laboratorio.
class OrderResultsDialog extends StatefulWidget {
  final OrderInDb order;

  const OrderResultsDialog({super.key, required this.order});

  @override
  State<OrderResultsDialog> createState() => _OrderResultsDialogState();
}

class _OrderResultsDialogState extends State<OrderResultsDialog> {
  final _formKey = GlobalKey<FormState>();
  late List<OrderTestResult> _results;
  late Map<String, bool> _visibilityMap;
  late Map<String, TextEditingController> _controllers;
  late TextEditingController _notesController;
  late Map<String, String> _qualitativeValues;
  late List<FocusNode> _focusNodes;
  late FocusNode _notesFocusNode;
  final Set<String> _autoCalculatedFieldIds = {};
  final Map<String, String> _autoCalculatedFormulas = {};
  final Set<String> _manuallyOverriddenFieldIds = {};
  bool _isEvaluatingCalculations = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _results = List.from(widget.order.results);
    _visibilityMap = {
      for (var r in _results) r.labTestId: r.showInPrint,
    };
    _controllers = {};
    _qualitativeValues = {};
    _notesController = TextEditingController(text: widget.order.notes ?? '');
    _notesFocusNode = FocusNode();

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

    // Evaluación inicial preventiva si la orden tiene valores precargados
    _evaluateCalculations();

    _focusNodes = List.generate(_results.length, (index) {
      final node = FocusNode();
      node.addListener(() {
        if (node.hasFocus) {
          final r = _results[index];
          final controller = _controllers[r.labTestId];
          if (controller != null && controller.text.isNotEmpty) {
            controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller.text.length,
            );
          }
        }
      });
      return node;
    });

    if (_focusNodes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNodes.isNotEmpty) {
          _focusNodes.first.requestFocus();
        }
      });
    }
  }

  void _toggleVisibility(String labTestId, bool show) {
    setState(() {
      _visibilityMap[labTestId] = show;
    });
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
          triggeredCanonical = ClinicalFormulasRegistry.resolveCanonicalKey(triggeredResult.parameterName);
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
            final isHbManual = _manuallyOverriddenFieldIds.contains(hbResult.labTestId);
            if (!isHbManual) {
              final approxHb = htcVal / 3.0;
              final formattedHb = ClinicalFormulasRegistry.formatClinicalValue(approxHb, 1);
              _controllers[hbResult.labTestId]?.text = ThousandsSeparatorInputFormatter.formatText(formattedHb);
              available['HB'] = approxHb;
              _autoCalculatedFieldIds.add(hbResult.labTestId);
              _autoCalculatedFormulas[hbResult.labTestId] = 'Hematocrito / 3';
            }
          }

          // B) Eritrocitos = Hemoglobina / 3 (o Hematocrito / 9) (3 decimales en millones)
          if (eriResult != null) {
            final isEriManual = _manuallyOverriddenFieldIds.contains(eriResult.labTestId);
            if (!isEriManual) {
              final currentHb = available['HB'] ?? (htcVal / 3.0);
              final approxEri = currentHb / 3.0;
              final formattedEri = ClinicalFormulasRegistry.formatClinicalValue(approxEri, 3);
              _controllers[eriResult.labTestId]?.text = ThousandsSeparatorInputFormatter.formatText(formattedEri);
              available['ERI'] = approxEri;
              _autoCalculatedFieldIds.add(eriResult.labTestId);
              _autoCalculatedFormulas[eriResult.labTestId] = 'Hemoglobina / 3';
            }
          }
        }
      }

      // =========================================================================
      // 2. RECÁLCULO DINÁMICO DE ÍNDICES DE WINTROBE (VCM, HCM, CHCM)
      // =========================================================================
      // Aplica tanto si cambió HTC, como si se sobreescribió manualmente HB o ERI.
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
        if (!_manuallyOverriddenFieldIds.contains(r.labTestId) && computedResults.containsKey(canonical)) {
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
        if (canonical == 'HTC' || canonical == 'HB' || canonical == 'ERI' ||
            canonical == 'VCM' || canonical == 'HCM' || canonical == 'CHCM') {
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

  void _onNumericFieldChanged(OrderTestResult r, String val) {
    final canonical = ClinicalFormulasRegistry.resolveCanonicalKey(r.parameterName);
    if (val.trim().isEmpty) {
      _manuallyOverriddenFieldIds.remove(r.labTestId);
    } else if (canonical != 'HTC') {
      // Si el usuario teclea en HB, ERI o índices de Wintrobe, se registra sobreescritura manual
      _manuallyOverriddenFieldIds.add(r.labTestId);
    }
    _autoCalculatedFieldIds.remove(r.labTestId);
    _autoCalculatedFormulas.remove(r.labTestId);

    _evaluateCalculations(triggeredTestId: r.labTestId);
    setState(() {});
  }

  void _onFieldSubmitted(int index) {
    if (index + 1 < _focusNodes.length) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _notesFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _notesFocusNode.dispose();
    _notesController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Busca el valor de referencia apropiado según el sexo del paciente
  ReferenceValue? _findReferenceValueForPatient(OrderTestResult r) {
    if (r.referenceValues.isEmpty) return null;
    final patientInfo = widget.order.patientInfo;
    if (patientInfo == null || r.referenceValues.length == 1) {
      return r.referenceValues.first;
    }
    final normalizedGender = (patientInfo.gender).toLowerCase();
    for (final ref in r.referenceValues) {
      final refGender = ref.gender.toLowerCase();
      final matchesGender = refGender.isEmpty ||
          refGender == 'both' ||
          refGender == 'todos' ||
          (refGender.startsWith('m') && normalizedGender.startsWith('m')) ||
          (refGender.startsWith('f') && normalizedGender.startsWith('f'));
      if (matchesGender) return ref;
    }
    return r.referenceValues.first;
  }

  /// Evalúa el flag de alerta médica de un resultado en tiempo real (H, L o null)
  String? _getAlertFlag(OrderTestResult r) {
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

      final ref = _findReferenceValueForPatient(r);
      if (ref != null) {
        return ClinicalFormulasRegistry.evaluateAlertFlag(
          value: valDouble,
          minValue: ref.minValue,
          maxValue: ref.maxValue,
        );
      }
      return null;
    } else {
      return null;
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    // Calcular en vivo la suma del diferencial leucocitario
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
    final differentialSum =
        ClinicalFormulasRegistry.calculateLeukocyteDifferentialSum(availableCanonicalInputs);

    // Validación de Negocio Estricta: Si se ingresó el diferencial, debe sumar exactamente 100%
    if (differentialSum != null && !ClinicalFormulasRegistry.isDifferentialValid(differentialSum)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El conteo diferencial debe sumar exactamente 100% (actualmente suma ${ClinicalFormulasRegistry.formatClinicalValue(differentialSum, 1)}%). Corrija los valores antes de guardar.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final updatedResults = _results.map((r) {
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
          if (r.dataType == 'numeric' && val != null && val.isNotEmpty && r.referenceValues.isNotEmpty) {
            final valDouble = ThousandsSeparatorInputFormatter.tryParseDouble(val);
            if (valDouble != null) {
              final ref = _findReferenceValueForPatient(r);
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
          resultValue: val,
          alertFlag: alert,
          showInPrint: _visibilityMap[r.labTestId] ?? true,
        );
      }).toList();

      final totalPrice = widget.order.totalPrice > 0
          ? widget.order.totalPrice
          : widget.order.salePriceApplied;
      final isFullyPaid = totalPrice > 0
          ? (widget.order.paidAmount >= totalPrice)
          : (widget.order.status == 'paid');

      final String newStatus;
      if (widget.order.status == 'completed') {
        newStatus = 'completed';
      } else if (isFullyPaid) {
        newStatus = 'paid';
      } else if (widget.order.paidAmount > 0) {
        newStatus = 'partiallyPaid';
      } else {
        newStatus = 'pending';
      }

      final updateOrder = UpdateOrder(
        status: newStatus,
        results: updatedResults,
        notes: _notesController.text.trim(),
      );

      final writeCubit = context.read<WriteOrderCubit>();
      await writeCubit.update(widget.order.id, updateOrder);

      if (!mounted) return;

      final state = writeCubit.state;
      if (state is OrderUpdated) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      } else if (state is WriteOrderError) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar resultados: ${state.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else {
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const isReadOnly = false;

    final patientName = widget.order.patientInfo?.name ?? 'Paciente #${widget.order.patientId}';
    final shortId = widget.order.id.length > 8
        ? widget.order.id.substring(widget.order.id.length - 8).toUpperCase()
        : widget.order.id.toUpperCase();

    // Contadores en tiempo real
    int filledCount = 0;
    int alertCount = 0;
    final availableCanonicalInputs = <String, double>{};
    for (var r in _results) {
      final alert = _getAlertFlag(r);
      if (r.dataType == 'boolean') {
        if (_qualitativeValues[r.labTestId]?.isNotEmpty ?? false) filledCount++;
      } else {
        final text = _controllers[r.labTestId]?.text.trim() ?? '';
        if (text.isNotEmpty) {
          filledCount++;
          final val = double.tryParse(text);
          if (val != null) {
            final canonical = ClinicalFormulasRegistry.resolveCanonicalKey(r.parameterName);
            if (canonical != null) {
              availableCanonicalInputs[canonical] = val;
            }
          }
        }
      }
      if (alert == 'H' || alert == 'HIGH' || alert == 'L' || alert == 'LOW' || alert == 'ABNORMAL') {
        alertCount++;
      }
    }
    final differentialSum =
        ClinicalFormulasRegistry.calculateLeukocyteDifferentialSum(availableCanonicalInputs);
    final visibleCount = _visibilityMap.values.where((v) => v).length;

    return PopScope(
      canPop: !_isSubmitting,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 680,
            maxHeight: 680,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cabecera Visual con Icono y Contexto
              OrderResultsHeader(
                examName: widget.order.examName,
                shortId: shortId,
                patientName: patientName,
                isSubmitting: _isSubmitting,
                onShowPatientInfo: () => showOrderPatientInfoDialog(context, widget.order),
                onClose: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  }
                },
              ),

              // 2. Barra de Resumen / Métricas Compacta
              OrderResultsSummaryBar(
                filledCount: filledCount,
                totalCount: _results.length,
                visibleCount: visibleCount,
                alertCount: alertCount,
                differentialSum: differentialSum,
              ),
              const Divider(height: 1),

              // 3. Lista de Parámetros con Tarjetas Claras y Observaciones
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == _results.length) {
                        return _buildNotesSection(theme, isReadOnly);
                      }

                      final r = _results[index];
                      final alert = _getAlertFlag(r);
                      final isAlert = alert == 'H' || alert == 'HIGH' || alert == 'L' || alert == 'LOW' || alert == 'ABNORMAL';

                      return ParameterCard(
                        result: r,
                        alert: alert,
                        isAlert: isAlert,
                        isReadOnly: isReadOnly,
                        focusNode: _focusNodes[index],
                        isLast: false,
                        onFieldSubmitted: () => _onFieldSubmitted(index),
                        controller: _controllers[r.labTestId],
                        isAutoCalculated: _autoCalculatedFieldIds.contains(r.labTestId),
                        formulaDisplay: _autoCalculatedFormulas[r.labTestId],
                        qualitativeValue: _qualitativeValues[r.labTestId],
                        showInPrint: _visibilityMap[r.labTestId] ?? true,
                        onToggleVisibility: (show) => _toggleVisibility(r.labTestId, show),
                        onQualitativeChanged: (val) {
                          setState(() => _qualitativeValues[r.labTestId] = val);
                        },
                        onNumericChanged: (val) {
                          _onNumericFieldChanged(r, val);
                        },
                      );
                    },
                  ),
                ),
              ),

              // 4. Footer de Acciones
              OrderResultsFooter(
                isReadOnly: isReadOnly,
                hasResults: widget.order.results.isNotEmpty,
                isSubmitting: _isSubmitting,
                canComplete: false,
                onViewReport: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  }
                  showClinicalOrderViewerDialog(context, widget.order);
                },
                onCancel: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  }
                },
                onSubmit: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSection(ThemeData theme, bool isReadOnly) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Descripción / Observaciones del Bioanalista',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (isReadOnly) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Solo Lectura',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _notesController,
            focusNode: _notesFocusNode,
            readOnly: isReadOnly,
            maxLines: 3,
            minLines: 2,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: isReadOnly
                  ? 'Sin descripción ni observaciones registradas'
                  : 'Ingrese notas diagnósticas, descripción clínica, incidencias de la muestra (ej. hemólisis, lipemia), o comentarios clínicos...',
              hintStyle: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              filled: true,
              fillColor: isReadOnly
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : theme.colorScheme.surface,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
