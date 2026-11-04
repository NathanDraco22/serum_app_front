import 'package:flutter/material.dart';
import '../../controllers/order_results_mediator.dart';
import '../../controllers/order_results_view_controller.dart';

/// Cabecera visual del diálogo de resultados clínicos (Icono, Nombre de Examen, Folio, Paciente y Botón Cerrar).
///
/// Siguiendo la arquitectura OKF v0.2:
/// - Extrae el contexto de la orden directamente desde [OrderResultsMediator].
/// - Permite parámetros opcionales para preservar retrocompatibilidad con tests aislados.
class OrderResultsHeader extends StatelessWidget {
  final String? examName;
  final String? shortId;
  final String? patientName;
  final bool? isSubmitting;
  final VoidCallback onClose;
  final VoidCallback? onShowPatientInfo;
  final OrderResultsViewController? viewController;

  const OrderResultsHeader({
    super.key,
    this.examName,
    this.shortId,
    this.patientName,
    this.isSubmitting,
    required this.onClose,
    this.onShowPatientInfo,
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
          resolvedExamName: examName ?? controller.examName,
          resolvedShortId: shortId ?? controller.shortId,
          resolvedPatientName: patientName ?? controller.patientDisplayName,
          resolvedIsSubmitting: isSubmitting ?? controller.isSubmitting,
        ),
      );
    }

    return _buildContent(
      context: context,
      resolvedExamName: examName ?? '',
      resolvedShortId: shortId ?? '',
      resolvedPatientName: patientName ?? '',
      resolvedIsSubmitting: isSubmitting ?? false,
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required String resolvedExamName,
    required String resolvedShortId,
    required String resolvedPatientName,
    required bool resolvedIsSubmitting,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: const Icon(Icons.science_outlined, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        resolvedExamName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#$resolvedShortId',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: onShowPatientInfo,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Paciente: $resolvedPatientName',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onShowPatientInfo != null) ...[
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Ver y copiar datos del paciente',
                            child: Icon(
                              Icons.info_outline,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Cerrar',
            onPressed: resolvedIsSubmitting ? null : onClose,
          ),
        ],
      ),
    );
  }
}
