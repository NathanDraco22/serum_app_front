import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:serum_business/serum_business.dart';

import '../../pdf_template.dart';
import 'report_pdf_base.dart';

/// Plantilla de exportación a PDF para el Reporte de Cuentas por Cobrar (Saldos Pendientes).
class PendingBalancesReportPdfTemplate implements PdfTemplate {
  final PendingBalancesReportResponse report;
  final String branchName;
  final String? branchAddress;
  final String? branchPhone;
  final String? generatedBy;

  PendingBalancesReportPdfTemplate({
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

    // Consolidar todas las órdenes pendientes (si viene por sucursales o en general)
    final allOrders = <PendingBalanceItem>[];
    for (final b in report.byBranch) {
      allOrders.addAll(b.orders);
    }
    // Ordenar por días de mora de mayor a menor
    allOrders.sort((a, b) => b.daysPending.compareTo(a.daysPending));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: ReportPdfHelper.buildHeader(
              reportTitle: 'Cuentas por Cobrar y Saldos Pendientes',
              subtitle: 'Control de órdenes clínicas con saldo deudor y antigüedad de mora',
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
          final totalPending = summary.totalPendingAmount;
          final totalOrders = summary.ordersCount;
          final avgPending = totalOrders > 0 ? (totalPending / totalOrders).round() : 0;

          // Órdenes críticas con más de 15 días de antigüedad
          final criticalCount = allOrders.where((o) => o.daysPending > 15).length;

          return [
            // Resumen de Métricas / KPIs
            pw.Row(
              children: [
                pw.Expanded(
                  child: ReportPdfHelper.buildKpiCard(
                    label: 'Total Cartera Insoluta',
                    value: ReportPdfHelper.formatCurrency(totalPending),
                    subtitle: 'Saldo deudor total',
                    accentColor: PdfColors.red800,
                    backgroundColor: PdfColors.red50,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: ReportPdfHelper.buildKpiCard(
                    label: 'Órdenes con Deuda',
                    value: '$totalOrders',
                    subtitle: 'Expedientes pendientes',
                    accentColor: PdfColors.amber900,
                    backgroundColor: PdfColors.amber50,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: ReportPdfHelper.buildKpiCard(
                    label: 'Deuda Promedio',
                    value: ReportPdfHelper.formatCurrency(avgPending),
                    subtitle: 'Por orden pendiente',
                    accentColor: PdfColors.blueGrey800,
                    backgroundColor: PdfColors.grey100,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: ReportPdfHelper.buildKpiCard(
                    label: 'Mora Alta (>15 Días)',
                    value: '$criticalCount',
                    subtitle: 'Órdenes críticas',
                    accentColor: PdfColors.deepOrange800,
                    backgroundColor: PdfColors.deepOrange50,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Tabla de Cuentas por Cobrar
            ReportPdfHelper.buildSectionTitle(
              'Padrón de Órdenes y Pacientes con Saldo Pendiente',
              subtitle: 'Listado detallado ordenado por mayor antigüedad de mora',
            ),
            if (allOrders.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  '¡Excelente! No existen órdenes con saldos pendientes en el período seleccionado.',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.teal800),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.8), // #
                  1: const pw.FlexColumnWidth(2.0), // Folio
                  2: const pw.FlexColumnWidth(1.8), // Fecha
                  3: const pw.FlexColumnWidth(3.4), // Paciente
                  4: const pw.FlexColumnWidth(2.0), // Teléfono
                  5: const pw.FlexColumnWidth(1.6), // Total
                  6: const pw.FlexColumnWidth(1.6), // Pagado
                  7: const pw.FlexColumnWidth(1.8), // Saldo
                  8: const pw.FlexColumnWidth(1.4), // Días
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                    children: [
                      ReportPdfHelper.buildTableHeaderCell('#', align: pw.TextAlign.center),
                      ReportPdfHelper.buildTableHeaderCell('FOLIO'),
                      ReportPdfHelper.buildTableHeaderCell('FECHA'),
                      ReportPdfHelper.buildTableHeaderCell('PACIENTE'),
                      ReportPdfHelper.buildTableHeaderCell('TELÉFONO'),
                      ReportPdfHelper.buildTableHeaderCell('TOTAL', align: pw.TextAlign.right),
                      ReportPdfHelper.buildTableHeaderCell('ABONADO', align: pw.TextAlign.right),
                      ReportPdfHelper.buildTableHeaderCell('SALDO', align: pw.TextAlign.right),
                      ReportPdfHelper.buildTableHeaderCell('MORA', align: pw.TextAlign.center),
                    ],
                  ),
                  ...allOrders.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final o = entry.value;
                    final isEven = (entry.key % 2) == 0;
                    final rowBg = isEven ? PdfColors.white : PdfColors.grey50;

                    final dateDt = DateTime.fromMillisecondsSinceEpoch(o.orderDate);
                    final folio = o.orderId.length > 8
                        ? o.orderId.substring(o.orderId.length - 8).toUpperCase()
                        : o.orderId.toUpperCase();

                    final isCritical = o.daysPending > 15;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: rowBg),
                      children: [
                        ReportPdfHelper.buildTableCell('$idx', align: pw.TextAlign.center),
                        ReportPdfHelper.buildTableCell(folio, isBold: true),
                        ReportPdfHelper.buildTableCell(ReportPdfHelper.formatDate(dateDt)),
                        ReportPdfHelper.buildTableCell(o.patientName, isBold: true),
                        ReportPdfHelper.buildTableCell(o.patientPhone.isNotEmpty ? o.patientPhone : '-'),
                        ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(o.totalPrice), align: pw.TextAlign.right),
                        ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(o.paidAmount), align: pw.TextAlign.right),
                        ReportPdfHelper.buildTableCell(
                          ReportPdfHelper.formatCurrency(o.pendingAmount),
                          align: pw.TextAlign.right,
                          isBold: true,
                          textColor: PdfColors.red800,
                        ),
                        ReportPdfHelper.buildTableCell(
                          '${o.daysPending} d',
                          align: pw.TextAlign.center,
                          isBold: isCritical,
                          textColor: isCritical ? PdfColors.deepOrange900 : PdfColors.grey800,
                        ),
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
                      ReportPdfHelper.buildTableCell('', align: pw.TextAlign.center),
                      ReportPdfHelper.buildTableCell('', align: pw.TextAlign.right),
                      ReportPdfHelper.buildTableCell('', align: pw.TextAlign.right),
                      ReportPdfHelper.buildTableCell(
                        ReportPdfHelper.formatCurrency(totalPending),
                        align: pw.TextAlign.right,
                        isBold: true,
                        textColor: PdfColors.red900,
                      ),
                      ReportPdfHelper.buildTableCell('', align: pw.TextAlign.center),
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
