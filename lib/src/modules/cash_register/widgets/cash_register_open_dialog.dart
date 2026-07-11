import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

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
  final _userNameController = TextEditingController();

  @override
  void dispose() {
    _initialCashController.dispose();
    _initialCardController.dispose();
    _initialTransferController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final initialCash = int.tryParse(_initialCashController.text) ?? 0;
      final initialCard = int.tryParse(_initialCardController.text) ?? 0;
      final initialTransfer = int.tryParse(_initialTransferController.text) ?? 0;
      final userName = _userNameController.text;

      final request = OpenCashRegisterRequest(
        initialCash: initialCash,
        initialCard: initialCard,
        initialTransfer: initialTransfer,
        openedBy: UserInfo(id: 'system', name: userName),
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
                decoration: const InputDecoration(labelText: 'Efectivo Inicial *'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Requerido';
                  if (int.tryParse(val) == null) return 'Ingrese un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _initialCardController,
                decoration: const InputDecoration(labelText: 'Tarjeta Inicial'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                    return 'Ingrese un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _initialTransferController,
                decoration: const InputDecoration(labelText: 'Transferencia Inicial'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                    return 'Ingrese un número válido';
                  }
                  return null;
                },
              ),
              const Divider(height: 24),
              TextFormField(
                controller: _userNameController,
                decoration: const InputDecoration(labelText: 'Nombre del Operador *'),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
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
