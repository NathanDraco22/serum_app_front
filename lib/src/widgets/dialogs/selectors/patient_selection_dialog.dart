import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';
import '../../common/search_field_debounced.dart';

Future<PatientInDb?> showPatientSelectionDialog(BuildContext context) async {
  return await showDialog<PatientInDb?>(
    context: context,
    builder: (context) => const PatientSelectionDialog(),
  );
}

class PatientSelectionDialog extends StatefulWidget {
  const PatientSelectionDialog({super.key});

  @override
  State<PatientSelectionDialog> createState() => _PatientSelectionDialogState();
}

class _PatientSelectionDialogState extends State<PatientSelectionDialog> {
  List<PatientInDb> _patients = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialPatients();
  }

  Future<void> _loadInitialPatients() async {
    try {
      final repo = context.read<PatientsRepository>();
      final list = await repo.getAllPatients();
      if (!mounted) return;
      setState(() {
        _patients = list;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchPatients(String keyword) async {
    _currentQuery = keyword.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<PatientsRepository>();
      List<PatientInDb> results;
      if (_currentQuery.isEmpty) {
        results = await repo.getAllPatients();
      } else {
        results = await repo.searchPatientsByText(_currentQuery);
      }

      if (!mounted) return;
      setState(() {
        _patients = results;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  int _calculateAge(int birthDateMs) {
    if (birthDateMs <= 0) return 0;
    final birthDate = DateTime.fromMillisecondsSinceEpoch(birthDateMs);
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age >= 0 ? age : 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_search, color: theme.colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seleccionar Paciente',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Busca por nombre, cédula o teléfono',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        height: 420,
        child: Column(
          children: [
            const SizedBox(height: 8),
            SearchFieldDebounced(
              autoFocus: true,
              hintText: 'Escribe nombre, cédula...',
              onSearch: _searchPatients,
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildContent(theme)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error al buscar pacientes:\n$_errorMessage',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      );
    }

    if (_patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 8),
            Text(
              _currentQuery.isEmpty
                  ? 'No hay pacientes registrados en el sistema'
                  : 'No se encontraron pacientes para "$_currentQuery"',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _patients.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final patient = _patients[index];
        final initial = patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P';
        final age = _calculateAge(patient.dateOfBirth);
        final genderStr = patient.gender == 'male' ? 'M' : patient.gender == 'female' ? 'F' : 'Otro';

        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Text(
            patient.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (patient.cardId != null && patient.cardId!.isNotEmpty)
                Text(
                  'ID: ${patient.cardId}',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
              Text(
                'Edad: $age años ($genderStr)',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              ),
              if (patient.phone.isNotEmpty)
                Text(
                  'Tel: ${patient.phone}',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () {
            Navigator.pop(context, patient);
          },
        );
      },
    );
  }
}
