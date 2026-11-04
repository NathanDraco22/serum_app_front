import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import '../../controllers/lab_test_form_mediator.dart';
import '../pack_test_selector.dart';

class LabTestPackChildrenSection extends StatelessWidget {
  final List<LabTestInDb> allAvailableTests;
  final VoidCallback onQuickCreateParameter;
  final ValueChanged<LabTestInDb> onQuickEditParameter;

  const LabTestPackChildrenSection({
    super.key,
    required this.allAvailableTests,
    required this.onQuickCreateParameter,
    required this.onQuickEditParameter,
  });

  @override
  Widget build(BuildContext context) {
    final controller = LabTestFormMediator.controllerOf(context);
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isPack) return const SizedBox.shrink();

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
                      Icons.checklist_outlined,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selección de Análisis para este Pack / Perfil',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Seleccione los análisis incluidos o cree parámetros nuevos directamente.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: onQuickCreateParameter,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Crear Parámetro en este Perfil'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PackTestSelector(
                  availableTests: allAvailableTests,
                  selectedTestIds: controller.childTestIds,
                  packSalePrice: controller.salePrice,
                  useChildTestsPriceSum: controller.useChildTestsPriceSum,
                  onEditTest: onQuickEditParameter,
                  onSelectionChanged: (updated) {
                    controller.setChildTestIds(updated, allAvailableTests);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
