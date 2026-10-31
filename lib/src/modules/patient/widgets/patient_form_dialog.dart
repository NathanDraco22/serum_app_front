import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/patient_cubit/write_patients_cubit.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';

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
  String? _address;
  late String _gender;
  String? _email;
  String? _cardId;
  late DateTime _dateOfBirth;
  late TextEditingController _ageController;

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _cardIdFocusNode = FocusNode();
  final FocusNode _ageFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();

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
      final ageVal = widget.patient!.age;
      _ageController = TextEditingController(text: ageVal > 0 ? ageVal.toString() : '');
    } else {
      _name = '';
      _phone = '';
      _address = null;
      _gender = 'male';
      _email = '';
      _cardId = '';
      _dateOfBirth = DateTime.now();
      _ageController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _nameFocusNode.dispose();
    _cardIdFocusNode.dispose();
    _ageFocusNode.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  int _calculateAge(int timestamp) {
    if (timestamp <= 0) return 0;
    final birth = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final today = DateTime.now();
    int age = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return age >= 0 ? age : 0;
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
        final computedAge = _calculateAge(picked.millisecondsSinceEpoch);
        _ageController.text = computedAge.toString();
      });
    }
  }

  void _onAgeChanged(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty) return;
    final age = int.tryParse(trimmed);
    if (age != null && age >= 0 && age <= 130) {
      final now = DateTime.now();
      final newYear = now.year - age;
      final newMonth = _dateOfBirth.month;
      final maxDays = DateTime(newYear, newMonth + 1, 0).day;
      final newDay = _dateOfBirth.day > maxDays ? maxDays : _dateOfBirth.day;
      setState(() {
        _dateOfBirth = DateTime(newYear, newMonth, newDay);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final cubit = context.read<WritePatientCubit>();
      final mappedGender = _gender == 'male' ? 'M' : _gender == 'female' ? 'F' : 'O';
      final parsedAge = int.tryParse(_ageController.text.trim());

      if (widget.patient == null) {
        final activeBranchId = context.read<AppSessionCubit>().currentBranchId;

        final newPatient = CreatePatient(
          name: _name,
          dateOfBirth: _dateOfBirth.millisecondsSinceEpoch,
          gender: mappedGender,
          phone: _phone,
          address: _address?.trim().isNotEmpty == true ? _address!.trim() : null,
          originBranch: activeBranchId,
          email: _email?.isNotEmpty == true ? _email : null,
          cardId: _cardId?.isNotEmpty == true ? _cardId : null,
          age: parsedAge,
        );
        cubit.create(newPatient).then((_) {
          if (!mounted) return;
          if (cubit.state is PatientCreated) {
            Navigator.pop(context, (cubit.state as PatientCreated).item);
          } else {
            Navigator.pop(context, true);
          }
        });
      } else {
        final updatePatient = UpdatePatient(
          name: _name,
          dateOfBirth: _dateOfBirth.millisecondsSinceEpoch,
          gender: mappedGender,
          phone: _phone,
          address: _address?.trim().isNotEmpty == true ? _address!.trim() : null,
          email: _email?.isNotEmpty == true ? _email : null,
          cardId: _cardId?.isNotEmpty == true ? _cardId : null,
          age: parsedAge,
        );
        cubit.update(widget.patient!.id, updatePatient).then((_) {
          if (!mounted) return;
          if (cubit.state is PatientUpdated) {
            Navigator.pop(context, (cubit.state as PatientUpdated).item);
          } else {
            Navigator.pop(context, true);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.patient != null;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(isEdit ? 'Editar Paciente' : 'Nuevo Paciente'),
          ),
          if (isEdit)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${widget.patient!.id}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
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
                  autofocus: true,
                  focusNode: _nameFocusNode,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _cardIdFocusNode.requestFocus(),
                  decoration: const InputDecoration(labelText: 'Nombre Completo *'),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  onSaved: (val) => _name = val ?? '',
                ),
                TextFormField(
                  initialValue: _cardId,
                  focusNode: _cardIdFocusNode,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _ageFocusNode.requestFocus(),
                  decoration: const InputDecoration(labelText: 'Cédula / Identificación'),
                  onSaved: (val) => _cardId = val,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        controller: _ageController,
                        focusNode: _ageFocusNode,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        onFieldSubmitted: (_) => _phoneFocusNode.requestFocus(),
                        decoration: const InputDecoration(
                          labelText: 'Edad (años) *',
                          hintText: 'Ej. 35',
                          prefixIcon: Icon(Icons.cake_outlined, size: 20),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Requerido';
                          }
                          final a = int.tryParse(val.trim());
                          if (a == null || a < 0 || a > 130) {
                            return 'Edad inválida';
                          }
                          return null;
                        },
                        onChanged: _onAgeChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha de Nacimiento',
                            suffixIcon: Icon(Icons.calendar_month, size: 20),
                          ),
                          child: Text(
                            '${_dateOfBirth.day.toString().padLeft(2, '0')}/${_dateOfBirth.month.toString().padLeft(2, '0')}/${_dateOfBirth.year}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
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
                  focusNode: _phoneFocusNode,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                  decoration: const InputDecoration(labelText: 'Teléfono *'),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  onSaved: (val) => _phone = val ?? '',
                ),
                TextFormField(
                  initialValue: _email,
                  focusNode: _emailFocusNode,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  onFieldSubmitted: (_) => _addressFocusNode.requestFocus(),
                  decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                  onSaved: (val) => _email = val,
                ),
                TextFormField(
                  initialValue: _address,
                  focusNode: _addressFocusNode,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(labelText: 'Dirección'),
                  onSaved: (val) => _address = val,
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
