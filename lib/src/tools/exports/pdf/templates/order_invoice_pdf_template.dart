import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:serum_business/serum_business.dart';
import '../../../../tools/cache/app_image_cache.dart';
import '../pdf_font_helper.dart';
import '../pdf_template.dart';

/// Plantilla PDF oficial para Comprobante de Factura de Orden Clínica.
/// Incluye desglose detallado de pruebas/perfiles, servicios adicionales y pagos/abonos.
class OrderInvoicePdfTemplate implements PdfTemplate {
  final OrderInDb order;
  final BranchInDb branch;
  final List<ReceiptInDb> receipts;
  final PatientInfo? patientInfo;
  final DoctorInfo? doctorInfo;
  final PdfPageFormat pageFormat;

  OrderInvoicePdfTemplate({
    required this.order,
    required this.branch,
    this.receipts = const [],
    PatientInfo? patientInfo,
    DoctorInfo? doctorInfo,
    PdfPageFormat? pageFormat,
  })  : patientInfo = patientInfo ?? order.patientInfo,
        doctorInfo = doctorInfo ?? order.doctorInfo,
        pageFormat = pageFormat ?? PdfPageFormat.a4;

  int _calculateAge(int birthDateMs) {
    if (birthDateMs <= 0) return 0;
    final birthDate = DateTime.fromMillisecondsSinceEpoch(birthDateMs);
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age >= 0 ? age : 0;
  }

