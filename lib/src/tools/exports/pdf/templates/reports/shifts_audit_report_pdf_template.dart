import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:serum_business/serum_business.dart';

import '../../pdf_template.dart';
import 'report_pdf_base.dart';

/// Plantilla de exportación a PDF para el Reporte de Auditoría de Turnos de Caja.
class ShiftsAuditReportPdfTemplate implements PdfTemplate {
  final ShiftsAuditReportResponse report;
  final String branchName;
  final String? branchAddress;
  final String? branchPhone;
  final String? generatedBy;
  final bool discrepanciesOnly;

  ShiftsAuditReportPdfTemplate({
    required this.report,
    required this.branchName,
    this.branchAddress,
    this.branchPhone,
    this.generatedBy,
    this.discrepanciesOnly = false,
  });

  @override
  Future<pw.Document> buildDocument() async {
    final doc = pw.Document();

    final startDate = DateTime.fromMillisecondsSinceEpoch(report.startDate);
    final endDate = DateTime.fromMillisecondsSinceEpoch(report.endDate);

    // Consolidar todos los turnos
    final allShifts = <ShiftAuditItem>[];
    for (final b in report.byBranch) {
      allShifts.addAll(b.shifts);
    }
    // Filtrar si el usuario eligió solo discrepancias
    final displayedShifts = discrepanciesOnly
        ? allShifts.where((s) => (s.difference ?? 0) != 0).toList()
        : allShifts;

    // Ordenar de más reciente a más antiguo
    displayedShifts.sort((a, b) => b.openedAt.compareTo(a.openedAt));

    final filterSubtitle = discrepanciesOnly
        ? 'Filtrado: Únicamente turnos con descuadre (sobrantes o faltantes)'
        : 'Todos los turnos y arqueos registrados';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: ReportPdfHelper.buildHeader(
              reportTitle: 'Auditoría de Turnos de Caja',
              subtitle: 'Control de arqueos, balance contable y detección de descuadres ($filterSubtitle)',
              branchName: branchName,
              branchAddress: branchAddress,
              branchPhone: branchPhone,
              startDate: startDate,
              endDate: endDate,
              generatedBy: generatedBy,
            ),
          );
        },
        footer: (pw.Context context) => ReportPdfHelper.buildFooter(context),
        build: (pw.Context context) {
          final summary = report.summary;
          final totalShifts = summary.totalShifts;
          final discrepancies = summary.totalDiscrepancies;
          final netDiff = summary.netDifference;
          final conformityPct = totalShifts > 0
              ? (((totalShifts - discrepancies) / totalShifts) * 100).toStringAsFixed(1)
              : '100.0';

          return [
            // Resumen de Métricas / KPIs
            pw.Row(
              children: [
                pw.Expanded(
                  child: ReportPdfHelper.buildKpiCard(
                    label: 'Turnos Evaluados',
                    value: '$totalShifts',
                    subtitle: 'Arqueos en período',
                    accentColor: PdfColors.blue800,
                    backgroundColor: PdfColors.blue50,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: ReportPdfHelper.buildKpiCard(
                    label: 'Con Descuadre',
                    value: '$discrepancies',
                    subtitle: discrepancies > 0 ? 'Faltantes / Sobrantes' : 'Totalmente cuadrados',
                    accentColor: discrepancies > 0 ? PdfColors.deepOrange800 : PdfColors.teal800,
                    backgroundColor: discrepancies > 0 ? PdfColors.deepOrange50 : PdfColors.teal50,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: ReportPdfHelper.buildKpiCard(
                    label: 'Diferencia Neta',
                    value: ReportPdfHelper.formatCurrency(netDiff),
                    subtitle: netDiff > 0
                        ? 'Sobrante global'
                        : (netDiff < 0 ? 'Faltante global' : 'Cuadre exacto'),
                    accentColor: netDiff >= 0 ? PdfColors.teal800 : PdfColors.red800,
                    backgroundColor: netDiff >= 0 ? PdfColors.teal50 : PdfColors.red50,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: ReportPdfHelper.buildKpiCard(
                    label: 'Conformidad',
                    value: '$conformityPct%',
                    subtitle: 'Turnos sin error',
                    accentColor: PdfColors.blueGrey800,
                    backgroundColor: PdfColors.grey100,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Tabla de Auditoría de Turnos
            ReportPdfHelper.buildSectionTitle(
              'Historial de Turnos y Arqueos de Caja',
              subtitle: 'Listado detallado cronológico con desglose de conteo y balance',
            ),
            if (displayedShifts.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  discrepanciesOnly
                      ? '¡Excelente! No se registraron descuadres en los turnos del período seleccionado.'
                      : 'No se encontraron turnos cerrados en el período indicado.',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.8), // #
                  1: const pw.FlexColumnWidth(2.6), // Cajero
                  2: const pw.FlexColumnWidth(2.2), // Apertura
                  3: const pw.FlexColumnWidth(2.2), // Cierre
                  4: const pw.FlexColumnWidth(1.6), // Fondo Ini
                  5: const pw.FlexColumnWidth(1.6), // Efectivo Sist
                  6: const pw.FlexColumnWidth(1.6), // Declarado
                  7: const pw.FlexColumnWidth(1.8), // Descuadre
                  8: const pw.FlexColumnWidth(2.4), // Notas
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                    children: [
                      ReportPdfHelper.buildTableHeaderCell('#', align: pw.TextAlign.center),
                      ReportPdfHelper.buildTableHeaderCell('CAJERO / OPERADOR'),
                      ReportPdfHelper.buildTableHeaderCell('APERTURA'),
                      ReportPdfHelper.buildTableHeaderCell('CIERRE'),
                      ReportPdfHelper.buildTableHeaderCell('FONDO INI', align: pw.TextAlign.right),
                      ReportPdfHelper.buildTableHeaderCell('EFEC. SIST', align: pw.TextAlign.right),
                      ReportPdfHelper.buildTableHeaderCell('DECLARADO', align: pw.TextAlign.right),
                      ReportPdfHelper.buildTableHeaderCell('DESCUADRE', align: pw.TextAlign.right),
                      ReportPdfHelper.buildTableHeaderCell('NOTAS'),
                    ],
                  ),
                  ...displayedShifts.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final s = entry.value;
                    final isEven = (entry.key % 2) == 0;
                    final rowBg = isEven ? PdfColors.white : PdfColors.grey50;

                    final openDt = DateTime.fromMillisecondsSinceEpoch(s.openedAt);
                    final closeDt = s.closedAt != null
                        ? DateTime.fromMillisecondsSinceEpoch(s.closedAt!)
                        : null;

                    final diff = s.difference ?? 0;
                    final isMismatch = diff != 0;
                    final diffColor = diff > 0
                        ? PdfColors.teal800
                        : (diff < 0 ? PdfColors.red800 : PdfColors.grey700);

                    final diffText = diff > 0
                        ? '+${ReportPdfHelper.formatCurrency(diff)}'
                        : (diff < 0 ? ReportPdfHelper.formatCurrency(diff) : '\$0.00');

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: rowBg),
                      children: [
                        ReportPdfHelper.buildTableCell('$idx', align: pw.TextAlign.center),
                        ReportPdfHelper.buildTableCell(s.userName.isNotEmpty ? s.userName : 'Usuario #${s.userId}', isBold: true),
                        ReportPdfHelper.buildTableCell(ReportPdfHelper.formatDateTime(openDt), fontSize: 7),
                        ReportPdfHelper.buildTableCell(closeDt != null ? ReportPdfHelper.formatDateTime(closeDt) : 'Abierto', fontSize: 7),
                        ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(s.initialBalance), align: pw.TextAlign.right),
                        ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(s.cashBalance), align: pw.TextAlign.right),
                        ReportPdfHelper.buildTableCell(
                          s.declaredCash != null
                              ? ReportPdfHelper.formatCurrency(s.declaredCash!)
                              : '-',
                          align: pw.TextAlign.right,
                        ),
                        ReportPdfHelper.buildTableCell(
                          diffText,
                          align: pw.TextAlign.right,
                          isBold: isMismatch,
                          textColor: diffColor,
                        ),
                        ReportPdfHelper.buildTableCell(
                          s.notes.isNotEmpty ? s.notes : '-',
                          fontSize: 7,
                        ),
                      ],
                    );
                  }),
                ],
              ),
          ];
        },
      ),
    );

    return doc;
  }
}
