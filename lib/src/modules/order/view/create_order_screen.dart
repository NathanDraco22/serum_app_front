import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import '../../../cubits/order_cubit/write_orders_cubit.dart';
import '../../../cubits/patient_cubit/write_patients_cubit.dart';
import '../../../cubits/doctor_cubit/write_doctors_cubit.dart';
import '../../../widgets/dialogs/selectors/patient_selection_dialog.dart';
import '../../../widgets/dialogs/selectors/doctor_selection_dialog.dart';
import '../../patient/widgets/patient_form_dialog.dart';
import '../../doctor/widgets/doctor_form_dialog.dart';
import '../../../widgets/common/app_buttons.dart';
import '../controllers/create_order_mediator.dart';
import '../controllers/create_order_view_controller.dart';
import '../widgets/order_catalog_section.dart';
import '../widgets/order_cart_section.dart';
import '../widgets/edit_item_price_dialog.dart';
import '../widgets/add_service_dialog.dart';
import '../widgets/add_discount_dialog.dart';

class CreateOrderScreen extends StatelessWidget {
  final OrderInDb? editingOrder;

  const CreateOrderScreen({super.key, this.editingOrder});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WriteOrderCubit>(
      create: (context) => WriteOrderCubit(
        ordersRepository: RepositoryProvider.of<OrdersRepository>(context),
      ),
      child: _CreateOrderContent(editingOrder: editingOrder),
    );
  }
}

class _CreateOrderContent extends StatefulWidget {
  final OrderInDb? editingOrder;

  const _CreateOrderContent({this.editingOrder});

  @override
  State<_CreateOrderContent> createState() => _CreateOrderContentState();
}

class _CreateOrderContentState extends State<_CreateOrderContent> {
  late final CreateOrderViewController viewController;
  bool _isPopulated = false;

  @override
  void initState() {
    super.initState();
    viewController = CreateOrderViewController(editingOrder: widget.editingOrder);
    if (widget.editingOrder != null) {
      final labTestState = context.read<ReadLabTestCubit>().state;
      if (labTestState is ReadLabTestSuccess && labTestState.items.isNotEmpty) {
        viewController.populateFromOrder(widget.editingOrder!, labTestState.items);
        _isPopulated = true;
      }
    }
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
    if (!_ensureEditingLoaded() || !_ensurePatientCanChange()) return;
    final patient = await showPatientSelectionDialog(context);
    if (patient != null && mounted) {
      viewController.selectPatient(patient);
    }
  }

