import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/patient_cubit/read_patients_cubit.dart';
import '../../../cubits/patient_cubit/write_patients_cubit.dart';

class PatientsList extends StatelessWidget {
  final List<PatientInDb> patients;
  final Function(PatientInDb) onEdit;

  const PatientsList({
    super.key,
    required this.patients,
    required this.onEdit,
  });

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (patients.isEmpty) {
      return const Center(child: Text('No se encontraron pacientes'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: Text(patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.badge, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            patient.cardId ?? 'Sin Identificación',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.cake, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(patient.dateOfBirth),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.wc, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            patient.gender == 'male' ? 'Masculino' : patient.gender == 'female' ? 'Femenino' : 'Otro',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(patient.phone, style: theme.textTheme.bodySmall),
                          const SizedBox(width: 16),
                          Icon(Icons.location_on, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              patient.address,
                              style: theme.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => onEdit(patient),
                  color: theme.colorScheme.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text('Eliminar Paciente'),
                        content: Text('¿Está seguro de eliminar a ${patient.name}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<WritePatientCubit>().delete(patient.id).then((_) {
                                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                                if (context.mounted) context.read<ReadPatientCubit>().getAll();
                              });
                            },
                            child: Text(
                              'Eliminar',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  color: theme.colorScheme.error,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
