import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import '../../../../tools/formatters/thousands_separator_input_formatter.dart';
import 'parameter_badge_pill.dart';

/// Tarjeta individual para captura, validación y visualización referencial de un análisis clínico.
class ParameterCard extends StatelessWidget {
  final OrderTestResult result;
  final String? alert;
  final bool isAlert;
  final bool isReadOnly;
  final FocusNode? focusNode;
  final bool isLast;
  final VoidCallback? onFieldSubmitted;
  final TextEditingController? controller;
  final bool isAutoCalculated;
  final String? formulaDisplay;
  final String? qualitativeValue;
  final ValueChanged<String> onQualitativeChanged;
  final ValueChanged<String> onNumericChanged;

  const ParameterCard({
    super.key,
    required this.result,
    required this.alert,
    required this.isAlert,
    required this.isReadOnly,
    this.focusNode,
    this.isLast = false,
    this.onFieldSubmitted,
    required this.controller,
    this.isAutoCalculated = false,
    this.formulaDisplay,
    required this.qualitativeValue,
    required this.onQualitativeChanged,
    required this.onNumericChanged,
  });

  bool get _hasValue {
    if (result.dataType == 'qualitative' || result.dataType == 'boolean') {
      return qualitativeValue != null && qualitativeValue!.isNotEmpty;
    }
    return controller != null && controller!.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isNormal = _hasValue && !isAlert;
    // Decoración de borde reactivo
    final borderColor = isAlert
        ? Colors.red.shade300
        : (isNormal ? Colors.green.shade200 : theme.colorScheme.outlineVariant);

    final cardBg = isAlert
        ? Colors.red.shade50.withValues(alpha: 0.3)
        : theme.colorScheme.surfaceContainerLowest;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isAlert ? 1.4 : 1.0),
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
                          color: isAlert ? Colors.red.shade900 : theme.colorScheme.onSurface,
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
                    if (isAutoCalculated) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: formulaDisplay != null
                            ? 'Calculado automáticamente: $formulaDisplay'
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
              _buildStatusBadge(theme),
            ],
          ),
          const SizedBox(height: 8),

          // Fila 2: Valor de Referencia destacado + Input
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Caja de Referencia
              Tooltip(
                message: _getReferenceText(),
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
                        _getReferenceText(),
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

              // Control de Entrada
              Expanded(
                child: _buildInput(theme),
              ),
            ],
          ),

          // Alerta contextual explicativa
          if (isAlert) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.info_outline, size: 13, color: Colors.red.shade800),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _getAlertExplanation(),
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

  Widget _buildStatusBadge(ThemeData theme) {
    if (alert == 'HIGH' || alert == 'H') {
      return ParameterBadgePill(
        label: 'ALTO ▲ (H)',
        bgColor: Colors.red.shade50,
        textColor: Colors.red.shade900,
        borderColor: Colors.red.shade200,
      );
    } else if (alert == 'LOW' || alert == 'L') {
      return ParameterBadgePill(
        label: 'BAJO ▼ (L)',
        bgColor: Colors.blue.shade50,
        textColor: Colors.blue.shade900,
        borderColor: Colors.blue.shade200,
      );
    } else if (alert == 'ABNORMAL') {
      return ParameterBadgePill(
        label: 'ANORMAL',
        bgColor: Colors.orange.shade50,
        textColor: Colors.orange.shade900,
        borderColor: Colors.orange.shade200,
      );
    } else if (alert == 'NORMAL' || _hasValue) {
      return ParameterBadgePill(
        label: 'NORMAL',
        bgColor: Colors.green.shade50,
        textColor: Colors.green.shade800,
        borderColor: Colors.green.shade200,
      );
    }
    return ParameterBadgePill(
      label: 'PENDIENTE',
      bgColor: theme.colorScheme.surfaceContainerHigh,
      textColor: theme.colorScheme.onSurfaceVariant,
      borderColor: theme.colorScheme.outlineVariant,
    );
  }

  String _getReferenceText() {
    if (result.referenceText.isNotEmpty) {
      return result.referenceText;
    }
    if (result.dataType == 'numeric') {
      if (result.referenceValues.isNotEmpty) {
        final ref = result.referenceValues.first;
        final unit = result.unitOfMeasure.isNotEmpty ? ' ${result.unitOfMeasure}' : '';
        return '${ref.minValue} - ${ref.maxValue}$unit';
      }
      return 'No especificado';
    } else if (result.dataType == 'qualitative' || result.dataType == 'boolean') {
      return result.expectedQualitativeValue ?? 'Negativo';
    }
    return 'Texto libre';
  }

  String _getAlertExplanation() {
    if ((alert == 'HIGH' || alert == 'H') && result.referenceValues.isNotEmpty) {
      final ref = result.referenceValues.first;
      return 'El valor está por encima del límite máximo (${ref.maxValue} ${result.unitOfMeasure}) [Flag H]';
    } else if ((alert == 'LOW' || alert == 'L') && result.referenceValues.isNotEmpty) {
      final ref = result.referenceValues.first;
      return 'El valor está por debajo del límite mínimo (${ref.minValue} ${result.unitOfMeasure}) [Flag L]';
    } else if (alert == 'ABNORMAL') {
      return 'El resultado difiere del valor esperado (${result.expectedQualitativeValue ?? "Normal"})';
    }
    return 'Valor fuera de los parámetros estándar';
  }

  Widget _buildInput(ThemeData theme) {
    if (result.dataType == 'qualitative' || result.dataType == 'boolean') {
      final options = result.qualitativeOptions.isNotEmpty
          ? result.qualitativeOptions
          : ['Negativo', 'Positivo'];
      final selectedValue =
          (qualitativeValue != null && options.contains(qualitativeValue))
              ? qualitativeValue
              : options.first;

      return DropdownButtonFormField<String>(
        focusNode: focusNode,
        initialValue: selectedValue,
        isDense: true,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          return DropdownMenuItem(
            value: opt,
            child: Text(opt, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        onChanged: isReadOnly ? null : (val) {
          if (val != null) {
            onQualitativeChanged(val);
            onFieldSubmitted?.call();
          }
        },
      );
    } else if (result.dataType == 'text') {
      return TextFormField(
        focusNode: focusNode,
        controller: controller,
        readOnly: isReadOnly,
        maxLines: 1,
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: (_) => onFieldSubmitted?.call(),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Observación...',
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
      );
    } else {
      return TextFormField(
        focusNode: focusNode,
        controller: controller,
        readOnly: isReadOnly,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          ThousandsSeparatorInputFormatter(allowFraction: true),
        ],
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: (_) => onFieldSubmitted?.call(),
        onChanged: onNumericChanged,
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.bold,
          color: isAlert ? Colors.red.shade900 : theme.colorScheme.onSurface,
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
        validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
      );
    }
  }
}
