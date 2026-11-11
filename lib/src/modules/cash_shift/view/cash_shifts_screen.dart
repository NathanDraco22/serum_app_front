import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/cash_shift_cubit/read_cash_shifts_cubit.dart';
import '../widgets/cash_shift_card.dart';
import '../widgets/cash_shift_open_dialog.dart';

class CashShiftsScreen extends StatelessWidget {
  const CashShiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RootScaffold();
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

enum _ShiftFilter { all, open, closed }

class _BodyState extends State<_Body> {
  _ShiftFilter _filter = _ShiftFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadShifts();
      }
    });
  }

  void _loadShifts() {
    final bId = context.read<AppSessionCubit>().currentBranchId;
    context.read<ReadCashShiftCubit>().getAll(branchId: bId);
    context.read<AppSessionCubit>().fetchActiveShift();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionState = context.watch<AppSessionCubit>().state;
    final user = sessionState.currentUser;
    final activeShift = sessionState.activeShift;
    final isShiftInCurrentBranch = sessionState.isShiftInCurrentBranch;
    final hasShiftBranchMismatch = sessionState.hasShiftBranchMismatch;

    final shiftsState = context.watch<ReadCashShiftCubit>().state;
    List<CashShiftInDb> shifts = [];
    if (shiftsState is ReadCashShiftSuccess) {
      shifts = shiftsState.items;
    }

    final openCount = shifts.where((s) => s.isOpen).length;
    final closedCount = shifts.where((s) => !s.isOpen).length;

    List<CashShiftInDb> filteredShifts = shifts;
    if (_filter == _ShiftFilter.open) {
      filteredShifts = shifts.where((s) => s.isOpen).toList();
    } else if (_filter == _ShiftFilter.closed) {
      filteredShifts = shifts.where((s) => !s.isOpen).toList();
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Turnos de Caja',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Historial de turnos de trabajo, cobros en tiempo real y arqueos contables',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (activeShift == null) ...[
                const SizedBox(width: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.lock_open_rounded, size: 18),
                  label: const Text('Abrir Mi Turno'),
                  onPressed: () async {
                    final res = await CashShiftOpenDialog.show(context);
                    if (res != null) {
                      _loadShifts();
                    }
                  },
                ),
              ],
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refrescar Turnos',
                onPressed: _loadShifts,
              ),
            ],
          ),
        ),

        // Banner informativo cuando el turno activo pertenece a otra sucursal
        if (hasShiftBranchMismatch && activeShift != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade400),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber.shade900,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Turno activo en otra sucursal',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tienes el turno abierto #${activeShift.id} en "${activeShift.branchName ?? 'otra sucursal'}". No puedes registrar cobros, movimientos de caja ni abrir otro turno mientras navegues en "${sessionState.currentBranch?.name ?? 'esta sucursal'}".',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber.shade200,
                    foregroundColor: Colors.amber.shade900,
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: Text('Cambiar a ${activeShift.branchName ?? 'Sucursal del Turno'}'),
                  onPressed: () {
                    context.read<AppSessionCubit>().changeBranch(activeShift.branchId);
                  },
                ),
              ],
            ),
          ),

        // Filter chips bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withAlpha(80),
              ),
            ),
          ),
          child: Row(
            children: [
              SegmentedButton<_ShiftFilter>(
                segments: [
                  ButtonSegment(
                    value: _ShiftFilter.all,
                    label: Text('Todos (${shifts.length})'),
                    icon: const Icon(Icons.list, size: 16),
                  ),
                  ButtonSegment(
                    value: _ShiftFilter.open,
                    label: Text('Abiertos ($openCount)'),
                    icon: const Icon(Icons.lock_open, size: 16),
                  ),
                  ButtonSegment(
                    value: _ShiftFilter.closed,
                    label: Text('Cerrados ($closedCount)'),
                    icon: const Icon(Icons.lock, size: 16),
                  ),
                ],
                selected: {_filter},
                onSelectionChanged: (val) {
                  setState(() => _filter = val.first);
                },
              ),
              const Spacer(),
              if (activeShift != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isShiftInCurrentBranch
                        ? theme.colorScheme.primaryContainer.withAlpha(70)
                        : Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isShiftInCurrentBranch
                          ? theme.colorScheme.primary.withAlpha(120)
                          : Colors.amber.shade400,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isShiftInCurrentBranch ? Icons.check_circle : Icons.warning_amber_rounded,
                        size: 14,
                        color: isShiftInCurrentBranch
                            ? theme.colorScheme.primary
                            : Colors.amber.shade900,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isShiftInCurrentBranch
                            ? 'Tienes un turno activo: ${NumberFormatter.currencyFormat.format(activeShift.totalCashExpectedDouble)} en efectivo'
                            : 'Turno en "${activeShift.branchName ?? 'otra sucursal'}": ${NumberFormatter.currencyFormat.format(activeShift.totalCashExpectedDouble)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isShiftInCurrentBranch
                              ? theme.colorScheme.primary
                              : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Shifts List
        Expanded(
          child: BlocBuilder<ReadCashShiftCubit, ReadCashShiftState>(
            builder: (context, state) {
              if (state is ReadCashShiftLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ReadCashShiftError) {
                return Center(
                  child: Text(
                    'Error al cargar turnos: ${state.message}',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                );
              }

              if (filteredShifts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_clock_outlined,
                        size: 56,
                        color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _filter == _ShiftFilter.all
                            ? 'No hay turnos registrados'
                            : (_filter == _ShiftFilter.open
                                  ? 'No hay turnos abiertos actualmente'
                                  : 'No hay turnos cerrados'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: filteredShifts.length,
                itemBuilder: (context, index) {
                  final shift = filteredShifts[index];
                  final isCurrentUser = shift.userId == user?.id || shift.id == activeShift?.id;

                  return CashShiftCard(
                    shift: shift,
                    isCurrentUser: isCurrentUser,
                    onShiftUpdated: _loadShifts,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
