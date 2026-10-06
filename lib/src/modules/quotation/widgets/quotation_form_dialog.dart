import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/patient_cubit/read_patients_cubit.dart';
import '../../../cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import '../../../cubits/quotation_cubit/write_quotations_cubit.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';

class QuotationFormDialog extends StatefulWidget {
  const QuotationFormDialog({super.key});

  @override
  State<QuotationFormDialog> createState() => _QuotationFormDialogState();
}

class _QuotationFormDialogState extends State<QuotationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String _clientName = '';
  String? _selectedPatientId;
  final List<QuotedExam> _selectedExams = [];

  void _submit(List<PatientInDb> patients, int totalAmount) {
    if (_formKey.currentState!.validate() && _selectedExams.isNotEmpty) {
      _formKey.currentState!.save();

      final activeBranchId = context.read<AppSessionCubit>().currentBranchId;

      final newQuotation = CreateQuotation(
        clientName: _selectedPatientId != null
            ? (patients.firstWhere((p) => p.id == _selectedPatientId).name)
            : _clientName,
        patientId: _selectedPatientId,
        branchId: activeBranchId,
        exams: _selectedExams,
        totalAmount: totalAmount,
        status: 'pending',
      );

      context.read<WriteQuotationCubit>().create(newQuotation).then((_) {
        if (!mounted) return;
        Navigator.pop(context, true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final patientsState = context.watch<ReadPatientCubit>().state;
    final labTestsState = context.watch<ReadLabTestCubit>().state;

    List<PatientInDb> patients = [];
    if (patientsState is ReadPatientSuccess) {
      patients = patientsState.items;
    }

    List<LabTestInDb> labTests = [];
    if (labTestsState is ReadLabTestSuccess) {
      labTests = labTestsState.items;
    }

    int totalAmount = _selectedExams.fold(0, (sum, item) => sum + item.quotedPrice);

    return AlertDialog(
      title: const Text('Nueva Cotización'),
      content: SizedBox(
        width: 650,
        height: 450,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Details & Items
            Expanded(
              flex: 3,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Paciente Registrado (Opcional)',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Cliente General (No registrado)'),
                        ),
                        ...patients.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedPatientId = val;
                        });
                      },
                    ),
                    if (_selectedPatientId == null)
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Nombre del Cliente *'),
                        validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                        onSaved: (val) => _clientName = val ?? '',
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Análisis / Packs Cotizados:',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Total: \$${(totalAmount / 100).toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _selectedExams.length,
                        itemBuilder: (context, index) {
                          final item = _selectedExams[index];
                          return ListTile(
                            dense: true,
                            title: Text(item.name),
                            subtitle: Text('\$${(item.quotedPrice / 100).toStringAsFixed(2)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                /* // Comentado temporalmente por requerimiento del cliente: Soporte Precio 2
                                IconButton(
                                  icon: Text(
                                    'P${item.priceLevel}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: item.priceLevel == 2
                                          ? theme.colorScheme.tertiary
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                  tooltip: 'Alternar tarifa P1 / P2',
                                  onPressed: () {
                                    final test = labTests.firstWhere(
                                      (t) => t.id == item.labTestId,
                                      orElse: () => LabTestInDb(
                                        id: item.labTestId,
                                        name: item.name,
                                        createdAt: 0,
                                      ),
                                    );
                                    final nextLevel = item.priceLevel == 1 ? 2 : 1;
                                    final nextPrice = (nextLevel == 2 && test.salePrice2 > 0)
                                        ? test.salePrice2
                                        : test.salePrice;
                                    setState(() {
                                      _selectedExams[index] = QuotedExam(
                                        labTestId: item.labTestId,
                                        name: item.name,
                                        quotedPrice: nextPrice,
                                        isPack: item.isPack,
                                        priceLevel: nextLevel,
                                      );
                                    });
                                  },
                                ),
                                */
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => setState(() => _selectedExams.removeAt(index)),
                                  color: theme.colorScheme.error,
                                ),
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
            const VerticalDivider(),
            // Right Column: Available Lab Tests / Packs
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Text(
                    'Catálogo de Pruebas y Packs',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: labTests.length,
                      itemBuilder: (context, index) {
                        final test = labTests[index];
                        final price1Str = (test.salePrice / 100).toStringAsFixed(2);
                        /* // Comentado temporalmente por requerimiento del cliente: Soporte Precio 2
                        final price2Str = (test.salePrice2 / 100).toStringAsFixed(2);
                        final priceDisplay = test.salePrice2 > 0
                            ? 'P1: \$$price1Str | P2: \$$price2Str'
                            : '\$$price1Str';
                        */
                        final priceDisplay = '\$$price1Str';

                        return ListTile(
                          dense: true,
                          leading: Icon(
                            test.isPack ? Icons.inventory_2 : Icons.science,
                            size: 20,
                            color: test.isPack
                                ? theme.colorScheme.tertiary
                                : theme.colorScheme.primary,
                          ),
                          title: Text(test.name),
                          subtitle: Text(priceDisplay),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle),
                            onPressed: () {
                              if (_selectedExams.any((e) => e.labTestId == test.id)) {
                                return;
                              }
                              setState(() {
                                _selectedExams.add(
                                  QuotedExam(
                                    labTestId: test.id,
                                    name: test.name,
                                    quotedPrice: test.salePrice,
                                    isPack: test.isPack,
                                    priceLevel: 1,
                                  ),
                                );
                              });
                            },
                            color: theme.colorScheme.primary,
                          ),
                        );
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
        BlocBuilder<WriteQuotationCubit, WriteQuotationState>(
          builder: (context, state) {
            if (state is WritingQuotation) {
              return const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            return ElevatedButton(
              onPressed: () => _submit(patients, totalAmount),
              child: const Text('Generar Cotización'),
            );
          },
        ),
      ],
    );
  }
}
