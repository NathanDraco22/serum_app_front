import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/cash_register_cubit/write_cash_registers_cubit.dart';

class CashRegisterFormDialog extends StatefulWidget {
  final CashRegisterInDb? register;

  const CashRegisterFormDialog({super.key, this.register});

  @override
  State<CashRegisterFormDialog> createState() => _CashRegisterFormDialogState();
}

class _CashRegisterFormDialogState extends State<CashRegisterFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _branchId;

  @override
  void initState() {
    super.initState();
    if (widget.register != null) {
      _name = widget.register!.name;
      _branchId = widget.register!.branchId;
    } else {
      _name = '';
      _branchId = 'BRANCH-001';
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final cubit = context.read<WriteCashRegisterCubit>();

      if (widget.register == null) {
        final newRegister = CreateCashRegister(
          branchId: _branchId,
          name: _name,
          isOpen: false,
          cashBalance: 0,
          cardBalance: 0,
          transferBalance: 0,
          totalBalance: 0,
        );
        cubit.create(newRegister).then((_) {
          if (!mounted) return;
          Navigator.pop(context, true);
        });
      } else {
        final updateRegister = UpdateCashRegister(
          name: _name,
        );
        cubit.update(widget.register!.id, updateRegister).then((_) {
          if (!mounted) return;
          Navigator.pop(context, true);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.register != null;

    return AlertDialog(
      title: Text(isEdit ? 'Editar Caja' : 'Nueva Caja Registradora'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Nombre de la Caja *'),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                onSaved: (val) => _name = val ?? '',
              ),
              if (!isEdit)
                TextFormField(
                  initialValue: _branchId,
                  decoration: const InputDecoration(labelText: 'Sucursal (ID) *'),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  onSaved: (val) => _branchId = val ?? 'BRANCH-001',
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
              child: Text(isEdit ? 'Guardar Cambios' : 'Registrar'),
            );
          },
        ),
      ],
    );
  }
}
