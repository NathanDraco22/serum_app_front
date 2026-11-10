import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import '../../../../tools/formatters/thousands_separator_input_formatter.dart';
import '../../controllers/order_results_mediator.dart';
import '../../controllers/order_results_view_controller.dart';
import 'parameter_badge_pill.dart';

/// Tarjeta individual para captura, validación y visualización referencial de un análisis clínico.
///
/// Siguiendo la arquitectura **ViewController + Mediator (OKF v0.2)**:
/// - Extrae controladores, mutaciones, alertas clínicas y badges directamente desde [OrderResultsMediator].
/// - Permite parámetros opcionales para preservar retrocompatibilidad con suites de pruebas aisladas del widget.
/// - Se suscribe a redibujados quirúrgicos mediante [ListenableBuilder].
class ParameterCard extends StatelessWidget {
  /// Presets estándar de atajos rápidos para resultados de texto libre en laboratorio clínico
  static const List<String> defaultTextPresets = [
    'Ninguno',
    'No se observa',
    'Normal',
    'Negativo',
  ];

  final OrderTestResult result;
  final String? alert;
  final bool? isAlert;
  final bool isReadOnly;
  final FocusNode? focusNode;
  final bool isLast;
  final VoidCallback? onFieldSubmitted;
  final TextEditingController? controller;
  final bool? isAutoCalculated;
  final String? formulaDisplay;
  final String? qualitativeValue;
  final ValueChanged<String>? onQualitativeChanged;
  final ValueChanged<String>? onNumericChanged;
  final bool? showInPrint;
  final ValueChanged<bool>? onToggleVisibility;
  final OrderResultsViewController? viewController;

  const ParameterCard({
    super.key,
    required this.result,
    this.alert,
    this.isAlert,
    this.isReadOnly = false,
    this.focusNode,
    this.isLast = false,
    this.onFieldSubmitted,
    this.controller,
    this.isAutoCalculated,
    this.formulaDisplay,
    this.qualitativeValue,
    this.onQualitativeChanged,
    this.onNumericChanged,
    this.showInPrint,
    this.onToggleVisibility,
    this.viewController,
  });

  List<String> get _textPresets {
    if (result.qualitativeOptions.isNotEmpty) {
      return result.qualitativeOptions;
    }
    final presets = <String>[...defaultTextPresets];
    if (result.expectedQualitativeValue != null &&
        result.expectedQualitativeValue!.trim().isNotEmpty &&
        !presets.any((p) => p.toLowerCase() == result.expectedQualitativeValue!.trim().toLowerCase())) {
      presets.add(result.expectedQualitativeValue!.trim());
    }
    return presets;
  }

  void _handlePresetText({
    required String preset,
    required TextEditingController? resolvedController,
    required ValueChanged<String>? resolvedOnNumericChanged,
    required OrderResultsViewController? activeController,
  }) {
    if (isReadOnly) return;
    if (activeController != null) {
      activeController.applyPresetText(result.labTestId, preset);
      return;
    }
    if (resolvedController != null) {
      resolvedController.text = preset;
      resolvedController.selection = TextSelection.fromPosition(
        TextPosition(offset: preset.length),
      );
    }
    resolvedOnNumericChanged?.call(preset);
  }

