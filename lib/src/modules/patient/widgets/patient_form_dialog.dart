import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/patient_cubit/write_patients_cubit.dart';

class PatientFormDialog extends StatefulWidget {
  final PatientInDb? patient;

  const PatientFormDialog({super.key, this.patient});

  @override
  State<PatientFormDialog> createState() => _PatientFormDialogState();
}

class _PatientFormDialogState extends State<PatientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _phone;
  late String _address;
  late String _gender;
  String? _email;
  String? _cardId;
  late DateTime _dateOfBirth;

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _name = widget.patient!.name;
      _phone = widget.patient!.phone;
      _address = widget.patient!.address;
      
      final rawGender = widget.patient!.gender.toLowerCase();
      if (rawGender == 'm' || rawGender == 'male') {
        _gender = 'male';
      } else if (rawGender == 'f' || rawGender == 'female') {
        _gender = 'female';
      } else {
        _gender = 'other';
      }
      
      _email = widget.patient!.email;
      _cardId = widget.patient!.cardId;
      _dateOfBirth = DateTime.fromMillisecondsSinceEpoch(widget.patient!.dateOfBirth);
    } else {
      _name = '';
      _phone = '';
      _address = '';
      _gender = 'male';
      _email = '';
      _cardId = '';
      _dateOfBirth = DateTime.now();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final cubit = context.read<WritePatientCubit>();
      final mappedGender = _gender == 'male' ? 'M' : _gender == 'female' ? 'F' : 'O';

      if (widget.patient == null) {
        final newPatient = CreatePatient(
          name: _name,
          dateOfBirth: _dateOfBirth.millisecondsSinceEpoch,
          gender: mappedGender,
          phone: _phone,
          address: _address,
          email: _email?.isNotEmpty == true ? _email : null,
          cardId: _cardId?.isNotEmpty == true ? _cardId : null,
        );
        cubit.create(newPatient).then((_) {
          if (!mounted) return;
          Navigator.pop(context, true);
        });
      } else {
        final updatePatient = UpdatePatient(
          name: _name,
          dateOfBirth: _dateOfBirth.millisecondsSinceEpoch,
          gender: mappedGender,
          phone: _phone,
          address: _address,
          email: _email?.isNotEmpty == true ? _email : null,
          cardId: _cardId?.isNotEmpty == true ? _cardId : null,
        );
        cubit.update(widget.patient!.id, updatePatient).then((_) {
          if (!mounted) return;
          Navigator.pop(context, true);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.patient != null;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(isEdit ? 'Editar Paciente' : 'Nuevo Paciente'),
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
                  initialValue: _cardId,
                  decoration: const InputDecoration(labelText: 'Cédula / Identificación'),
                  onSaved: (val) => _cardId = val,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Fecha de Nacimiento:\n${_dateOfBirth.day}/${_dateOfBirth.month}/${_dateOfBirth.year}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Género'),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Masculino')),
                    DropdownMenuItem(value: 'female', child: Text('Femenino')),
                    DropdownMenuItem(value: 'other', child: Text('Otro')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _gender = val;
                      });
                    }
                  },
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
                TextFormField(
                  initialValue: _address,
                  decoration: const InputDecoration(labelText: 'Dirección *'),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  onSaved: (val) => _address = val ?? '',
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
        BlocBuilder<WritePatientCubit, WritePatientState>(
          builder: (context, state) {
            if (state is WritingPatient) {
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
