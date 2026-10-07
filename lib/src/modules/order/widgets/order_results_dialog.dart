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
          val = _controllers[r.labTestId]?.text;
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

    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
        title: Text('Resultados de Orden: ${widget.order.examName}'),
      content: SizedBox(
        width: 550,
        height: 450,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingreso de Resultados por Análisis:',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final r = _results[index];
                    final hasAlert = r.alertFlag != null;

                    Widget inputWidget;
                    if (r.dataType == 'boolean') {
                      final options = r.qualitativeOptions.isNotEmpty
                          ? r.qualitativeOptions
                          : ['Negativo', 'Positivo'];
                      inputWidget = DropdownButtonFormField<String>(
                        initialValue: _qualitativeValues[r.labTestId] ?? options.first,
                        decoration: const InputDecoration(
                          labelText: 'Resultado Cualitativo',
                          isDense: true,
                        ),
                        items: options.map((opt) {
                          return DropdownMenuItem(value: opt, child: Text(opt));
                        }).toList(),
                        onChanged: isReadOnly
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() => _qualitativeValues[r.labTestId] = val);
                                }
                              },
                      );
                    } else if (r.dataType == 'text') {
                      final controller = _controllers[r.labTestId];
                      inputWidget = TextFormField(
                        controller: controller,
                        readOnly: isReadOnly,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones / Texto',
                          isDense: true,
                        ),
                      );
                    } else {
                      final controller = _controllers[r.labTestId];
                      inputWidget = TextFormField(
                        controller: controller,
                        readOnly: isReadOnly,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Resultado Numérico',
                          suffixText: r.unitOfMeasure,
                          isDense: true,
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.parameterName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (r.dataType == 'numeric' && r.referenceValues.isNotEmpty)
                                  Text(
                                    'Ref: ${r.referenceValues.first.minValue}-${r.referenceValues.first.maxValue} ${r.unitOfMeasure}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                else if (r.dataType == 'boolean' &&
                                    r.expectedQualitativeValue != null)
                                  Text(
                                    'Esperado: ${r.expectedQualitativeValue}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: inputWidget,
                          ),
                          if (hasAlert) ...[
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Tooltip(
                                message: 'Fuera de valor normal: ${r.alertFlag}',
                                child: Icon(
                                  Icons.warning,
                                  color: theme.colorScheme.error,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (isReadOnly || widget.order.results.isNotEmpty)
          OutlinedButton.icon(
            icon: const Icon(Icons.picture_as_pdf, size: 16),
            label: const Text('Ver / Exportar Informe'),
            onPressed: _isSubmitting
                ? null
                : () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.pop(context);
                    }
                    showClinicalOrderViewerDialog(context, widget.order);
                  },
          ),
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
        if (!isReadOnly)
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Completar y Guardar'),
          ),
      ],
      ),
    );
  }
}
