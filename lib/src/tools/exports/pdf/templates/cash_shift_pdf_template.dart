import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:serum_business/serum_business.dart';

import '../../../../tools/cache/app_image_cache.dart';

import '../pdf_font_helper.dart';
import '../pdf_template.dart';

/// Plantilla PDF oficial para Comprobante de Turno de Caja y Arqueo Contable.
/// Diseñada bajo filosofía Ink-Saver (ahorro de tinta y cero saturación de color sólido)
/// e integración de marca (Logo o IsoLogo de la sucursal).
class CashShiftPdfTemplate implements PdfTemplate {
  final CashShiftInDb shift;
  final BranchInDb branch;
  final List<CashMovementInDb> movements;
  final PdfPageFormat pageFormat;

  CashShiftPdfTemplate({
    required this.shift,
    required this.branch,
    this.movements = const [],
    PdfPageFormat? pageFormat,
  }) : pageFormat = pageFormat ?? PdfPageFormat.a4;

  String _formatDateTime(int? timestamp) {
    if (timestamp == null || timestamp <= 0) return '—';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/${dt.year} $hour:$minute';
  }

  String _formatTimeOnly(int? timestamp) {
    if (timestamp == null || timestamp <= 0) return '—';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatMoney(int cents) {
    return NumberFormatter.convertToMoneyLike(cents);
  }

  String _formatDiffText(int diffCents) {
    if (diffCents == 0) return 'Exacto (\$0.00)';
    final sign = diffCents > 0 ? '+' : '-';
    final absVal = (diffCents.abs() / 100.0).toStringAsFixed(2);
    return '$sign\$$absVal';
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
      case 'efectivo':
        return 'Efectivo';
      case 'card':
      case 'tarjeta':
        return 'Tarjeta';
      case 'transfer':
      case 'transferencia':
        return 'Transferencia';
      default:
        return method;
    }
  }

  @override
  Future<pw.Document> buildDocument() async {
    await PdfFontHelper.ensureInitialized();
    final doc = pw.Document();

    final isIsoLogo = branch.isoLogoUrl != null && branch.isoLogoUrl!.isNotEmpty;
    final headerImageUrl = branch.effectiveIsoLogo;
    pw.MemoryImage? headerImage;

    if (headerImageUrl != null && headerImageUrl.isNotEmpty) {
      final bytes = await AppImageCache.getImageBytes(headerImageUrl);
      if (bytes != null) {
        headerImage = pw.MemoryImage(bytes);
      }
    }

    _buildStandardDocument(doc, headerImage, isIsoLogo);

    return doc;
  }

