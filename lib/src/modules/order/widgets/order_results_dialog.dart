import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/order_cubit/write_orders_cubit.dart';
import '../../../widgets/dialogs/viewers/clinical_order_viewer.dart';

class OrderResultsDialog extends StatefulWidget {
  final OrderInDb order;

  const OrderResultsDialog({super.key, required this.order});

  @override
  State<OrderResultsDialog> createState() => _OrderResultsDialogState();
}

class _OrderResultsDialogState extends State<OrderResultsDialog> {
  final _formKey = GlobalKey<FormState>();
  late List<OrderTestResult> _results;
  late Map<String, TextEditingController> _controllers;
  late Map<String, String> _qualitativeValues;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _results = List.from(widget.order.results);
    _controllers = {};
    _qualitativeValues = {};

    for (var r in _results) {
      if (r.dataType == 'boolean') {
        final options = r.qualitativeOptions.isNotEmpty
            ? r.qualitativeOptions
            : ['Negativo', 'Positivo'];
        _qualitativeValues[r.labTestId] =
            r.resultValue ?? r.expectedQualitativeValue ?? options.first;
      } else {
        _controllers[r.labTestId] = TextEditingController(text: r.resultValue ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Evalúa el flag de alerta médica de un resultado en tiempo real
  String? _getAlertFlag(OrderTestResult r) {
    if (r.dataType == 'boolean') {
      final val = _qualitativeValues[r.labTestId];
      if (val != null &&
          r.expectedQualitativeValue != null &&
          r.expectedQualitativeValue!.isNotEmpty &&
          val != r.expectedQualitativeValue) {
        return 'ABNORMAL';
      }
      return val != null ? 'NORMAL' : null;
    } else if (r.dataType == 'numeric') {
      final text = _controllers[r.labTestId]?.text.trim() ?? '';
      if (text.isEmpty) return null;
      final valDouble = double.tryParse(text);
      if (valDouble == null) return null;

      if (r.referenceValues.isNotEmpty) {
        final ref = r.referenceValues.first;
        if (valDouble < ref.minValue) return 'LOW';
        if (valDouble > ref.maxValue) return 'HIGH';
        return 'NORMAL';
      }
      return 'NORMAL';
    } else {
      final text = _controllers[r.labTestId]?.text.trim() ?? '';
      return text.isNotEmpty ? 'NORMAL' : null;
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final updatedResults = _results.map((r) {
        String? val;
        String? alert;

        if (r.dataType == 'boolean') {
          val = _qualitativeValues[r.labTestId];
          if (r.expectedQualitativeValue != null &&
              r.expectedQualitativeValue!.isNotEmpty &&
              val != r.expectedQualitativeValue) {
            alert = 'ABNORMAL';
          }
        } else {
          val = _controllers[r.labTestId]?.text.trim();
          if (r.dataType == 'numeric' && val != null && r.referenceValues.isNotEmpty) {
            final valDouble = double.tryParse(val);
            if (valDouble != null) {
              final ref = r.referenceValues.first;
              if (valDouble < ref.minValue) {
                alert = 'LOW';
              } else if (valDouble > ref.maxValue) {
                alert = 'HIGH';
              }
            }
          }
        }

        return OrderTestResult(
          labTestId: r.labTestId,
          parameterName: r.parameterName,
          medicalClassification: r.medicalClassification,
          dataType: r.dataType,
          unitOfMeasure: r.unitOfMeasure,
          referenceValues: r.referenceValues,
          qualitativeOptions: r.qualitativeOptions,
          expectedQualitativeValue: r.expectedQualitativeValue,
          resultValue: val,
          alertFlag: alert,
        );
      }).toList();

      final totalPrice = widget.order.totalPrice > 0
          ? widget.order.totalPrice
          : widget.order.salePriceApplied;
      final isFullyPaid = totalPrice > 0
          ? (widget.order.paidAmount >= totalPrice)
          : (widget.order.status == 'paid');

      final hasAllResults = updatedResults.isNotEmpty &&
          updatedResults.every((r) => r.resultValue != null && r.resultValue!.trim().isNotEmpty);

      final String newStatus;
      if (hasAllResults && isFullyPaid) {
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
    final isReadOnly = widget.order.status == 'completed';

    final patientName = widget.order.patientInfo?.name ?? 'Paciente #${widget.order.patientId}';
    final shortId = widget.order.id.length > 8
        ? widget.order.id.substring(widget.order.id.length - 8).toUpperCase()
        : widget.order.id.toUpperCase();

    // Contadores en tiempo real
    int filledCount = 0;
    int alertCount = 0;
    for (var r in _results) {
      final alert = _getAlertFlag(r);
      if (r.dataType == 'boolean') {
        if (_qualitativeValues[r.labTestId]?.isNotEmpty ?? false) filledCount++;
      } else {
        if (_controllers[r.labTestId]?.text.trim().isNotEmpty ?? false) filledCount++;
      }
      if (alert == 'HIGH' || alert == 'LOW' || alert == 'ABNORMAL') {
        alertCount++;
      }
    }

    return PopScope(
      canPop: !_isSubmitting,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 560,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cabecera Visual con Icono y Contexto
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  border: Border(
                    bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      child: const Icon(Icons.science_outlined, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.order.examName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#$shortId',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Paciente: $patientName',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: 'Cerrar',
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.pop(context);
                              }
                            },
                    ),
                  ],
                ),
              ),

              // 2. Barra de Resumen / Métricas Compacta
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                color: theme.colorScheme.surfaceContainerLowest,
                child: Row(
                  children: [
                    Icon(
                      Icons.checklist,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$filledCount de ${_results.length} análisis capturados',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (alertCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red.shade800),
                            const SizedBox(width: 4),
                            Text(
                              '$alertCount fuera de rango',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (filledCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: 12, color: Colors.green.shade800),
                            const SizedBox(width: 4),
                            Text(
                              'Valores normales',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // 3. Lista de Parámetros con Tarjetas Claras
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final r = _results[index];
                      final alert = _getAlertFlag(r);
                      final isAlert = alert == 'HIGH' || alert == 'LOW' || alert == 'ABNORMAL';

                      return _ParameterCard(
                        result: r,
                        alert: alert,
                        isAlert: isAlert,
                        isReadOnly: isReadOnly,
                        controller: _controllers[r.labTestId],
                        qualitativeValue: _qualitativeValues[r.labTestId],
                        onQualitativeChanged: (val) {
                          setState(() => _qualitativeValues[r.labTestId] = val);
                        },
                        onNumericChanged: (_) {
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
              ),

              // 4. Footer de Acciones
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    if (isReadOnly || widget.order.results.isNotEmpty)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text('Ver Informe'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.pop(context);
                                }
                                showClinicalOrderViewerDialog(context, widget.order);
                              },
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.pop(context);
                              }
                            },
                      child: Text(isReadOnly ? 'Cerrar' : 'Cancelar'),
                    ),
                    if (!isReadOnly) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check, size: 16),
                        label: Text(
                          filledCount == _results.length && widget.order.paidAmount >= widget.order.totalPrice
                              ? 'Completar y Guardar'
                              : 'Guardar Resultados',
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParameterCard extends StatelessWidget {
  final OrderTestResult result;
  final String? alert;
  final bool isAlert;
  final bool isReadOnly;
  final TextEditingController? controller;
  final String? qualitativeValue;
  final ValueChanged<String> onQualitativeChanged;
  final ValueChanged<String> onNumericChanged;

  const _ParameterCard({
    required this.result,
    required this.alert,
    required this.isAlert,
    required this.isReadOnly,
    required this.controller,
    required this.qualitativeValue,
    required this.onQualitativeChanged,
    required this.onNumericChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Decoración de borde reactivo
    final borderColor = isAlert
        ? Colors.red.shade300
        : (alert == 'NORMAL' ? Colors.green.shade200 : theme.colorScheme.outlineVariant);

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
              Container(
                constraints: const BoxConstraints(minWidth: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      result.dataType == 'numeric' ? 'VALOR REFERENCIAL' : 'VALOR ESPERADO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getReferenceText(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
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
    if (alert == 'HIGH') {
      return _BadgePill(
        label: 'ALTO ▲',
        bgColor: Colors.red.shade50,
        textColor: Colors.red.shade900,
        borderColor: Colors.red.shade200,
      );
    } else if (alert == 'LOW') {
      return _BadgePill(
        label: 'BAJO ▼',
        bgColor: Colors.blue.shade50,
        textColor: Colors.blue.shade900,
        borderColor: Colors.blue.shade200,
      );
    } else if (alert == 'ABNORMAL') {
      return _BadgePill(
        label: 'ANORMAL',
        bgColor: Colors.orange.shade50,
        textColor: Colors.orange.shade900,
        borderColor: Colors.orange.shade200,
      );
    } else if (alert == 'NORMAL') {
      return _BadgePill(
        label: 'NORMAL',
        bgColor: Colors.green.shade50,
        textColor: Colors.green.shade800,
        borderColor: Colors.green.shade200,
      );
    }
    return _BadgePill(
      label: 'PENDIENTE',
      bgColor: theme.colorScheme.surfaceContainerHigh,
      textColor: theme.colorScheme.onSurfaceVariant,
      borderColor: theme.colorScheme.outlineVariant,
    );
  }

  String _getReferenceText() {
    if (result.dataType == 'numeric') {
      if (result.referenceValues.isNotEmpty) {
        final ref = result.referenceValues.first;
        final unit = result.unitOfMeasure.isNotEmpty ? ' ${result.unitOfMeasure}' : '';
        return '${ref.minValue} - ${ref.maxValue}$unit';
      }
      return 'No especificado';
    } else if (result.dataType == 'boolean') {
      return result.expectedQualitativeValue ?? 'Negativo';
    }
    return 'Texto libre';
  }

  String _getAlertExplanation() {
    if (alert == 'HIGH' && result.referenceValues.isNotEmpty) {
      final ref = result.referenceValues.first;
      return 'El valor está por encima del límite máximo (${ref.maxValue} ${result.unitOfMeasure})';
    } else if (alert == 'LOW' && result.referenceValues.isNotEmpty) {
      final ref = result.referenceValues.first;
      return 'El valor está por debajo del límite mínimo (${ref.minValue} ${result.unitOfMeasure})';
    } else if (alert == 'ABNORMAL') {
      return 'El resultado difiere del valor esperado (${result.expectedQualitativeValue ?? "Normal"})';
    }
    return 'Valor fuera de los parámetros estándar';
  }

  Widget _buildInput(ThemeData theme) {
    if (result.dataType == 'boolean') {
      final options = result.qualitativeOptions.isNotEmpty
          ? result.qualitativeOptions
          : ['Negativo', 'Positivo'];

      return DropdownButtonFormField<String>(
        initialValue: qualitativeValue ?? options.first,
        isDense: true,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            child: Text(opt, style: const TextStyle(fontSize: 13)),
          );
        }).toList(),
        onChanged: isReadOnly ? null : (val) {
          if (val != null) onQualitativeChanged(val);
        },
      );
    } else if (result.dataType == 'text') {
      return TextFormField(
        controller: controller,
        readOnly: isReadOnly,
        maxLines: 1,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Observación...',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
        controller: controller,
        readOnly: isReadOnly,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: onNumericChanged,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isAlert ? Colors.red.shade900 : theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: '0.00',
          suffixText: result.unitOfMeasure.isNotEmpty ? result.unitOfMeasure : null,
          suffixStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

class _BadgePill extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;

  const _BadgePill({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
