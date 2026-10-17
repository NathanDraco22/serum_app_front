import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import '../../../widgets/common/app_buttons.dart';
import 'order_patient_card.dart';
import 'order_doctor_card.dart';

class OrderCartSection extends StatelessWidget {
  final PatientInDb? selectedPatient;
  final DoctorInDb? selectedDoctor;
  final List<LabTestInDb> selectedItems;
  final Map<String, int> itemPriceLevels;
  final Map<String, int> itemCustomPrices;
  final int defaultPriceLevel;
  final bool isSubmitting;
  final VoidCallback onSelectPatient;
  final VoidCallback onRemovePatient;
  final VoidCallback onSelectDoctor;
  final VoidCallback onRemoveDoctor;
  final void Function(LabTestInDb) onRemoveItem;
  final void Function(LabTestInDb, int) onPriceLevelChanged;
  final void Function(int) onDefaultPriceLevelChanged;
  final void Function(LabTestInDb) onEditItemPrice;
  final VoidCallback onClearItems;
  final VoidCallback onSubmitOrder;

  const OrderCartSection({
    super.key,
    required this.selectedPatient,
    required this.selectedDoctor,
    required this.selectedItems,
    this.itemPriceLevels = const {},
    this.itemCustomPrices = const {},
    this.defaultPriceLevel = 1,
    required this.isSubmitting,
    required this.onSelectPatient,
    required this.onRemovePatient,
    required this.onSelectDoctor,
    required this.onRemoveDoctor,
    required this.onRemoveItem,
    required this.onPriceLevelChanged,
    required this.onDefaultPriceLevelChanged,
    required this.onEditItemPrice,
    required this.onClearItems,
    required this.onSubmitOrder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCents = selectedItems.fold<int>(0, (sum, item) {
      if (itemCustomPrices.containsKey(item.id)) {
        return sum + itemCustomPrices[item.id]!;
      }
      final level = itemPriceLevels[item.id] ?? defaultPriceLevel;
      final price = (level == 2 && item.salePrice2 > 0) ? item.salePrice2 : item.salePrice;
      return sum + price;
    });
    final totalFormatted = NumberFormatter.convertToMoneyLike(totalCents);

    final hasModifiedPrices = selectedItems.any((item) {
      final custom = itemCustomPrices[item.id];
      return custom != null && custom != item.salePrice;
    });

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

            /* // Comentado temporalmente por requerimiento del cliente: Soporte Precio 2
            // Selector global de Nivel de Tarifa para toda la orden
            if (selectedItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Tarifa predeterminada:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('Precio 1 (Regular)', style: TextStyle(fontSize: 10)),
                      selected: defaultPriceLevel == 1,
                      onSelected: isSubmitting
                          ? null
                          : (sel) {
                              if (sel) onDefaultPriceLevelChanged(1);
                            },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    ChoiceChip(
                      label: const Text('Precio 2 (Convenio)', style: TextStyle(fontSize: 10)),
                      selected: defaultPriceLevel == 2,
                      onSelected: isSubmitting
                          ? null
                          : (sel) {
                              if (sel) onDefaultPriceLevelChanged(2);
                            },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            */

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
                        final level = itemPriceLevels[item.id] ?? defaultPriceLevel;
                        final customPrice = itemCustomPrices[item.id];
                        final isPriceModified = customPrice != null && customPrice != item.salePrice;
                        final appliedPrice = customPrice ??
                            ((level == 2 && item.salePrice2 > 0)
                                ? item.salePrice2
                                : item.salePrice);
                        final priceStr = NumberFormatter.convertToMoneyLike(appliedPrice);

                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          onLongPress: isSubmitting ? null : () => onEditItemPrice(item),
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
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                              if (isPriceModified)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.amber.shade300),
                                  ),
                                  child: Text(
                                    'Modificado',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                            ],
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
                              Tooltip(
                                message: 'Modificar precio (mantén presionado)',
                                child: InkWell(
                                  onTap: isSubmitting ? null : () => onEditItemPrice(item),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          priceStr,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isPriceModified
                                                ? Colors.amber.shade900
                                                : (level == 2 ? theme.colorScheme.tertiary : theme.colorScheme.primary),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 14,
                                          color: isPriceModified ? Colors.amber.shade900 : theme.colorScheme.outline,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
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
                        'Total de Análisis Clínicos a Evaluar:',
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
                        totalFormatted,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (hasModifiedPrices) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline, size: 15, color: Colors.amber.shade900),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Precios modificados: La orden se creará con requerimiento de autorización de supervisor.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Submit Button
            PrimaryButton(
              onPressed: canSubmit ? onSubmitOrder : null,
              icon: Icons.check_circle_outline,
              label: isSubmitting ? 'Creando Orden...' : 'Crear Orden Clínica',
              isLoading: isSubmitting,
              isCompact: false,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
