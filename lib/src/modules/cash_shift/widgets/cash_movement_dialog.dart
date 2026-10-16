import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/cash_movement_cubit/write_cash_movements_cubit.dart';

class CashMovementDialog extends StatefulWidget {
  final CashShiftInDb shift;
  final String? initialType; // 'income' | 'withdrawal'

  const CashMovementDialog({
    super.key,
    required this.shift,
    this.initialType,
  });

  static Future<CashMovementInDb?> show(
    BuildContext context, {
    required CashShiftInDb shift,
    String? initialType,
  }) {
    return showDialog<CashMovementInDb>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CashMovementDialog(
        shift: shift,
        initialType: initialType,
      ),
    );
  }

  @override
  State<CashMovementDialog> createState() => _CashMovementDialogState();
}

class _CashMovementDialogState extends State<CashMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _conceptController = TextEditingController();

  late String _movementType; // 'income' | 'withdrawal'
  String _paymentMethod = 'cash';
  bool _isLoading = false;

  final List<String> _incomeSuggestions = [
    'Fondo adicional',
    'Cambio inicial extra',
    'Aportación a caja',
    'Ajuste positivo',
  ];

  final List<String> _withdrawalSuggestions = [
    'Garrafón de agua',
    'Insumos de limpieza',
    'Artículos de papelería',
    'Pago de mensajería',
    'Café y despensa',
    'Gasto operativo menor',
  ];

  @override
  void initState() {
    super.initState();
    _movementType = widget.initialType ?? 'withdrawal';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _conceptController.dispose();
    super.dispose();
  }

  int get _availableCashCents =>
      widget.shift.initialBalance + widget.shift.cashBalance;

  double get _availableCashDouble =>
      NumberFormatter.convertFromCentsToDouble(_availableCashCents);

  int get _amountCents {
    final doubleVal = double.tryParse(_amountController.text.trim()) ?? 0.0;
    return (doubleVal * 100).round();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final sessionCubit = context.read<AppSessionCubit>();
    final user = sessionCubit.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay sesión de usuario activa')),
      );
      return;
    }

    final cents = _amountCents;
    if (cents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto debe ser mayor a \$0.00')),
      );
      return;
    }

    if (_movementType == 'withdrawal' && _paymentMethod == 'cash') {
      if (cents > _availableCashCents) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No hay suficiente efectivo disponible en el turno para este retiro',
            ),
          ),
        );
        return;
      }
    }

    final request = CreateCashMovement(
      shiftId: widget.shift.id,
      branchId: widget.shift.branchId,
      movementType: _movementType,
      paymentMethod: _paymentMethod,
      amount: cents,
      concept: _conceptController.text.trim(),
      performedBy: UserInfo(id: user.id, name: user.name),
    );

    setState(() => _isLoading = true);

    final writeCubit = context.read<WriteCashMovementCubit>();
    final newMovement = await writeCubit.create(request);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (newMovement != null) {
      // Refrescar el turno activo en la sesión
      await sessionCubit.fetchActiveShift();

      if (!mounted) return;
      Navigator.of(context).pop(newMovement);

      final isInc = _movementType == 'income';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isInc
                ? 'Ingreso de ${newMovement.formattedAmount} registrado correctamente'
                : 'Egreso de ${newMovement.formattedAmount} registrado correctamente',
          ),
          backgroundColor: isInc ? Colors.green.shade700 : Colors.orange.shade800,
        ),
      );
    } else {
      final state = writeCubit.state;
      String errorMsg = 'Error al registrar el movimiento';
      if (state is WriteCashMovementError) {
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
    final isIncome = _movementType == 'income';
    final accentColor = isIncome ? Colors.green.shade700 : Colors.red.shade700;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: accentColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isIncome ? 'Ingreso Libre de Caja' : 'Egreso / Retiro de Caja',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Turno #${widget.shift.id} — Custodio: ${widget.shift.userName ?? "Operador"}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed:
                            _isLoading ? null : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Segmented Switch: Ingreso vs Egreso
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _isLoading
                                ? null
                                : () => setState(() => _movementType = 'withdrawal'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isIncome
                                    ? Colors.red.shade700
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 16,
                                    color: !isIncome
                                        ? Colors.white
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Egreso / Gasto (-)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !isIncome
                                          ? Colors.white
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _isLoading
                                ? null
                                : () => setState(() => _movementType = 'income'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isIncome
                                    ? Colors.green.shade700
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 16,
                                    color: isIncome
                                        ? Colors.white
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Ingreso Extra (+)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isIncome
                                          ? Colors.white
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Caja de Información de Efectivo Disponible
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(120),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Efectivo disponible en cajón de turno:',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '\$${_availableCashDouble.toStringAsFixed(2)} MXN',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Campo de Monto
                  Text(
                    'Monto (\$)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.attach_money),
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    autofocus: true,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Ingresa una cantidad';
                      }
                      final parsed = double.tryParse(val.trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Ingresa un monto válido mayor a 0';
                      }
                      if (_movementType == 'withdrawal' &&
                          _paymentMethod == 'cash') {
                        final cents = (parsed * 100).round();
                        if (cents > _availableCashCents) {
                          return 'Excede el efectivo en caja (\$${_availableCashDouble.toStringAsFixed(2)})';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Método de Pago
                  Text(
                    'Método de Pago',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _paymentMethod,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'cash',
                        child: Text('Efectivo (Cajón Físico)'),
                      ),
                      DropdownMenuItem(
                        value: 'card',
                        child: Text('Tarjeta / Terminal'),
                      ),
                      DropdownMenuItem(
                        value: 'transfer',
                        child: Text('Transferencia Bancaria'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _paymentMethod = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Concepto / Motivo
                  Text(
                    'Concepto / Justificación',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _conceptController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: isIncome
                          ? 'Ej. Fondo adicional para cambio en mostrador'
                          : 'Ej. Compra de 2 garrafones de agua potable',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'El concepto o motivo es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Sugerencias Rápidas de Concepto
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: (isIncome
                            ? _incomeSuggestions
                            : _withdrawalSuggestions)
                        .map(
                          (suggestion) => ActionChip(
                            label: Text(
                              suggestion,
                              style: theme.textTheme.labelSmall,
                            ),
                            onPressed: () {
                              _conceptController.text = suggestion;
                            },
                          ),
                        )
                        .toList(),
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
                          backgroundColor: accentColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                isIncome
                                    ? Icons.add_circle_outline
                                    : Icons.remove_circle_outline,
                                size: 18,
                              ),
                        label: Text(
                          isIncome ? 'Registrar Ingreso' : 'Registrar Egreso',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isLoading ? null : _submit,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