  bool _computeHasValue({
    required TextEditingController? resolvedController,
    required String? resolvedQualitativeValue,
  }) {
    if (result.dataType == 'qualitative' || result.dataType == 'boolean') {
      return resolvedQualitativeValue != null && resolvedQualitativeValue.isNotEmpty;
    }
    return resolvedController != null && resolvedController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final activeController = viewController ?? OrderResultsMediator.maybeControllerOf(context);

    if (activeController != null) {
      return ListenableBuilder(
        listenable: activeController,
        builder: (context, _) => _buildCard(
          context: context,
          activeController: activeController,
        ),
      );
    }

    return _buildCard(
      context: context,
      activeController: null,
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required OrderResultsViewController? activeController,
  }) {
    final theme = Theme.of(context);

    // Resolución de dependencias: se priorizan los valores explícitos o se consultan del controller
    final resolvedController = controller ?? activeController?.getController(result.labTestId);
    final resolvedQualitativeValue = qualitativeValue ?? activeController?.getQualitativeValue(result.labTestId);
    final resolvedShowInPrint = showInPrint ?? activeController?.isVisible(result.labTestId) ?? true;
    final resolvedIsAutoCalculated = isAutoCalculated ?? activeController?.isAutoCalculated(result.labTestId) ?? false;
    final resolvedFormulaDisplay = formulaDisplay ?? activeController?.getFormulaDisplay(result.labTestId);
    final resolvedAlert = alert ?? activeController?.getAlertFlag(result);
    final resolvedIsAlert = isAlert ?? (activeController != null ? activeController.isAlert(result) : (resolvedAlert == 'H' || resolvedAlert == 'HIGH' || resolvedAlert == 'L' || resolvedAlert == 'LOW' || resolvedAlert == 'ABNORMAL'));

    final hasVal = _computeHasValue(
      resolvedController: resolvedController,
      resolvedQualitativeValue: resolvedQualitativeValue,
    );

    final isNormal = hasVal && !resolvedIsAlert;
    final isFocused = focusNode?.hasFocus == true;

    // Decoración de borde reactivo
    final borderColor = !resolvedShowInPrint
        ? theme.colorScheme.outlineVariant.withValues(alpha: 0.5)
        : (resolvedIsAlert
            ? Colors.red.shade300
            : (isFocused
                ? theme.colorScheme.primary.withValues(alpha: 0.85)
                : (isNormal ? Colors.green.shade200 : theme.colorScheme.outlineVariant)));

    final cardBg = !resolvedShowInPrint
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
        : (resolvedIsAlert
            ? Colors.red.shade50.withValues(alpha: 0.3)
            : (isFocused
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.12)
                : theme.colorScheme.surfaceContainerLowest));

