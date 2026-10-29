import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import '../../../widgets/common/app_buttons.dart';
import 'order_patient_card.dart';
import 'order_doctor_card.dart';

class OrderCartSection extends StatelessWidget {
  final PatientInDb? selectedPatient;
  final DoctorInDb? selectedDoctor;
  final List<LabTestInDb> selectedItems;
  final List<OrderService> services;
  final List<OrderDiscount> discounts;
  final Map<String, int> itemPriceLevels;
  final Map<String, int> itemCustomPrices;
  final int defaultPriceLevel;
  final bool isSubmitting;
  final TextEditingController? notesController;
  final VoidCallback onSelectPatient;
  final VoidCallback onRemovePatient;
  final VoidCallback onSelectDoctor;
  final VoidCallback onRemoveDoctor;
  final void Function(LabTestInDb) onRemoveItem;
  final void Function(LabTestInDb, int) onPriceLevelChanged;
  final void Function(int) onDefaultPriceLevelChanged;
  final void Function(LabTestInDb) onEditItemPrice;
  final VoidCallback onClearItems;
  final VoidCallback onAddService;
  final void Function(OrderService) onRemoveService;
  final void Function(OrderService) onEditService;
  final VoidCallback onAddDiscount;
  final void Function(OrderDiscount) onRemoveDiscount;
  final void Function(OrderDiscount) onEditDiscount;
  final VoidCallback onSubmitOrder;

