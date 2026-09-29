import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

class OrderPatientCard extends StatelessWidget {
  final PatientInDb? patient;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  const OrderPatientCard({
    super.key,
    required this.patient,
    required this.onSelect,
    required this.onRemove,
  });

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
    final hasPatient = patient != null;

    return Container(
      decoration: BoxDecoration(
        color: hasPatient
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPatient ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          width: hasPatient ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasPatient
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasPatient ? Icons.person : Icons.person_outline,
              size: 24,
              color: hasPatient
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'PACIENTE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: hasPatient
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '* (Requerido)',
                      style: TextStyle(
                        fontSize: 10,
                        color: hasPatient ? theme.colorScheme.outline : theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  hasPatient ? patient!.name : 'Ningún paciente asignado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: hasPatient ? theme.colorScheme.onSurface : theme.colorScheme.outline,
                  ),
                ),
                if (hasPatient) ...[
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (patient!.cardId != null && patient!.cardId!.isNotEmpty)
                        Text(
                          'ID: ${patient!.cardId}',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      Text(
                        'Edad: ${_calculateAge(patient!.dateOfBirth)} años (${patient!.gender == 'male' ? 'M' : 'F'})',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                      ),
                      if (patient!.phone.isNotEmpty)
                        Text(
                          'Tel: ${patient!.phone}',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (hasPatient) ...[
            IconButton(
              icon: const Icon(Icons.swap_horiz, size: 20),
              tooltip: 'Cambiar Paciente',
              onPressed: onSelect,
              color: theme.colorScheme.primary,
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Quitar Paciente',
              onPressed: onRemove,
              color: theme.colorScheme.error,
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: onSelect,
              icon: const Icon(Icons.person_search, size: 16),
              label: const Text('Seleccionar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
