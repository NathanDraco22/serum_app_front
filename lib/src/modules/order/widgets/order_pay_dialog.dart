import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/order_cubit/write_orders_cubit.dart';

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
  final _registerIdController = TextEditingController();
  final _userNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.order.salePriceApplied.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _registerIdController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = int.tryParse(_amountController.text) ?? 0;
      final registerId = _registerIdController.text.trim();
      final userName = _userNameController.text.trim();

      final request = OrderPayRequest(
        amount: amount,
        registerId: registerId,
        paymentMethod: _paymentMethod,
        performedBy: UserInfo(id: 'system', name: userName),
      );

      context.read<WriteOrderCubit>().payOrder(widget.order.id, request).then((_) {
        if (!mounted) return;
        Navigator.pop(context, true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingAmount = widget.order.salePriceApplied;

    return AlertDialog(
      title: Text('Pagar Orden: ${widget.order.examName}'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Precio total:', style: theme.textTheme.bodyMedium),
                  Text(
                    '\$$pendingAmount',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Monto a Pagar *'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Requerido';
                  final parsed = int.tryParse(val);
                  if (parsed == null) return 'Ingrese un número válido';
                  if (parsed <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Método de Pago *'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
                  DropdownMenuItem(value: 'card', child: Text('Tarjeta')),
                  DropdownMenuItem(value: 'transfer', child: Text('Transferencia')),
                ],
                onChanged: (val) => setState(() => _paymentMethod = val ?? 'cash'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _registerIdController,
                decoration: const InputDecoration(
                  labelText: 'ID de Caja Registradora *',
                  hintText: 'Ingrese el UUID de la caja',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
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
        BlocBuilder<WriteOrderCubit, WriteOrderState>(
          builder: (context, state) {
            if (state is WritingOrder) {
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
              child: const Text('Registrar Pago'),
            );
          },
        ),
      ],
    );
  }
}
