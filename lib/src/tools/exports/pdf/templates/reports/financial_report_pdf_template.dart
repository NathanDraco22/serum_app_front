import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:serum_business/serum_business.dart';

import '../../pdf_template.dart';
import 'report_pdf_base.dart';

/// Plantilla de exportación a PDF para el Reporte Financiero y de Cobranza.
class FinancialReportPdfTemplate implements PdfTemplate {
  final FinancialReportResponse report;
  final String branchName;
  final String? branchAddress;
  final String? branchPhone;
  final String? generatedBy;

  FinancialReportPdfTemplate({
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
              reportTitle: 'Reporte Financiero y Cobranza',
              subtitle: 'Flujo de facturación, ingresos en Kardex y cartera insoluta',
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
          final methods = summary.paymentMethods;
          final totalCollected = summary.totalCollected;

          // Cálculo de porcentajes de métodos de pago
          final cashPct = totalCollected > 0
              ? (methods.cash / totalCollected * 100).toStringAsFixed(1)
              : '0.0';
          final cardPct = totalCollected > 0
              ? (methods.card / totalCollected * 100).toStringAsFixed(1)
              : '0.0';
          final transferPct = totalCollected > 0
              ? (methods.transfer / totalCollected * 100).toStringAsFixed(1)
              : '0.0';

          return [
            // Resumen de Métricas / KPIs Principales
            pw.Row(
              children: [
                pw.Expanded(
                  child: ReportPdfHelper.buildKpiCard(
                    label: 'Total Facturado',
                    value: ReportPdfHelper.formatCurrency(summary.totalBilled),
                    subtitle: '${summary.ordersCount} órdenes creadas',
                    accentColor: PdfColors.blue800,
                    backgroundColor: PdfColors.blue50,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: ReportPdfHelper.buildKpiCard(
                    label: 'Total Cobrado',
                    value: ReportPdfHelper.formatCurrency(summary.totalCollected),
                    subtitle: '${summary.transactionsCount} cobros Kardex',
                    accentColor: PdfColors.teal800,
                    backgroundColor: PdfColors.teal50,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: ReportPdfHelper.buildKpiCard(
                    label: 'Por Cobrar',
                    value: ReportPdfHelper.formatCurrency(summary.pendingReceivables),
                    subtitle: 'Cartera pendiente',
                    accentColor: PdfColors.amber900,
                    backgroundColor: PdfColors.amber50,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Desglose de Cobranza por Método de Pago
            ReportPdfHelper.buildSectionTitle(
              'Desglose de Cobranza por Método de Pago',
              subtitle: 'Distribución porcentual de los ingresos registrados en el Kardex',
            ),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                  children: [
                    ReportPdfHelper.buildTableHeaderCell('MÉTODO DE PAGO', align: pw.TextAlign.left),
                    ReportPdfHelper.buildTableHeaderCell('MONTO COBRADO', align: pw.TextAlign.right),
                    ReportPdfHelper.buildTableHeaderCell('PARTICIPACIÓN', align: pw.TextAlign.right),
                  ],
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.white),
                  children: [
                    ReportPdfHelper.buildTableCell('Efectivo (Cash)'),
                    ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(methods.cash), align: pw.TextAlign.right),
                    ReportPdfHelper.buildTableCell('$cashPct%', align: pw.TextAlign.right),
                  ],
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey50),
                  children: [
                    ReportPdfHelper.buildTableCell('Tarjeta de Débito / Crédito (Card)'),
                    ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(methods.card), align: pw.TextAlign.right),
                    ReportPdfHelper.buildTableCell('$cardPct%', align: pw.TextAlign.right),
                  ],
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.white),
                  children: [
                    ReportPdfHelper.buildTableCell('Transferencia / Depósito (Transfer)'),
                    ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(methods.transfer), align: pw.TextAlign.right),
                    ReportPdfHelper.buildTableCell('$transferPct%', align: pw.TextAlign.right),
                  ],
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    ReportPdfHelper.buildTableCell('TOTAL RECAUDADO', isBold: true),
                    ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(totalCollected), align: pw.TextAlign.right, isBold: true),
                    ReportPdfHelper.buildTableCell('100.0%', align: pw.TextAlign.right, isBold: true),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Desglose por Sucursal (si hay datos disponibles)
            if (report.byBranch.isNotEmpty) ...[
              ReportPdfHelper.buildSectionTitle(
                'Desglose Comparativo por Sucursal',
                subtitle: 'Rendimiento financiero y cobros segmentados por sede física',
              ),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3.0), // Sucursal
                  1: const pw.FlexColumnWidth(1.8), // Facturado
                  2: const pw.FlexColumnWidth(1.8), // Cobrado
                  3: const pw.FlexColumnWidth(1.8), // Pendiente
                  4: const pw.FlexColumnWidth(1.2), // Órdenes
                  5: const pw.FlexColumnWidth(1.5), // Efectivo
                  6: const pw.FlexColumnWidth(1.5), // Tarjeta
                  7: const pw.FlexColumnWidth(1.5), // Transf.
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                    children: [
                      ReportPdfHelper.buildTableHeaderCell('SUCURSAL'),
                      ReportPdfHelper.buildTableHeaderCell('FACTURADO', align: pw.TextAlign.right),
                      ReportPdfHelper.buildTableHeaderCell('COBRADO', align: pw.TextAlign.right),
                      ReportPdfHelper.buildTableHeaderCell('POR COBRAR', align: pw.TextAlign.right),
                      ReportPdfHelper.buildTableHeaderCell('ÓRDENES', align: pw.TextAlign.center),
                      ReportPdfHelper.buildTableHeaderCell('EFECTIVO', align: pw.TextAlign.right),
                      ReportPdfHelper.buildTableHeaderCell('TARJETA', align: pw.TextAlign.right),
                      ReportPdfHelper.buildTableHeaderCell('TRANSF.', align: pw.TextAlign.right),
                    ],
                  ),
                  ...report.byBranch.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final b = entry.value;
                    final isEven = idx % 2 == 0;
                    final rowBg = isEven ? PdfColors.white : PdfColors.grey50;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: rowBg),
                      children: [
                        ReportPdfHelper.buildTableCell(b.branchName.isNotEmpty ? b.branchName : 'Sucursal #${b.branchId}'),
                        ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(b.totalBilled), align: pw.TextAlign.right),
                        ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(b.totalCollected), align: pw.TextAlign.right),
                        ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(b.pendingReceivables), align: pw.TextAlign.right),
                        ReportPdfHelper.buildTableCell('${b.ordersCount}', align: pw.TextAlign.center),
                        ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(b.paymentMethods.cash), align: pw.TextAlign.right),
                        ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(b.paymentMethods.card), align: pw.TextAlign.right),
                        ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(b.paymentMethods.transfer), align: pw.TextAlign.right),
                      ],
                    );
                  }),
                  // Fila de Totales
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      ReportPdfHelper.buildTableCell('TOTAL GENERAL', isBold: true),
                      ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(summary.totalBilled), align: pw.TextAlign.right, isBold: true),
                      ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(summary.totalCollected), align: pw.TextAlign.right, isBold: true),
                      ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(summary.pendingReceivables), align: pw.TextAlign.right, isBold: true),
                      ReportPdfHelper.buildTableCell('${summary.ordersCount}', align: pw.TextAlign.center, isBold: true),
                      ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(methods.cash), align: pw.TextAlign.right, isBold: true),
                      ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(methods.card), align: pw.TextAlign.right, isBold: true),
                      ReportPdfHelper.buildTableCell(ReportPdfHelper.formatCurrency(methods.transfer), align: pw.TextAlign.right, isBold: true),
                    ],
                  ),
                ],
              ),
            ],
          ];
        },
      ),
    );

    return doc;
  }
}
