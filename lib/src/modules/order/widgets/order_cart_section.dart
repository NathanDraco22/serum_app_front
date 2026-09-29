import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'order_patient_card.dart';
import 'order_doctor_card.dart';

class OrderCartSection extends StatelessWidget {
  final PatientInDb? selectedPatient;
  final DoctorInDb? selectedDoctor;
  final List<LabTestInDb> selectedItems;
  final bool isSubmitting;
  final VoidCallback onSelectPatient;
  final VoidCallback onRemovePatient;
  final VoidCallback onSelectDoctor;
  final VoidCallback onRemoveDoctor;
  final void Function(LabTestInDb) onRemoveItem;
  final VoidCallback onClearItems;
  final VoidCallback onSubmitOrder;

  const OrderCartSection({
    super.key,
    required this.selectedPatient,
    required this.selectedDoctor,
    required this.selectedItems,
    required this.isSubmitting,
    required this.onSelectPatient,
    required this.onRemovePatient,
    required this.onSelectDoctor,
    required this.onRemoveDoctor,
    required this.onRemoveItem,
    required this.onClearItems,
    required this.onSubmitOrder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCents = selectedItems.fold(0, (sum, i) => sum + i.salePrice);
    final totalFormatted = (totalCents / 100.0).toStringAsFixed(2);

    // Calculate total individual clinical tests that will result from packs + items
    int totalParameters = 0;
    for (final item in selectedItems) {
      if (item.isPack) {
        totalParameters += item.childTestIds.length;
      } else {
        totalParameters += 1;
      }
    }

    final canSubmit = selectedPatient != null && selectedItems.isNotEmpty && !isSubmitting;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selectors for Patient & Doctor
            OrderPatientCard(
              patient: selectedPatient,
              onSelect: onSelectPatient,
              onRemove: onRemovePatient,
            ),
            const SizedBox(height: 8),
            OrderDoctorCard(
              doctor: selectedDoctor,
              onSelect: onSelectDoctor,
              onRemove: onRemoveDoctor,
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Cart Items Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.list_alt, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Análisis en la Orden (${selectedItems.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (selectedItems.isNotEmpty)
                  TextButton.icon(
                    onPressed: isSubmitting ? null : onClearItems,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                    label: const Text('Vaciar', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),

            // Items List
            Expanded(
              child: selectedItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.science_outlined,
                            size: 44,
                            color: theme.colorScheme.outline.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No has agregado análisis',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Haz clic en "Agregar" en el catálogo izquierdo.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: selectedItems.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = selectedItems[index];
                        final priceStr = (item.salePrice / 100.0).toStringAsFixed(2);

                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: item.isPack
                                  ? theme.colorScheme.tertiaryContainer
                                  : theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              item.isPack ? Icons.inventory_2 : Icons.science,
                              size: 16,
                              color: item.isPack
                                  ? theme.colorScheme.onTertiaryContainer
                                  : theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          subtitle: Text(
                            item.isPack
                                ? 'Perfil comercial (${item.childTestIds.length} análisis incluidos)'
                                : item.commercialCategory,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '\$$priceStr',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                color: theme.colorScheme.error,
                                tooltip: 'Quitar de la orden',
                                onPressed: isSubmitting ? null : () => onRemoveItem(item),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Summary Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total de Análisis Clí­nicos a Evaluar:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '$totalParameters parámetro${totalParameters == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total a Cobrar:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$$totalFormatted USD',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Submit Button
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: canSubmit ? onSubmitOrder : null,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  isSubmitting ? 'Creando Orden...' : 'Crear Orden Clínica',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
