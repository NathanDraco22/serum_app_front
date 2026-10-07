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
import '../widgets/quotation_cart_section.dart';

class CreateQuotationScreen extends StatelessWidget {
  const CreateQuotationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReadLabTestCubit>(
          create: (context) => ReadLabTestCubit(
            labTestsRepository: RepositoryProvider.of<LabTestsRepository>(context),
          )..getAll(),
        ),
        BlocProvider<WriteQuotationCubit>(
          create: (context) => WriteQuotationCubit(
            quotationsRepository: RepositoryProvider.of<QuotationsRepository>(context),
          ),
        ),
      ],
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
  PatientInDb? _selectedPatient;
  DoctorInDb? _selectedDoctor;
  final TextEditingController _casualClientNameController = TextEditingController();
  final List<LabTestInDb> _selectedItems = [];
  final Map<String, int> _itemPriceLevels = {};
  int _defaultPriceLevel = 1;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _casualClientNameController.dispose();
    super.dispose();
  }

  Future<void> _pickPatient() async {
    final patient = await showPatientSelectionDialog(context);
    if (patient != null && mounted) {
      setState(() {
        _selectedPatient = patient;
        _casualClientNameController.text = patient.name;
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
        _casualClientNameController.text = created.name;
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
    });
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
              setState(() {
                _selectedItems.clear();
                _itemPriceLevels.clear();
              });
            },
            child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_selectedItems.isEmpty &&
        _selectedPatient == null &&
        _casualClientNameController.text.isEmpty) {
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
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes agregar al menos un análisis a la cotización.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // 1. Resolver nombre del cliente
    final casualText = _casualClientNameController.text.trim();
    final clientName = _selectedPatient != null
        ? _selectedPatient!.name
        : (casualText.isNotEmpty ? casualText : 'Cliente General');

    // 2. Resolver snapshots opcionales
    final PatientInfo? clientInfo = _selectedPatient != null
        ? PatientInfo(
            name: _selectedPatient!.name,
            dateOfBirth: _selectedPatient!.dateOfBirth,
            gender: _selectedPatient!.gender,
            phone: _selectedPatient!.phone,
            address: _selectedPatient!.address ?? '',
            cardId: _selectedPatient!.cardId,
            email: _selectedPatient!.email,
          )
        : (casualText.isNotEmpty ? PatientInfo(name: casualText) : null);

    final DoctorInfo? doctorInfo = _selectedDoctor != null
        ? DoctorInfo(
            name: _selectedDoctor!.name,
            specialty: _selectedDoctor!.specialty,
            phone: _selectedDoctor!.phone ?? '',
            cardId: _selectedDoctor!.cardId,
            email: _selectedDoctor!.email,
          )
        : null;

    // 3. Construir lista de QuotedExam congelando tarifas
    final quotedExams = _selectedItems.map((test) {
      final level = _itemPriceLevels[test.id] ?? _defaultPriceLevel;
      final price = (level == 2 && test.salePrice2 > 0) ? test.salePrice2 : test.salePrice;
      return QuotedExam(
        labTestId: test.id,
        name: test.name,
        quotedPrice: price,
        isPack: test.isPack,
        priceLevel: level,
      );
    }).toList();

    final totalAmount = quotedExams.fold<int>(0, (sum, i) => sum + i.quotedPrice);
    final activeBranchId = context.read<AppSessionCubit>().currentBranchId;

    final newQuotation = CreateQuotation(
      clientName: clientName,
      branchId: activeBranchId,
      patientId: _selectedPatient?.id,
      clientInfo: clientInfo,
      doctorId: _selectedDoctor?.id,
      doctorInfo: doctorInfo,
      exams: quotedExams,
      totalAmount: totalAmount,
      status: 'pending',
    );

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

    return PopScope(
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
            setState(() => _isSubmitting = false);
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
            setState(() => _isSubmitting = false);
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

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Columna 1: Catálogo de Pruebas y Packs
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
                      // Columna 2: Carrito de Cotización
                      Expanded(
                        flex: 42,
                        child: QuotationCartSection(
                          selectedPatient: _selectedPatient,
                          clientNameController: _casualClientNameController,
                          selectedDoctor: _selectedDoctor,
                          selectedItems: _selectedItems,
                          itemPriceLevels: _itemPriceLevels,
                          defaultPriceLevel: _defaultPriceLevel,
                          isSubmitting: _isSubmitting,
                          onSelectPatient: _pickPatient,
                          onRemovePatient: () => setState(() {
                            _selectedPatient = null;
                            _casualClientNameController.clear();
                          }),
                          onSelectDoctor: _pickDoctor,
                          onRemoveDoctor: () => setState(() => _selectedDoctor = null),
                          onRemoveItem: _removeItem,
                          onPriceLevelChanged: _changeItemPriceLevel,
                          onDefaultPriceLevelChanged: _changeDefaultPriceLevel,
                          onClearItems: _clearItems,
                          onSubmitQuotation: _submit,
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
                        child: QuotationCartSection(
                          selectedPatient: _selectedPatient,
                          clientNameController: _casualClientNameController,
                          selectedDoctor: _selectedDoctor,
                          selectedItems: _selectedItems,
                          itemPriceLevels: _itemPriceLevels,
                          defaultPriceLevel: _defaultPriceLevel,
                          isSubmitting: _isSubmitting,
                          onSelectPatient: _pickPatient,
                          onRemovePatient: () => setState(() {
                            _selectedPatient = null;
                            _casualClientNameController.clear();
                          }),
                          onSelectDoctor: _pickDoctor,
                          onRemoveDoctor: () => setState(() => _selectedDoctor = null),
                          onRemoveItem: _removeItem,
                          onPriceLevelChanged: _changeItemPriceLevel,
                          onDefaultPriceLevelChanged: _changeDefaultPriceLevel,
                          onClearItems: _clearItems,
                          onSubmitQuotation: _submit,
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
