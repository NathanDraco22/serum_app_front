import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

class OrderDoctorCard extends StatelessWidget {
  final DoctorInDb? doctor;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  const OrderDoctorCard({
    super.key,
    required this.doctor,
    required this.onSelect,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDoctor = doctor != null;

    return Container(
      decoration: BoxDecoration(
        color: hasDoctor
            ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.25)
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDoctor ? theme.colorScheme.secondary : theme.colorScheme.outlineVariant,
          width: hasDoctor ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasDoctor
                  ? theme.colorScheme.secondaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasDoctor ? Icons.medical_services : Icons.medical_services_outlined,
              size: 22,
              color: hasDoctor
                  ? theme.colorScheme.secondary
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
                      'MÉDICO REMITENTE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: hasDoctor
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(Opcional)',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  hasDoctor ? doctor!.name : 'Sin médico asignado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: hasDoctor ? theme.colorScheme.onSurface : theme.colorScheme.outline,
                  ),
                ),
                if (hasDoctor) ...[
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        doctor!.specialty.isNotEmpty ? doctor!.specialty : 'Medicina General',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      if (doctor!.cardId != null && doctor!.cardId!.isNotEmpty)
                        Text(
                          'Cédula: ${doctor!.cardId}',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      if (doctor!.phone.isNotEmpty)
                        Text(
                          'Tel: ${doctor!.phone}',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (hasDoctor) ...[
            IconButton(
              icon: const Icon(Icons.swap_horiz, size: 20),
              tooltip: 'Cambiar Médico',
              onPressed: onSelect,
              color: theme.colorScheme.secondary,
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Quitar Médico',
              onPressed: onRemove,
              color: theme.colorScheme.error,
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: onSelect,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Asignar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                side: BorderSide(color: theme.colorScheme.outlineVariant),
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
