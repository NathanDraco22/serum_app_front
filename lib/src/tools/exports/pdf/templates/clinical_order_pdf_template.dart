import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:serum_business/serum_business.dart';
import '../pdf_template.dart';

class SingleClinicalOrderTemplate implements PdfTemplate {
  final OrderInDb order;
  final BranchInDb branch;
  final PatientInfo? patientInfo;
  final DoctorInfo? doctorInfo;

  SingleClinicalOrderTemplate({
    required this.order,
    required this.branch,
    PatientInfo? patientInfo,
    DoctorInfo? doctorInfo,
  })  : patientInfo = patientInfo ?? order.patientInfo,
        doctorInfo = doctorInfo ?? order.doctorInfo;

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

    final orderDate = DateTime.fromMillisecondsSinceEpoch(order.createdAt);
    final formattedDate =
        '${DateTimeTool.formatddMMyy(orderDate)} ${DateTimeTool.formatHHmm(orderDate)}';

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
            _buildPatientAndDoctorInfo(),
            pw.SizedBox(height: 12),
            _buildExamSummary(),
            pw.SizedBox(height: 12),
            _buildResultsTable(),
            pw.SizedBox(height: 24),
            _buildSignatureAndNotes(),
          ];
        },
      ),
    );

    return doc;
  }

  pw.Widget _buildHeader(String formattedDate) {
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
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Text(
                  'INFORME CLÍNICO',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Folio: ${order.id.length > 8 ? order.id.substring(order.id.length - 8).toUpperCase() : order.id.toUpperCase()}',
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

  pw.Widget _buildPatientAndDoctorInfo() {
    final patient = patientInfo ??
        PatientInfo(
          name: 'Paciente #${order.patientId}',
          dateOfBirth: 0,
          gender: 'M',
        );
    final doctor = doctorInfo;
    final patientAge = _calculateAge(patient.dateOfBirth);
    final genderStr = _formatGender(patient.gender);

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
          // Datos del Paciente
          pw.Expanded(
            flex: 5,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DATOS DEL PACIENTE',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 4),
                _buildInfoLine('Nombre:', patient.name, isBold: true),
                _buildInfoLine(
                  'Edad / Sexo:',
                  '${patientAge > 0 ? '$patientAge años' : 'N/D'} | $genderStr',
                ),
                if (patient.cardId != null && patient.cardId!.isNotEmpty)
                  _buildInfoLine('Identificación:', patient.cardId!),
                if (patient.phone.isNotEmpty)
                  _buildInfoLine('Teléfono:', patient.phone),
                if (patient.address.isNotEmpty)
                  _buildInfoLine('Dirección:', patient.address),
              ],
            ),
          ),
          pw.SizedBox(width: 14),
          // Línea divisoria vertical
          pw.Container(width: 0.5, height: 60, color: PdfColors.grey400),
          pw.SizedBox(width: 14),
          // Datos del Médico Referente
          pw.Expanded(
            flex: 5,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'MÉDICO REFERENTE',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 4),
                if (doctor != null) ...[
                  _buildInfoLine('Médico:', doctor.name, isBold: true),
                  _buildInfoLine('Especialidad:', doctor.specialty),
                  if (doctor.cardId != null && doctor.cardId!.isNotEmpty)
                    _buildInfoLine('Colegiatura:', doctor.cardId!),
                  if (doctor.phone.isNotEmpty)
                    _buildInfoLine('Contacto:', doctor.phone),
                ] else ...[
                  _buildInfoLine('Médico:', 'Particular / Sin médico asignado', isBold: true),
                  _buildInfoLine('Atención:', 'Directa en ventanilla'),
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
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildExamSummary() {
    final studyTitle = order.examName.isNotEmpty ? order.examName : 'Estudios Clínicos Solicitados';

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue800,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'ESTUDIO: ${studyTitle.toUpperCase()}',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.Text(
            'ESTADO: ${order.status.toUpperCase()}',
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildResultsTable() {
    return pw.Table(
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
        bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.8),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3.8), // Parámetro
        1: const pw.FlexColumnWidth(2.2), // Resultado
        2: const pw.FlexColumnWidth(1.6), // Unidades
        3: const pw.FlexColumnWidth(3.0), // Valores de Referencia
        4: const pw.FlexColumnWidth(1.8), // Alerta / Flag
      },
      children: [
        // Encabezado de la tabla
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey200,
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
            ),
          ),
          children: [
            _buildTableHeaderCell('ANÁLISIS / PARÁMETRO', align: pw.TextAlign.left),
            _buildTableHeaderCell('RESULTADO', align: pw.TextAlign.center),
            _buildTableHeaderCell('UNIDADES', align: pw.TextAlign.center),
            _buildTableHeaderCell('VALOR REFERENCIAL', align: pw.TextAlign.center),
            _buildTableHeaderCell('ESTADO', align: pw.TextAlign.center),
          ],
        ),
        // Filas con cada resultado
        ...order.results.map((r) {
          final hasAlert = r.alertFlag != null && r.alertFlag!.isNotEmpty;
          final isNumeric = r.dataType == 'numeric';

          String referenceText = '—';
          if (isNumeric && r.referenceValues.isNotEmpty) {
            final ref = r.referenceValues.first;
            referenceText = '${ref.minValue} - ${ref.maxValue}';
          } else if (r.dataType == 'boolean' && r.expectedQualitativeValue != null) {
            referenceText = 'Esperado: ${r.expectedQualitativeValue}';
          }

          final alertLabel = hasAlert
              ? (r.alertFlag == 'HIGH'
                  ? 'ALTO'
                  : r.alertFlag == 'LOW'
                      ? 'BAJO'
                      : r.alertFlag == 'ABNORMAL'
                          ? 'ANORMAL'
                          : r.alertFlag!)
              : 'NORMAL';

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: hasAlert ? PdfColors.red50 : PdfColors.white,
            ),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      r.parameterName,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: hasAlert ? PdfColors.red900 : PdfColors.black,
                      ),
                    ),
                    if (r.medicalClassification.isNotEmpty)
                      pw.Text(
                        r.medicalClassification,
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                      ),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: pw.Text(
                  r.resultValue ?? '—',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: hasAlert ? PdfColors.red900 : PdfColors.black,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: pw.Text(
                  r.unitOfMeasure.isNotEmpty ? r.unitOfMeasure : '—',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: pw.Text(
                  referenceText,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: pw.Text(
                  alertLabel,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: hasAlert ? PdfColors.red800 : PdfColors.green800,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  pw.Widget _buildSignatureAndNotes() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'Nota: Los resultados aquí expresados corresponden única y exclusivamente a la muestra recibida y procesada en nuestras instalaciones. Todo resultado debe ser correlacionado clínicamente por el médico tratante.',
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
            textAlign: pw.TextAlign.justify,
          ),
        ),
        pw.SizedBox(height: 40),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            pw.Column(
              children: [
                pw.Container(
                  width: 180,
                  height: 0.5,
                  color: PdfColors.black,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Responsable de Laboratorio',
                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Firma y Sello de Validación',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
