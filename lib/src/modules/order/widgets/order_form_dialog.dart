import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/patient_cubit/read_patients_cubit.dart';
import '../../../cubits/exam_cubit/read_exams_cubit.dart';
import '../../../cubits/order_cubit/write_orders_cubit.dart';

class OrderFormDialog extends StatefulWidget {
  const OrderFormDialog({super.key});

  @override
  State<OrderFormDialog> createState() => _OrderFormDialogState();
}

class _OrderFormDialogState extends State<OrderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPatientId;
  String? _selectedExamId;

  void _submit(List<ExamInDb> exams) {
    if (_formKey.currentState!.validate() && _selectedPatientId != null && _selectedExamId != null) {
      final selectedExam = exams.firstWhere((e) => e.id == _selectedExamId);
      final results = selectedExam.includedTests.map((test) {
        return OrderTestResult(
          labTestId: test.labTestId,
          parameterName: test.parameterName,
          medicalClassification: test.medicalClassification,
          dataType: test.dataType,
          unitOfMeasure: test.unitOfMeasure,
          referenceValues: test.referenceValues,
          resultValue: null,
          alertFlag: null,
        );
      }).toList();

      final newOrder = CreateOrder(
        patientId: _selectedPatientId!,
        examId: selectedExam.id,
        examName: selectedExam.name,
        salePriceApplied: selectedExam.salePrice,
        status: 'pending',
        results: results,
      );

      context.read<WriteOrderCubit>().create(newOrder).then((_) {
        if (!mounted) return;
        Navigator.pop(context, true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return AlertDialog(
      title: const Text('Nueva Orden Clínica'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Seleccionar Paciente *'),
                items: patients.map((p) {
                  return DropdownMenuItem(value: p.id, child: Text(p.name));
                }).toList(),
                validator: (val) => val == null ? 'Requerido' : null,
                onChanged: (val) => setState(() => _selectedPatientId = val),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Seleccionar Examen *'),
                items: exams.map((e) {
                  return DropdownMenuItem(value: e.id, child: Text('${e.name} (\$${e.salePrice})'));
                }).toList(),
                validator: (val) => val == null ? 'Requerido' : null,
                onChanged: (val) => setState(() => _selectedExamId = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        BlocBuilder<WriteOrderCubit, WriteOrderState>(
          builder: (context, state) {
            if (state is WritingOrder) {
              return const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            return ElevatedButton(
              onPressed: () => _submit(exams),
              child: const Text('Crear Orden'),
            );
          },
        ),
      ],
    );
  }
}
