import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/cash_register_cubit/read_cash_registers_cubit.dart';
import '../../../cubits/cash_register_cubit/write_cash_registers_cubit.dart';
import '../widgets/cash_register_card.dart';
import '../widgets/cash_register_form_dialog.dart';

class CashRegistersScreen extends StatelessWidget {
  const CashRegistersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReadCashRegisterCubit>(
          create: (context) => ReadCashRegisterCubit(
            cashRegistersRepository: RepositoryProvider.of<CashRegistersRepository>(context),
          )..getAll(),
        ),
        BlocProvider<WriteCashRegisterCubit>(
          create: (context) => WriteCashRegisterCubit(
            cashRegistersRepository: RepositoryProvider.of<CashRegistersRepository>(context),
          ),
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
  void _openCashRegisterForm(BuildContext context, [CashRegisterInDb? register]) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<WriteCashRegisterCubit>(context),
          child: CashRegisterFormDialog(register: register),
        );
      },
    ).then((value) {
      if (value == true && context.mounted) {
        context.read<ReadCashRegisterCubit>().getAll();
      }
    });
  }

  void _toggleRegisterOpen(BuildContext context, CashRegisterInDb register) {
    final cubit = context.read<WriteCashRegisterCubit>();
    final update = UpdateCashRegister(
      isOpen: !register.isOpen,
    );
    cubit.update(register.id, update).then((_) {
      if (context.mounted) context.read<ReadCashRegisterCubit>().getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<WriteCashRegisterCubit, WriteCashRegisterState>(
      listener: (context, state) {
        if (state is CashRegisterCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Caja registradora creada con éxito')),
          );
        } else if (state is CashRegisterUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Estado de caja actualizado con éxito')),
          );
        } else if (state is CashRegisterDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Caja registradora eliminada con éxito')),
          );
        } else if (state is WriteCashRegisterError) {
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
                      'Cajas Registradoras',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Control de turnos, arqueos y balances de caja por sucursal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _openCashRegisterForm(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nueva Caja'),
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
          // Cash Registers List
          Expanded(
            child: BlocBuilder<ReadCashRegisterCubit, ReadCashRegisterState>(
              builder: (context, readState) {
                if (readState is ReadCashRegisterLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (readState is ReadCashRegisterSuccess) {
                  final registers = readState.items;
                  if (registers.isEmpty) {
                    return const Center(child: Text('No hay cajas registradoras configuradas'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: registers.length,
                    itemBuilder: (context, index) {
                      final reg = registers[index];
                      return CashRegisterCard(
                        register: reg,
                        onToggleOpen: () => _toggleRegisterOpen(context, reg),
                        onEdit: () => _openCashRegisterForm(context, reg),
                        onDelete: () {
                          showDialog(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              title: const Text('Eliminar Caja'),
                              content: Text('¿Está seguro de eliminar la caja ${reg.name}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.read<WriteCashRegisterCubit>().delete(reg.id).then((_) {
                                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                                      if (context.mounted) context.read<ReadCashRegisterCubit>().getAll();
                                    });
                                  },
                                  child: Text(
                                    'Eliminar',
                                    style: TextStyle(color: theme.colorScheme.error),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                } else if (readState is ReadCashRegisterError) {
                  return Center(
                    child: Text(
                      'Error al cargar cajas registradoras: ${readState.message}',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  );
                }
                return const Center(child: Text('Cargando cajas...'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
