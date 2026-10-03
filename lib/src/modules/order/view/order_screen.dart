import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/app_router.dart';
import '../../../cubits/order_cubit/read_orders_cubit.dart';
import '../../../cubits/order_cubit/write_orders_cubit.dart';
import '../../../cubits/patient_cubit/read_patients_cubit.dart';
import '../../../cubits/doctor_cubit/read_doctors_cubit.dart';
import '../../../cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import '../widgets/orders_list.dart';
import '../widgets/order_results_dialog.dart';
import '../widgets/order_pay_dialog.dart';
import '../../../widgets/dialogs/viewers/clinical_order_viewer.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReadOrderCubit>(
          create: (context) => ReadOrderCubit(
            ordersRepository: RepositoryProvider.of<OrdersRepository>(context),
          )..getAll(),
        ),
        BlocProvider<WriteOrderCubit>(
          create: (context) => WriteOrderCubit(
            ordersRepository: RepositoryProvider.of<OrdersRepository>(context),
          ),
        ),
        BlocProvider<ReadPatientCubit>(
          create: (context) => ReadPatientCubit(
            patientsRepository: RepositoryProvider.of<PatientsRepository>(context),
          )..getAll(),
        ),
        BlocProvider<ReadDoctorCubit>(
          create: (context) => ReadDoctorCubit(
            doctorsRepository: RepositoryProvider.of<DoctorsRepository>(context),
          )..getAll(),
        ),
        BlocProvider<ReadLabTestCubit>(
          create: (context) => ReadLabTestCubit(
            labTestsRepository: RepositoryProvider.of<LabTestsRepository>(context),
          )..getAll(),
        ),
      ],
      child: const _RootScaffold(),
    );
  }
}

