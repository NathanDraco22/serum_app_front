import 'package:flutter/material.dart';

import '../../../../tools/exports/pdf/templates/clinical_comparison_pdf_template.dart';

/// Tarjetas KPI destacadas para los 3 parámetros cardinales: Hemoglobina, Leucocitos y Plaquetas.
class ClinicalComparisonKpiCards extends StatelessWidget {
  final List<ClinicalComparisonPdfRow> allRows;

  const ClinicalComparisonKpiCards({
    super.key,
    required this.allRows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ClinicalComparisonPdfRow? hbRow;
    ClinicalComparisonPdfRow? leuRow;
    ClinicalComparisonPdfRow? pltRow;

    for (final r in allRows) {
      final key = r.key.toUpperCase();
      if (key == 'HB') hbRow = r;
      if (key == 'LEU') leuRow = r;
      if (key == 'PLAQ') pltRow = r;
    }

    if (hbRow == null && leuRow == null && pltRow == null) {
      return const SizedBox();
    }

    return Row(
      children: [
        if (hbRow != null)
          Expanded(child: _buildSingleKpiCard(theme, colorScheme, hbRow, 'Hemoglobina', Icons.water_drop_outlined, Colors.red.shade700)),
        if (hbRow != null && (leuRow != null || pltRow != null))
          const SizedBox(width: 10),
        if (leuRow != null)
          Expanded(child: _buildSingleKpiCard(theme, colorScheme, leuRow, 'Leucocitos', Icons.shield_outlined, Colors.teal.shade700)),
        if (leuRow != null && pltRow != null)
          const SizedBox(width: 10),
        if (pltRow != null)
          Expanded(child: _buildSingleKpiCard(theme, colorScheme, pltRow, 'Plaquetas', Icons.grain_outlined, Colors.indigo.shade700)),
      ],
    );
  }

  Widget _buildSingleKpiCard(
    ThemeData theme,
    ColorScheme colorScheme,
    ClinicalComparisonPdfRow row,
    String title,
    IconData icon,
    Color accentColor,
  ) {
    final baseVal = row.baseResult?.resultValue ?? '—';
    final compVal = row.comparisonResult?.resultValue ?? '—';
    final delta = row.deltaAbsolute;
    final pct = row.deltaPercentage;

    Color deltaColor = Colors.grey.shade700;
    IconData trendIcon = Icons.remove;
    if (delta != null) {
      if (delta > 0.001) {
        deltaColor = Colors.green.shade800;
        trendIcon = Icons.arrow_upward_rounded;
      } else if (delta < -0.001) {
        deltaColor = Colors.red.shade800;
        trendIcon = Icons.arrow_downward_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (delta != null && pct != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: deltaColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: deltaColor.withAlpha(60)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendIcon, size: 12, color: deltaColor),
                      Text(
                        '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: deltaColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                baseVal,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
              ),
              Text(
                compVal,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                row.unitOfMeasure,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
