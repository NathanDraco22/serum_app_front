import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/cash_register_cubit/write_cash_registers_cubit.dart';

class CashRegisterCloseDialog extends StatefulWidget {
  final CashRegisterInDb register;

  const CashRegisterCloseDialog({super.key, required this.register});

  @override
  State<CashRegisterCloseDialog> createState() => _CashRegisterCloseDialogState();
}

class _CashRegisterCloseDialogState extends State<CashRegisterCloseDialog> {
  final _userNameController = TextEditingController();

  @override
  void dispose() {
    _userNameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_userNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese el nombre del operador')),
      );
      return;
    }

    final request = CloseCashRegisterRequest(
      performedBy: UserInfo(id: 'system', name: _userNameController.text),
    );

    context.read<WriteCashRegisterCubit>().closeCashRegister(widget.register.id, request).then((_) {
      if (!mounted) return;
      Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Cerrar Caja: ${widget.register.name}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Está por cerrar la caja registradora. Todos los saldos se ajustarán a cero y se generará una transacción de cierre.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _BalanceRow(title: 'Efectivo', amount: widget.register.cashBalance, theme: theme),
            _BalanceRow(title: 'Tarjeta', amount: widget.register.cardBalance, theme: theme),
            _BalanceRow(title: 'Transferencia', amount: widget.register.transferBalance, theme: theme),
            const Divider(),
            _BalanceRow(title: 'Total General', amount: widget.register.totalBalance, theme: theme, isTotal: true),
            const SizedBox(height: 16),
            TextFormField(
              controller: _userNameController,
              decoration: const InputDecoration(labelText: 'Nombre del Operador *'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        BlocBuilder<WriteCashRegisterCubit, WriteCashRegisterState>(
          builder: (context, state) {
            if (state is WritingCashRegister) {
              return const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            return ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: const Text('Cerrar Caja'),
            );
          },
        ),
      ],
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String title;
  final int amount;
  final ThemeData theme;
  final bool isTotal;

  const _BalanceRow({
    required this.title,
    required this.amount,
    required this.theme,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$$amount',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
