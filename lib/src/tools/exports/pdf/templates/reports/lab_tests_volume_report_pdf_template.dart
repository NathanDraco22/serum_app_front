import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:serum_business/serum_business.dart';

import '../../pdf_template.dart';
import 'report_pdf_base.dart';

/// Plantilla de exportación a PDF para el Reporte de Demanda de Pruebas Clínicas y Packs.
class LabTestsVolumeReportPdfTemplate implements PdfTemplate {
  final LabTestsVolumeReportResponse report;
  final String branchName;
  final String? branchAddress;
  final String? branchPhone;
  final String? generatedBy;

  LabTestsVolumeReportPdfTemplate({
    required this.report,
    required this.branchName,
    this.branchAddress,
    this.branchPhone,
    this.generatedBy,
  });

  @override
  Future<pw.Document> buildDocument() async {
    final doc = pw.Document();

    final startDate = DateTime.fromMillisecondsSinceEpoch(report.startDate);
    final endDate = DateTime.fromMillisecondsSinceEpoch(report.endDate);
    final isQuotations = report.source == 'quotations';
    final sourceLabel = isQuotations ? 'Cotizaciones / Presupuestos' : 'Órdenes Clínicas';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: ReportPdfHelper.buildHeader(
              reportTitle: 'Demanda de Pruebas y Packs',
              subtitle: 'Análisis de frecuencia y recaudación por catálogo ($sourceLabel)',
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
          final tests = summary.topTests;
          final totalCount = summary.totalTestsCount;
          final totalRev = summary.totalRevenue;

          final packsCount = tests.where((t) => t.isPack).fold<int>(0, (acc, t) => acc + t.timesOrdered);
          final singlesCount = tests.where((t) => !t.isPack).fold<int>(0, (acc, t) => acc + t.timesOrdered);

          return [
            // Resumen de Métricas / KPIs
            pw.Row(
              children: [
                pw.Expanded(
                  child: ReportPdfHelper.buildKpiCard(
                    label: 'Estudios Solicitados',
                    value: '$totalCount',
                    subtitle: 'Total de análisis y packs',
                    accentColor: PdfColors.blue800,
                    backgroundColor: PdfColors.blue50,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: ReportPdfHelper.buildKpiCard(
                    label: 'Recaudación Catálogo',
                    value: ReportPdfHelper.formatCurrency(totalRev),
                    subtitle: 'Ingresos generados',
                    accentColor: PdfColors.teal800,
                    backgroundColor: PdfColors.teal50,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: ReportPdfHelper.buildKpiCard(
                    label: 'Packs / Perfiles',
                    value: '$packsCount',
                    subtitle: 'Estudios compuestos',
                    accentColor: PdfColors.purple800,
                    backgroundColor: PdfColors.purple50,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: ReportPdfHelper.buildKpiCard(
                    label: 'Pruebas Individuales',
                    value: '$singlesCount',
                    subtitle: 'Análisis individuales',
                    accentColor: PdfColors.cyan800,
                    backgroundColor: PdfColors.cyan50,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Tabla de Demanda de Análisis
            ReportPdfHelper.buildSectionTitle(
              'Ranking de Demanda del Catálogo Clínico',
              subtitle: 'Listado ordenado por frecuencia de solicitud en $sourceLabel',
            ),
            if (tests.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'No se registraron estudios ni análisis solicitados en el período indicado.',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.8), // #
                  1: const pw.FlexColumnWidth(4.2), // Nombre
                  2: const pw.FlexColumnWidth(1.8), // Tipo
                  3: const pw.FlexColumnWidth(2.2), // Categoría
                  4: const pw.FlexColumnWidth(1.4), // Veces
                  5: const pw.FlexColumnWidth(1.4), // % Demanda
                  6: const pw.FlexColumnWidth(2.0), // Total
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                    children: [
                      ReportPdfHelper.buildTableHeaderCell('#', align: pw.TextAlign.center),
                      ReportPdfHelper.buildTableHeaderCell('ESTUDIO / PERFIL CLÍNICO'),
                      ReportPdfHelper.buildTableHeaderCell('TIPO', align: pw.TextAlign.center),
                      ReportPdfHelper.buildTableHeaderCell('CATEGORÍA'),
                      ReportPdfHelper.buildTableHeaderCell('VECES', align: pw.TextAlign.center),
                      ReportPdfHelper.buildTableHeaderCell('% DEMANDA', align: pw.TextAlign.right),
                      ReportPdfHelper.buildTableHeaderCell('TOTAL', align: pw.TextAlign.right),
                    ],
                  ),
                  ...tests.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final t = entry.value;
                    final isEven = (entry.key % 2) == 0;
                    final rowBg = isEven ? PdfColors.white : PdfColors.grey50;

                    final pct = totalCount > 0
                        ? (t.timesOrdered / totalCount * 100).toStringAsFixed(1)
                        : '0.0';

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: rowBg),
                      children: [
                        ReportPdfHelper.buildTableCell('$idx', align: pw.TextAlign.center, isBold: idx <= 3),
                        ReportPdfHelper.buildTableCell(t.name, isBold: idx <= 3),
                        ReportPdfHelper.buildTableCell(
                          t.isPack ? 'PACK / PERFIL' : 'INDIVIDUAL',
                          align: pw.TextAlign.center,
                          isBold: t.isPack,
                          textColor: t.isPack ? PdfColors.purple800 : PdfColors.grey800,
                        ),
                        ReportPdfHelper.buildTableCell(t.category.isNotEmpty ? t.category : 'General'),
                        ReportPdfHelper.buildTableCell('${t.timesOrdered}', align: pw.TextAlign.center),
                        ReportPdfHelper.buildTableCell('$pct%', align: pw.TextAlign.right),
                        ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(t.totalRevenue), align: pw.TextAlign.right),
                      ],
                    );
                  }),
                  // Fila de Totales
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      ReportPdfHelper.buildTableCell('', align: pw.TextAlign.center),
                      ReportPdfHelper.buildTableCell('TOTAL GENERAL', isBold: true),
                      ReportPdfHelper.buildTableCell('', align: pw.TextAlign.center),
                      ReportPdfHelper.buildTableCell('', isBold: true),
                      ReportPdfHelper.buildTableCell('$totalCount', align: pw.TextAlign.center, isBold: true),
                      ReportPdfHelper.buildTableCell('100.0%', align: pw.TextAlign.right, isBold: true),
                      ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(totalRev), align: pw.TextAlign.right, isBold: true),
                    ],
                  ),
                ],
              ),
          ];
        },
      ),
    );

    return doc;
  }
}
