import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/doctor_cubit/write_doctors_cubit.dart';

class DoctorFormDialog extends StatefulWidget {
  final DoctorInDb? doctor;

  const DoctorFormDialog({super.key, this.doctor});

  @override
  State<DoctorFormDialog> createState() => _DoctorFormDialogState();
}

class _DoctorFormDialogState extends State<DoctorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _specialty;
  late String _phone;
  String? _email;
  String? _cardId;

  @override
  void initState() {
    super.initState();
    if (widget.doctor != null) {
      _name = widget.doctor!.name;
      _specialty = widget.doctor!.specialty;
      _phone = widget.doctor!.phone;
      _email = widget.doctor!.email;
      _cardId = widget.doctor!.cardId;
    } else {
      _name = '';
      _specialty = '';
      _phone = '';
      _email = '';
      _cardId = '';
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final cubit = context.read<WriteDoctorCubit>();

      if (widget.doctor == null) {
        final newDoctor = CreateDoctor(
          name: _name,
          specialty: _specialty,
          phone: _phone,
          email: _email?.isNotEmpty == true ? _email : null,
          cardId: _cardId?.isNotEmpty == true ? _cardId : null,
        );
        cubit.create(newDoctor).then((_) {
          if (!mounted) return;
          Navigator.pop(context, true);
        });
      } else {
        final updateDoctor = UpdateDoctor(
          name: _name,
          specialty: _specialty,
          phone: _phone,
          email: _email?.isNotEmpty == true ? _email : null,
          cardId: _cardId?.isNotEmpty == true ? _cardId : null,
        );
        cubit.update(widget.doctor!.id, updateDoctor).then((_) {
          if (!mounted) return;
          Navigator.pop(context, true);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.doctor != null;

    return AlertDialog(
      title: Text(isEdit ? 'Editar Médico' : 'Nuevo Médico'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _name,
                  decoration: const InputDecoration(labelText: 'Nombre Completo *'),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  onSaved: (val) => _name = val ?? '',
                ),
                TextFormField(
                  initialValue: _specialty,
                  decoration: const InputDecoration(labelText: 'Especialidad *'),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  onSaved: (val) => _specialty = val ?? '',
                ),
                TextFormField(
                  initialValue: _cardId,
                  decoration: const InputDecoration(labelText: 'Nº Licencia / Identificación'),
                  onSaved: (val) => _cardId = val,
                ),
                TextFormField(
                  initialValue: _phone,
                  decoration: const InputDecoration(labelText: 'Teléfono *'),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  onSaved: (val) => _phone = val ?? '',
                ),
                TextFormField(
                  initialValue: _email,
                  decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                  onSaved: (val) => _email = val,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        BlocBuilder<WriteDoctorCubit, WriteDoctorState>(
          builder: (context, state) {
            if (state is WritingDoctor) {
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