class _RootScaffold extends StatelessWidget {
  const _RootScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _Body(),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'all'; // 'all', 'pending', 'paid', 'completed'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openOrderForm(BuildContext context) {
    context.push<bool>(AppRouter.createOrder).then((value) {
      if (value == true && context.mounted) {
        context.read<ReadOrderCubit>().getAll();
      }
    });
  }

  void _openResultsForm(BuildContext context, OrderInDb order) {
    if (order.status == 'completed') {
      showClinicalOrderViewerDialog(context, order);
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<WriteOrderCubit>(context),
          child: OrderResultsDialog(order: order),
        );
      },
    ).then((value) {
      if (value == true && context.mounted) {
        context.read<ReadOrderCubit>().getAll();
      }
    });
  }

  void _openPayDialog(BuildContext context, OrderInDb order) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<WriteOrderCubit>(context),
          child: OrderPayDialog(order: order),
        );
      },
    ).then((value) {
      if (value == true && context.mounted) {
        context.read<ReadOrderCubit>().getAll();
      }
    });
  }

  List<OrderInDb> _applyFilters(List<OrderInDb> baseList, Map<String, String> patientNames) {
    final query = _searchController.text.trim().toLowerCase();

    return baseList.where((order) {
      // 1. Filtro por Estado
      final totalPrice = order.totalPrice > 0 ? order.totalPrice : order.salePriceApplied;
      final isFullyPaid = order.status == 'paid' ||
          order.status == 'completed' ||
          (totalPrice > 0 && order.paidAmount >= totalPrice);
      final hasAllResults = order.results.isNotEmpty &&
          order.results.every((r) => r.resultValue != null && r.resultValue!.trim().isNotEmpty);

      if (_filterStatus == 'pending') {
        // Aún pendiente de pago o en proceso sin completarse
        if (order.status == 'completed' || (isFullyPaid && hasAllResults)) {
          return false;
        }
        if (order.status == 'paid' && !hasAllResults) {
          return false; // está en 'paid' adelantada
        }
      } else if (_filterStatus == 'paid') {
        // Pagada por adelantado pero pendiente de resultados completos
        if (order.status != 'paid' && !(isFullyPaid && !hasAllResults)) {
          return false;
        }
      } else if (_filterStatus == 'completed') {
        // Completada: 100% pagada y con resultados listos
        if (order.status != 'completed' && !(isFullyPaid && hasAllResults)) {
          return false;
        }
      }

      // 2. Filtro por Búsqueda de Texto
      if (query.isNotEmpty) {
        final patientName = (patientNames[order.patientId] ?? '').toLowerCase();
        final examName = order.examName.toLowerCase();
        final orderId = order.id.toLowerCase();

        final matchesPatient = patientName.contains(query);
        final matchesExam = examName.contains(query);
        final matchesId = orderId.contains(query);

        if (!matchesPatient && !matchesExam && !matchesId) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mapeo de nombres de pacientes
    final patientsState = context.watch<ReadPatientCubit>().state;
    final Map<String, String> patientNames = {};
    if (patientsState is ReadPatientSuccess) {
      for (final p in patientsState.items) {
        patientNames[p.id] = p.name;
      }
    }

    return BlocListener<WriteOrderCubit, WriteOrderState>(
      listener: (context, state) {
        if (state is OrderCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Orden creada con éxito')),
          );
        } else if (state is OrderUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Orden actualizada con éxito')),
          );
        } else if (state is OrderDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Orden eliminada con éxito')),
          );
        } else if (state is OrderPaid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pago registrado con éxito')),
          );
        } else if (state is WriteOrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}'), backgroundColor: theme.colorScheme.error),
          );
        }
      },
      child: BlocBuilder<ReadOrderCubit, ReadOrderState>(
        builder: (context, readState) {
          final allOrders = (readState is ReadOrderSuccess)
              ? readState.items
              : (readState is ReadOrderRefreshing)
                  ? readState.items
                  : <OrderInDb>[];

          final totalCount = allOrders.length;
          final completedCount = allOrders.where((o) {
            final total = o.totalPrice > 0 ? o.totalPrice : o.salePriceApplied;
            final isFullyPaid = o.status == 'paid' ||
                o.status == 'completed' ||
                (total > 0 && o.paidAmount >= total);
            final hasResults = o.results.isNotEmpty &&
                o.results.every((r) => r.resultValue != null && r.resultValue!.trim().isNotEmpty);
            return o.status == 'completed' || (isFullyPaid && hasResults);
          }).length;

          final paidCount = allOrders.where((o) {
            final total = o.totalPrice > 0 ? o.totalPrice : o.salePriceApplied;
            final isFullyPaid = o.status == 'paid' ||
                o.status == 'completed' ||
                (total > 0 && o.paidAmount >= total);
            final hasResults = o.results.isNotEmpty &&
                o.results.every((r) => r.resultValue != null && r.resultValue!.trim().isNotEmpty);
            return (o.status == 'paid' || isFullyPaid) && !hasResults && o.status != 'completed';
          }).length;

          final pendingCount = totalCount - completedCount - paidCount;

          final filteredOrders = _applyFilters(allOrders, patientNames);

          return Column(
            children: [
              // Header Bar con KPIs y Acciones Principales
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Órdenes Clínicas',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Registro, seguimiento de análisis médicos y control de pagos',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // KPIs rápidos
                        _KpiBadge(
                          label: 'Total',
                          count: totalCount,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        _KpiBadge(
                          label: 'Pendientes',
                          count: pendingCount,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        _KpiBadge(
                          label: 'Pagadas',
                          count: paidCount,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        _KpiBadge(
                          label: 'Completadas',
                          count: completedCount,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openOrderForm(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Nueva Orden'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Barra de Filtros: Buscador + Dropdown de Estado + Chips rápidos
                    Row(
                      children: [
                        // Search Input
                        SizedBox(
                          width: 340,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Buscar por paciente, examen o folio...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Filtro de Estado (Dropdown)
                        SizedBox(
                          width: 250,
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(_filterStatus),
                            initialValue: _filterStatus,
                            isDense: true,
                            decoration: InputDecoration(
                              labelText: 'Estado de la orden',
                              prefixIcon: const Icon(Icons.filter_list, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('Todas las órdenes')),
                              DropdownMenuItem(value: 'pending', child: Text('Pendientes de pago/proceso')),
                              DropdownMenuItem(value: 'paid', child: Text('Pagadas (por adelantado)')),
                              DropdownMenuItem(value: 'completed', child: Text('Completadas (con resultados)')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _filterStatus = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Chips de Estado Rápido
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _StatusFilterChip(
                            label: 'Todas',
                            isSelected: _filterStatus == 'all',
                            onSelected: () => setState(() => _filterStatus = 'all'),
                          ),
                          const SizedBox(width: 6),
                          _StatusFilterChip(
                            label: 'Pendientes ($pendingCount)',
                            isSelected: _filterStatus == 'pending',
                            onSelected: () => setState(() => _filterStatus = 'pending'),
                          ),
                          const SizedBox(width: 6),
                          _StatusFilterChip(
                            label: 'Pagadas ($paidCount)',
                            isSelected: _filterStatus == 'paid',
                            onSelected: () => setState(() => _filterStatus = 'paid'),
                          ),
                          const SizedBox(width: 6),
                          _StatusFilterChip(
                            label: 'Completadas ($completedCount)',
                            isSelected: _filterStatus == 'completed',
                            onSelected: () => setState(() => _filterStatus = 'completed'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Orders List
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (readState is ReadOrderLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (readState is ReadOrderError) {
                      return Center(
                        child: Text(
                          'Error al cargar órdenes: ${readState.message}',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      );
                    }

                    if (filteredOrders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              allOrders.isEmpty
                                  ? 'No hay órdenes registradas'
                                  : 'No se encontraron órdenes con los filtros seleccionados',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      );
                    }

                    return OrdersList(
                      orders: filteredOrders,
                      onEditResults: (order) => _openResultsForm(context, order),
                      onPayOrder: (order) => _openPayDialog(context, order),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KpiBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _KpiBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
          Text(
            '$count',
            style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _StatusFilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
    );
  }
}
