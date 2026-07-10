import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/order_cubit/read_orders_cubit.dart';
import '../../../cubits/order_cubit/write_orders_cubit.dart';
import '../../../cubits/patient_cubit/read_patients_cubit.dart';
import '../../../cubits/exam_cubit/read_exams_cubit.dart';
import '../widgets/orders_list.dart';
import '../widgets/order_form_dialog.dart';
import '../widgets/order_results_dialog.dart';

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
        BlocProvider<ReadExamCubit>(
          create: (context) => ReadExamCubit(
            examsRepository: RepositoryProvider.of<ExamsRepository>(context),
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
  void _openOrderForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: BlocProvider.of<WriteOrderCubit>(context)),
            BlocProvider.value(value: BlocProvider.of<ReadPatientCubit>(context)),
            BlocProvider.value(value: BlocProvider.of<ReadExamCubit>(context)),
          ],
          child: const OrderFormDialog(),
        );
      },
    ).then((value) {
      if (value == true && context.mounted) {
        context.read<ReadOrderCubit>().getAll();
      }
    });
  }

  void _openResultsForm(BuildContext context, OrderInDb order) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        } else if (state is WriteOrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}'), backgroundColor: theme.colorScheme.error),
          );
        }
      },
      child: Column(
        children: [
          // Header Bar
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
            child: Row(
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
                      'Registro y seguimiento de órdenes y resultados',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _openOrderForm(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nueva Orden'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Orders List
          Expanded(
            child: BlocBuilder<ReadOrderCubit, ReadOrderState>(
              builder: (context, readState) {
                if (readState is ReadOrderLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (readState is ReadOrderSuccess) {
                  final orders = readState.items;
                  if (orders.isEmpty) {
                    return const Center(child: Text('No hay órdenes registradas'));
                  }
                  return OrdersList(
                    orders: orders,
                    onEditResults: (order) => _openResultsForm(context, order),
                  );
                } else if (readState is ReadOrderError) {
                  return Center(
                    child: Text(
                      'Error al cargar órdenes: ${readState.message}',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  );
                }
                return const Center(child: Text('Cargando órdenes...'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
