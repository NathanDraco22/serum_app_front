import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/cash_shift_cubit/read_cash_shifts_cubit.dart';
import '../../../cubits/cash_transaction_cubit/read_cash_transactions_cubit.dart';
import '../widgets/cash_transactions_list.dart';

class CashTransactionsScreen extends StatelessWidget {
  const CashTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReadCashTransactionCubit>(
      create: (context) => ReadCashTransactionCubit(
        cashTransactionsRepository:
            RepositoryProvider.of<CashTransactionsRepository>(context),
      )..getAll(),
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
  String? _selectedShiftId;

  @override
  void initState() {
    super.initState();
    // Cargar o refrescar el listado de turnos para poblar el filtro
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReadCashShiftCubit>().getAll();
      }
    });
  }

  String _formatDateShort(int timestamp) {
    if (timestamp <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionState = context.watch<AppSessionCubit>().state;
    final activeShift = sessionState.activeShift;

    final shiftsState = context.watch<ReadCashShiftCubit>().state;
    List<CashShiftInDb> shifts = [];
    if (shiftsState is ReadCashShiftSuccess) {
      shifts = shiftsState.items;
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
                    'Libro diario de ingresos, egresos y cobros por turno contable',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Filter by Cash Shift
              SizedBox(
                width: 290,
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedShiftId,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por Turno',
                    prefixIcon: Icon(Icons.lock_clock_outlined, size: 20),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos los Turnos'),
                    ),
                    if (activeShift != null)
                      DropdownMenuItem(
                        value: activeShift.id,
                        child: Text(
                          '🟢 Mi Turno Activo (#${activeShift.id.substring(0, activeShift.id.length >= 8 ? 8 : activeShift.id.length)})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ...shifts
                        .where((s) => s.id != activeShift?.id)
                        .map((s) {
                      final shortId = s.id.length >= 8 ? s.id.substring(0, 8) : s.id;
                      final icon = s.isOpen ? '🟢' : '⚪';
                      final dateStr = _formatDateShort(s.openedAt);
                      final userLabel = s.userName?.isNotEmpty == true ? ' • ${s.userName}' : '';
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          '$icon #$shortId ($dateStr$userLabel)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (val) => setState(() => _selectedShiftId = val),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refrescar Transacciones',
                onPressed: () {
                  context.read<ReadCashTransactionCubit>().getAll();
                  context.read<ReadCashShiftCubit>().getAll();
                },
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

                if (_selectedShiftId != null) {
                  items = items
                      .where((element) => element.shiftId == _selectedShiftId)
                      .toList();
                }

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 56,
                          color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedShiftId != null
                              ? 'No hay transacciones registradas para este turno'
                              : 'No hay transacciones registradas',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return CashTransactionsList(
                  items: items,
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
