import 'package:flutter/material.dart';

import '../../../../tools/exports/pdf/templates/clinical_comparison_pdf_template.dart';
import 'clinical_comparison_table_row.dart';

/// Tabla comparativa detallada con agrupación por series clínicas y visualización de Deltas.
class ClinicalComparisonTable extends StatelessWidget {
  final List<ClinicalComparisonPdfRow> rows;

  const ClinicalComparisonTable({
    super.key,
    required this.rows,
  });

  String _getCategoryForRow(ClinicalComparisonPdfRow row) {
    final key = row.key.toUpperCase();
    if (['ERI', 'HB', 'HTC', 'VCM', 'HCM', 'CHCM'].contains(key)) {
      return 'Serie Roja';
    }
    if (['LEU', 'SEG', 'LINF', 'EOS', 'MON', 'BAN', 'BAS', 'LINF-ATIP'].contains(key)) {
      return 'Serie Blanca';
    }
    if (['PLAQ'].contains(key)) {
      return 'Serie Plaquetaria';
    }
    final mc = row.medicalClassification.trim().toUpperCase();
    if (mc.contains('ROJA') || mc.contains('ERITRO')) return 'Serie Roja';
    if (mc.contains('BLANCA') || mc.contains('LEUCO')) return 'Serie Blanca';
    if (mc.contains('PLAQ')) return 'Serie Plaquetaria';
    if (mc.isNotEmpty) return row.medicalClassification;
    return 'General';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: colorScheme.outline),
              const SizedBox(height: 12),
              Text(
                'No se encontraron parámetros con los filtros aplicados',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Map<String, List<ClinicalComparisonPdfRow>> groups = {};
    for (final row in rows) {
      final group = _getCategoryForRow(row);
      groups.putIfAbsent(group, () => []).add(row);
    }

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.blueGrey.shade900,
              child: const Row(
                children: [
                  Expanded(
                    flex: 32,
                    child: Text(
                      'Parámetro / Análisis',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 12,
                    child: Text(
                      'Unidad',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 16,
                    child: Text(
                      'Valor Base',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 16,
                    child: Text(
                      'Valor Reciente',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 16,
                    child: Text(
                      'Variación (Delta)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 18,
                    child: Text(
                      'Referencia',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...groups.entries.map((entry) {
              final groupName = entry.key;
              final groupRows = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey.shade100,
                    child: Row(
                      children: [
                        Icon(
                          groupName == 'Serie Roja'
                              ? Icons.water_drop
                              : groupName == 'Serie Blanca'
                                  ? Icons.shield
                                  : groupName == 'Serie Plaquetaria'
                                      ? Icons.grain
                                      : Icons.biotech,
                          size: 16,
                          color: Colors.blueGrey.shade800,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          groupName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...groupRows.map((r) => ClinicalComparisonTableRow(row: r)),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
