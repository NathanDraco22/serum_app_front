import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/cash_register_cubit/write_cash_registers_cubit.dart';

class CashRegisterOpenDialog extends StatefulWidget {
  final CashRegisterInDb register;

  const CashRegisterOpenDialog({super.key, required this.register});

  @override
  State<CashRegisterOpenDialog> createState() => _CashRegisterOpenDialogState();
}

class _CashRegisterOpenDialogState extends State<CashRegisterOpenDialog> {
  final _formKey = GlobalKey<FormState>();
  final _initialCashController = TextEditingController();
  final _initialCardController = TextEditingController();
  final _initialTransferController = TextEditingController();

  @override
  void dispose() {
    _initialCashController.dispose();
    _initialCardController.dispose();
    _initialTransferController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final cashDouble = double.tryParse(_initialCashController.text.trim().replaceAll(',', '')) ?? 0.0;
      final cardDouble = double.tryParse(_initialCardController.text.trim().replaceAll(',', '')) ?? 0.0;
      final transferDouble = double.tryParse(_initialTransferController.text.trim().replaceAll(',', '')) ?? 0.0;

      final initialCash = NumberFormatter.convertFromDoubleToCents(cashDouble);
      final initialCard = NumberFormatter.convertFromDoubleToCents(cardDouble);
      final initialTransfer = NumberFormatter.convertFromDoubleToCents(transferDouble);

      final currentUser = context.read<AppSessionCubit>().state.currentUser;
      final userName = currentUser != null && currentUser.name.trim().isNotEmpty
          ? currentUser.name.trim()
          : (currentUser?.username.trim().isNotEmpty == true
              ? currentUser!.username.trim()
              : 'Usuario');
      final userId = currentUser?.id ?? 'system';

      final request = OpenCashRegisterRequest(
        initialCash: initialCash,
        initialCard: initialCard,
        initialTransfer: initialTransfer,
        openedBy: UserInfo(id: userId, name: userName),
      );

      context.read<WriteCashRegisterCubit>().openCashRegister(widget.register.id, request).then((_) {
        if (!mounted) return;
        Navigator.pop(context, true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = context.watch<AppSessionCubit>().state.currentUser;
    final operatorName = currentUser != null && currentUser.name.trim().isNotEmpty
        ? currentUser.name.trim()
        : (currentUser?.username.trim().isNotEmpty == true
            ? currentUser!.username.trim()
            : 'Usuario actual');

    return AlertDialog(
      title: Text('Abrir Caja: ${widget.register.name}'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ingrese los saldos iniciales con los que se abrirá la caja:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _initialCashController,
                decoration: const InputDecoration(
                  labelText: 'Efectivo Inicial *',
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Requerido';
                  final parsed = double.tryParse(val.trim().replaceAll(',', ''));
                  if (parsed == null) return 'Ingrese un número válido';
                  if (parsed < 0) return 'No puede ser negativo';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _initialCardController,
                decoration: const InputDecoration(
                  labelText: 'Tarjeta Inicial',
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final parsed = double.tryParse(val.trim().replaceAll(',', ''));
                    if (parsed == null) return 'Ingrese un número válido';
                    if (parsed < 0) return 'No puede ser negativo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _initialTransferController,
                decoration: const InputDecoration(
                  labelText: 'Transferencia Inicial',
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final parsed = double.tryParse(val.trim().replaceAll(',', ''));
                    if (parsed == null) return 'Ingrese un número válido';
                    if (parsed < 0) return 'No puede ser negativo';
                  }
                  return null;
                },
              ),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      child: const Icon(Icons.person, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Operador Responsable',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            operatorName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Abrir Caja'),
            );
          },
        ),
      ],
    );
  }
}
