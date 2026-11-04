import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import '../../../cubits/quotation_cubit/write_quotations_cubit.dart';
import '../../../cubits/patient_cubit/write_patients_cubit.dart';
import '../../../cubits/doctor_cubit/write_doctors_cubit.dart';
import '../../../widgets/dialogs/selectors/patient_selection_dialog.dart';
import '../../../widgets/dialogs/selectors/doctor_selection_dialog.dart';
import '../../../widgets/dialogs/viewers/quotation_viewer.dart';
import '../../patient/widgets/patient_form_dialog.dart';
import '../../doctor/widgets/doctor_form_dialog.dart';
import '../../../widgets/common/app_buttons.dart';
import '../../order/widgets/order_catalog_section.dart';
import '../controllers/create_quotation_mediator.dart';
import '../controllers/create_quotation_view_controller.dart';
import '../widgets/quotation_cart_section.dart';

class CreateQuotationScreen extends StatelessWidget {
  const CreateQuotationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WriteQuotationCubit>(
      create: (context) => WriteQuotationCubit(
        quotationsRepository: RepositoryProvider.of<QuotationsRepository>(context),
      ),
      child: const _CreateQuotationContent(),
    );
  }
}

class _CreateQuotationContent extends StatefulWidget {
  const _CreateQuotationContent();

  @override
  State<_CreateQuotationContent> createState() => _CreateQuotationContentState();
}

class _CreateQuotationContentState extends State<_CreateQuotationContent> {
  late final CreateQuotationViewController viewController;

  @override
  void initState() {
    super.initState();
    viewController = CreateQuotationViewController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReadLabTestCubit>().loadIfNotLoaded(
              branchId: context.read<AppSessionCubit>().currentBranchId,
            );
      }
    });
  }

  @override
  void dispose() {
    viewController.dispose();
    super.dispose();
  }

  Future<void> _pickPatient() async {
    final patient = await showPatientSelectionDialog(context);
    if (patient != null && mounted) {
      viewController.selectPatient(patient);
    }
  }

  Future<void> _pickDoctor() async {
    final doctor = await showDoctorSelectionDialog(context);
    if (doctor != null && mounted) {
      viewController.selectDoctor(doctor);
    }
  }

  Future<void> _openCreatePatientDialog() async {
    final created = await showDialog<dynamic>(
      context: context,
      builder: (dialogCtx) => BlocProvider<WritePatientCubit>(
        create: (context) => WritePatientCubit(
          patientsRepository: RepositoryProvider.of<PatientsRepository>(context),
        ),
        child: const PatientFormDialog(),
      ),
    );
    if (created != null && created is PatientInDb && mounted) {
      viewController.selectPatient(created);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paciente "${created.name}" registrado y seleccionado')),
      );
    }
  }

  Future<void> _openCreateDoctorDialog() async {
    final created = await showDialog<dynamic>(
      context: context,
      builder: (dialogCtx) => BlocProvider<WriteDoctorCubit>(
        create: (context) => WriteDoctorCubit(
          doctorsRepository: RepositoryProvider.of<DoctorsRepository>(context),
        ),
        child: const DoctorFormDialog(),
      ),
    );
    if (created != null && created is DoctorInDb && mounted) {
      viewController.selectDoctor(created);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Médico "${created.name}" registrado y seleccionado')),
      );
    }
  }

  void _clearItems() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Vaciar Cotización'),
        content: const Text('¿Deseas quitar todos los análisis agregados a este presupuesto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              viewController.clearCart();
            },
            child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (viewController.isEmpty) {
      return true;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar Cotización'),
        content: const Text(
          'Tienes datos ingresados en esta cotización. ¿Deseas salir y descartar los cambios?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Descartar y salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    return discard ?? false;
  }

  void _submit() {
    if (viewController.selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes agregar al menos un análisis a la cotización.')),
      );
      return;
    }

    viewController.setSubmitting(true);

    final activeBranchId = context.read<AppSessionCubit>().currentBranchId;
    final newQuotation = viewController.generateCreateQuotation(branchId: activeBranchId);

    if (newQuotation == null) {
      viewController.setSubmitting(false);
      return;
    }

    context.read<WriteQuotationCubit>().create(newQuotation);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labTestsState = context.watch<ReadLabTestCubit>().state;

    List<LabTestInDb> allLabTests = [];
    bool isLoadingTests = false;
    if (labTestsState is ReadLabTestLoading) {
      isLoadingTests = true;
    } else if (labTestsState is ReadLabTestSuccess) {
      allLabTests = labTestsState.items;
    }

    final sessionCubit = context.watch<AppSessionCubit>();
    final branchName = sessionCubit.currentBranchName;

    return CreateQuotationMediator(
      viewController: viewController,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        },
        child: BlocListener<WriteQuotationCubit, WriteQuotationState>(
          listener: (context, state) {
            if (state is QuotationCreated) {
              viewController.setSubmitting(false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡Cotización generada exitosamente!')),
              );

              // Abrir visor de cotización inmediatamente para exportar a PDF o imprimir
              showQuotationViewerDialog(
                context,
                state.item,
                clientInfo: state.item.clientInfo,
                doctorInfo: state.item.doctorInfo,
              ).then((_) {
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              });
            } else if (state is WriteQuotationError) {
              viewController.setSubmitting(false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al generar la cotización: ${state.message}'),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          },
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            appBar: AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: BackButton(
                color: Colors.white,
                onPressed: () async {
                  final shouldPop = await _onWillPop();
                  if (shouldPop && context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nueva Cotización de Análisis',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  Text(
                    'Presupuesto Rápido con Exportación a PDF',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFCCE5FF),
                    ),
                  ),
                ],
              ),
              actions: [
                GlassButton(
                  onPressed: _openCreatePatientDialog,
                  icon: Icons.person_add_outlined,
                  label: 'Nuevo Paciente',
                ),
                const SizedBox(width: 8),
                GlassButton(
                  onPressed: _openCreateDoctorDialog,
                  icon: Icons.medical_services_outlined,
                  label: 'Nuevo Médico',
                ),
                const SizedBox(width: 12),
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.point_of_sale, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        branchName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(14.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 950;

                  final catalogWidget = ListenableBuilder(
                    listenable: viewController,
                    builder: (context, _) => OrderCatalogSection(
                      allLabTests: allLabTests,
                      isLoading: isLoadingTests,
                      selectedItems: viewController.selectedItems,
                      onToggleItem: viewController.toggleItem,
                    ),
                  );

                  final cartWidget = QuotationCartSection(
                    onSelectPatient: _pickPatient,
                    onSelectDoctor: _pickDoctor,
                    onClearItems: _clearItems,
                    onSubmitQuotation: _submit,
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Columna 1: Catálogo de Pruebas y Packs
                        Expanded(
                          flex: 58,
                          child: catalogWidget,
                        ),
                        const SizedBox(width: 14),
                        // Columna 2: Carrito de Cotización
                        Expanded(
                          flex: 42,
                          child: cartWidget,
                        ),
                      ],
                    );
                  }

                  // Layout en columna para pantallas medianas o reducidas
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 520,
                          child: catalogWidget,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 600,
                          child: cartWidget,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
