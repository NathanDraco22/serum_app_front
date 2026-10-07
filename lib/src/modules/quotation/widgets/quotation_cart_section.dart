import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import '../../../widgets/common/app_buttons.dart';
import '../../order/widgets/order_doctor_card.dart';
import 'quotation_client_card.dart';

class QuotationCartSection extends StatelessWidget {
  final PatientInDb? selectedPatient;
  final TextEditingController clientNameController;
  final DoctorInDb? selectedDoctor;
  final List<LabTestInDb> selectedItems;
  final Map<String, int> itemPriceLevels;
  final int defaultPriceLevel;
  final bool isSubmitting;
  final VoidCallback onSelectPatient;
  final VoidCallback onRemovePatient;
  final VoidCallback onSelectDoctor;
  final VoidCallback onRemoveDoctor;
  final void Function(LabTestInDb) onRemoveItem;
  final void Function(LabTestInDb, int) onPriceLevelChanged;
  final void Function(int) onDefaultPriceLevelChanged;
  final VoidCallback onClearItems;
  final VoidCallback onSubmitQuotation;

  const QuotationCartSection({
    super.key,
    required this.selectedPatient,
    required this.clientNameController,
    required this.selectedDoctor,
    required this.selectedItems,
    this.itemPriceLevels = const {},
    this.defaultPriceLevel = 1,
    required this.isSubmitting,
    required this.onSelectPatient,
    required this.onRemovePatient,
    required this.onSelectDoctor,
    required this.onRemoveDoctor,
    required this.onRemoveItem,
    required this.onPriceLevelChanged,
    required this.onDefaultPriceLevelChanged,
    required this.onClearItems,
    required this.onSubmitQuotation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCents = selectedItems.fold<int>(0, (sum, item) {
      final level = itemPriceLevels[item.id] ?? defaultPriceLevel;
      final price = (level == 2 && item.salePrice2 > 0) ? item.salePrice2 : item.salePrice;
      return sum + price;
    });
    final totalFormatted = NumberFormatter.convertToMoneyLike(totalCents);

    final canSubmit = selectedItems.isNotEmpty && !isSubmitting;

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
            // Selectores para Cliente y Médico (Ambos opcionales)
            QuotationClientCard(
              patient: selectedPatient,
              clientNameController: clientNameController,
              onSelectPatient: onSelectPatient,
              onRemovePatient: onRemovePatient,
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

            // Encabezado de la lista de análisis
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.request_quote_outlined, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Análisis Cotizados (${selectedItems.length})',
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

            // Selector global de tarifa P1 / P2
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
                    ),
                    ChoiceChip(
                      label: const Text('Precio 2 (Especial)', style: TextStyle(fontSize: 10)),
                      selected: defaultPriceLevel == 2,
                      onSelected: isSubmitting
                          ? null
                          : (sel) {
                              if (sel) onDefaultPriceLevelChanged(2);
                            },
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

            // Lista con scroll de los análisis agregados
            Expanded(
              child: selectedItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_shopping_cart_outlined,
                            size: 40,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No has agregado análisis al presupuesto',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Selecciona del catálogo a la izquierda',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: selectedItems.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = selectedItems[index];
                        final level = itemPriceLevels[item.id] ?? defaultPriceLevel;
                        final price = (level == 2 && item.salePrice2 > 0)
                            ? item.salePrice2
                            : item.salePrice;
                        final priceFormatted = NumberFormatter.convertToMoneyLike(price);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: item.isPack
                                ? theme.colorScheme.tertiaryContainer
                                : theme.colorScheme.primaryContainer,
                            child: Icon(
                              item.isPack ? Icons.inventory_2 : Icons.science,
                              size: 14,
                              color: item.isPack
                                  ? theme.colorScheme.onTertiaryContainer
                                  : theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                item.isPack ? 'Pack Clínico' : 'Individual',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: item.isPack
                                      ? theme.colorScheme.tertiary
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: item.isPack ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Selector de tarifa individual P1 / P2
                              InkWell(
                                onTap: isSubmitting
                                    ? null
                                    : () {
                                        final next = level == 1 ? 2 : 1;
                                        onPriceLevelChanged(item, next);
                                      },
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: level == 2
                                        ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5)
                                        : theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: level == 2
                                          ? theme.colorScheme.tertiary
                                          : theme.colorScheme.outlineVariant,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    'P$level',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: level == 2
                                          ? theme.colorScheme.tertiary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                priceFormatted,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 18),
                                color: theme.colorScheme.error,
                                tooltip: 'Quitar',
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
            const SizedBox(height: 8),

            // Resumen de Montos
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
                        'Total de Análisis / Perfiles:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${selectedItems.length} ítem${selectedItems.length == 1 ? '' : 's'}',
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
                        'Total Presupuestado:',
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
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Botón Principal
            PrimaryButton(
              onPressed: canSubmit ? onSubmitQuotation : null,
              icon: Icons.request_quote_outlined,
              label: isSubmitting ? 'Generando Cotización...' : 'Generar Cotización',
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
