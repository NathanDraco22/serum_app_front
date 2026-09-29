import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';
import '../../common/search_field_debounced.dart';

Future<DoctorInDb?> showDoctorSelectionDialog(BuildContext context) async {
  return await showDialog<DoctorInDb?>(
    context: context,
    builder: (context) => const DoctorSelectionDialog(),
  );
}

class DoctorSelectionDialog extends StatefulWidget {
  const DoctorSelectionDialog({super.key});

  @override
  State<DoctorSelectionDialog> createState() => _DoctorSelectionDialogState();
}

class _DoctorSelectionDialogState extends State<DoctorSelectionDialog> {
  List<DoctorInDb> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialDoctors();
  }

  Future<void> _loadInitialDoctors() async {
    try {
      final repo = context.read<DoctorsRepository>();
      final list = await repo.getAllDoctors();
      if (!mounted) return;
      setState(() {
        _doctors = list;
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

  Future<void> _searchDoctors(String keyword) async {
    _currentQuery = keyword.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<DoctorsRepository>();
      List<DoctorInDb> results;
      if (_currentQuery.isEmpty) {
        results = await repo.getAllDoctors();
      } else {
        results = await repo.searchDoctorsByText(_currentQuery);
      }

      if (!mounted) return;
      setState(() {
        _doctors = results;
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
              color: theme.colorScheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.medical_services_outlined, color: theme.colorScheme.onSecondaryContainer, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seleccionar Médico',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Busca por nombre, especialidad o cédula',
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
              hintText: 'Escribe nombre o especialidad...',
              onSearch: _searchDoctors,
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
            'Error al buscar médicos:\n$_errorMessage',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      );
    }

    if (_doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 8),
            Text(
              _currentQuery.isEmpty
                  ? 'No hay médicos registrados en el sistema'
                  : 'No se encontraron médicos para "$_currentQuery"',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _doctors.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final doctor = _doctors[index];
        final initial = doctor.name.isNotEmpty ? doctor.name[0].toUpperCase() : 'D';

        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Text(
            doctor.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                doctor.specialty.isNotEmpty ? doctor.specialty : 'Medicina General',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (doctor.cardId != null && doctor.cardId!.isNotEmpty)
                Text(
                  'Cédula: ${doctor.cardId}',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
              if (doctor.phone.isNotEmpty)
                Text(
                  'Tel: ${doctor.phone}',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () {
            Navigator.pop(context, doctor);
          },
        );
      },
    );
  }
}
