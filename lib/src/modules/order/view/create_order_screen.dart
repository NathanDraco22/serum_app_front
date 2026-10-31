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
import '../widgets/order_catalog_section.dart';
import '../widgets/order_cart_section.dart';
import '../widgets/edit_item_price_dialog.dart';
import '../widgets/add_service_dialog.dart';
import '../widgets/add_discount_dialog.dart';

class CreateOrderScreen extends StatelessWidget {
  const CreateOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WriteOrderCubit>(
      create: (context) => WriteOrderCubit(
        ordersRepository: RepositoryProvider.of<OrdersRepository>(context),
      ),
      child: const _CreateOrderContent(),
    );
  }
}

class _CreateOrderContent extends StatefulWidget {
  const _CreateOrderContent();

  @override
  State<_CreateOrderContent> createState() => _CreateOrderContentState();
}

class _CreateOrderContentState extends State<_CreateOrderContent> {
  PatientInDb? _selectedPatient;
  DoctorInDb? _selectedDoctor;
  final List<LabTestInDb> _selectedItems = [];
  final List<OrderService> _services = [];
  final List<OrderDiscount> _discounts = [];
  final Map<String, int> _itemPriceLevels = {};
  final Map<String, int> _customPrices = {};
  int _defaultPriceLevel = 1;
  bool _isSubmitting = false;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
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
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPatient() async {
    final patient = await showPatientSelectionDialog(context);
    if (patient != null && mounted) {
      setState(() {
        _selectedPatient = patient;
      });
    }
  }

  Future<void> _pickDoctor() async {
    final doctor = await showDoctorSelectionDialog(context);
    if (doctor != null && mounted) {
      setState(() {
        _selectedDoctor = doctor;
      });
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
      setState(() {
        _selectedPatient = created;
      });
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
      setState(() {
        _selectedDoctor = created;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Médico "${created.name}" registrado y seleccionado')),
      );
    }
  }

  void _toggleItem(LabTestInDb test) {
    setState(() {
      final index = _selectedItems.indexWhere((i) => i.id == test.id);
      if (index >= 0) {
        _selectedItems.removeAt(index);
        _itemPriceLevels.remove(test.id);
        _customPrices.remove(test.id);
      } else {
        _selectedItems.add(test);
        _itemPriceLevels[test.id] = _defaultPriceLevel;
      }
    });
  }

  void _removeItem(LabTestInDb test) {
    setState(() {
      _selectedItems.removeWhere((i) => i.id == test.id);
      _itemPriceLevels.remove(test.id);
      _customPrices.remove(test.id);
    });
  }

  Future<void> _editItemPrice(LabTestInDb test) async {
    final current = _customPrices[test.id] ?? test.salePrice;
    final newPrice = await EditItemPriceDialog.show(
      context,
      testName: test.name,
      catalogPrice: test.salePrice,
      currentPrice: current,
    );
    if (newPrice != null && mounted) {
      setState(() {
        if (newPrice == test.salePrice) {
          _customPrices.remove(test.id);
        } else {
          _customPrices[test.id] = newPrice;
        }
      });
    }
  }

  void _changeItemPriceLevel(LabTestInDb test, int level) {
    setState(() {
      _itemPriceLevels[test.id] = level;
    });
  }

  void _changeDefaultPriceLevel(int level) {
    setState(() {
      _defaultPriceLevel = level;
      for (final item in _selectedItems) {
        _itemPriceLevels[item.id] = level;
      }
    });
  }

  Future<void> _openAddServiceDialog() async {
    final result = await AddServiceDialog.show(context);
    if (result != null && mounted) {
      setState(() {
        _services.add(result);
      });
    }
  }

  Future<void> _editService(OrderService service) async {
    final result = await AddServiceDialog.show(context, initialService: service);
    if (result != null && mounted) {
      setState(() {
        final index = _services.indexWhere((s) => s.id == service.id);
        if (index >= 0) {
          _services[index] = result;
        }
      });
    }
  }

  void _removeService(OrderService service) {
    setState(() {
      _services.removeWhere((s) => s.id == service.id);
    });
  }

  int _calculateCurrentGrossSubtotal() {
    final testsTotalInCents = _selectedItems.fold<int>(0, (sum, test) {
      final level = _itemPriceLevels[test.id] ?? _defaultPriceLevel;
      final customPrice = _customPrices[test.id];
      final price = customPrice ??
          ((level == 2 && test.salePrice2 > 0) ? test.salePrice2 : test.salePrice);
      return sum + price;
    });
    final servicesTotalInCents = _services.fold<int>(0, (sum, s) => sum + s.price);
    return testsTotalInCents + servicesTotalInCents;
  }

  Future<void> _openAddDiscountDialog() async {
    final currentSubtotal = _calculateCurrentGrossSubtotal();
    if (currentSubtotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega análisis o servicios antes de aplicar un descuento.')),
      );
      return;
    }
    final result = await AddDiscountDialog.show(context, currentSubtotal: currentSubtotal);
    if (result != null && mounted) {
      setState(() {
        _discounts.add(result);
      });
    }
  }