  String _formatGender(String gender) {
    final g = gender.trim().toLowerCase();
    if (g == 'm' || g == 'male' || g == 'masculino') return 'Masculino';
    if (g == 'f' || g == 'female' || g == 'femenino') return 'Femenino';
    return gender;
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return 'Tarjeta';
      case 'transfer':
        return 'Transferencia';
      case 'cash':
      default:
        return 'Efectivo';
    }
  }

  @override
  Future<pw.Document> buildDocument() async {
    await PdfFontHelper.ensureInitialized();
    final doc = pw.Document();

    final orderDate = DateTime.fromMillisecondsSinceEpoch(order.createdAt);
    final formattedDate =
        '${DateTimeTool.formatddMMyy(orderDate)} ${DateTimeTool.formatHHmm(orderDate)}';

    final totalOrder = order.totalPrice > 0 ? order.totalPrice : order.salePriceApplied;
    final totalPaid = order.paidAmount;
    final remainingBalance = max(0, totalOrder - totalPaid);
    final isFullyPaid = totalOrder > 0 && totalPaid >= totalOrder;

    final isIsoLogo = branch.isoLogoUrl != null && branch.isoLogoUrl!.isNotEmpty;
    final headerImageUrl = branch.effectiveIsoLogo;
    pw.MemoryImage? headerImage;

    if (headerImageUrl != null && headerImageUrl.isNotEmpty) {
      final bytes = await AppImageCache.getImageBytes(headerImageUrl);
      if (bytes != null) {
        headerImage = pw.MemoryImage(bytes);
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 26),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: _buildHeader(
              formattedDate,
              isFullyPaid,
              remainingBalance,
              headerImage,
              isIsoLogo,
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Serum LIS - Sistema de Laboratorio Clínico y Diagnóstico',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.Divider(color: PdfColors.grey500, thickness: 0.8),
            pw.SizedBox(height: 6),

            // 1. Información del Paciente y Médico
            _buildPatientAndDoctorCard(),
            pw.SizedBox(height: 12),

            // 2. Tabla de Análisis Clínicos y Perfiles
            _buildClinicalItemsTable(),
            pw.SizedBox(height: 10),

            // 3. Tabla de Servicios Adicionales (si existen)
            if (order.services.isNotEmpty) ...[
              _buildServicesTable(),
              pw.SizedBox(height: 10),
            ],

            // 4. Totales de la Orden
            _buildTotalsSection(totalOrder),
            pw.SizedBox(height: 14),

            // 5. Historial de Pagos y Abonos
            _buildReceiptsBreakdown(totalOrder, totalPaid, remainingBalance, isFullyPaid),
            pw.SizedBox(height: 16),

            // 6. Firmas y Términos
            _buildSignatureAndNotes(),
          ];
        },
      ),
    );

    return doc;
  }

  pw.Widget _buildHeader(
    String formattedDate,
    bool isFullyPaid,
    int remainingBalance,
    pw.MemoryImage? headerImage,
    bool isIsoLogo,
  ) {
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
                      height: 70,
                      margin: const pw.EdgeInsets.only(bottom: 6),
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
                        width: 68,
                        height: 68,
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
        // Badge de Factura y Folio
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: null,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.grey800, width: 0.8),
                ),
                child: pw.Text(
                  'COMPROBANTE DE FACTURA',
                  style: pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'ORDEN #${order.id}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Fecha: $formattedDate',
                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 3),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: null,
                  borderRadius: pw.BorderRadius.circular(3),
                  border: pw.Border.all(
                    color: isFullyPaid
                        ? PdfColors.green700
                        : (order.paidAmount > 0 ? PdfColors.blue700 : PdfColors.amber700),
                    width: 0.8,
                  ),
                ),
                child: pw.Text(
                  isFullyPaid
                      ? 'PAGADA EN SU TOTALIDAD'
                      : (order.paidAmount > 0
                          ? 'ABONADA PARCIALMENTE'
                          : 'PENDIENTE DE PAGO'),
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: isFullyPaid
                        ? PdfColors.green900
                        : (order.paidAmount > 0 ? PdfColors.blue900 : PdfColors.amber900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPatientAndDoctorCard() {
    final patientName = patientInfo?.name ?? 'Paciente General';
    final cardId = patientInfo?.cardId ?? 'N/D';
    final age = patientInfo != null ? _calculateAge(patientInfo!.dateOfBirth) : 0;
    final gender = patientInfo != null ? _formatGender(patientInfo!.gender) : 'N/D';
    final phone = patientInfo?.phone.isNotEmpty == true ? patientInfo!.phone : 'N/D';

    final doctorName = doctorInfo?.name ?? 'No asignado / Consulta Externa';
    final doctorSpecialty = doctorInfo?.specialty ?? 'Medicina General';

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: null,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.grey400, width: 0.7),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Paciente
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DATOS DEL PACIENTE',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 3),
                _buildFieldRow('Nombre:', patientName, isBold: true),
                _buildFieldRow('Identificación / Cédula:', cardId),
                _buildFieldRow('Edad / Sexo:', '$age años  •  $gender'),
                _buildFieldRow('Teléfono:', phone),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          // Médico
          pw.Expanded(
            flex: 4,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'MÉDICO REMITENTE',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 3),
                _buildFieldRow('Doctor(a):', doctorName, isBold: true),
                _buildFieldRow('Especialidad:', doctorSpecialty),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFieldRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 82,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildClinicalItemsTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ANÁLISIS CLÍNICOS Y PERFILES',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.TableHelper.fromTextArray(
          border: const pw.TableBorder(
            top: pw.BorderSide(color: PdfColors.grey700, width: 0.8),
            bottom: pw.BorderSide(color: PdfColors.grey700, width: 0.8),
            horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
          ),
          headers: ['#', 'Descripción del Análisis / Perfil', 'Tipo', 'Precio'],
          headerStyle: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
          headerDecoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey700, width: 0.8)),
          ),
          headerAlignment: pw.Alignment.centerLeft,
          oddRowDecoration: const pw.BoxDecoration(),
          rowDecoration: const pw.BoxDecoration(),
          cellStyle: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(24),
            1: const pw.FlexColumnWidth(6),
            2: const pw.FlexColumnWidth(2.5),
            3: const pw.FlexColumnWidth(2.2),
          },
          cellAlignments: {
            0: pw.Alignment.center,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.centerRight,
          },
          data: List<List<dynamic>>.generate(order.items.length, (index) {
            final item = order.items[index];
            return [
              '${index + 1}',
              item.name,
              item.isPack ? 'Perfil / Pack' : 'Individual',
              NumberFormatter.convertToMoneyLike(item.salePriceApplied),
            ];
          }),
        ),
      ],
    );
  }

  pw.Widget _buildServicesTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'SERVICIOS ADICIONALES',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.TableHelper.fromTextArray(
          border: const pw.TableBorder(
            top: pw.BorderSide(color: PdfColors.grey700, width: 0.8),
            bottom: pw.BorderSide(color: PdfColors.grey700, width: 0.8),
            horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
          ),
          headers: ['#', 'Descripción del Servicio', 'Detalle', 'Precio'],
          headerStyle: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
          headerDecoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey700, width: 0.8)),
          ),
          headerAlignment: pw.Alignment.centerLeft,
          oddRowDecoration: const pw.BoxDecoration(),
          rowDecoration: const pw.BoxDecoration(),
          cellStyle: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(24),
            1: const pw.FlexColumnWidth(6),
            2: const pw.FlexColumnWidth(2.5),
            3: const pw.FlexColumnWidth(2.2),
          },
          cellAlignments: {
            0: pw.Alignment.center,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.centerRight,
          },
          data: List<List<dynamic>>.generate(order.services.length, (index) {
            final service = order.services[index];
            return [
              '${index + 1}',
              service.name,
              'Servicio complementario',
              NumberFormatter.convertToMoneyLike(service.price),
            ];
          }),
        ),
      ],
    );
  }

  pw.Widget _buildTotalsSection(int totalOrder) {
    final testsSum = order.items.fold<int>(0, (sum, i) => sum + i.salePriceApplied);
    final servicesSum = order.services.fold<int>(0, (sum, s) => sum + s.price);
    final discountsSum = order.discounts.fold<int>(0, (sum, d) => sum + d.appliedAmount);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 220,
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            color: null,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColors.grey400, width: 0.7),
          ),
          child: pw.Column(
            children: [
              if (order.services.isNotEmpty || order.discounts.isNotEmpty) ...[
                _buildTotalRow('Subtotal Análisis:', NumberFormatter.convertToMoneyLike(testsSum)),
                if (order.services.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  _buildTotalRow('Subtotal Servicios:', NumberFormatter.convertToMoneyLike(servicesSum)),
                ],
                if (order.discounts.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  _buildTotalRow(
                    'Descuentos:',
                    '- ${NumberFormatter.convertToMoneyLike(discountsSum)}',
                    color: PdfColors.red700,
                  ),
                ],
                pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              ],
              _buildTotalRow(
                'TOTAL DE LA ORDEN:',
                NumberFormatter.convertToMoneyLike(totalOrder),
                isBold: true,
                fontSize: 10.5,
                color: PdfColors.black,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTotalRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 8.5,
    PdfColor color = PdfColors.black,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildReceiptsBreakdown(
    int totalOrder,
    int totalPaid,
    int remainingBalance,
    bool isFullyPaid,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'HISTORIAL DE ABONOS Y COBROS',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
            pw.Text(
              'Recibos vinculados: ${receipts.length}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        if (receipts.isEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: null,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.grey400, width: 0.7),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'No se han registrado abonos ni pagos a la fecha.',
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                ),
                pw.Text(
                  'Saldo Pendiente: ${NumberFormatter.convertToMoneyLike(remainingBalance)}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
          )
        else ...[
          pw.TableHelper.fromTextArray(
            border: const pw.TableBorder(
              top: pw.BorderSide(color: PdfColors.grey700, width: 0.8),
              bottom: pw.BorderSide(color: PdfColors.grey700, width: 0.8),
              horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
            headers: ['Recibo #', 'Fecha', 'Método de Pago', 'Concepto', 'Monto Abonado'],
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
            headerDecoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey700, width: 0.8)),
            ),
            headerAlignment: pw.Alignment.centerLeft,
            oddRowDecoration: const pw.BoxDecoration(),
            rowDecoration: const pw.BoxDecoration(),
            cellStyle: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.8),
              1: const pw.FlexColumnWidth(2.2),
              2: const pw.FlexColumnWidth(2.0),
              3: const pw.FlexColumnWidth(3.5),
              4: const pw.FlexColumnWidth(2.2),
            },
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerRight,
            },
            data: receipts.map((r) {
              final rDate = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
              final rDateStr =
                  '${DateTimeTool.formatddMMyy(rDate)} ${DateTimeTool.formatHHmm(rDate)}';
              return [
                r.receiptNumber.isNotEmpty
                    ? r.receiptNumber
                    : '#${r.id.substring(max(0, r.id.length - 6))}',
                rDateStr,
                _formatPaymentMethod(r.paymentMethod),
                r.concept,
                r.formattedAmount,
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 6),
          // Resumen de saldos
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const pw.BoxDecoration(
              color: null,
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey400, width: 0.7),
                bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.7),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildBalanceMetric('Total de Orden', NumberFormatter.convertToMoneyLike(totalOrder)),
                _buildBalanceMetric('Total Abonado', NumberFormatter.convertToMoneyLike(totalPaid),
                    highlightColor: PdfColors.green900),
                _buildBalanceMetric(
                  'Saldo Pendiente',
                  NumberFormatter.convertToMoneyLike(remainingBalance),
                  highlightColor: remainingBalance > 0 ? PdfColors.red900 : PdfColors.black,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildBalanceMetric(String title, String value, {PdfColor? highlightColor}) {
    return pw.Column(
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: highlightColor ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSignatureAndNotes() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          flex: 6,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CONDICIONES GENERALES:',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '• Este documento certifica la facturación y los abonos recibidos para la orden médica referenciada.\n'
                '• Conserve este comprobante para el retiro o consulta de sus resultados de laboratorio.\n'
                '• Para consultas o seguimiento, contacte a nuestros teléfonos de atención o visite nuestra sede.',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            children: [
              pw.Container(
                width: 140,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 0.8)),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Caja / Recepción del Laboratorio',
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'Firma y Sello Autorizado',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
