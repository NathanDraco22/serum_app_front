import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:serum_business/serum_business.dart';
import '../pdf_template.dart';

class SingleQuotationTemplate implements PdfTemplate {
  final QuotationInDb quotation;
  final BranchInDb branch;
  final PatientInfo? clientInfo;
  final DoctorInfo? doctorInfo;

  SingleQuotationTemplate({
    required this.quotation,
    required this.branch,
    PatientInfo? clientInfo,
    DoctorInfo? doctorInfo,
  })  : clientInfo = clientInfo ?? quotation.clientInfo,
        doctorInfo = doctorInfo ?? quotation.doctorInfo;

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

  @override
  Future<pw.Document> buildDocument() async {
    final doc = pw.Document();

    final quoteDate = DateTime.fromMillisecondsSinceEpoch(quotation.createdAt);
    final formattedDate =
        '${DateTimeTool.formatddMMyy(quoteDate)} ${DateTimeTool.formatHHmm(quoteDate)}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            child: _buildHeader(formattedDate),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 12),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Serum LIS — Sistema de Laboratorio Clínico',
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
            pw.Divider(color: PdfColors.blueGrey800, thickness: 1.5),
            pw.SizedBox(height: 8),
            _buildClientAndDoctorInfo(),
            pw.SizedBox(height: 12),
            _buildItemsTable(),
            pw.SizedBox(height: 14),
            _buildTotalsSection(),
            pw.SizedBox(height: 20),
            _buildValidityAndTerms(),
            pw.SizedBox(height: 24),
            _buildSignatureSection(),
          ];
        },
      ),
    );

    return doc;
  }

  pw.Widget _buildHeader(String formattedDate) {
    final folio = quotation.id.length > 8
        ? quotation.id.substring(quotation.id.length - 8).toUpperCase()
        : quotation.id.toUpperCase();

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 6,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                branch.name.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Dirección: ${branch.address}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
              pw.Text(
                'Teléfono: ${branch.phone}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.amber400),
                ),
                child: pw.Text(
                  'PRESUPUESTO / COTIZACIÓN',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.amber900,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Cotización #: $folio',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Fecha: $formattedDate',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildClientAndDoctorInfo() {
    final client = clientInfo;
    final doctor = doctorInfo;
    final displayName = client?.name.isNotEmpty == true
        ? client!.name
        : (quotation.clientName.isNotEmpty ? quotation.clientName : 'Cliente General');

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Datos del Cliente
          pw.Expanded(
            flex: 5,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DATOS DEL CLIENTE / PACIENTE',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 4),
                _buildInfoLine('Nombre:', displayName, isBold: true),
                if (client != null && client.dateOfBirth > 0)
                  _buildInfoLine(
                    'Edad / Sexo:',
                    '${_calculateAge(client.dateOfBirth)} años | ${_formatGender(client.gender)}',
                  ),
                if (client?.cardId != null && client!.cardId!.isNotEmpty)
                  _buildInfoLine('Identificación:', client.cardId!),
                if (client != null && client.phone.isNotEmpty)
                  _buildInfoLine('Teléfono:', client.phone),
                if (client != null && client.address.isNotEmpty)
                  _buildInfoLine('Dirección:', client.address),
              ],
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Container(width: 0.5, height: 60, color: PdfColors.grey400),
          pw.SizedBox(width: 14),
          // Datos del Médico (si fue especificado)
          pw.Expanded(
            flex: 5,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'MÉDICO REFERENTE (OPCIONAL)',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 4),
                if (doctor != null && doctor.name.isNotEmpty) ...[
                  _buildInfoLine('Médico:', doctor.name, isBold: true),
                  _buildInfoLine('Especialidad:', doctor.specialty),
                  if (doctor.phone.isNotEmpty)
                    _buildInfoLine('Teléfono:', doctor.phone),
                ] else ...[
                  pw.Text(
                    'No asignado (Venta directa / Solicitud particular)',
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoLine(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 75,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
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

  pw.Widget _buildItemsTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ANÁLISIS Y PERFILES PRESUPUESTADOS',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          headerStyle: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
          headerAlignment: pw.Alignment.centerLeft,
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          cellStyle: const pw.TextStyle(fontSize: 8.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(28),
            1: const pw.FlexColumnWidth(5),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(2),
          },
          headers: ['#', 'Descripción del Análisis / Perfil', 'Tipo', 'Tarifa', 'Precio Cotizado'],
          data: quotation.exams.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final item = entry.value;
            final isPack = item.isPack;
            final priceFormatted = NumberFormatter.convertToMoneyLike(item.quotedPrice);

            return [
              '$idx',
              item.name,
              isPack ? 'PERFIL / PACK' : 'INDIVIDUAL',
              'P${item.priceLevel}',
              priceFormatted,
            ];
          }).toList(),
        ),
      ],
    );
  }

  pw.Widget _buildTotalsSection() {
    final totalFormatted = NumberFormatter.convertToMoneyLike(quotation.totalAmount);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 260,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.blueGrey200),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TOTAL PRESUPUESTADO:',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Text(
                totalFormatted,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildValidityAndTerms() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TÉRMINOS Y CONDICIONES DE LA COTIZACIÓN',
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '1. Este presupuesto tiene una validez de 15 días a partir de la fecha de su emisión.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
          ),
          pw.Text(
            '2. Las tarifas cotizadas quedan garantizadas durante el periodo de vigencia indicado.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
          ),
          pw.Text(
            '3. Para formalizar la realización de los análisis, presente este comprobante en la recepción del laboratorio.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
          ),
          pw.Text(
            '4. Algunos análisis requieren preparación clínica previa (ayuno, recolección en recipientes especiales, etc.). Por favor consultar en ventanilla.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignatureSection() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        pw.Column(
          children: [
            pw.Container(width: 170, height: 0.8, color: PdfColors.grey600),
            pw.SizedBox(height: 4),
            pw.Text(
              'Emitido por Recepción / Caja',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Column(
          children: [
            pw.Container(width: 170, height: 0.8, color: PdfColors.grey600),
            pw.SizedBox(height: 4),
            pw.Text(
              'Sello / Autorización de Laboratorio',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }
}
