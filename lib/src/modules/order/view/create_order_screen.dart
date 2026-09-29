import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import '../../../cubits/order_cubit/write_orders_cubit.dart';
import '../../../widgets/dialogs/selectors/patient_selection_dialog.dart';
import '../../../widgets/dialogs/selectors/doctor_selection_dialog.dart';
import '../widgets/order_catalog_section.dart';
import '../widgets/order_cart_section.dart';

class CreateOrderScreen extends StatelessWidget {
  const CreateOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReadLabTestCubit>(
          create: (context) => ReadLabTestCubit(
            labTestsRepository: RepositoryProvider.of<LabTestsRepository>(context),
          )..getAll(),
        ),
        BlocProvider<WriteOrderCubit>(
          create: (context) => WriteOrderCubit(
            ordersRepository: RepositoryProvider.of<OrdersRepository>(context),
          ),
        ),
      ],
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
  bool _isSubmitting = false;

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

  void _toggleItem(LabTestInDb test) {
    setState(() {
      final index = _selectedItems.indexWhere((i) => i.id == test.id);
      if (index >= 0) {
        _selectedItems.removeAt(index);
      } else {
        _selectedItems.add(test);
      }
    });
  }

  void _removeItem(LabTestInDb test) {
    setState(() {
      _selectedItems.removeWhere((i) => i.id == test.id);
    });
  }

  void _clearItems() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Vaciar Análisis'),
        content: const Text('¿Deseas quitar todos los análisis agregados a esta orden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              setState(() => _selectedItems.clear());
            },
            child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_selectedItems.isEmpty && _selectedPatient == null) {
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

    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes agregar al menos un análisis a la orden.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // 1. Construir lista de OrderItem congelando precio
    final orderItems = _selectedItems.map((test) {
      return OrderItem(
        labTestId: test.id,
        name: test.name,
        salePriceApplied: test.salePrice,
        isPack: test.isPack,
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
    final activeBranchId =
        session.activeCashRegister?.branchId ?? session.currentUser?.branches.firstOrNull ?? '';

    final newOrder = CreateOrder(
      patientId: _selectedPatient!.id,
      doctorId: _selectedDoctor?.id,
      branchId: activeBranchId,
      items: orderItems,
      totalPrice: totalInCents,
      status: 'pending',
      results: resultsMap.values.toList(),
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

    final session = context.watch<AppSessionCubit>().state;
    final branchName = session.activeCashRegister?.name ?? 'Sucursal Principal';

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
            backgroundColor: theme.colorScheme.surfaceContainerLowest,
            leading: BackButton(
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Punto de Registro y Solicitud de Análisis',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.point_of_sale, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      branchName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
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
                          isSubmitting: _isSubmitting,
                          onSelectPatient: _pickPatient,
                          onRemovePatient: () => setState(() => _selectedPatient = null),
                          onSelectDoctor: _pickDoctor,
                          onRemoveDoctor: () => setState(() => _selectedDoctor = null),
                          onRemoveItem: _removeItem,
                          onClearItems: _clearItems,
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
                          isSubmitting: _isSubmitting,
                          onSelectPatient: _pickPatient,
                          onRemovePatient: () => setState(() => _selectedPatient = null),
                          onSelectDoctor: _pickDoctor,
                          onRemoveDoctor: () => setState(() => _selectedDoctor = null),
                          onRemoveItem: _removeItem,
                          onClearItems: _clearItems,
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
