import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

/// Cabecera con datos demográficos del paciente, KPIs de órdenes y banner de biometrías.
class PatientHistoryHeader extends StatelessWidget {
  final PatientInDb? patient;
  final String patientId;
  final int totalOrdersCount;
  final int completedOrdersCount;
  final int totalBilled;
  final int totalPendingBalance;
  final List<OrderInDb> biometryOrders;
  final VoidCallback onCompareBiometries;

  const PatientHistoryHeader({
    super.key,
    required this.patient,
    required this.patientId,
    required this.totalOrdersCount,
    required this.completedOrdersCount,
    required this.totalBilled,
    required this.totalPendingBalance,
    required this.biometryOrders,
    required this.onCompareBiometries,
  });

  String _calculateAge(int timestamp) {
    if (timestamp <= 0) return 'Edad N/D';
    final birth = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return '$age años';
  }

  Widget _buildKpiCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(120)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: Text(
                  patient != null && patient!.name.isNotEmpty
                      ? patient!.name[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
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
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#$patientId',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            patient?.name ?? 'Paciente Desconocido',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
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
                        if (patient?.cardId != null && patient!.cardId!.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.badge_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text('Cédula: ${patient!.cardId}', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        if (patient != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cake_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(_calculateAge(patient!.dateOfBirth), style: theme.textTheme.bodySmall),
                            ],
                          ),
                        if (patient != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.wc_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                patient!.gender == 'male'
                                    ? 'Masculino'
                                    : patient!.gender == 'female'
                                        ? 'Femenino'
                                        : 'Otro',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        if (patient?.phone != null && patient!.phone.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(patient!.phone, style: theme.textTheme.bodySmall),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          // KPIs Rápidos
          Row(
            children: [
              _buildKpiCard(
                theme,
                colorScheme,
                title: 'Órdenes',
                value: '$totalOrdersCount',
                icon: Icons.assignment_outlined,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              _buildKpiCard(
                theme,
                colorScheme,
                title: 'Completadas',
                value: '$completedOrdersCount',
                icon: Icons.check_circle_outline,
                color: Colors.teal,
              ),
              const SizedBox(width: 12),
              _buildKpiCard(
                theme,
                colorScheme,
                title: 'Facturado',
                value: NumberFormatter.convertToMoneyLike(totalBilled),
                icon: Icons.payments_outlined,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: 12),
              _buildKpiCard(
                theme,
                colorScheme,
                title: 'Saldo Pendiente',
                value: NumberFormatter.convertToMoneyLike(totalPendingBalance),
                icon: Icons.pending_actions_outlined,
                color: totalPendingBalance > 0 ? colorScheme.error : Colors.green,
              ),
            ],
          ),
          // Banner de Biometrías detectadas si hay 2 o más
          if (biometryOrders.length >= 2) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(70),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.primary.withAlpha(120)),
              ),
              child: Row(
                children: [
                  Icon(Icons.insights_rounded, color: colorScheme.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${biometryOrders.length} Biometrías Hemáticas registradas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Compara la evolución analítica entre las dos tomas más recientes con 1 clic.',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: onCompareBiometries,
                    icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                    label: const Text('Comparar Biometrías'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
