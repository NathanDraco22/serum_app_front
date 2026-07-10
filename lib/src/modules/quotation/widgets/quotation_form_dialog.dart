import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/patient_cubit/read_patients_cubit.dart';
import '../../../cubits/exam_cubit/read_exams_cubit.dart';
import '../../../cubits/quotation_cubit/write_quotations_cubit.dart';

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

      final newQuotation = CreateQuotation(
        clientName: _selectedPatientId != null
            ? (patients.firstWhere((p) => p.id == _selectedPatientId).name)
            : _clientName,
        patientId: _selectedPatientId,
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
    final examsState = context.watch<ReadExamCubit>().state;

    List<PatientInDb> patients = [];
    if (patientsState is ReadPatientSuccess) {
      patients = patientsState.items;
    }

    List<ExamInDb> exams = [];
    if (examsState is ReadExamSuccess) {
      exams = examsState.items;
    }

    int totalAmount = _selectedExams.fold(0, (sum, item) => sum + item.quotedPrice);

    return AlertDialog(
      title: const Text('Nueva Cotización'),
      content: SizedBox(
        width: 600,
        height: 400,
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
                      decoration: const InputDecoration(labelText: 'Paciente Registrado (Opcional)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Cliente General (No registrado)')),
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
                        Text('Exámenes a Cotizar:', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Total: \$$totalAmount', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _selectedExams.length,
                        itemBuilder: (context, index) {
                          final item = _selectedExams[index];
                          return ListTile(
                            dense: true,
                            title: Text(item.examName),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => setState(() => _selectedExams.removeAt(index)),
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
            // Right Column: Available Exams
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text('Catálogo de Exámenes', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: exams.length,
                      itemBuilder: (context, index) {
                        final exam = exams[index];
                        return ListTile(
                          dense: true,
                          title: Text(exam.name),
                          subtitle: Text('\$${exam.salePrice}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle),
                            onPressed: () {
                              if (_selectedExams.any((e) => e.examId == exam.id)) {
                                return;
                              }
                              setState(() {
                                _selectedExams.add(
                                  QuotedExam(
                                    examId: exam.id,
                                    examName: exam.name,
                                    quotedPrice: exam.salePrice,
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
