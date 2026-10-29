import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:serum_business/serum_business.dart';
import '../../../../tools/cache/app_image_cache.dart';
import '../pdf_font_helper.dart';
import '../pdf_template.dart';

/// Plantilla PDF oficial para comprobantes de pago y recibos de caja.
class ReceiptPdfTemplate implements PdfTemplate {
  final ReceiptInDb receipt;
  final BranchInDb branch;
  final OrderInDb? order;
  final PdfPageFormat pageFormat;

  ReceiptPdfTemplate({
    required this.receipt,
    required this.branch,
    this.order,
    PdfPageFormat? pageFormat,
  }) : pageFormat = pageFormat ??
            PdfPageFormat(
              8.5 * PdfPageFormat.inch,
              5.5 * PdfPageFormat.inch,
              marginTop: 20,
              marginBottom: 20,
              marginLeft: 28,
              marginRight: 28,
            );

  @override
  Future<pw.Document> buildDocument() async {
    await PdfFontHelper.ensureInitialized();
    final doc = pw.Document();

    pw.MemoryImage? headerImage;
    final isIsoLogo = branch.isoLogoUrl != null && branch.isoLogoUrl!.isNotEmpty;
    final headerImageUrl = branch.effectiveIsoLogo;

    if (headerImageUrl != null && headerImageUrl.isNotEmpty) {
      final bytes = await AppImageCache.getImageBytes(headerImageUrl);
      if (bytes != null) {
        headerImage = pw.MemoryImage(bytes);
      }
    }

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. Encabezado institucional y folio
              _buildHeader(headerImage, isIsoLogo),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.blueGrey800, thickness: 1.2),
              pw.SizedBox(height: 8),

              // 2. Información del Paciente y Referencia de Orden
              _buildPatientAndOrderInfo(),
              pw.SizedBox(height: 10),

              // 3. Desglose del Pago (Monto, Método y Concepto)
              _buildPaymentBreakdown(),
              pw.SizedBox(height: 10),

              // 4. Estado de Cuenta de la Orden (si está disponible)
              if (order != null) ...[
                _buildOrderBalancesTable(),
                pw.SizedBox(height: 10),
              ],

              pw.Spacer(),

