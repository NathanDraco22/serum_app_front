import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/doctor_cubit/read_doctors_cubit.dart';
import '../../../cubits/doctor_cubit/write_doctors_cubit.dart';

class DoctorsList extends StatelessWidget {
  final List<DoctorInDb> doctors;
  final Function(DoctorInDb) onEdit;

  const DoctorsList({
    super.key,
    required this.doctors,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (doctors.isEmpty) {
      return const Center(child: Text('No se encontraron médicos'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: doctors.length,
      itemBuilder: (context, index) {
        final doctor = doctors[index];
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
                  child: Text(doctor.name.isNotEmpty ? doctor.name[0].toUpperCase() : 'M'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.local_hospital, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            doctor.specialty,
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.badge, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            doctor.cardId ?? 'Sin Registro',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(doctor.phone, style: theme.textTheme.bodySmall),
                          const SizedBox(width: 16),
                          Icon(Icons.email, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(doctor.email ?? 'Sin correo', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => onEdit(doctor),
                  color: theme.colorScheme.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text('Eliminar Médico'),
                        content: Text('¿Está seguro de eliminar al doctor ${doctor.name}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<WriteDoctorCubit>().delete(doctor.id).then((_) {
                                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                                if (context.mounted) context.read<ReadDoctorCubit>().getAll();
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