  /// Evita modificar una orden de edición mientras aún no se cargó su estado.
  bool _ensureEditingLoaded() {
    if (widget.editingOrder != null && !viewController.isPopulated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La orden aún se está cargando. Espera a que el catálogo esté disponible para evitar perder exámenes o resultados.',
          ),
        ),
      );
      return false;
    }
    return true;
  }

  /// Evita reasignar el paciente cuando la orden ya tiene resultados capturados.
  bool _ensurePatientCanChange() {
    if (widget.editingOrder != null && viewController.hasCapturedResults) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se puede cambiar el paciente porque la orden ya tiene resultados capturados. Corrige o elimina los resultados primero.',
          ),
        ),
      );
      return false;
    }
    return true;
  }

  void _removePatient() {
    if (!_ensureEditingLoaded() || !_ensurePatientCanChange()) return;
    viewController.removePatient();
  }

  Future<void> _pickDoctor() async {
    final doctor = await showDoctorSelectionDialog(context);
    if (doctor != null && mounted) {
      viewController.selectDoctor(doctor);
    }
  }

  Future<void> _openCreatePatientDialog() async {
    if (!_ensureEditingLoaded() || !_ensurePatientCanChange()) return;
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

  Future<void> _editItemPrice(LabTestInDb test) async {
    final current = viewController.getItemEffectivePrice(test);
    final newPrice = await EditItemPriceDialog.show(
      context,
      testName: test.name,
      catalogPrice: test.salePrice,
      currentPrice: current,
    );
    if (newPrice != null && mounted) {
      viewController.editItemPrice(test.id, newPrice, test.salePrice);
    }
  }

  Future<void> _openAddServiceDialog() async {
    final result = await AddServiceDialog.show(context);
    if (result != null && mounted) {
      viewController.addService(result);
    }
  }

  Future<void> _editService(OrderService service) async {
    final result = await AddServiceDialog.show(context, initialService: service);
    if (result != null && mounted) {
      viewController.editService(result);
    }
  }

  Future<void> _openAddDiscountDialog() async {
    final currentSubtotal = viewController.grossSubtotalInCents;
    if (currentSubtotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega análisis o servicios antes de aplicar un descuento.')),
      );
      return;
    }
    final result = await AddDiscountDialog.show(context, currentSubtotal: currentSubtotal);
    if (result != null && mounted) {
      viewController.addDiscount(result);
    }
  }

  Future<void> _editDiscount(OrderDiscount discount) async {
    final currentSubtotal = viewController.grossSubtotalInCents;
    final result = await AddDiscountDialog.show(
      context,
      currentSubtotal: currentSubtotal,
      initialDiscount: discount,
    );
    if (result != null && mounted) {
      viewController.editDiscount(result);
    }
  }

  void _clearItems() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Vaciar Análisis y Servicios'),
        content: const Text(
          '¿Deseas quitar todos los análisis, servicios y descuentos agregados a esta orden?',
        ),
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
        title: const Text('Descartar Orden'),
        content: const Text(
          'Tienes datos ingresados en esta orden. ¿Deseas salir y descartar los cambios?',
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

  Future<bool> _ensurePatientDemographics() async {
    final patient = viewController.selectedPatient;
    if (patient == null) return false;

    final hasDemographics = patient.dateOfBirth > 0 || patient.explicitAge != null;
    if (hasDemographics) return true;

    final shouldEdit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Datos demográficos incompletos'),
        content: Text(
          'El paciente "${patient.name}" no tiene fecha de nacimiento ni edad registrada.\n\n'
          'Complete estos datos antes de crear la orden para interpretar correctamente los rangos de referencia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Editar paciente'),
          ),
        ],
      ),
    );

    if (shouldEdit != true || !mounted) return false;

    final updated = await showDialog<dynamic>(
      context: context,
      builder: (dialogCtx) => BlocProvider<WritePatientCubit>(
        create: (context) => WritePatientCubit(
          patientsRepository: RepositoryProvider.of<PatientsRepository>(context),
        ),
        child: PatientFormDialog(patient: patient),
      ),
    );

    if (updated is PatientInDb && mounted) {
      viewController.updateSelectedPatientData(updated);
      return updated.dateOfBirth > 0 || updated.explicitAge != null;
    }
    return false;
  }

  Future<void> _submit(List<LabTestInDb> allLabTests) async {
    if (viewController.isSubmitting) return;

    if (widget.editingOrder != null && !viewController.isPopulated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La orden aún no ha terminado de cargar. No se guardará para evitar borrar sus exámenes y resultados.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (viewController.selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un paciente.')),
      );
      return;
    }

    if (!await _ensurePatientDemographics()) return;
    if (!mounted) return;

    if (viewController.selectedItems.isEmpty && viewController.services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes agregar al menos un análisis o servicio a la orden.')),
      );
      return;
    }

    final packError = viewController.validatePacksExpansion(allLabTests);
    if (packError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(packError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    viewController.setSubmitting(true);

    final activeBranchId = context.read<AppSessionCubit>().currentBranchId;
    final currentUser = context.read<AppSessionCubit>().user;

    if (widget.editingOrder != null) {
      final updateOrder = viewController.generateUpdateOrder(
        branchId: activeBranchId,
        currentUser: currentUser,
        allLabTests: allLabTests,
      );

      if (updateOrder == null) {
        viewController.setSubmitting(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo preparar la modificación de la orden. Revisa el catálogo y los exámenes seleccionados.',
            ),
          ),
        );
        return;
      }

      context.read<WriteOrderCubit>().update(widget.editingOrder!.id, updateOrder);
    } else {
      final newOrder = viewController.generateCreateOrder(
        branchId: activeBranchId,
        currentUser: currentUser,
        allLabTests: allLabTests,
      );

      if (newOrder == null) {
        viewController.setSubmitting(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo preparar la orden. Revisa el catálogo y los exámenes seleccionados.',
            ),
          ),
        );
        return;
      }

      context.read<WriteOrderCubit>().create(newOrder);
    }
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
      if (widget.editingOrder != null && !_isPopulated && allLabTests.isNotEmpty) {
        _isPopulated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            viewController.populateFromOrder(widget.editingOrder!, allLabTests);
            setState(() {});
          }
        });
      }
    }

    final sessionCubit = context.watch<AppSessionCubit>();
    final branchName = sessionCubit.currentBranchDisplayName;

    return CreateOrderMediator(
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
        child: BlocListener<WriteOrderCubit, WriteOrderState>(
          listener: (context, state) {
            if (state is OrderCreated) {
              viewController.setSubmitting(false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡Orden clínica creada exitosamente!')),
              );
              Navigator.pop(context, true);
            } else if (state is OrderUpdated) {
              viewController.setSubmitting(false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('¡Orden #${state.item.id} modificada exitosamente!')),
              );
              Navigator.pop(context, true);
            } else if (state is WriteOrderError) {
              viewController.setSubmitting(false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.editingOrder != null
                        ? 'Error al modificar la orden: ${state.message}'
                        : 'Error al crear la orden: ${state.message}',
                  ),
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
                  Text(
                    widget.editingOrder != null
                        ? 'Modificar Orden #${widget.editingOrder!.id}'
                        : 'Nueva Orden Clínica',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  Text(
                    widget.editingOrder != null
                        ? 'Paciente: ${widget.editingOrder!.patientInfo?.name ?? widget.editingOrder!.patientId}'
                        : 'Punto de Registro y Solicitud de Análisis',
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
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: Text(
                          branchName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.editingOrder != null && !viewController.isPopulated)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.hourglass_top_rounded,
                            size: 18,
                            color: Colors.amber.shade900,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cargando la orden y el catálogo. No se permite guardar hasta que termine, para no perder exámenes ni resultados.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
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

                        final cartWidget = OrderCartSection(
                          onSelectPatient: _pickPatient,
                          onSelectDoctor: _pickDoctor,
                          onRemovePatient: _removePatient,
                          onEditItemPrice: _editItemPrice,
                          onClearItems: _clearItems,
                          onAddService: _openAddServiceDialog,
                          onEditService: _editService,
                          onAddDiscount: _openAddDiscountDialog,
                          onEditDiscount: _editDiscount,
                          onSubmitOrder: () => _submit(allLabTests),
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Columna 1: Catálogo de Pruebas y Perfiles
                              Expanded(
                                flex: 58,
                                child: catalogWidget,
                              ),
                              const SizedBox(width: 14),
                              // Columna 2: Resumen, Paciente, Médico y Carrito
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
