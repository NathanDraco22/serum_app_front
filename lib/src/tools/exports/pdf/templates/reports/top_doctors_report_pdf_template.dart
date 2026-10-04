import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:serum_business/serum_business.dart';

import '../../pdf_template.dart';
import 'report_pdf_base.dart';

/// Plantilla de exportación a PDF para el Reporte de Médicos Referentes.
class TopDoctorsReportPdfTemplate implements PdfTemplate {
  final TopDoctorsReportResponse report;
  final String branchName;
  final String? branchAddress;
  final String? branchPhone;
  final String? generatedBy;

  TopDoctorsReportPdfTemplate({
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

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: ReportPdfHelper.buildHeader(
              reportTitle: 'Ranking de Médicos Referentes',
              subtitle: 'Análisis de derivación clínica, volumen de órdenes y facturación',
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
          final doctors = summary.topDoctors;
          final totalRev = summary.totalRevenue;
          final totalOrders = summary.totalOrders;
          final avgTicket = totalOrders > 0 ? (totalRev / totalOrders).round() : 0;

          return [
            // Resumen de Métricas / KPIs
            pw.Row(
              children: [
                pw.Expanded(
                  child: ReportPdfHelper.buildKpiCard(
                    label: 'Órdenes Referidas',
                    value: '$totalOrders',
                    subtitle: 'Total órdenes médicas',
                    accentColor: PdfColors.indigo800,
                    backgroundColor: PdfColors.indigo50,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: ReportPdfHelper.buildKpiCard(
                    label: 'Facturación Generada',
                    value: ReportPdfHelper.formatCurrency(totalRev),
                    subtitle: 'Ingresos por prescripción',
                    accentColor: PdfColors.teal800,
                    backgroundColor: PdfColors.teal50,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: ReportPdfHelper.buildKpiCard(
                    label: 'Médicos Activos',
                    value: '${doctors.length}',
                    subtitle: 'Prescriptores en período',
                    accentColor: PdfColors.blueGrey800,
                    backgroundColor: PdfColors.grey100,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: ReportPdfHelper.buildKpiCard(
                    label: 'Ticket Promedio',
                    value: ReportPdfHelper.formatCurrency(avgTicket),
                    subtitle: 'Por orden referida',
                    accentColor: PdfColors.deepOrange800,
                    backgroundColor: PdfColors.deepOrange50,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Tabla de Ranking de Médicos
            ReportPdfHelper.buildSectionTitle(
              'Ranking de Prescriptores Médicos',
              subtitle: 'Listado ordenado por volumen facturado de mayor a menor',
            ),
            if (doctors.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'No se encontraron órdenes ni derivaciones médicas en el período seleccionado.',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.8), // #
                  1: const pw.FlexColumnWidth(3.8), // Médico
                  2: const pw.FlexColumnWidth(2.4), // Especialidad
                  3: const pw.FlexColumnWidth(1.4), // Órdenes
                  4: const pw.FlexColumnWidth(2.0), // Facturación
                  5: const pw.FlexColumnWidth(1.4), // % Aporte
                  6: const pw.FlexColumnWidth(1.8), // Prom./Orden
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                    children: [
                      ReportPdfHelper.buildTableHeaderCell('#', align: pw.TextAlign.center),
                      ReportPdfHelper.buildTableHeaderCell('MÉDICO PRESCRIPTOR'),
                      ReportPdfHelper.buildTableHeaderCell('ESPECIALIDAD'),
                      ReportPdfHelper.buildTableHeaderCell('ÓRDENES', align: pw.TextAlign.center),
                      ReportPdfHelper.buildTableHeaderCell('FACTURADO', align: pw.TextAlign.right),
                      ReportPdfHelper.buildTableHeaderCell('% APORTE', align: pw.TextAlign.right),
                      ReportPdfHelper.buildTableHeaderCell('PROM/ORDEN', align: pw.TextAlign.right),
                    ],
                  ),
                  ...doctors.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final d = entry.value;
                    final isEven = (entry.key % 2) == 0;
                    final rowBg = isEven ? PdfColors.white : PdfColors.grey50;

                    final pct = totalRev > 0
                        ? (d.totalRevenue / totalRev * 100).toStringAsFixed(1)
                        : '0.0';
                    final docAvg = d.totalOrders > 0
                        ? (d.totalRevenue / d.totalOrders).round()
                        : 0;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: rowBg),
                      children: [
                        ReportPdfHelper.buildTableCell('$idx', align: pw.TextAlign.center, isBold: idx <= 3),
                        ReportPdfHelper.buildTableCell(d.doctorName, isBold: idx <= 3),
                        ReportPdfHelper.buildTableCell(d.specialty.isNotEmpty ? d.specialty : 'General / Particular'),
                        ReportPdfHelper.buildTableCell('${d.totalOrders}', align: pw.TextAlign.center),
                        ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(d.totalRevenue), align: pw.TextAlign.right),
                        ReportPdfHelper.buildTableCell('$pct%', align: pw.TextAlign.right),
                        ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(docAvg), align: pw.TextAlign.right),
                      ],
                    );
                  }),
                  // Fila de Totales
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      ReportPdfHelper.buildTableCell('', align: pw.TextAlign.center),
                      ReportPdfHelper.buildTableCell('TOTAL GENERAL', isBold: true),
                      ReportPdfHelper.buildTableCell('', isBold: true),
                      ReportPdfHelper.buildTableCell('$totalOrders', align: pw.TextAlign.center, isBold: true),
                      ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(totalRev), align: pw.TextAlign.right, isBold: true),
                      ReportPdfHelper.buildTableCell('100.0%', align: pw.TextAlign.right, isBold: true),
                      ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(avgTicket), align: pw.TextAlign.right, isBold: true),
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
