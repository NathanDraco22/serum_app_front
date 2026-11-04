import 'package:flutter/material.dart';
import '../../../../tools/calculators/clinical_formulas_registry.dart';
import '../../controllers/order_results_mediator.dart';
import '../../controllers/order_results_view_controller.dart';

/// Barra de resumen métrico del diálogo de resultados (conteo de capturados, diferencial leucocitario y alertas).
///
/// Siguiendo la arquitectura OKF v0.2:
/// - Se suscribe reactivamente al [OrderResultsViewController] mediante [ListenableBuilder].
/// - Permite parámetros opcionales para preservar retrocompatibilidad con tests aislados.
class OrderResultsSummaryBar extends StatelessWidget {
  final int? filledCount;
  final int? totalCount;
  final int? visibleCount;
  final int? alertCount;
  final double? differentialSum;
  final OrderResultsViewController? viewController;

  const OrderResultsSummaryBar({
    super.key,
    this.filledCount,
    this.totalCount,
    this.visibleCount,
    this.alertCount,
    this.differentialSum,
    this.viewController,
  });

  @override
  Widget build(BuildContext context) {
    final controller = viewController ?? OrderResultsMediator.maybeControllerOf(context);

    if (controller != null) {
      return ListenableBuilder(
        listenable: controller,
        builder: (context, _) => _buildContent(
          context: context,
          resolvedFilledCount: filledCount ?? controller.completedParametersCount,
          resolvedTotalCount: totalCount ?? controller.totalParametersCount,
          resolvedVisibleCount: visibleCount ?? controller.visibleParametersCount,
          resolvedAlertCount: alertCount ?? controller.alertCount,
          resolvedDifferentialSum: differentialSum ?? controller.differentialSum,
        ),
      );
    }

    return _buildContent(
      context: context,
      resolvedFilledCount: filledCount ?? 0,
      resolvedTotalCount: totalCount ?? 0,
      resolvedVisibleCount: visibleCount,
      resolvedAlertCount: alertCount ?? 0,
      resolvedDifferentialSum: differentialSum,
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required int resolvedFilledCount,
    required int resolvedTotalCount,
    required int? resolvedVisibleCount,
    required int resolvedAlertCount,
    required double? resolvedDifferentialSum,
  }) {
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
            '$resolvedFilledCount de $resolvedTotalCount análisis capturados',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (resolvedVisibleCount != null && resolvedVisibleCount < resolvedTotalCount) ...[
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
                    '$resolvedVisibleCount a imprimir',
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
          if (resolvedDifferentialSum != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ClinicalFormulasRegistry.isDifferentialValid(resolvedDifferentialSum)
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ClinicalFormulasRegistry.isDifferentialValid(resolvedDifferentialSum)
                      ? Colors.green.shade300
                      : Colors.red.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ClinicalFormulasRegistry.isDifferentialValid(resolvedDifferentialSum)
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    size: 13,
                    color: ClinicalFormulasRegistry.isDifferentialValid(resolvedDifferentialSum)
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ClinicalFormulasRegistry.isDifferentialValid(resolvedDifferentialSum)
                        ? 'Diferencial: 100% ✓'
                        : 'Diferencial: ${ClinicalFormulasRegistry.formatClinicalValue(resolvedDifferentialSum, 1)}% (Debe sumar 100%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: ClinicalFormulasRegistry.isDifferentialValid(resolvedDifferentialSum)
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (resolvedAlertCount > 0)
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
                    '$resolvedAlertCount fuera de rango',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            )
          else if (resolvedFilledCount > 0)
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
