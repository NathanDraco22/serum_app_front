import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import '../../../widgets/common/app_buttons.dart';
import '../../order/widgets/order_doctor_card.dart';
import '../controllers/create_quotation_mediator.dart';
import '../controllers/create_quotation_view_controller.dart';
import 'quotation_client_card.dart';

/// Sección de resumen y carrito para la pantalla de Creación de Cotizaciones.
///
/// Siguiendo la arquitectura pura de OKF:
/// - Extrae el 100% del estado en memoria, tarifas y mutaciones directamente
///   del [CreateQuotationViewController] provisto por [CreateQuotationMediator].
/// - Su constructor se reduce exclusivamente a los callbacks de interacción
///   que abren modales de la interfaz (selectores de paciente y médico, vaciar o generar).
class QuotationCartSection extends StatelessWidget {
  final CreateQuotationViewController? viewController;

  // Callbacks para acciones que requieren abrir diálogos modales en la UI
  final VoidCallback? onSelectPatient;
  final VoidCallback? onSelectDoctor;
  final VoidCallback? onClearItems;
  final VoidCallback? onSubmitQuotation;

  const QuotationCartSection({
    super.key,
    this.viewController,
    this.onSelectPatient,
    this.onSelectDoctor,
    this.onClearItems,
    this.onSubmitQuotation,
  });

  @override
  Widget build(BuildContext context) {
    final controller = viewController ?? CreateQuotationMediator.of(context).viewController;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _buildCartContent(
        context: context,
        controller: controller,
      ),
    );
  }

  Widget _buildCartContent({
    required BuildContext context,
    required CreateQuotationViewController controller,
  }) {
    final theme = Theme.of(context);

    // Datos y estados leídos directamente del controlador
    final patient = controller.selectedPatient;
    final doctor = controller.selectedDoctor;
    final items = controller.selectedItems;
    final defaultPriceLevel = controller.defaultPriceLevel;
    final isSubmitting = controller.isSubmitting;
    final totalCents = controller.totalAmount;
    final totalFormatted = NumberFormatter.convertToMoneyLike(totalCents);

    final canSubmit = items.isNotEmpty && !isSubmitting;

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
              patient: patient,
              clientNameController: controller.casualClientNameController,
              onSelectPatient: onSelectPatient ?? () {},
              onRemovePatient: controller.removePatient,
            ),
            const SizedBox(height: 8),
            OrderDoctorCard(
              doctor: doctor,
              onSelect: onSelectDoctor ?? () {},
              onRemove: controller.removeDoctor,
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Encabezado de la lista de análisis
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.request_quote_outlined, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Análisis Cotizados (${items.length})',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (items.isNotEmpty)
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
            if (items.isNotEmpty)
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
                              if (sel) controller.changeDefaultPriceLevel(1);
                            },
                      visualDensity: VisualDensity.compact,
                    ),
                    ChoiceChip(
                      label: const Text('Precio 2 (Especial)', style: TextStyle(fontSize: 10)),
                      selected: defaultPriceLevel == 2,
                      onSelected: isSubmitting
                          ? null
                          : (sel) {
                              if (sel) controller.changeDefaultPriceLevel(2);
                            },
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

            // Lista con scroll de los análisis agregados
            Expanded(
              child: items.isEmpty
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
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final level = controller.getItemPriceLevel(item.id);
                        final price = controller.getItemEffectivePrice(item);
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
                                        controller.changeItemPriceLevel(item.id, next);
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
                                onPressed: isSubmitting ? null : () => controller.removeItem(item),
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
                        '${items.length} ítem${items.length == 1 ? '' : 's'}',
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
