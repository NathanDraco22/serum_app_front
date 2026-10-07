import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

class QuotationClientCard extends StatelessWidget {
  final PatientInDb? patient;
  final TextEditingController clientNameController;
  final VoidCallback onSelectPatient;
  final VoidCallback onRemovePatient;
  final ValueChanged<String>? onNameChanged;

  const QuotationClientCard({
    super.key,
    required this.patient,
    required this.clientNameController,
    required this.onSelectPatient,
    required this.onRemovePatient,
    this.onNameChanged,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hasPatient
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasPatient ? Icons.person : Icons.person_outline,
                  size: 22,
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
                          'CLIENTE / PACIENTE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: hasPatient
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Opcional',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (hasPatient) ...[
                      Text(
                        patient!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
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
                    ] else ...[
                      Text(
                        'Cliente Casual o Seleccionar del Catálogo',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                        ),
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
                  onPressed: onSelectPatient,
                  color: theme.colorScheme.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Quitar Paciente (Usar texto casual)',
                  onPressed: onRemovePatient,
                  color: theme.colorScheme.error,
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: onSelectPatient,
                  icon: const Icon(Icons.person_search, size: 16),
                  label: const Text('Buscar', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ],
          ),
          if (!hasPatient) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: clientNameController,
              onChanged: onNameChanged,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Nombre del Cliente (Ej: Juan Pérez o dejar en blanco)',
                prefixIcon: const Icon(Icons.edit, size: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
