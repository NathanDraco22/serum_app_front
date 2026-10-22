import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:serum_business/serum_business.dart';

/// Cabecera comparativa que muestra datos del paciente, intervalo de tiempo y resumen de órdenes enfrentadas.
class ClinicalComparisonHeader extends StatelessWidget {
  final PatientInfo resolvedPatient;
  final OrderInDb baseOrder;
  final OrderInDb comparisonOrder;
  final int daysElapsed;

  const ClinicalComparisonHeader({
    super.key,
    required this.resolvedPatient,
    required this.baseOrder,
    required this.comparisonOrder,
    required this.daysElapsed,
  });

  String _formatDateTime(int timestamp) {
    if (timestamp <= 0) return 'Fecha no disponible';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd/MM/yyyy • hh:mm a').format(date);
  }

  int _calculateAge(int timestamp) {
    if (timestamp <= 0) return 0;
    final birth = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age >= 0 ? age : 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final patientAge = _calculateAge(resolvedPatient.dateOfBirth);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(120)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Fila Paciente
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  child: Text(
                    resolvedPatient.name.isNotEmpty
                        ? resolvedPatient.name[0].toUpperCase()
                        : 'P',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resolvedPatient.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Wrap(
                        spacing: 12,
                        children: [
                          if (resolvedPatient.cardId != null && resolvedPatient.cardId!.isNotEmpty)
                            Text(
                              'Cédula: ${resolvedPatient.cardId}',
                              style: theme.textTheme.bodySmall,
                            ),
                          Text(
                            'Edad: ${patientAge > 0 ? '$patientAge años' : 'N/D'}',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            'Sexo: ${resolvedPatient.gender == 'male' ? 'Masculino' : resolvedPatient.gender == 'female' ? 'Femenino' : resolvedPatient.gender}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge de tiempo transcurrido
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(140),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.primary.withAlpha(100), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timelapse_rounded, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        daysElapsed == 0
                            ? 'Mismo día'
                            : daysElapsed == 1
                                ? '1 día transcurrido'
                                : '$daysElapsed días transcurridos',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Fila de las dos órdenes enfrentadas
            Row(
              children: [
                // Orden Base
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(120),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ORDEN BASE (ANTERIOR)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '#${baseOrder.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(
                              _formatDateTime(baseOrder.createdAt),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        if (baseOrder.doctorInfo != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.medical_services_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Dr(a). ${baseOrder.doctorInfo!.name}',
                                  style: theme.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward_rounded, color: Colors.blueGrey, size: 24),
                ),
                // Orden Evolutiva
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(50),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.primary.withAlpha(100), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ORDEN EVOLUTIVA (RECIENTE)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '#${comparisonOrder.id}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              _formatDateTime(comparisonOrder.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if (comparisonOrder.doctorInfo != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.medical_services_outlined, size: 14, color: colorScheme.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Dr(a). ${comparisonOrder.doctorInfo!.name}',
                                  style: theme.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