    final borderWidth =
        (resolvedIsAlert && resolvedShowInPrint) || isFocused ? 1.4 : 1.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Nombre del Parámetro y Badge de Estado
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        result.parameterName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: !resolvedShowInPrint
                              ? theme.colorScheme.onSurfaceVariant
                              : (resolvedIsAlert ? Colors.red.shade900 : theme.colorScheme.onSurface),
                        ),
                      ),
                    ),
                    if (result.medicalClassification.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          result.medicalClassification,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                    if (resolvedIsAutoCalculated) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: resolvedFormulaDisplay != null
                            ? 'Calculado automáticamente: $resolvedFormulaDisplay'
                            : 'Calculado automáticamente',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 10, color: theme.colorScheme.primary),
                              const SizedBox(width: 3),
                              Text(
                                'Auto ⚡',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!resolvedShowInPrint) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Text(
                    'NO SE IMPRIME',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              _buildStatusBadge(theme, resolvedAlert, hasVal),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  resolvedShowInPrint ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 19,
                  color: resolvedShowInPrint ? theme.colorScheme.primary : theme.colorScheme.outline,
                ),
                tooltip: resolvedShowInPrint
                    ? 'Visible en informe (clic para ocultar)'
                    : 'Oculto de informe (clic para mostrar)',
                onPressed: () {
                  if (onToggleVisibility != null) {
                    onToggleVisibility!(!resolvedShowInPrint);
                  } else if (activeController != null) {
                    activeController.toggleVisibility(result.labTestId, !resolvedShowInPrint);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Fila 2: Valor de Referencia destacado + Input
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Caja de Referencia (solo si no es texto libre o si tiene referenceText definido)
              if (result.dataType != 'text' || result.referenceText.trim().isNotEmpty) ...[
                Tooltip(
                  message: _getReferenceText(activeController),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 160, maxWidth: 260),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          result.referenceText.isNotEmpty
                              ? 'ESCALA REFERENCIAL'
                              : (result.dataType == 'numeric' ? 'VALOR REFERENCIAL' : 'VALOR ESPERADO'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _getReferenceText(activeController),
                          maxLines: result.referenceText.isNotEmpty ? 4 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: result.referenceText.isNotEmpty ? 11 : 13.5,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Control de Entrada
              Expanded(
                child: _buildInput(
                  theme: theme,
                  resolvedController: resolvedController,
                  resolvedQualitativeValue: resolvedQualitativeValue,
                  resolvedShowInPrint: resolvedShowInPrint,
                  resolvedIsAlert: resolvedIsAlert,
                  activeController: activeController,
                ),
              ),
            ],
          ),

          // Alerta contextual explicativa
          if (resolvedIsAlert && resolvedShowInPrint) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.info_outline, size: 13, color: Colors.red.shade800),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _getAlertExplanation(resolvedAlert, activeController),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, String? resolvedAlert, bool hasVal) {
    if (resolvedAlert == 'HIGH' || resolvedAlert == 'H') {
      return ParameterBadgePill(
        label: 'ALTO ▲ (H)',
        bgColor: Colors.red.shade50,
        textColor: Colors.red.shade900,
        borderColor: Colors.red.shade200,
      );
    } else if (resolvedAlert == 'LOW' || resolvedAlert == 'L') {
      return ParameterBadgePill(
        label: 'BAJO ▼ (L)',
        bgColor: Colors.blue.shade50,
        textColor: Colors.blue.shade900,
        borderColor: Colors.blue.shade200,
      );
    } else if (resolvedAlert == 'ABNORMAL') {
      return ParameterBadgePill(
        label: 'ANORMAL',
        bgColor: Colors.orange.shade50,
        textColor: Colors.orange.shade900,
        borderColor: Colors.orange.shade200,
      );
    } else if (resolvedAlert == 'NORMAL' || hasVal) {
      return ParameterBadgePill(
        label: 'NORMAL',
        bgColor: Colors.green.shade50,
        textColor: Colors.green.shade800,
        borderColor: Colors.green.shade200,
      );
    }
    return ParameterBadgePill(
      label: 'PENDIENTE',
      icon: Icon(
        Icons.warning_amber_rounded,
        size: 11,
        color: Colors.amber.shade800,
      ),
      bgColor: theme.colorScheme.surfaceContainerHigh,
      textColor: theme.colorScheme.onSurfaceVariant,
      borderColor: theme.colorScheme.outlineVariant,
    );
  }

  String _getReferenceText(OrderResultsViewController? activeController) {
    if (result.referenceText.isNotEmpty) {
      return result.referenceText;
    }
    if (result.dataType == 'numeric') {
      final ref = activeController?.findReferenceValueForPatient(result) ??
          (result.referenceValues.isNotEmpty ? result.referenceValues.first : null);
      if (ref != null) {
        final unit = result.unitOfMeasure.isNotEmpty ? ' ${result.unitOfMeasure}' : '';
        return '${ref.minValue} - ${ref.maxValue}$unit';
      }
      return 'Sin rango definido';
    } else if (result.dataType == 'qualitative' || result.dataType == 'boolean') {
      return result.expectedQualitativeValue ?? 'No aplica';
    }
    return 'Texto descriptivo';
  }

  String _getAlertExplanation(String? resolvedAlert, OrderResultsViewController? activeController) {
    final ref = activeController?.findReferenceValueForPatient(result) ??
        (result.referenceValues.isNotEmpty ? result.referenceValues.first : null);

    if (resolvedAlert == 'HIGH' || resolvedAlert == 'H') {
      if (ref != null) {
        return 'Valor superior al límite máximo (${ref.maxValue} ${result.unitOfMeasure}).';
      }
      return 'Valor clínicamente alto.';
    } else if (resolvedAlert == 'LOW' || resolvedAlert == 'L') {
      if (ref != null) {
        return 'Valor inferior al límite mínimo (${ref.minValue} ${result.unitOfMeasure}).';
      }
      return 'Valor clínicamente bajo.';
    } else if (resolvedAlert == 'ABNORMAL') {
      return 'Resultado difiere del valor esperado (${result.expectedQualitativeValue}).';
    }
    return '';
  }

  Widget _buildInput({
    required ThemeData theme,
    required TextEditingController? resolvedController,
    required String? resolvedQualitativeValue,
    required bool resolvedShowInPrint,
    required bool resolvedIsAlert,
    required OrderResultsViewController? activeController,
  }) {
    if (result.dataType == 'qualitative' || result.dataType == 'boolean') {
      final options = result.qualitativeOptions.isNotEmpty
          ? result.qualitativeOptions
          : ['Negativo', 'Positivo'];

      return DropdownButtonFormField<String>(
        initialValue: resolvedQualitativeValue,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        items: options.map((opt) {
          final isAlertOpt = result.expectedQualitativeValue != null &&
              result.expectedQualitativeValue!.isNotEmpty &&
              opt != result.expectedQualitativeValue;

          return DropdownMenuItem<String>(
            value: opt,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  opt,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAlertOpt ? Colors.orange.shade900 : theme.colorScheme.onSurface,
                  ),
                ),
                if (isAlertOpt)
                  Text(
                    ' (Anormal)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
        onChanged: isReadOnly
            ? null
            : (val) {
                if (val != null) {
                  if (onQualitativeChanged != null) {
                    onQualitativeChanged!(val);
                  } else if (activeController != null) {
                    activeController.setQualitativeValue(result.labTestId, val);
                  }
                }
              },
      );
    } else if (result.dataType == 'text') {
      final presets = _textPresets;
      final currentText = resolvedController?.text.trim().toLowerCase() ?? '';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            focusNode: focusNode,
            controller: resolvedController,
            readOnly: isReadOnly,
            keyboardType: TextInputType.multiline,
            minLines: 3,
            maxLines: null,
            textInputAction: TextInputAction.newline,
            onFieldSubmitted: (_) => onFieldSubmitted?.call(),
            onChanged: (val) {
              if (onNumericChanged != null) {
                onNumericChanged!(val);
              } else if (activeController != null) {
                activeController.onNumericChanged(result, val);
              }
            },
            style: const TextStyle(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Ingrese observaciones o resultado descriptivo...',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
          ),
          if (presets.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 13,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Atajos:',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                ...presets.map((preset) {
                  final isSelected = currentText.isNotEmpty && currentText == preset.toLowerCase();
                  return ActionChip(
                    avatar: isSelected
                        ? Icon(Icons.check, size: 13, color: theme.colorScheme.primary)
                        : null,
                    label: Text(
                      preset,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    backgroundColor: isSelected
                        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : theme.colorScheme.surfaceContainerHigh,
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.4)
                          : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    visualDensity: VisualDensity.compact,
                    onPressed: isReadOnly
                        ? null
                        : () => _handlePresetText(
                              preset: preset,
                              resolvedController: resolvedController,
                              resolvedOnNumericChanged: onNumericChanged,
                              activeController: activeController,
                            ),
                  );
                }),
              ],
            ),
          ],
        ],
      );
    } else {
      return TextFormField(
        focusNode: focusNode,
        controller: resolvedController,
        readOnly: isReadOnly,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          ThousandsSeparatorInputFormatter(allowFraction: true),
        ],
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: (_) => onFieldSubmitted?.call(),
        onChanged: (val) {
          if (onNumericChanged != null) {
            onNumericChanged!(val);
          } else if (activeController != null) {
            activeController.onNumericChanged(result, val);
          }
        },
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.bold,
          color: resolvedIsAlert && resolvedShowInPrint ? Colors.red.shade900 : theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: '0.00',
          hintStyle: TextStyle(
            fontSize: 15,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
          ),
          suffixText: result.unitOfMeasure.isNotEmpty ? result.unitOfMeasure : null,
          suffixStyle: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        validator: (val) {
          if (!resolvedShowInPrint) return null;
          return val == null || val.trim().isEmpty ? 'Requerido' : null;
        },
      );
    }
  }
}
