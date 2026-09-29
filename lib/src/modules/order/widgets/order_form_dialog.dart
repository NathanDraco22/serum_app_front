import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/patient_cubit/read_patients_cubit.dart';
import '../../../cubits/doctor_cubit/read_doctors_cubit.dart';
import '../../../cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import '../../../cubits/order_cubit/write_orders_cubit.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';

class OrderFormDialog extends StatefulWidget {
  const OrderFormDialog({super.key});

  @override
  State<OrderFormDialog> createState() => _OrderFormDialogState();
}

class _OrderFormDialogState extends State<OrderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPatientId;
  String? _selectedDoctorId;
  final List<LabTestInDb> _selectedItems = [];

  void _submit(List<LabTestInDb> allLabTests) {
    if (_formKey.currentState!.validate() &&
        _selectedPatientId != null &&
        _selectedItems.isNotEmpty) {
      // 1. Construir lista de OrderItem
      final orderItems = _selectedItems.map((test) {
        return OrderItem(
          labTestId: test.id,
          name: test.name,
          salePriceApplied: test.salePrice,
          isPack: test.isPack,
        );
      }).toList();

      // 2. Resolver todos los test individuales para ingresar resultados (sin duplicar)
      final Map<String, OrderTestResult> resultsMap = {};

      for (var item in _selectedItems) {
        if (item.isPack) {
          // Expandir pruebas hijas del pack
          for (var childId in item.childTestIds) {
            final childTest = allLabTests.firstWhere(
              (t) => t.id == childId,
              orElse: () => LabTestInDb(
                id: childId,
                name: 'Análisis ($childId)',
                createdAt: 0,
              ),
            );
            if (!resultsMap.containsKey(childTest.id)) {
              resultsMap[childTest.id] = OrderTestResult(
                labTestId: childTest.id,
                parameterName: childTest.name,
                medicalClassification: childTest.commercialCategory,
                dataType: childTest.dataType,
                unitOfMeasure: childTest.unitOfMeasure,
                referenceValues: childTest.referenceValues,
                qualitativeOptions: childTest.qualitativeOptions,
                expectedQualitativeValue: childTest.expectedQualitativeValue,
              );
            }
          }
        } else {
          // Prueba individual
          if (!resultsMap.containsKey(item.id)) {
            resultsMap[item.id] = OrderTestResult(
              labTestId: item.id,
              parameterName: item.name,
              medicalClassification: item.commercialCategory,
              dataType: item.dataType,
              unitOfMeasure: item.unitOfMeasure,
              referenceValues: item.referenceValues,
              qualitativeOptions: item.qualitativeOptions,
              expectedQualitativeValue: item.expectedQualitativeValue,
            );
          }
        }
      }

      final totalInCents = _selectedItems.fold(0, (sum, i) => sum + i.salePrice);

      final session = context.read<AppSessionCubit>().state;
      final activeBranchId = session.activeCashRegister?.branchId ?? session.currentUser?.branches.firstOrNull ?? '';

      final newOrder = CreateOrder(
        patientId: _selectedPatientId!,
        doctorId: _selectedDoctorId,
        branchId: activeBranchId,
        items: orderItems,
        totalPrice: totalInCents,
        status: 'pending',
        results: resultsMap.values.toList(),
      );

      context.read<WriteOrderCubit>().create(newOrder).then((_) {
        if (!mounted) return;
        Navigator.pop(context, true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final patientsState = context.watch<ReadPatientCubit>().state;
    final doctorsState = context.watch<ReadDoctorCubit>().state;
    final labTestsState = context.watch<ReadLabTestCubit>().state;

    List<PatientInDb> patients = [];
    if (patientsState is ReadPatientSuccess) {
      patients = patientsState.items;
    }

    List<DoctorInDb> doctors = [];
    if (doctorsState is ReadDoctorSuccess) {
      doctors = doctorsState.items;
    }

    List<LabTestInDb> labTests = [];
    if (labTestsState is ReadLabTestSuccess) {
      labTests = labTestsState.items;
    }

    final totalFormatted = (_selectedItems.fold(0, (sum, i) => sum + i.salePrice) / 100.0)
        .toStringAsFixed(2);

    return AlertDialog(
      title: const Text('Nueva Orden Clínica'),
      content: SizedBox(
        width: 550,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector de Paciente
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Seleccionar Paciente *',
                  prefixIcon: Icon(Icons.person),
                ),
                items: patients.map((p) {
                  return DropdownMenuItem(value: p.id, child: Text(p.name));
                }).toList(),
                validator: (val) => val == null ? 'Requerido' : null,
                onChanged: (val) => setState(() => _selectedPatientId = val),
              ),
              const SizedBox(height: 12),

              // Selector de Médico Remitente (Opcional)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Médico Remitente (Opcional)',
                  prefixIcon: Icon(Icons.badge),
                ),
                items: doctors.map((d) {
                  return DropdownMenuItem(value: d.id, child: Text(d.name));
                }).toList(),
                onChanged: (val) => setState(() => _selectedDoctorId = val),
              ),
              const SizedBox(height: 16),

              // Buscador / Selector de Pruebas y Packs
              Text(
                'Seleccionar Pruebas o Packs Comercializables:',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Autocomplete<LabTestInDb>(
                displayStringForOption: (option) =>
                    '${option.name} (\$${(option.salePrice / 100).toStringAsFixed(2)})',
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return labTests;
                  }
                  final query = textEditingValue.text.toLowerCase();
                  return labTests.where(
                    (t) =>
                        t.name.toLowerCase().contains(query) ||
                        (t.code != null && t.code!.toLowerCase().contains(query)),
                  );
                },
                onSelected: (option) {
                  if (!_selectedItems.any((item) => item.id == option.id)) {
                    setState(() => _selectedItems.add(option));
                  }
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      hintText: 'Buscar prueba o pack (ej. Perfil Lipídico, Glucosa...)',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Lista de ítems seleccionados
              if (_selectedItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No has agregado ningún análisis a esta orden.',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _selectedItems.length,
                    itemBuilder: (context, index) {
                      final item = _selectedItems[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          item.isPack ? Icons.inventory_2 : Icons.science,
                          color: item.isPack
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.primary,
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          item.isPack
                              ? 'Pack (${item.childTestIds.length} sub-análisis)'
                              : item.commercialCategory,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\$${(item.salePrice / 100).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() => _selectedItems.removeAt(index)),
                              color: theme.colorScheme.error,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const Divider(),

              // Total general
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total a Cobrar:',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$$totalFormatted USD',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
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
              onPressed: () => _submit(labTests),
              child: const Text('Crear Orden'),
            );
          },
        ),
      ],
    );
  }
}
