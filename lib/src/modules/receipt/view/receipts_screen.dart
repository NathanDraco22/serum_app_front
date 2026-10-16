import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/app_theme.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/cash_shift_cubit/read_cash_shifts_cubit.dart';
import '../../../cubits/receipt_cubit/read_receipts_cubit.dart';
import '../widgets/receipts_list.dart';

class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReadReceiptCubit>(
      create: (context) => ReadReceiptCubit(
        receiptsRepository:
            RepositoryProvider.of<ReceiptsRepository>(context),
      )..getAll(),
      child: const _ReceiptsScreenContent(),
    );
  }
}

class _ReceiptsScreenContent extends StatefulWidget {
  const _ReceiptsScreenContent();

  @override
  State<_ReceiptsScreenContent> createState() => _ReceiptsScreenContentState();
}

class _ReceiptsScreenContentState extends State<_ReceiptsScreenContent> {
  final _searchController = TextEditingController();
  String _selectedMethod = 'all';
  String? _selectedShiftId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReadCashShiftCubit>().getAll();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReceiptInDb> _filterReceipts(List<ReceiptInDb> all) {
    final query = _searchController.text.trim().toLowerCase();
    return all.where((r) {
      if (_selectedMethod != 'all' &&
          r.paymentMethod.toLowerCase() != _selectedMethod) {
        return false;
      }
      if (_selectedShiftId != null && r.shiftId != _selectedShiftId) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchNumber = r.receiptNumber.toLowerCase().contains(query);
        final matchOrder = r.orderId.toLowerCase().contains(query);
        final matchPatient = (r.patientName ?? '').toLowerCase().contains(query);
        final matchCashier = r.performedBy.name.toLowerCase().contains(query);
        final matchConcept = r.concept.toLowerCase().contains(query);
        if (!matchNumber &&
            !matchOrder &&
            !matchPatient &&
            !matchCashier &&
            !matchConcept) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionState = context.watch<AppSessionCubit>().state;
    final shiftsState = context.watch<ReadCashShiftCubit>().state;

    List<CashShiftInDb> shifts = [];
    if (shiftsState is ReadCashShiftSuccess) {
      shifts = shiftsState.items;
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
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
                      'Recibos de Caja',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Historial de recibos emitidos por cobros y abonos en sucursal',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () => context.read<ReadReceiptCubit>().getAll(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Actualizar'),
                ),
              ],
            ),
          ),

          // KPIs y Filtros
          BlocBuilder<ReadReceiptCubit, ReadReceiptState>(
            builder: (context, state) {
              List<ReceiptInDb> allItems = [];
              if (state is ReadReceiptSuccess) {
                allItems = state.items;
              }
              final filtered = _filterReceipts(allItems);

              final totalCents =
                  filtered.fold<int>(0, (sum, r) => sum + r.amount);
              final cashCents = filtered
                  .where((r) => r.paymentMethod == 'cash')
                  .fold<int>(0, (sum, r) => sum + r.amount);
              final cardCents = filtered
                  .where((r) => r.paymentMethod == 'card')
                  .fold<int>(0, (sum, r) => sum + r.amount);
              final transferCents = filtered
                  .where((r) => r.paymentMethod == 'transfer')
                  .fold<int>(0, (sum, r) => sum + r.amount);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest.withAlpha(120),
                  border: Border(
                    bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                child: Column(
                  children: [
                    // Resumen Métrico
                    Row(
                      children: [
                        _buildKpiCard(
                          context,
                          title: 'Total Recaudado',
                          value: NumberFormatter.convertToMoneyLike(totalCents),
                          subtitle: '${filtered.length} recibo(s)',
                          icon: Icons.payments,
                          color: ColorPalette.primary,
                        ),
                        const SizedBox(width: 12),
                        _buildKpiCard(
                          context,
                          title: 'Efectivo',
                          value: NumberFormatter.convertToMoneyLike(cashCents),
                          subtitle: 'Caja física',
                          icon: Icons.money,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 12),
                        _buildKpiCard(
                          context,
                          title: 'Tarjeta',
                          value: NumberFormatter.convertToMoneyLike(cardCents),
                          subtitle: 'Terminales',
                          icon: Icons.credit_card,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _buildKpiCard(
                          context,
                          title: 'Transferencia',
                          value: NumberFormatter.convertToMoneyLike(transferCents),
                          subtitle: 'Banco / ACH',
                          icon: Icons.account_balance,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Barra de Filtros
                    Row(
                      children: [
                        // Campo de búsqueda
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText:
                                  'Buscar por folio (#REC), orden (#ORD), paciente o cajero...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () => _searchController.clear(),
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Filtro por método de pago
                        SizedBox(
                          width: 180,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedMethod,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Método de Pago',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text(
                                  'Todos los métodos',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'cash',
                                child: Text('Efectivo'),
                              ),
                              DropdownMenuItem(
                                value: 'card',
                                child: Text('Tarjeta'),
                              ),
                              DropdownMenuItem(
                                value: 'transfer',
                                child: Text('Transferencia'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedMethod = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Filtro por Turno
                        SizedBox(
                          width: 230,
                          child: DropdownButtonFormField<String?>(
                            initialValue: _selectedShiftId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Turno de Caja',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'Todos los turnos',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              if (sessionState.activeShift != null)
                                DropdownMenuItem<String?>(
                                  value: sessionState.activeShift!.id,
                                  child: Text(
                                    'Mi turno actual (#${sessionState.activeShift!.id})',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ...shifts
                                  .where((s) =>
                                      s.id != sessionState.activeShift?.id)
                                  .map(
                                    (s) => DropdownMenuItem<String?>(
                                      value: s.id,
                                      child: Text(
                                        'Turno #${s.id} (${s.userName ?? s.userId})',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedShiftId = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Contenido Principal
          Expanded(
            child: BlocBuilder<ReadReceiptCubit, ReadReceiptState>(
              builder: (context, state) {
                if (state is ReadReceiptLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ReadReceiptError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: ColorPalette.error),
                        const SizedBox(height: 12),
                        Text(
                          'Error al cargar recibos',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.message,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () =>
                              context.read<ReadReceiptCubit>().getAll(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ReadReceiptSuccess) {
                  final filtered = _filterReceipts(state.items);
                  return ReceiptsList(receipts: filtered);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
