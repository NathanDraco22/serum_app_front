import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/order_cubit/write_orders_cubit.dart';

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

  @override
  void initState() {
    super.initState();
    _results = List.from(widget.order.results);
    _controllers = {};
    for (var r in _results) {
      _controllers[r.labTestId] = TextEditingController(text: r.resultValue ?? '');
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final updatedResults = _results.map((r) {
        final val = _controllers[r.labTestId]?.text;
        // Evaluar alerta simple (si es numérico y se sale de los rangos)
        String? alert;
        if (val != null && r.referenceValues.isNotEmpty) {
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
        return OrderTestResult(
          labTestId: r.labTestId,
          parameterName: r.parameterName,
          medicalClassification: r.medicalClassification,
          dataType: r.dataType,
          unitOfMeasure: r.unitOfMeasure,
          referenceValues: r.referenceValues,
          resultValue: val,
          alertFlag: alert,
        );
      }).toList();

      final updateOrder = UpdateOrder(
        status: 'completed',
        results: updatedResults,
      );

      context.read<WriteOrderCubit>().update(widget.order.id, updateOrder).then((_) {
        if (!mounted) return;
        Navigator.pop(context, true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReadOnly = widget.order.status == 'completed';

    return AlertDialog(
      title: Text('Resultados: ${widget.order.examName}'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parámetros y Valores del Examen:',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final r = _results[index];
                    final controller = _controllers[r.labTestId];
                    final hasAlert = r.alertFlag != null;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.parameterName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                Text(
                                  r.referenceValues.isNotEmpty
                                      ? 'Ref: ${r.referenceValues.first.minValue}-${r.referenceValues.first.maxValue} ${r.unitOfMeasure}'
                                      : 'Sin ref.',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: controller,
                              readOnly: isReadOnly,
                              decoration: InputDecoration(
                                labelText: 'Resultado',
                                suffixText: r.unitOfMeasure,
                                isDense: true,
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          if (hasAlert) ...[
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Fuera de rango normal: ${r.alertFlag}',
                              child: Icon(Icons.warning, color: theme.colorScheme.error, size: 20),
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isReadOnly ? 'Cerrar' : 'Cancelar'),
        ),
        if (!isReadOnly)
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Completar y Guardar'),
          ),
      ],
    );
  }
}