  const OrderCartSection({
    super.key,
    required this.selectedPatient,
    required this.selectedDoctor,
    required this.selectedItems,
    this.services = const [],
    this.discounts = const [],
    this.itemPriceLevels = const {},
    this.itemCustomPrices = const {},
    this.defaultPriceLevel = 1,
    this.notesController,
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
    required this.onAddService,
    required this.onRemoveService,
    required this.onEditService,
    required this.onAddDiscount,
    required this.onRemoveDiscount,
    required this.onEditDiscount,
    required this.onSubmitOrder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final testsCents = selectedItems.fold<int>(0, (sum, item) {
      if (itemCustomPrices.containsKey(item.id)) {
        return sum + itemCustomPrices[item.id]!;
      }
      final level = itemPriceLevels[item.id] ?? defaultPriceLevel;
      final price = (level == 2 && item.salePrice2 > 0) ? item.salePrice2 : item.salePrice;
      return sum + price;
    });

    final servicesCents = services.fold<int>(0, (sum, s) => sum + s.price);
    final grossSubtotalCents = testsCents + servicesCents;
    final discountsCents = discounts.fold<int>(0, (sum, d) => sum + d.appliedAmount);
    final totalCents = (grossSubtotalCents - discountsCents).clamp(0, grossSubtotalCents);
    final totalFormatted = NumberFormatter.convertToMoneyLike(totalCents);

    final hasModifiedPrices = selectedItems.any((item) {
      final custom = itemCustomPrices[item.id];
      return custom != null && custom != item.salePrice;
    });
    final hasDiscounts = discounts.isNotEmpty;
    final requiresSupervisorApproval = hasModifiedPrices || hasDiscounts;

    // Calculate total individual clinical tests that will result from packs + items
    int totalParameters = 0;
    for (final item in selectedItems) {
      if (item.isPack) {
        totalParameters += item.childTestIds.length;
      } else {
        totalParameters += 1;
      }
    }

    final canSubmit = selectedPatient != null && (selectedItems.isNotEmpty || services.isNotEmpty) && !isSubmitting;

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

            // Scrollable Content for Tests & Services
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // --- Sección 1: Análisis en la Orden ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.list_alt, size: 18, color: theme.colorScheme.primary),
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

                  if (selectedItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.science_outlined,
                            size: 32,
                            color: theme.colorScheme.outline.withAlpha(120),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No has agregado análisis',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...selectedItems.map((item) {
                      final level = itemPriceLevels[item.id] ?? defaultPriceLevel;
                      final customPrice = itemCustomPrices[item.id];
                      final isPriceModified = customPrice != null && customPrice != item.salePrice;
                      final appliedPrice = customPrice ??
                          ((level == 2 && item.salePrice2 > 0)
                              ? item.salePrice2
                              : item.salePrice);
                      final priceStr = NumberFormatter.convertToMoneyLike(appliedPrice);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: theme.colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isPriceModified
                                  ? Colors.amber.shade300
                                  : theme.colorScheme.outlineVariant.withAlpha(80),
                            ),
                          ),
                          child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                message: 'Modificar precio de análisis',
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
                                tooltip: 'Quitar análisis',
                                onPressed: isSubmitting ? null : () => onRemoveItem(item),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // --- Sección 2: Servicios Adicionales (ej. A Domicilio) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.medical_services_outlined, size: 18, color: theme.colorScheme.secondary),
                          const SizedBox(width: 8),
                          Text(
                            'Servicios Adicionales (${services.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: isSubmitting ? null : onAddService,
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: const Text('Agregar Servicio', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.secondary,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  if (services.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      alignment: Alignment.center,
                      child: Text(
                        'Sin servicios adicionales (ej. servicio a domicilio, toma especial).',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.outline,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...services.map((service) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: theme.colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: theme.colorScheme.secondary.withAlpha(60),
                            ),
                          ),
                          child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.home_repair_service_outlined,
                              size: 16,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                          title: Text(
                            service.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          subtitle: const Text(
                            'Servicio libre adicional',
                            style: TextStyle(fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: 'Modificar precio de servicio',
                                child: InkWell(
                                  onTap: isSubmitting ? null : () => onEditService(service),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          NumberFormatter.convertToMoneyLike(service.price),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: theme.colorScheme.secondary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 14,
                                          color: theme.colorScheme.outline,
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
                                tooltip: 'Quitar servicio',
                                onPressed: isSubmitting ? null : () => onRemoveService(service),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // --- Sección 3: Descuentos en la Orden ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.discount_outlined, size: 18, color: theme.colorScheme.tertiary),
                          const SizedBox(width: 8),
                          Text(
                            'Descuentos en la Orden (${discounts.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: isSubmitting ? null : onAddDiscount,
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: const Text('Agregar Descuento', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.tertiary,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  if (discounts.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      alignment: Alignment.center,
                      child: Text(
                        'Sin descuentos aplicados a esta orden.',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.outline,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...discounts.map((discount) {
                      final discountStr = discount.isPercentage
                          ? '${discount.value % 1 == 0 ? discount.value.toInt() : discount.value.toStringAsFixed(1)}%'
                          : NumberFormatter.convertToMoneyLike(discount.appliedAmount);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: theme.colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: theme.colorScheme.tertiary.withAlpha(70),
                            ),
                          ),
                          child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              discount.isPercentage ? Icons.percent : Icons.attach_money,
                              size: 16,
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                          ),
                          title: Text(
                            discount.description,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          subtitle: Text(
                            discount.isPercentage
                                ? 'Deducción del $discountStr sobre el subtotal'
                                : 'Descuento por monto fijo',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: 'Modificar descuento',
                                child: InkWell(
                                  onTap: isSubmitting ? null : () => onEditDiscount(discount),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '- ${NumberFormatter.convertToMoneyLike(discount.appliedAmount)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 14,
                                          color: theme.colorScheme.outline,
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
                                tooltip: 'Quitar descuento',
                                onPressed: isSubmitting ? null : () => onRemoveDiscount(discount),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Campo opcional de Notas / Observaciones
            TextField(
              controller: notesController,
              maxLines: 2,
              minLines: 1,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.note_alt_outlined, size: 18),
                labelText: 'Notas u Observaciones (Opcional)',
                hintText: 'Ej. Indicación médica, muestra en ayunas...',
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
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
                  if (services.isNotEmpty || discounts.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal Análisis:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          NumberFormatter.convertToMoneyLike(testsCents),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                    if (services.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal Servicios:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            NumberFormatter.convertToMoneyLike(servicesCents),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (discounts.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Descuentos Totales:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '- ${NumberFormatter.convertToMoneyLike(discountsCents)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
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
                  if (requiresSupervisorApproval) ...[
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
                              hasDiscounts && hasModifiedPrices
                                  ? 'Precios modificados y descuentos aplicados: La orden se creará con requerimiento de autorización de supervisor.'
                                  : (hasDiscounts
                                      ? 'Descuento aplicado: La orden se creará con requerimiento de autorización de supervisor.'
                                      : 'Precios modificados: La orden se creará con requerimiento de autorización de supervisor.'),
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
