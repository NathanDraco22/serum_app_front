import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../tools/exports/pdf/templates/clinical_comparison_pdf_template.dart';
import '../../../../tools/formatters/thousands_separator_input_formatter.dart';

/// Fila individual para la tabla comparativa con valor base, valor reciente, delta y alertas.
class ClinicalComparisonTableRow extends StatelessWidget {
  final ClinicalComparisonPdfRow row;

  const ClinicalComparisonTableRow({
    super.key,
    required this.row,
  });

  String? _resolveAlertFlag(OrderTestResult? r, List<ReferenceValue> referenceValues) {
    if (r == null) return null;
    if (r.alertFlag != null && r.alertFlag!.isNotEmpty) {
      final flag = r.alertFlag!.toUpperCase();
      if (flag == 'HIGH' || flag == 'ALTO' || flag == 'H') return 'H';
      if (flag == 'LOW' || flag == 'BAJO' || flag == 'L') return 'L';
      if (flag == 'ABNORMAL' || flag == 'ANORMAL') return '*';
      return flag;
    }

    if (r.dataType == 'numeric' && r.resultValue != null && referenceValues.isNotEmpty) {
      final numVal = ThousandsSeparatorInputFormatter.tryParseDouble(r.resultValue);
      if (numVal != null) {
        final ref = referenceValues.first;
        if (numVal > ref.maxValue) return 'H';
        if (numVal < ref.minValue) return 'L';
      }
    }
    return null;
  }

  Widget _buildAlertBadge(String flag) {
    Color bg = Colors.red.shade100;
    Color fg = Colors.red.shade900;
    if (flag == 'L') {
      bg = Colors.blue.shade100;
      fg = Colors.blue.shade900;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        flag,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseAlert = _resolveAlertFlag(row.baseResult, row.referenceValues);
    final compAlert = _resolveAlertFlag(row.comparisonResult, row.referenceValues);

    final baseVal = row.baseResult?.resultValue != null &&
            row.baseResult!.resultValue!.isNotEmpty
        ? ThousandsSeparatorInputFormatter.formatText(row.baseResult!.resultValue!)
        : '—';

    final compVal = row.comparisonResult?.resultValue != null &&
            row.comparisonResult!.resultValue!.isNotEmpty
        ? ThousandsSeparatorInputFormatter.formatText(row.comparisonResult!.resultValue!)
        : '—';

    final delta = row.deltaAbsolute;
    final pct = row.deltaPercentage;

    String deltaStr = '—';
    Color deltaColor = Colors.grey.shade800;
    IconData? trendIcon;

    if (delta != null && pct != null) {
      final sign = delta > 0 ? '+' : '';
      final formattedDelta = delta.abs() >= 100
          ? delta.toStringAsFixed(0)
          : delta.toStringAsFixed(1);
      final pctSign = pct > 0 ? '+' : '';
      deltaStr = '$sign$formattedDelta ($pctSign${pct.toStringAsFixed(1)}%)';

      if (delta > 0.001) {
        trendIcon = Icons.arrow_upward_rounded;
        deltaColor = Colors.teal.shade800;
      } else if (delta < -0.001) {
        trendIcon = Icons.arrow_downward_rounded;
        deltaColor = Colors.indigo.shade800;
      } else {
        trendIcon = Icons.remove;
        deltaStr = '0.0 (0.0%)';
        deltaColor = Colors.grey.shade600;
      }
    }

    String refText = '—';
    if (row.dataType == 'numeric' && row.referenceValues.isNotEmpty) {
      final ref = row.referenceValues.first;
      final unit = row.unitOfMeasure.isNotEmpty ? ' ${row.unitOfMeasure}' : '';
      refText = '${ref.minValue} - ${ref.maxValue}$unit';
    } else if (row.expectedQualitativeValue != null) {
      refText = 'Esp: ${row.expectedQualitativeValue}';
    }

    final bool alertStatusChanged = baseAlert != compAlert;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: alertStatusChanged && compAlert != null
            ? Colors.amber.shade50.withAlpha(120)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 32,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    row.parameterName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: compAlert != null ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (alertStatusChanged && compAlert != null)
                  Tooltip(
                    message: 'El estado de alerta cambió en este estudio',
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('CAMBIO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              row.unitOfMeasure,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            flex: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  baseVal,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (baseAlert != null) ...[
                  const SizedBox(width: 4),
                  _buildAlertBadge(baseAlert),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  compVal,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: compAlert != null ? Colors.red.shade900 : Colors.black87,
                  ),
                ),
                if (compAlert != null) ...[
                  const SizedBox(width: 4),
                  _buildAlertBadge(compAlert),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (trendIcon != null) ...[
                  Icon(trendIcon, size: 14, color: deltaColor),
                  const SizedBox(width: 2),
                ],
                Flexible(
                  child: Text(
                    deltaStr,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: deltaColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              refText,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}
