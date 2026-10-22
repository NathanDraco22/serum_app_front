import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/patient_cubit/read_patients_cubit.dart';
import '../../../cubits/patient_cubit/write_patients_cubit.dart';
import '../view/patient_orders_history_screen.dart';
import '../../../widgets/dialogs/confirm_delete_dialog.dart';

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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${patient.id}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              patient.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.badge, size: 14, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                patient.cardId != null && patient.cardId!.isNotEmpty
                                    ? 'Cédula: ${patient.cardId}'
                                    : 'Sin Cédula',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cake, size: 14, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(patient.dateOfBirth),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.wc, size: 14, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                patient.gender == 'male' ? 'Masculino' : patient.gender == 'female' ? 'Femenino' : 'Otro',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
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
                              patient.address != null && patient.address!.isNotEmpty
                                  ? patient.address!
                                  : 'Sin dirección',
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
                  icon: const Icon(Icons.history_rounded),
                  tooltip: 'Historial de Órdenes',
                  color: theme.colorScheme.secondary,
                  onPressed: () {
                    PatientOrdersHistoryScreen.show(
                      context,
                      patientId: patient.id,
                      patient: patient,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => onEdit(patient),
                  color: theme.colorScheme.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirmed = await ConfirmDeleteDialog.show(
                      context,
                      title: 'Eliminar Paciente',
                      message: '¿Está seguro de eliminar al paciente del sistema? Esta acción no se puede deshacer.',
                      itemName: patient.name,
                    );
                    if (confirmed && context.mounted) {
                      context.read<WritePatientCubit>().delete(patient.id).then((_) {
                        if (context.mounted) context.read<ReadPatientCubit>().getAll();
                      });
                    }
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
