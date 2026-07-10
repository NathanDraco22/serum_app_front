import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/exam_cubit/write_exams_cubit.dart';
import '../../../cubits/lab_test_cubit/read_lab_tests_cubit.dart';

class ExamFormDialog extends StatefulWidget {
  final ExamInDb? exam;

  const ExamFormDialog({super.key, this.exam});

  @override
  State<ExamFormDialog> createState() => _ExamFormDialogState();
}

class _ExamFormDialogState extends State<ExamFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _commercialCategory;
  late int _salePrice;
  late String _currency;
  late List<IncludedTest> _includedTests;

  @override
  void initState() {
    super.initState();
    if (widget.exam != null) {
      _name = widget.exam!.name;
      _commercialCategory = widget.exam!.commercialCategory;
      _salePrice = widget.exam!.salePrice;
      _currency = widget.exam!.currency;
      _includedTests = List.from(widget.exam!.includedTests);
    } else {
      _name = '';
      _commercialCategory = '';
      _salePrice = 0;
      _currency = 'USD';
      _includedTests = [];
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final cubit = context.read<WriteExamCubit>();

      if (widget.exam == null) {
        final newExam = CreateExam(
          name: _name,
          commercialCategory: _commercialCategory,
          salePrice: _salePrice,
          currency: _currency,
          includedTests: _includedTests,
        );
        cubit.create(newExam).then((_) {
          if (!mounted) return;
          Navigator.pop(context, true);
        });
      } else {
        final updateExam = UpdateExam(
          name: _name,
          commercialCategory: _commercialCategory,
          salePrice: _salePrice,
          currency: _currency,
          includedTests: _includedTests,
        );
        cubit.update(widget.exam!.id, updateExam).then((_) {
          if (!mounted) return;
          Navigator.pop(context, true);
        });
      }
    }
  }

  void _addLabTest(LabTestInDb labTest) {
    if (_includedTests.any((element) => element.labTestId == labTest.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta prueba ya ha sido agregada')),
      );
      return;
    }
    setState(() {
      _includedTests.add(
        IncludedTest(
          labTestId: labTest.id,
          parameterName: labTest.parameterName,
          medicalClassification: labTest.medicalClassification,
          dataType: 'text',
          unitOfMeasure: 'N/A',
          referenceValues: [],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.exam != null;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(isEdit ? 'Editar Examen' : 'Nuevo Examen'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Panel: Basic Details & Selected Tests
            Expanded(
              flex: 3,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(labelText: 'Nombre del Examen *'),
                      validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                      onSaved: (val) => _name = val ?? '',
                    ),
                    TextFormField(
                      initialValue: _commercialCategory,
                      decoration: const InputDecoration(labelText: 'Categoría Comercial *'),
                      validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                      onSaved: (val) => _commercialCategory = val ?? '',
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _salePrice.toString(),
                            decoration: const InputDecoration(labelText: 'Precio de Venta *'),
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || int.tryParse(val) == null ? 'Inválido' : null,
                            onSaved: (val) => _salePrice = int.parse(val ?? '0'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _currency,
                            decoration: const InputDecoration(labelText: 'Moneda'),
                            items: const [
                              DropdownMenuItem(value: 'USD', child: Text('USD')),
                              DropdownMenuItem(value: 'DOP', child: Text('DOP')),
                            ],
                            onChanged: (val) => setState(() => _currency = val ?? 'USD'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pruebas Incluidas (${_includedTests.length}):',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _includedTests.length,
                        itemBuilder: (context, index) {
                          final test = _includedTests[index];
                          return ListTile(
                            title: Text(test.parameterName),
                            subtitle: Text(test.medicalClassification),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => setState(() => _includedTests.removeAt(index)),
                              color: theme.colorScheme.error,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(),
            // Right Panel: Available Lab Tests to Add
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    'Pruebas Disponibles',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: BlocBuilder<ReadLabTestCubit, ReadLabTestState>(
                      builder: (context, state) {
                        if (state is ReadLabTestLoading) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (state is ReadLabTestSuccess) {
                          return ListView.builder(
                            itemCount: state.items.length,
                            itemBuilder: (context, index) {
                              final labTest = state.items[index];
                              return ListTile(
                                dense: true,
                                title: Text(labTest.parameterName),
                                subtitle: Text(labTest.medicalClassification),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_circle),
                                  onPressed: () => _addLabTest(labTest),
                                  color: theme.colorScheme.primary,
                                ),
                              );
                            },
                          );
                        }
                        return const Center(child: Text('Cargando pruebas...'));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        BlocBuilder<WriteExamCubit, WriteExamState>(
          builder: (context, state) {
            if (state is WritingExam) {
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
