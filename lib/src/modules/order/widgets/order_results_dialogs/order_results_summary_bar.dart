import 'package:flutter/material.dart';
import '../../../../tools/calculators/clinical_formulas_registry.dart';

/// Barra de resumen métrico del diálogo de resultados (conteo de capturados, diferencial leucocitario y alertas).
class OrderResultsSummaryBar extends StatelessWidget {
  final int filledCount;
  final int totalCount;
  final int? visibleCount;
  final int alertCount;
  final double? differentialSum;

  const OrderResultsSummaryBar({
    super.key,
    required this.filledCount,
    required this.totalCount,
    this.visibleCount,
    required this.alertCount,
    this.differentialSum,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Row(
        children: [
          Icon(
            Icons.checklist,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '$filledCount de $totalCount análisis capturados',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (visibleCount != null && visibleCount! < totalCount) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility,
                    size: 11,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$visibleCount a imprimir',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          if (differentialSum != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ClinicalFormulasRegistry.isDifferentialValid(differentialSum)
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ClinicalFormulasRegistry.isDifferentialValid(differentialSum)
                      ? Colors.green.shade300
                      : Colors.red.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ClinicalFormulasRegistry.isDifferentialValid(differentialSum)
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    size: 13,
                    color: ClinicalFormulasRegistry.isDifferentialValid(differentialSum)
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ClinicalFormulasRegistry.isDifferentialValid(differentialSum)
                        ? 'Diferencial: 100% ✓'
                        : 'Diferencial: ${ClinicalFormulasRegistry.formatClinicalValue(differentialSum!, 1)}% (Debe sumar 100%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: ClinicalFormulasRegistry.isDifferentialValid(differentialSum)
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (alertCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red.shade800),
                  const SizedBox(width: 4),
                  Text(
                    '$alertCount fuera de rango',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            )
          else if (filledCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 12, color: Colors.green.shade800),
                  const SizedBox(width: 4),
                  Text(
                    'Valores normales',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
