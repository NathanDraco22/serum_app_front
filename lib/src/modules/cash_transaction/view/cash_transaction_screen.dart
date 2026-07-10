import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/cash_transaction_cubit/read_cash_transactions_cubit.dart';
import '../../../cubits/cash_register_cubit/read_cash_registers_cubit.dart';
import '../widgets/cash_transactions_list.dart';

class CashTransactionsScreen extends StatelessWidget {
  const CashTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReadCashTransactionCubit>(
          create: (context) => ReadCashTransactionCubit(
            cashTransactionsRepository: RepositoryProvider.of<CashTransactionsRepository>(context),
          )..getAll(),
        ),
        BlocProvider<ReadCashRegisterCubit>(
          create: (context) => ReadCashRegisterCubit(
            cashRegistersRepository: RepositoryProvider.of<CashRegistersRepository>(context),
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
  String? _selectedRegisterId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final registersState = context.watch<ReadCashRegisterCubit>().state;
    List<CashRegisterInDb> registers = [];
    if (registersState is ReadCashRegisterSuccess) {
      registers = registersState.items;
    }

    return Column(
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
                    'Transacciones de Caja',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Historial detallado de entradas y salidas de efectivo',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Filter by Cash Register
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedRegisterId,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por Caja',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas las Cajas')),
                    ...registers.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))),
                  ],
                  onChanged: (val) => setState(() => _selectedRegisterId = val),
                ),
              ),
            ],
          ),
        ),
        // Transactions List
        Expanded(
          child: BlocBuilder<ReadCashTransactionCubit, ReadCashTransactionState>(
            builder: (context, readState) {
              if (readState is ReadCashTransactionLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (readState is ReadCashTransactionSuccess) {
                var items = readState.items;

                if (_selectedRegisterId != null) {
                  items = items.where((element) => element.registerId == _selectedRegisterId).toList();
                }

                if (items.isEmpty) {
                  return const Center(child: Text('No hay transacciones registradas'));
                }

                return CashTransactionsList(
                  items: items,
                  registers: registers,
                );
              } else if (readState is ReadCashTransactionError) {
                return Center(
                  child: Text(
                    'Error al cargar transacciones: ${readState.message}',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                );
              }
              return const Center(child: Text('Cargando transacciones...'));
            },
          ),
        ),
      ],
    );
  }
}
