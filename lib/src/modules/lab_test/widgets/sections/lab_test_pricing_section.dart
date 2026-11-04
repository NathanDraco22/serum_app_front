import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import '../../controllers/lab_test_form_mediator.dart';

class LabTestPricingSection extends StatelessWidget {
  final List<LabTestInDb> allAvailableTests;

  const LabTestPricingSection({
    super.key,
    this.allAvailableTests = const [],
  });

  @override
  Widget build(BuildContext context) {
    final controller = LabTestFormMediator.controllerOf(context);
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isAutoSum = controller.isPack && controller.useChildTestsPriceSum;

        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Precios y Tarifas Comerciales',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PRECIO 1 (Público General)
                    Expanded(
                      child: TextFormField(
                        controller: controller.priceController,
                        readOnly: isAutoSum,
                        decoration: InputDecoration(
                          labelText: isAutoSum
                              ? 'Precio Calculado Automáticamente (\$ USD)'
                              : 'Precio de Venta Público (\$ USD) *',
                          hintText: 'ej. 15.00',
                          prefixIcon: Icon(
                            isAutoSum ? Icons.calculate : Icons.attach_money,
                            size: 20,
                            color: isAutoSum ? theme.colorScheme.primary : null,
                          ),
                          helperText: isAutoSum
                              ? 'Sumatoria automática de análisis'
                              : (controller.isPack
                                  ? 'Tarifa personalizada (debe ser mayor a 0)'
                                  : null),
                          filled: isAutoSum,
                          fillColor: isAutoSum
                              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          if (isAutoSum) return null;
                          if (val == null || val.trim().isEmpty) {
                            return 'El precio es requerido';
                          }
                          final parsed = double.tryParse(val);
                          if (parsed == null || parsed <= 0) {
                            return 'El precio debe ser mayor a 0';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null) {
                            controller.setSalePrice(parsed);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // PRECIO 2 (Convenios / Aseguradoras - Opcional)
                    Expanded(
                      child: TextFormField(
                        controller: controller.price2Controller,
                        decoration: InputDecoration(
                          labelText: 'Precio Convenios / Nivel 2 (\$ USD)',
                          hintText: 'ej. 12.00',
                          prefixIcon: const Icon(Icons.handshake_outlined, size: 20),
                          helperText: 'Opcional (para aseguradoras o tarifas corporativas)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final parsed = double.tryParse(val) ?? 0.0;
                          controller.setSalePrice2(parsed);
                        },
                      ),
                    ),
                  ],
                ),
                if (controller.isPack) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: controller.useChildTestsPriceSum
                            ? theme.colorScheme.primary.withValues(alpha: 0.5)
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          controller.useChildTestsPriceSum
                              ? Icons.calculate_outlined
                              : Icons.edit_note_outlined,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Usar la sumatoria de los precios de las pruebas que contiene',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                controller.useChildTestsPriceSum
                                    ? 'El precio del pack se calcula automáticamente sumando el precio de cada análisis seleccionado'
                                    : 'Establecer tarifa fija personalizada para el perfil/pack (debe ser mayor a 0)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: controller.useChildTestsPriceSum,
                          onChanged: (val) {
                            controller.setUseChildTestsPriceSum(val, allAvailableTests);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
