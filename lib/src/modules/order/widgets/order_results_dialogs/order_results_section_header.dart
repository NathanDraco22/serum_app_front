import 'package:flutter/material.dart';

/// Pequeño separador visual para estructurar perfiles clínicos en la captura de resultados.
///
/// Informa al bioanalista:
/// - El nombre del examen o pack (ej. "BIOMETRÍA HEMÁTICA COMPLETA", "PERFIL LIPÍDICO").
/// - La disciplina médica (ej. "HEMATOLOGÍA", "QUÍMICA CLÍNICA").
/// - El avance cuantitativo de parámetros capturados ($completedCount / $totalCount).
/// - Un resalte visual activo cuando el usuario está escribiendo en este perfil.
class OrderResultsSectionHeader extends StatelessWidget {
  final String studyTitle;
  final String clinicalArea;
  final int completedCount;
  final int totalCount;
  final bool isCurrentActive;

  const OrderResultsSectionHeader({
    super.key,
    required this.studyTitle,
    this.clinicalArea = '',
    required this.completedCount,
    required this.totalCount,
    this.isCurrentActive = false,
  });

  IconData _resolveIcon() {
    final titleUpper = studyTitle.toUpperCase();
    final areaUpper = clinicalArea.toUpperCase();

    if (titleUpper.contains('ORINA') ||
        titleUpper.contains('EGO') ||
        areaUpper.contains('URO')) {
      return Icons.opacity_outlined;
    }
    if (titleUpper.contains('HECES') ||
        titleUpper.contains('COPRO') ||
        areaUpper.contains('COPRO')) {
      return Icons.biotech_outlined;
    }
    if (titleUpper.contains('HEMÁTICA') ||
        titleUpper.contains('HEMATICA') ||
        titleUpper.contains('BHC') ||
        titleUpper.contains('SANG') ||
        areaUpper.contains('HEMAT')) {
      return Icons.water_drop_outlined;
    }
    if (titleUpper.contains('LIP') ||
        titleUpper.contains('GLUC') ||
        titleUpper.contains('QUÍM') ||
        titleUpper.contains('QUIM') ||
        areaUpper.contains('QUÍM') ||
        areaUpper.contains('QUIM')) {
      return Icons.science_outlined;
    }
    return Icons.folder_open_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFullyCompleted = totalCount > 0 && completedCount >= totalCount;

    final baseBorderColor = isCurrentActive
        ? colorScheme.primary
        : (isFullyCompleted
            ? Colors.green.shade600
            : colorScheme.outlineVariant.withValues(alpha: 0.6));

    final bgColor = isCurrentActive
        ? colorScheme.primaryContainer.withValues(alpha: 0.35)
        : (isFullyCompleted
            ? Colors.green.shade50.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHigh.withValues(alpha: 0.45));

    final iconColor = isCurrentActive
        ? colorScheme.primary
        : (isFullyCompleted ? Colors.green.shade700 : colorScheme.onSurfaceVariant);

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCurrentActive
              ? colorScheme.primary.withValues(alpha: 0.6)
              : baseBorderColor,
          width: isCurrentActive ? 1.2 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(_resolveIcon(), size: 14, color: iconColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              studyTitle.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.3,
                color: isCurrentActive ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ),
          if (clinicalArea.isNotEmpty &&
              clinicalArea.toUpperCase() != studyTitle.toUpperCase()) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '• ${clinicalArea.toUpperCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (isCurrentActive) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 8.5, color: Colors.white),
                  SizedBox(width: 3),
                  Text(
                    'Editando',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: isFullyCompleted
                  ? Colors.green.shade100
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFullyCompleted) ...[
                  Icon(Icons.check_circle_rounded, size: 10, color: Colors.green.shade800),
                  const SizedBox(width: 3),
                ],
                Text(
                  '$completedCount / $totalCount',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: isFullyCompleted ? FontWeight.bold : FontWeight.w600,
                    color: isFullyCompleted
                        ? Colors.green.shade900
                        : colorScheme.onSurfaceVariant,
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
