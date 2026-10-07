import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/app_theme.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/order_cubit/write_orders_cubit.dart';
import '../../cash_shift/widgets/cash_shift_open_dialog.dart';

class OrderPayDialog extends StatefulWidget {
  final OrderInDb order;

  const OrderPayDialog({super.key, required this.order});

  @override
  State<OrderPayDialog> createState() => _OrderPayDialogState();
}

class _OrderPayDialogState extends State<OrderPayDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _paymentMethod = 'cash';

  int get _totalPrice => widget.order.totalPrice > 0
      ? widget.order.totalPrice
      : widget.order.salePriceApplied;

  int get _remainingBalance => max(0, _totalPrice - widget.order.paidAmount);

  @override
  void initState() {
    super.initState();
    _amountController.text =
        NumberFormatter.convertFromCentsToDouble(_remainingBalance)
            .toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final sessionCubit = context.read<AppSessionCubit>();
    final activeShift = sessionCubit.activeShift;
    final currentUser = sessionCubit.user;

    if (activeShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes abrir tu turno con un fondo inicial para registrar cobros.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final parsedDouble = double.tryParse(
            _amountController.text.trim().replaceAll(',', '')) ??
        0.0;
    final amountInCents =
        NumberFormatter.convertFromDoubleToCents(parsedDouble);

    final performedBy = UserInfo(
      id: currentUser?.id ?? 'system',
      name: currentUser?.name ?? currentUser?.username ?? 'Operador',
    );

    final request = OrderPayRequest(
      amount: amountInCents,
      shiftId: activeShift.id,
      paymentMethod: _paymentMethod,
      performedBy: performedBy,
    );

    final writeCubit = context.read<WriteOrderCubit>();
    writeCubit
        .payOrder(widget.order.id, request)
        .then((_) {
      if (!mounted) return;
      if (writeCubit.state is OrderPaid) {
        // Actualizar también el turno activo de la sesión para reflejar el nuevo cobro
        sessionCubit.fetchActiveShift();
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context, true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.watch<AppSessionCubit>();
    final writeState = context.watch<WriteOrderCubit>().state;
    final isWriting = writeState is WritingOrder;
    final activeShift = session.activeShift;
    final currentUser = session.user;
    final canPay = activeShift != null && activeShift.isOpen && !isWriting;

    return PopScope(
      canPop: !isWriting,
      child: AlertDialog(
        title: Row(
        children: [
          Icon(Icons.point_of_sale, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Cobro de Orden: ${widget.order.examName}',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Resumen financiero de la orden
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withAlpha(100),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Precio total:',
                            style: theme.textTheme.bodyMedium),
                        Text(
                          NumberFormatter.convertToMoneyLike(_totalPrice),
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (widget.order.paidAmount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Monto ya pagado:',
                              style: theme.textTheme.bodySmall),
                          Text(
                            NumberFormatter.convertToMoneyLike(
                                widget.order.paidAmount),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Saldo Pendiente:',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          NumberFormatter.convertToMoneyLike(
                              _remainingBalance),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _remainingBalance > 0
                                ? theme.colorScheme.primary
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Información del Turno de Caja del Usuario
              if (activeShift != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                        color: Colors.green.shade800,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Turno Activo: \$${activeShift.totalCashExpectedDouble.toStringAsFixed(2)} en efectivo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.green.shade900,
                              ),
                            ),
                            Text(
                              'Fondo inicial: \$${activeShift.initialBalanceDouble.toStringAsFixed(2)} • Listo para cobrar',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorPalette.errorContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: ColorPalette.error.withAlpha(100)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lock_open_rounded,
                            color: ColorPalette.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sin Turno Abierto',
                              style: TextStyle(
                                color: ColorPalette.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Debes abrir tu turno con un fondo inicial para registrar cobros.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Abrir Turno Ahora'),
                          onPressed: () => CashShiftOpenDialog.show(context),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Operador asignado
              Row(
                children: [
                  Icon(Icons.person,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Cajero / Operador: ${currentUser?.name ?? currentUser?.username ?? 'Sesión activa'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Monto a Cobrar en formato decimal
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Monto a Cobrar *',
                  prefixText: '\$ ',
                  isDense: true,
                  helperText: _remainingBalance > 0
                      ? 'Saldo pendiente: ${NumberFormatter.convertToMoneyLike(_remainingBalance)}'
                      : 'Orden saldada',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Requerido';
                  final parsed =
                      double.tryParse(val.trim().replaceAll(',', ''));
                  if (parsed == null) return 'Ingrese un monto válido';
                  if (parsed <= 0) return 'El monto debe ser mayor a 0';
                  final inCents =
                      NumberFormatter.convertFromDoubleToCents(parsed);
                  if (_remainingBalance > 0 && inCents > _remainingBalance) {
                    return 'El monto no puede exceder el saldo restante (${NumberFormatter.convertToMoneyLike(_remainingBalance)})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Selector de Método de Pago
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Método de Pago *',
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'cash',
                    child: Row(
                      children: [
                        Icon(Icons.money, size: 18),
                        SizedBox(width: 8),
                        Text('Efectivo'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'card',
                    child: Row(
                      children: [
                        Icon(Icons.credit_card, size: 18),
                        SizedBox(width: 8),
                        Text('Tarjeta'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'transfer',
                    child: Row(
                      children: [
                        Icon(Icons.account_balance, size: 18),
                        SizedBox(width: 8),
                        Text('Transferencia'),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) =>
                    setState(() => _paymentMethod = val ?? 'cash'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isWriting
              ? null
              : () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  }
                },
          child: const Text('Cancelar'),
        ),
        BlocBuilder<WriteOrderCubit, WriteOrderState>(
          builder: (context, state) {
            if (state is WritingOrder) {
              return const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            return ElevatedButton.icon(
              onPressed: canPay ? _submit : null,
              icon: const Icon(Icons.check, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              label: const Text('Registrar Pago'),
            );
          },
        ),
      ],
      ),
    );
  }
}