  // ==========================================
  // FORMATO A4 / CARTA (INK-SAVER OFICIAL)
  // ==========================================
  void _buildStandardDocument(
    pw.Document doc,
    pw.MemoryImage? headerImage,
    bool isIsoLogo,
  ) {
    final shortId = shift.id.length >= 8 ? shift.id.substring(0, 8).toUpperCase() : shift.id.toUpperCase();
    final isOpen = shift.isOpen;
    final now = DateTime.now();

    final diff = shift.difference ?? 0;

    // Métricas de movimientos
    final incomeMovements = movements.where((m) => m.isIncome && !m.isDeleted).toList();
    final expenseMovements = movements.where((m) => !m.isIncome && !m.isDeleted).toList();
    final totalIncomesCents = incomeMovements.fold<int>(0, (sum, m) => sum + m.amount);
    final totalExpensesCents = expenseMovements.fold<int>(0, (sum, m) => sum + m.amount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Identidad Institucional / Marca con Logo o IsoLogo
                pw.Expanded(
                  flex: 6,
                  child: isIsoLogo && headerImage != null
                      ? pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              height: 48,
                              margin: const pw.EdgeInsets.only(bottom: 5),
                              child: pw.Image(headerImage, fit: pw.BoxFit.contain),
                            ),
                            if (branch.address.isNotEmpty)
                              pw.Text(
                                branch.address,
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
                                width: 48,
                                height: 48,
                                margin: const pw.EdgeInsets.only(right: 12),
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
                                      color: PdfColors.black,
                                    ),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    'Laboratorio Clínico y Diagnóstico Especializado',
                                    style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                                  ),
                                  if (branch.address.isNotEmpty)
                                    pw.Text(
                                      branch.address,
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
                              ),
                            ),
                          ],
                        ),
                ),
                // Folio y Estado de Arqueo (Ink-Saver: Borde fino sin plasta de color)
                pw.Expanded(
                  flex: 4,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: null,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                          border: pw.Border.all(
                            color: isOpen ? PdfColors.grey700 : PdfColors.black,
                            width: 0.8,
                          ),
                        ),
                        child: pw.Text(
                          isOpen ? 'TURNO EN CURSO' : 'CORTE Y ARQUEO FINAL',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'TURNO #$shortId',
                        style: pw.TextStyle(
                          fontSize: 11.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Text(
                        'Emisión: ${_formatDateTime(now.millisecondsSinceEpoch)}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Comprobante contable de turno y arqueo de caja • Serum LIS',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          final custodianName = shift.userName?.isNotEmpty == true
              ? shift.userName!
              : (shift.userId.isNotEmpty ? shift.userId : 'Operador');

          final branchName = shift.branchName?.isNotEmpty == true
              ? shift.branchName!
              : branch.name;

          return [
            pw.Divider(color: PdfColors.grey800, thickness: 0.8),
            pw.SizedBox(height: 6),

            // 1. Ficha de Datos del Turno (Ink-Saver: Borde sutil, fondo blanco)
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: null,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                border: pw.Border.all(color: PdfColors.grey400, width: 0.6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetaItem('Custodio / Cajero', custodianName),
                  _buildMetaItem('Sucursal', branchName),
                  _buildMetaItem('Apertura', _formatDateTime(shift.openedAt)),
                  _buildMetaItem('Cierre', isOpen ? 'Activo (En curso)' : _formatDateTime(shift.closedAt)),
                  _buildMetaItem('Estado', isOpen ? 'ABIERTO' : 'CERRADO', isBold: true),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // 2. Resumen Financiero y Cuadre de Saldos (Ink-Saver: Cero fondos de color)
            pw.Text(
              '1. BALANCE GENERAL Y FONDOS DE CAJA',
              style: pw.TextStyle(
                fontSize: 10.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 5),

            pw.Table(
              border: const pw.TableBorder(
                top: pw.BorderSide(color: PdfColors.grey800, width: 0.8),
                bottom: pw.BorderSide(color: PdfColors.grey800, width: 0.8),
                horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey800, width: 0.8)),
                  ),
                  children: [
                    _tableHeaderCell('Concepto / Rubro'),
                    _tableHeaderCell('Método / Destino'),
                    _tableHeaderCell('Monto', align: pw.TextAlign.right),
                  ],
                ),
                _tableRowCell('Fondo Inicial de Caja (Apertura)', 'Efectivo', _formatMoney(shift.initialBalance)),
                _tableRowCell('Cobros en Efectivo (Ventas / Abonos)', 'Efectivo', _formatMoney(shift.cashBalance)),
                _tableRowCell('Cobros con Tarjeta Bancaria', 'Terminal / Tarjeta', _formatMoney(shift.cardBalance)),
                _tableRowCell('Cobros por Transferencia Electrónica', 'Banco / Transferencia', _formatMoney(shift.transferBalance)),
                if (shift.bankTransfers.isNotEmpty)
                  _tableRowCell(
                    '   └─ Desglose por Banco',
                    shift.bankTransfers.entries
                        .map((e) => '${e.key}: ${_formatMoney(e.value)}')
                        .join(' | '),
                    '',
                  ),
                if (totalIncomesCents > 0)
                  _tableRowCell('Entradas Libres Extraordinarias', 'Caja Chica', '+${_formatMoney(totalIncomesCents)}'),
                if (totalExpensesCents > 0)
                  _tableRowCell('Egresos / Gastos Menores Autorizados', 'Caja Chica', '-${_formatMoney(totalExpensesCents)}'),
                // Total Efectivo en Gaveta
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: PdfColors.grey600, width: 0.6)),
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5.5),
                      child: pw.Text(
                        'Total Efectivo Esperado en Gaveta',
                        style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5.5),
                      child: pw.Text('Fondo Inicial + Efectivo Cobrado', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5.5),
                      child: pw.Text(
                        _formatMoney(shift.initialBalance + shift.cashBalance),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                      ),
                    ),
                  ],
                ),
                // Total General del Turno
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: PdfColors.grey800, width: 0.8)),
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5.5),
                      child: pw.Text(
                        'Total General del Turno (Todos los Métodos)',
                        style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5.5),
                      child: pw.Text('Efectivo + Tarjeta + Transferencia', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5.5),
                      child: pw.Text(
                        _formatMoney(shift.totalBalance),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // 2. Sección de Arqueo Contable (Cierre) - Ink-Saver: Sin bloques saturados
            pw.Text(
              '2. RESULTADO DEL ARQUEO FÍSICO DE CAJA',
              style: pw.TextStyle(
                fontSize: 10.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 5),

            if (!isOpen && shift.declaredCash != null)
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: null,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: PdfColors.grey700, width: 0.8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Efectivo Contado y Declarado por el Cajero: ${_formatMoney(shift.declaredCash!)}',
                          style: pw.TextStyle(
                            fontSize: 10.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Efectivo Teórico Esperado en Gaveta: ${_formatMoney(shift.initialBalance + shift.cashBalance)}',
                          style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: null,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        border: pw.Border.all(color: PdfColors.grey800, width: 0.8),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'Diferencia',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            _formatDiffText(diff),
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: null,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.6),
                ),
                child: pw.Text(
                  'El turno continúa abierto. Este documento representa un corte parcial/informativo previo a la declaración física de efectivo.',
                  style: const pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                ),
              ),
            pw.SizedBox(height: 12),

            // 3. Detalle de Movimientos Libres de Caja (Ink-Saver)
            if (movements.isNotEmpty) ...[
              pw.Text(
                '3. MOVIMIENTOS EXTRAORDINARIOS DE CAJA (${movements.length})',
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Table(
                border: const pw.TableBorder(
                  top: pw.BorderSide(color: PdfColors.grey700, width: 0.8),
                  bottom: pw.BorderSide(color: PdfColors.grey700, width: 0.8),
                  horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey700, width: 0.8)),
                    ),
                    children: [
                      _tableHeaderCell('Hora'),
                      _tableHeaderCell('Tipo'),
                      _tableHeaderCell('Método'),
                      _tableHeaderCell('Concepto / Motivo'),
                      _tableHeaderCell('Monto', align: pw.TextAlign.right),
                    ],
                  ),
                  ...movements.where((m) => !m.isDeleted).map((m) {
                    final isInc = m.isIncome;
                    return pw.TableRow(
                      children: [
                        _tableDataCell(_formatTimeOnly(m.createdAt), fontSize: 9),
                        _tableDataCell(isInc ? 'Ingreso' : 'Egreso', isBold: true, fontSize: 9.5),
                        _tableDataCell(_formatPaymentMethod(m.paymentMethod), fontSize: 9.5),
                        _tableDataCell(m.concept, fontSize: 9.5),
                        _tableDataCell(
                          '${isInc ? '+' : '-'}${_formatMoney(m.amount)}',
                          align: pw.TextAlign.right,
                          isBold: true,
                          fontSize: 10,
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 12),
            ],

            // 4. Observaciones / Notas (Ink-Saver)
            if (shift.notes.isNotEmpty) ...[
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  color: null,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'NOTAS / OBSERVACIONES:',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      shift.notes,
                      style: const pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic, color: PdfColors.grey800),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
            ],

            pw.Spacer(),

            // 6. Firmas de Conformidad
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 170, height: 0.8, color: PdfColors.grey700),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Entregué Conforme',
                      style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                    ),
                    pw.Text(
                      custodianName,
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                    pw.Text('Cajero / Custodio', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 170, height: 0.8, color: PdfColors.grey700),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Recibí y Audité Conforme',
                      style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                    ),
                    pw.Text('Firma Autorizada', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.Text('Supervisor / Administración', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
          ];
        },
      ),
    );
  }

  // ==========================================
  // HELPERS DE RENDERIZADO
  // ==========================================
  pw.Widget _buildMetaItem(String label, String value, {bool isBold = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 1.5),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }

  pw.TableRow _tableRowCell(String concept, String method, String amount) {
    return pw.TableRow(
      children: [
        _tableDataCell(concept, fontSize: 9.5),
        _tableDataCell(method, fontSize: 9.5),
        _tableDataCell(amount, align: pw.TextAlign.right, isBold: true, fontSize: 10),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    double fontSize = 10,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5.5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _tableDataCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
    double fontSize = 9.5,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
      ),
    );
  }
}
