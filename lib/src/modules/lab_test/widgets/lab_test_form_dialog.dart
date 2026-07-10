import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/lab_test_cubit/write_lab_tests_cubit.dart';

class LabTestFormDialog extends StatefulWidget {
  final LabTestInDb? labTest;

  const LabTestFormDialog({super.key, this.labTest});

  @override
  State<LabTestFormDialog> createState() => _LabTestFormDialogState();
}

class _LabTestFormDialogState extends State<LabTestFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _parameterName;
  late String _medicalClassification;
  late String _dataType;
  late String _unitOfMeasure;
  late List<ReferenceValue> _referenceValues;

  @override
  void initState() {
    super.initState();
    if (widget.labTest != null) {
      _parameterName = widget.labTest!.parameterName;
      _medicalClassification = widget.labTest!.medicalClassification;
      _dataType = widget.labTest!.dataType;
      _unitOfMeasure = widget.labTest!.unitOfMeasure;
      _referenceValues = List.from(widget.labTest!.referenceValues);
    } else {
      _parameterName = '';
      _medicalClassification = '';
      _dataType = 'numeric';
      _unitOfMeasure = 'mg/dL';
      _referenceValues = [];
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final cubit = context.read<WriteLabTestCubit>();

      if (widget.labTest == null) {
        final newTest = CreateLabTest(
          parameterName: _parameterName,
          medicalClassification: _medicalClassification,
          dataType: _dataType,
          unitOfMeasure: _unitOfMeasure,
          referenceValues: _referenceValues,
        );
        cubit.create(newTest).then((_) {
          if (!mounted) return;
          Navigator.pop(context, true);
        });
      } else {
        final updateTest = UpdateLabTest(
          parameterName: _parameterName,
          medicalClassification: _medicalClassification,
          dataType: _dataType,
          unitOfMeasure: _unitOfMeasure,
          referenceValues: _referenceValues,
        );
        cubit.update(widget.labTest!.id, updateTest).then((_) {
          if (!mounted) return;
          Navigator.pop(context, true);
        });
      }
    }
  }

  void _addReferenceValue() {
    setState(() {
      _referenceValues.add(
        ReferenceValue(
          patientType: 'general',
          gender: 'both',
          minAgeDays: 0,
          maxAgeDays: 36500, // 100 años aprox
          minValue: 0.0,
          maxValue: 10.0,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.labTest != null;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(isEdit ? 'Editar Prueba' : 'Nueva Prueba'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _parameterName,
                  decoration: const InputDecoration(labelText: 'Nombre del Parámetro *'),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  onSaved: (val) => _parameterName = val ?? '',
                ),
                TextFormField(
                  initialValue: _medicalClassification,
                  decoration: const InputDecoration(labelText: 'Clasificación Médica / Categoría *'),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  onSaved: (val) => _medicalClassification = val ?? '',
                ),
                DropdownButtonFormField<String>(
                  initialValue: _dataType,
                  decoration: const InputDecoration(labelText: 'Tipo de Dato'),
                  items: const [
                    DropdownMenuItem(value: 'numeric', child: Text('Numérico')),
                    DropdownMenuItem(value: 'text', child: Text('Texto / Descriptivo')),
                    DropdownMenuItem(value: 'boolean', child: Text('Booleano (Positivo/Negativo)')),
                  ],
                  onChanged: (val) => setState(() => _dataType = val ?? 'numeric'),
                ),
                TextFormField(
                  initialValue: _unitOfMeasure,
                  decoration: const InputDecoration(labelText: 'Unidad de Medida'),
                  onSaved: (val) => _unitOfMeasure = val ?? '',
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Valores de Referencia:',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: _addReferenceValue,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Agregar Valor'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _referenceValues.length,
                  itemBuilder: (context, index) {
                    final ref = _referenceValues[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: ref.gender,
                                  isDense: true,
                                  decoration: const InputDecoration(labelText: 'Género'),
                                  items: const [
                                    DropdownMenuItem(value: 'both', child: Text('Ambos')),
                                    DropdownMenuItem(value: 'male', child: Text('Masculino')),
                                    DropdownMenuItem(value: 'female', child: Text('Femenino')),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _referenceValues[index] = ReferenceValue(
                                        patientType: ref.patientType,
                                        gender: val ?? 'both',
                                        minAgeDays: ref.minAgeDays,
                                        maxAgeDays: ref.maxAgeDays,
                                        minValue: ref.minValue,
                                        maxValue: ref.maxValue,
                                      );
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: ref.minValue.toString(),
                                  decoration: const InputDecoration(labelText: 'Mínimo'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val) ?? 0.0;
                                    _referenceValues[index] = ReferenceValue(
                                      patientType: ref.patientType,
                                      gender: ref.gender,
                                      minAgeDays: ref.minAgeDays,
                                      maxAgeDays: ref.maxAgeDays,
                                      minValue: parsed,
                                      maxValue: ref.maxValue,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: ref.maxValue.toString(),
                                  decoration: const InputDecoration(labelText: 'Máximo'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val) ?? 0.0;
                                    _referenceValues[index] = ReferenceValue(
                                      patientType: ref.patientType,
                                      gender: ref.gender,
                                      minAgeDays: ref.minAgeDays,
                                      maxAgeDays: ref.maxAgeDays,
                                      minValue: ref.minValue,
                                      maxValue: parsed,
                                    );
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(() => _referenceValues.removeAt(index)),
                                color: theme.colorScheme.error,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        BlocBuilder<WriteLabTestCubit, WriteLabTestState>(
          builder: (context, state) {
            if (state is WritingLabTest) {
              return const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            return ElevatedButton(
              onPressed: _submit,
              child: Text(isEdit ? 'Guardar Cambios' : 'Registrar'),
            );
          },
        ),
      ],
    );
  }
}
