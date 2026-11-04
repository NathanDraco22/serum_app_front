import 'package:flutter/material.dart';
import '../../controllers/order_results_mediator.dart';
import '../../controllers/order_results_view_controller.dart';

/// Pie de acciones del diálogo de resultados (Ver Informe PDF, Cancelar/Cerrar y Guardar).
///
/// Siguiendo la arquitectura OKF v0.2:
/// - Se suscribe al estado de envío ([isSubmitting]) mediante [OrderResultsMediator].
/// - Permite parámetros opcionales para preservar retrocompatibilidad con tests aislados.
class OrderResultsFooter extends StatelessWidget {
  final bool isReadOnly;
  final bool? hasResults;
  final bool? isSubmitting;
  final bool canComplete;
  final VoidCallback onViewReport;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final OrderResultsViewController? viewController;

  const OrderResultsFooter({
    super.key,
    this.isReadOnly = false,
    this.hasResults,
    this.isSubmitting,
    this.canComplete = false,
    required this.onViewReport,
    required this.onCancel,
    required this.onSubmit,
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
          resolvedHasResults: hasResults ?? controller.hasResults,
          resolvedIsSubmitting: isSubmitting ?? controller.isSubmitting,
        ),
      );
    }

    return _buildContent(
      context: context,
      resolvedHasResults: hasResults ?? false,
      resolvedIsSubmitting: isSubmitting ?? false,
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required bool resolvedHasResults,
    required bool resolvedIsSubmitting,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isReadOnly || resolvedHasResults)
            Flexible(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('Ver Informe'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: resolvedIsSubmitting ? null : onViewReport,
              ),
            )
          else
            const SizedBox.shrink(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: resolvedIsSubmitting ? null : onCancel,
                child: Text(isReadOnly ? 'Cerrar' : 'Cancelar'),
              ),
              if (!isReadOnly) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: resolvedIsSubmitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: const Text('Guardar Resultados'),
                  onPressed: resolvedIsSubmitting ? null : onSubmit,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
