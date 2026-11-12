import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import '../../../cubits/lab_test_cubit/write_lab_tests_cubit.dart';
import '../../../widgets/common/app_buttons.dart';
import '../controllers/lab_test_cycle_guard.dart';
import '../controllers/lab_test_form_mediator.dart';
import '../controllers/lab_test_form_view_controller.dart';
import '../widgets/quick_create_parameter_dialog.dart';
import '../widgets/sections/lab_test_general_info_section.dart';
import '../widgets/sections/lab_test_pack_children_section.dart';
import '../widgets/sections/lab_test_pricing_section.dart';
import '../widgets/sections/lab_test_reference_values_section.dart';

class LabTestFormScreen extends StatefulWidget {
  final LabTestInDb? labTest;

  const LabTestFormScreen({super.key, this.labTest});

  @override
  State<LabTestFormScreen> createState() => _LabTestFormScreenState();
}

class _LabTestFormScreenState extends State<LabTestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final LabTestFormViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LabTestFormViewController(initialLabTest: widget.labTest);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openQuickCreateParameter(List<LabTestInDb> allAvailableTests) async {
    final branchId = context.read<AppSessionCubit>().currentBranchId;
    final created = await QuickCreateParameterDialog.show(
      context,
      initialCategory: _controller.commercialCategory,
      initialSubclassification: _controller.subclassification,
      branchId: branchId,
    );

    if (created != null && mounted) {
      final updatedAvailable = [...allAvailableTests, created];
      _controller.addChildTestId(created.id, updatedAvailable);
      context.read<ReadLabTestCubit>().getAll(branchId: branchId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Parámetro "${created.name}" creado e incluido en este perfil.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _openQuickEditParameter(
    LabTestInDb testToEdit,
    List<LabTestInDb> allAvailableTests,
  ) async {
    final branchId = context.read<AppSessionCubit>().currentBranchId;
    final updated = await QuickCreateParameterDialog.showEdit(
      context,
      parameter: testToEdit,
      branchId: branchId,
    );

    if (updated != null && mounted) {
      final updatedList = allAvailableTests.map((t) => t.id == updated.id ? updated : t).toList();
      _controller.updateCalculatedPrice(updatedList);
      context.read<ReadLabTestCubit>().getAll(branchId: branchId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Parámetro "${updated.name}" actualizado exitosamente.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  void _submit() {
    if (_controller.isPack && _controller.childTestIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Debe seleccionar al menos un análisis clínico para el pack.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_controller.referenceRangesError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.referenceRangesError!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final branchId = context.read<AppSessionCubit>().currentBranchId;
      final cubit = context.read<WriteLabTestCubit>();

      if (widget.labTest == null) {
        final newTest = _controller.generateCreateDto(branchId: branchId);
        cubit.create(newTest);
      } else {
        final updateTest = _controller.generateUpdateDto(branchId: branchId);
        cubit.update(widget.labTest!.id, updateTest);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _controller.isEdit;
    final theme = Theme.of(context);
    final readState = context.watch<ReadLabTestCubit>().state;
    final allAvailableTests = (readState is ReadLabTestSuccess)
        ? filterAvailableTestsForPack(
            allTests: readState.items,
            currentPackId: widget.labTest?.id,
          )
        : <LabTestInDb>[];

    return LabTestFormMediator(
      viewController: _controller,
      child: BlocListener<WriteLabTestCubit, WriteLabTestState>(
        listener: (context, state) {
          if (state is LabTestCreated || state is LabTestUpdated) {
            Navigator.of(context).pop(true);
          } else if (state is WriteLabTestError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al guardar: ${state.message}'),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: 'Volver al Catálogo',
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Editar Prueba / Pack' : 'Registrar Nueva Prueba / Pack',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isEdit
                          ? _controller.name
                          : (_controller.isPack
                                ? 'Configurando Paquete Comercial (Pack de Análisis)'
                                : 'Configurando Parámetro Clínico Individual'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFCCE5FF),
                      ),
                    ),
                  ],
                );
              },
            ),
            actions: [
              const SizedBox(width: 12),
              BlocBuilder<WriteLabTestCubit, WriteLabTestState>(
                builder: (context, state) {
                  final isSaving = state is WritingLabTest;
                  return GlassButton(
                    onPressed: isSaving ? null : _submit,
                    isLoading: isSaving,
                    isPrimary: true,
                    icon: Icons.save_outlined,
                    label: isEdit ? 'Guardar Cambios' : 'Registrar Prueba',
                  );
                },
              ),
              const SizedBox(width: 20),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const LabTestGeneralInfoSection(),
                      const SizedBox(height: 16),
                      LabTestPricingSection(allAvailableTests: allAvailableTests),
                      const SizedBox(height: 16),
                      LabTestPackChildrenSection(
                        allAvailableTests: allAvailableTests,
                        onQuickCreateParameter: () => _openQuickCreateParameter(allAvailableTests),
                        onQuickEditParameter: (t) => _openQuickEditParameter(t, allAvailableTests),
                        branchId: context.read<AppSessionCubit>().currentBranchId,
                      ),
                      const LabTestReferenceValuesSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