              // 5. Pie de comprobante con operador, turno y firmas
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return doc;
  }

  pw.Widget _buildHeader(pw.MemoryImage? headerImage, bool isIsoLogo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Datos de la sucursal / Marca
        pw.Expanded(
          flex: 6,
          child: isIsoLogo && headerImage != null
              ? pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      height: 52,
                      margin: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Image(headerImage, fit: pw.BoxFit.contain),
                    ),
                    if (branch.address.isNotEmpty)
                      pw.Text(
                        'Dirección: ${branch.address}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    pw.Row(
                      children: [
                        if (branch.phone.isNotEmpty)
                          pw.Text(
                            'Tel: ${branch.phone}',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                          ),
                        if (branch.phone.isNotEmpty &&
                            branch.email != null &&
                            branch.email!.isNotEmpty)
                          pw.Text(
                            ' | ',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                          ),
                        if (branch.email != null && branch.email!.isNotEmpty)
                          pw.Text(
                            'Email: ${branch.email!}',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                          ),
                      ],
                    ),
                  ],
                )
              : pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (headerImage != null)
                      pw.Container(
                        width: 55,
                        height: 55,
                        margin: const pw.EdgeInsets.only(right: 10),
                        child: pw.Image(headerImage, fit: pw.BoxFit.contain),
                      ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            branch.name.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Laboratorio Clínico y Diagnóstico Especializado',
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                          ),
                          if (branch.address.isNotEmpty)
                            pw.Text(
                              'Dirección: ${branch.address}',
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                            ),
                          if (branch.phone.isNotEmpty)
                            pw.Text(
                              'Teléfono: ${branch.phone}',
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        // Badge de Comprobante y Folio
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: PdfColors.green700, width: 0.8),
                ),
                child: pw.Text(
                  'COMPROBANTE DE PAGO / RECIBO',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green900,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Folio: #${receipt.receiptNumber}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.Text(
                'Fecha: ${receipt.formattedDate}',
                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPatientAndOrderInfo() {
    final patientDisplayName = receipt.patientName?.trim().isNotEmpty == true
        ? receipt.patientName!.trim()
        : (order?.patientInfo?.name.trim().isNotEmpty == true
            ? order!.patientInfo!.name.trim()
            : 'Público General');

    final orderRef = receipt.orderNumber?.isNotEmpty == true
        ? 'Orden #${receipt.orderNumber}'
        : 'Orden #${receipt.orderId}';

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 6,
            child: pw.Row(
              children: [
                pw.Text(
                  'Paciente: ',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    patientDisplayName,
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                    overflow: pw.TextOverflow.clip,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            flex: 4,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Referencia: ',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
                pw.Text(
                  orderRef,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentBreakdown() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Concepto y método
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      'Concepto: ',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        receipt.concept,
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text(
                      'Método de Pago: ',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: pw.BoxDecoration(
                        color: _getMethodColorBg(receipt.paymentMethod),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                      child: pw.Text(
                        receipt.paymentMethodLabel.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: _getMethodColorFg(receipt.paymentMethod),
                        ),
                      ),
                    ),
                  ],
                ),
                if (receipt.paymentMethod.toLowerCase() == 'transfer' &&
                    ((receipt.bank != null && receipt.bank!.isNotEmpty) ||
                        (receipt.referenceNumber != null &&
                            receipt.referenceNumber!.isNotEmpty))) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(
                    children: [
                      pw.Text(
                        'Detalle Bancario: ',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        [
                          if (receipt.bank != null && receipt.bank!.isNotEmpty)
                            'Banco: ${receipt.bank!}',
                          if (receipt.referenceNumber != null &&
                              receipt.referenceNumber!.isNotEmpty)
                            'Ref: ${receipt.referenceNumber!}',
                        ].join(' | '),
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.purple900,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          pw.Container(
            height: 34,
            width: 1,
            color: PdfColors.grey300,
            margin: const pw.EdgeInsets.symmetric(horizontal: 10),
          ),
          // Monto recibido
          pw.Expanded(
            flex: 4,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'MONTO RECIBIDO',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  receipt.formattedAmount,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildOrderBalancesTable() {
    final totalOrder = order!.totalPrice > 0 ? order!.totalPrice : order!.salePriceApplied;
    final totalPaid = order!.paidAmount;
    final currentRemaining = max(0, totalOrder - totalPaid);
    final previousBalance = currentRemaining + receipt.amount;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColors.blue200, width: 0.8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildBalanceCol('Total de la Orden', NumberFormatter.convertToMoneyLike(totalOrder)),
          _buildBalanceCol('Saldo Anterior', NumberFormatter.convertToMoneyLike(previousBalance)),
          _buildBalanceCol('Abono en este Recibo', receipt.formattedAmount, isHighlight: true),
          _buildBalanceCol('Saldo Pendiente Actual', NumberFormatter.convertToMoneyLike(currentRemaining),
              isPending: currentRemaining > 0),
        ],
      ),
    );
  }

  pw.Widget _buildBalanceCol(String label, String value,
      {bool isHighlight = false, bool isPending = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: isHighlight
                ? PdfColors.green900
                : (isPending ? PdfColors.red800 : PdfColors.blueGrey900),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    final shiftText = receipt.shiftId != null ? 'Turno #${receipt.shiftId}' : 'Turno General';

    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            // Operador y turno
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Cajero / Operador: ${receipt.performedBy.name}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.Text(
                  'Operación: $shiftText',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '¡Gracias por su confianza! Conserve este comprobante para aclaraciones.',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            // Firma y sello
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 140,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 0.8)),
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Firma y Sello de Caja',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Serum LIS • Sistema de Laboratorio Clínico',
            style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey500),
          ),
        ),
      ],
    );
  }

  PdfColor _getMethodColorBg(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return PdfColors.blue100;
      case 'transfer':
        return PdfColors.purple100;
      case 'cash':
      default:
        return PdfColors.green100;
    }
  }

  PdfColor _getMethodColorFg(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return PdfColors.blue900;
      case 'transfer':
        return PdfColors.purple900;
      case 'cash':
      default:
        return PdfColors.green900;
    }
  }
}