  Future<void> _editDiscount(OrderDiscount discount) async {
    final currentSubtotal = _calculateCurrentGrossSubtotal();
    final result = await AddDiscountDialog.show(
      context,
      currentSubtotal: currentSubtotal,
      initialDiscount: discount,
    );
    if (result != null && mounted) {
      setState(() {
        final index = _discounts.indexWhere((d) => d.id == discount.id);
        if (index >= 0) {
          _discounts[index] = result;
        }
      });
    }
  }

  void _removeDiscount(OrderDiscount discount) {
    setState(() {
      _discounts.removeWhere((d) => d.id == discount.id);
    });
  }

  void _clearItems() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Vaciar Análisis y Servicios'),
        content: const Text('¿Deseas quitar todos los análisis, servicios y descuentos agregados a esta orden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              setState(() {
                _selectedItems.clear();
                _services.clear();
                _discounts.clear();
                _itemPriceLevels.clear();
                _customPrices.clear();
              });
            },
            child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_selectedItems.isEmpty && _services.isEmpty && _discounts.isEmpty && _selectedPatient == null) {
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

  void _submit(List<LabTestInDb> allLabTests) {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un paciente.')),
      );
      return;
    }

    if (_selectedItems.isEmpty && _services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes agregar al menos un análisis o servicio a la orden.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // 1. Construir lista de OrderItem congelando precio según su priceLevel o precio personalizado
    final orderItems = _selectedItems.map((test) {
      final level = _itemPriceLevels[test.id] ?? _defaultPriceLevel;
      final customPrice = _customPrices[test.id];
      final price = customPrice ??
          ((level == 2 && test.salePrice2 > 0) ? test.salePrice2 : test.salePrice);
      return OrderItem(
        labTestId: test.id,
        name: test.name,
        salePriceApplied: price,
        originalPrice: test.salePrice,
        isPack: test.isPack,
        priceLevel: level,
      );
    }).toList();

    // 2. Resolver parámetros individuales para ingreso de resultados (sin duplicar)
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
              subclassification: childTest.subclassification,
              dataType: childTest.dataType,
              unitOfMeasure: childTest.unitOfMeasure,
              referenceValues: childTest.referenceValues,
              qualitativeOptions: childTest.qualitativeOptions,
              expectedQualitativeValue: childTest.expectedQualitativeValue,
              referenceText: childTest.referenceText,
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
            subclassification: item.subclassification,
            dataType: item.dataType,
            unitOfMeasure: item.unitOfMeasure,
            referenceValues: item.referenceValues,
            qualitativeOptions: item.qualitativeOptions,
            expectedQualitativeValue: item.expectedQualitativeValue,
            referenceText: item.referenceText,
          );
        }
      }
    }

    final testsTotalInCents = orderItems.fold<int>(0, (sum, i) => sum + i.salePriceApplied);
    final servicesTotalInCents = _services.fold<int>(0, (sum, s) => sum + s.price);
    final grossTotalInCents = testsTotalInCents + servicesTotalInCents;
    final discountsTotalInCents = _discounts.fold<int>(0, (sum, d) => sum + d.appliedAmount);
    final totalInCents = (grossTotalInCents - discountsTotalInCents).clamp(0, grossTotalInCents);
    final activeBranchId = context.read<AppSessionCubit>().currentBranchId;

    // 3. Evaluar si algún ítem tiene precio diferente de su precio de catálogo o si hay descuentos
    final hasModifiedPrice = orderItems.any((i) => i.salePriceApplied != i.originalPrice);
    final hasDiscounts = _discounts.isNotEmpty;
    final requiresSupervisorApproval = hasModifiedPrice || hasDiscounts;
    final currentUser = context.read<AppSessionCubit>().user;
    final hasSupervisorLevel = (currentUser?.accessLevel ?? 0) > 3;

    bool isBlocked = false;
    OrderApproval? approval;

    if (requiresSupervisorApproval) {
      final defaultReason = hasDiscounts && hasModifiedPrice
          ? 'Precio modificado y descuento aplicado en ventanilla'
          : (hasDiscounts
              ? 'Descuento aplicado a la orden'
              : 'Precio modificado respecto al catálogo');

      if (hasSupervisorLevel && currentUser != null) {
        // Creado por un supervisor o admin -> se aprueba automáticamente
        isBlocked = false;
        approval = OrderApproval(
          requiresApproval: true,
          isApproved: true,
          approvedBy: UserInfo(id: currentUser.id, name: currentUser.name),
          approvedAt: DateTime.now().millisecondsSinceEpoch,
          reason: '$defaultReason (Autorizado por supervisor: ${currentUser.name})',
        );
      } else {
        // Creado por un operador -> nace bloqueada
        isBlocked = true;
        approval = OrderApproval(
          requiresApproval: true,
          isApproved: false,
          reason: defaultReason,
        );
      }
    }

    final newOrder = CreateOrder(
      patientId: _selectedPatient!.id,
      doctorId: _selectedDoctor?.id,
      patientInfo: PatientInfo(
        name: _selectedPatient!.name,
        dateOfBirth: _selectedPatient!.dateOfBirth,
        gender: _selectedPatient!.gender,
        phone: _selectedPatient!.phone,
        address: _selectedPatient!.address ?? '',
        cardId: _selectedPatient!.cardId,
        email: _selectedPatient!.email,
        age: _selectedPatient!.age,
      ),
      doctorInfo: _selectedDoctor != null
          ? DoctorInfo(
              name: _selectedDoctor!.name,
              specialty: _selectedDoctor!.specialty,
              phone: _selectedDoctor!.phone ?? '',
              cardId: _selectedDoctor!.cardId,
              email: _selectedDoctor!.email,
            )
          : null,
      branchId: activeBranchId,
      items: orderItems,
      services: _services,
      discounts: _discounts,
      totalPrice: totalInCents,
      status: 'pending',
      results: resultsMap.values.toList(),
      isBlocked: isBlocked,
      approval: approval,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    context.read<WriteOrderCubit>().create(newOrder);
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

    return PopScope(
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
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Orden clínica creada exitosamente!')),
            );
            Navigator.pop(context, true);
          } else if (state is WriteOrderError) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al crear la orden: ${state.message}'),
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
                  'Nueva Orden Clínica',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                Text(
                  'Punto de Registro y Solicitud de Análisis',
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

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Columna 1: Catálogo de Pruebas y Perfiles
                      Expanded(
                        flex: 58,
                        child: OrderCatalogSection(
                          allLabTests: allLabTests,
                          isLoading: isLoadingTests,
                          selectedItems: _selectedItems,
                          onToggleItem: _toggleItem,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Columna 2: Resumen, Paciente, Médico y Carrito
                      Expanded(
                        flex: 42,
                        child: OrderCartSection(
                          selectedPatient: _selectedPatient,
                          selectedDoctor: _selectedDoctor,
                          selectedItems: _selectedItems,
                          services: _services,
                          discounts: _discounts,
                          itemPriceLevels: _itemPriceLevels,
                          itemCustomPrices: _customPrices,
                          defaultPriceLevel: _defaultPriceLevel,
                          notesController: _notesController,
                          isSubmitting: _isSubmitting,
                          onSelectPatient: _pickPatient,
                          onRemovePatient: () => setState(() => _selectedPatient = null),
                          onSelectDoctor: _pickDoctor,
                          onRemoveDoctor: () => setState(() => _selectedDoctor = null),
                          onRemoveItem: _removeItem,
                          onPriceLevelChanged: _changeItemPriceLevel,
                          onDefaultPriceLevelChanged: _changeDefaultPriceLevel,
                          onEditItemPrice: _editItemPrice,
                          onClearItems: _clearItems,
                          onAddService: _openAddServiceDialog,
                          onRemoveService: _removeService,
                          onEditService: _editService,
                          onAddDiscount: _openAddDiscountDialog,
                          onRemoveDiscount: _removeDiscount,
                          onEditDiscount: _editDiscount,
                          onSubmitOrder: () => _submit(allLabTests),
                        ),
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
                        child: OrderCatalogSection(
                          allLabTests: allLabTests,
                          isLoading: isLoadingTests,
                          selectedItems: _selectedItems,
                          onToggleItem: _toggleItem,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 600,
                        child: OrderCartSection(
                          selectedPatient: _selectedPatient,
                          selectedDoctor: _selectedDoctor,
                          selectedItems: _selectedItems,
                          services: _services,
                          discounts: _discounts,
                          itemPriceLevels: _itemPriceLevels,
                          itemCustomPrices: _customPrices,
                          defaultPriceLevel: _defaultPriceLevel,
                          notesController: _notesController,
                          isSubmitting: _isSubmitting,
                          onSelectPatient: _pickPatient,
                          onRemovePatient: () => setState(() => _selectedPatient = null),
                          onSelectDoctor: _pickDoctor,
                          onRemoveDoctor: () => setState(() => _selectedDoctor = null),
                          onRemoveItem: _removeItem,
                          onPriceLevelChanged: _changeItemPriceLevel,
                          onDefaultPriceLevelChanged: _changeDefaultPriceLevel,
                          onEditItemPrice: _editItemPrice,
                          onClearItems: _clearItems,
                          onAddService: _openAddServiceDialog,
                          onRemoveService: _removeService,
                          onEditService: _editService,
                          onAddDiscount: _openAddDiscountDialog,
                          onRemoveDiscount: _removeDiscount,
                          onEditDiscount: _editDiscount,
                          onSubmitOrder: () => _submit(allLabTests),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
