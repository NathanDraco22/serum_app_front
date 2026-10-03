import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/app_theme.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/cash_shift_cubit/write_cash_shifts_cubit.dart';

class CashShiftCloseDialog extends StatefulWidget {
  final CashShiftInDb shift;

  const CashShiftCloseDialog({super.key, required this.shift});

  static Future<CashShiftInDb?> show(
    BuildContext context,
    CashShiftInDb shift,
  ) {
    return showDialog<CashShiftInDb>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CashShiftCloseDialog(shift: shift),
    );
  }

  @override
  State<CashShiftCloseDialog> createState() => _CashShiftCloseDialogState();
}

class _CashShiftCloseDialogState extends State<CashShiftCloseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _declaredCashController = TextEditingController();
  final _notesController = TextEditingController();

  double _declaredAmount = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _declaredCashController.addListener(_onDeclaredCashChanged);
  }

  void _onDeclaredCashChanged() {
    final parsed = double.tryParse(_declaredCashController.text.trim()) ?? 0.0;
    setState(() => _declaredAmount = parsed);
  }

  @override
  void dispose() {
    _declaredCashController.removeListener(_onDeclaredCashChanged);
    _declaredCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _expectedCashCents =>
      widget.shift.initialBalance + widget.shift.cashBalance;
  double get _expectedCashDouble => _expectedCashCents / 100.0;

  int get _declaredCents => (_declaredAmount * 100).round();
  int get _diffCents => _declaredCents - _expectedCashCents;
  double get _diffDouble => _diffCents / 100.0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final sessionCubit = context.read<AppSessionCubit>();
    final writeCubit = context.read<WriteCashShiftCubit>();

    final request = CloseCashShift(
      declaredCash: _declaredCents,
      notes: _notesController.text.trim(),
    );

    setState(() => _isLoading = true);

    final closedShift = await writeCubit.closeShift(
      widget.shift.id,
      request,
      userId: sessionCubit.user?.id,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (closedShift != null) {
      sessionCubit.clearActiveShift();
      Navigator.of(context).pop(closedShift);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Turno cerrado exitosamente. Diferencia final: \$${_diffDouble.toStringAsFixed(2)}',
          ),
          backgroundColor: _diffCents == 0
              ? Colors.green.shade700
              : (_diffCents < 0 ? ColorPalette.error : ColorPalette.primary),
        ),
      );
    } else {
      final state = writeCubit.state;
      String errorMsg = 'Error al cerrar el turno';
      if (state is WriteCashShiftError) {
        errorMsg = state.message;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shift = widget.shift;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withAlpha(80),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.lock_clock_rounded,
                        color: theme.colorScheme.error,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Corte y Arqueo de Turno',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Conteo físico de efectivo y cierre contable del turno',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Financial Breakdown Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withAlpha(120),
                    ),
                  ),
                  child: Column(
                    children: [
                      _BalanceRow(
                        label: 'Fondo Inicial',
                        amount: '\$${shift.initialBalanceDouble.toStringAsFixed(2)}',
                        icon: Icons.savings_outlined,
                      ),
                      const Divider(height: 14),
                      _BalanceRow(
                        label: 'Efectivo Cobrado en Turno',
                        amount: '\$${shift.cashBalanceDouble.toStringAsFixed(2)}',
                        icon: Icons.payments_outlined,
                      ),
                      const Divider(height: 14),
                      _BalanceRow(
                        label: 'Total Efectivo Esperado en Caja',
                        amount: '\$${_expectedCashDouble.toStringAsFixed(2)}',
                        icon: Icons.account_balance_wallet_rounded,
                        isHighlight: true,
                        highlightColor: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      // Non-cash info
                      Row(
                        children: [
                          Expanded(
                            child: _SmallStat(
                              label: 'Tarjetas',
                              value: '\$${shift.cardBalanceDouble.toStringAsFixed(2)}',
                              icon: Icons.credit_card,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SmallStat(
                              label: 'Transferencias',
                              value: '\$${shift.transferBalanceDouble.toStringAsFixed(2)}',
                              icon: Icons.swap_horiz,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Physical Count Input
                TextFormField(
                  controller: _declaredCashController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Efectivo Contado Físicamente *',
                    hintText: '0.00',
                    prefixIcon: const Icon(Icons.calculate_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    helperText:
                        'Ingresa la cantidad exacta de efectivo en tu gaveta/caja',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa el monto contado';
                    }
                    final num = double.tryParse(value.trim());
                    if (num == null || num < 0) {
                      return 'Ingresa un monto válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Live Difference Indicator
                _DifferenceBanner(
                  diffDouble: _diffDouble,
                  diffCents: _diffCents,
                ),
                const SizedBox(height: 16),

                // Observations
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notas / Observaciones del Corte',
                    hintText: 'Ej. Razón de faltante/sobrante, entregado a gerencia...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.lock_rounded, size: 18),
                      label: Text(_isLoading
                          ? 'Cerrando Turno...'
                          : 'Cerrar y Sellar Turno'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final bool isHighlight;
  final Color? highlightColor;

  const _BalanceRow({
    required this.label,
    required this.amount,
    required this.icon,
    this.isHighlight = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isHighlight
              ? (highlightColor ?? theme.colorScheme.primary)
              : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          amount,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            fontSize: isHighlight ? 16 : 14,
            color: isHighlight
                ? (highlightColor ?? theme.colorScheme.primary)
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SmallStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifferenceBanner extends StatelessWidget {
  final double diffDouble;
  final int diffCents;

  const _DifferenceBanner({
    required this.diffDouble,
    required this.diffCents,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bg;
    Color fg;
    IconData icon;
    String title;
    String subtitle;

    if (diffCents == 0) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
      icon = Icons.check_circle_rounded;
      title = 'Corte Cuadrado Exacto (\$0.00)';
      subtitle = 'El efectivo contado coincide exactamente con el sistema.';
    } else if (diffCents < 0) {
      bg = ColorPalette.errorContainer.withAlpha(80);
      fg = ColorPalette.error;
      icon = Icons.warning_rounded;
      title = 'Faltante de -\$${(-diffDouble).toStringAsFixed(2)}';
      subtitle = 'Hay menos efectivo en la gaveta del esperado.';
    } else {
      bg = ColorPalette.primaryContainer.withAlpha(50);
      fg = ColorPalette.primary;
      icon = Icons.info_rounded;
      title = 'Sobrante de +\$${diffDouble.toStringAsFixed(2)}';
      subtitle = 'Hay más efectivo en la gaveta del registrado.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withAlpha(120)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
