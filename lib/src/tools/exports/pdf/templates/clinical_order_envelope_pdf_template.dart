import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:serum_business/serum_business.dart';

import '../pdf_font_helper.dart';
import '../pdf_template.dart';

/// Plantilla para impresión de sobre físico (#10 / Oficio) con alimentación vertical (10.5 cm x 24.0 cm).
/// Fiel a la muestra física real de laboratorio clínico:
/// - El sobre entra en vertical por el lado angosto (10.5 cm) en la bandeja central.
/// - El contenido se renderiza rotado 90° para leerse horizontalmente a lo largo del sobre.
/// - Logo en esquina superior izquierda.
/// - Recuadro central delimitado por línea negra fina con Médico (condicional), Paciente y Fecha.
/// - Pie de sobre con marco redondeado azul y datos de contacto del laboratorio.
class ClinicalOrderEnvelopePdfTemplate implements PdfTemplate {
  final OrderInDb order;
  final BranchInDb branch;
  final PatientInfo? patientInfo;
  final DoctorInfo? doctorInfo;
  final bool rotate180;

  /// Formato estándar de sobre en alimentación vertical: 10.5 cm de ancho x 24.0 cm de alto.
  static final PdfPageFormat envelopeVerticalFormat = PdfPageFormat(
    10.5 * PdfPageFormat.cm,
    24.0 * PdfPageFormat.cm,
    marginAll: 0.8 * PdfPageFormat.cm,
  );

  /// Alias de compatibilidad
  static final PdfPageFormat envelopeFormat = envelopeVerticalFormat;

  ClinicalOrderEnvelopePdfTemplate({
    required this.order,
    required this.branch,
    PatientInfo? patientInfo,
    DoctorInfo? doctorInfo,
    this.rotate180 = false,
  })  : patientInfo = patientInfo ?? order.patientInfo,
        doctorInfo = doctorInfo ?? order.doctorInfo;

  @override
  Future<pw.Document> buildDocument() async {
    await PdfFontHelper.ensureInitialized();
    final doc = pw.Document();

    final orderDate = DateTime.fromMillisecondsSinceEpoch(order.createdAt);
    final dateStr = DateTimeTool.formatddMMyy(orderDate);

    pw.MemoryImage? logoImage;
    if (branch.imageUrl != null && branch.imageUrl!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(branch.imageUrl!));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {
        // En caso de no poder descargar el logo se continúa sin él
      }
    }

    // Configuración de página con orientación landscape sobre papel vertical:
    // El motor de PDF aplica automáticamente rotación de 90° adaptada a la alimentación vertical de la impresora.
    final pageTheme = pw.PageTheme(
      pageFormat: envelopeVerticalFormat,
      orientation: pw.PageOrientation.landscape,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    );

    doc.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (pw.Context context) {
          final content = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. Esquina superior izquierda: Logo y nombre de laboratorio
              _buildHeader(logoImage),

              pw.Spacer(flex: 1),

              // 2. Zona central: Recuadro delimitado con línea negra fina
              _buildCentralBox(dateStr),

              pw.Spacer(flex: 2),

              // 3. Pie del sobre: Marco redondeado con dirección y contactos
              _buildFooterBox(),
            ],
          );

          if (rotate180) {
            return pw.Transform.rotateBox(
              angle: math.pi,
              child: content,
            );
          }

          return content;
        },
      ),
    );

    return doc;
  }

  pw.Widget _buildHeader(pw.MemoryImage? logoImage) {
    return pw.Align(
      alignment: pw.Alignment.topLeft,
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logoImage != null) ...[
            pw.Container(
              width: 42,
              height: 42,
              margin: const pw.EdgeInsets.only(right: 8),
              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
            ),
          ],
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'Laboratorio Clínico',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.blueGrey700,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
              pw.Text(
                branch.name.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCentralBox(String dateStr) {
    final patient = patientInfo ??
        PatientInfo(
          name: 'Paciente #${order.patientId}',
          dateOfBirth: 0,
          gender: 'M',
        );

    final doctor = doctorInfo;
    final hasDoctor = doctor != null && doctor.name.trim().isNotEmpty;

    return pw.Align(
      alignment: const pw.Alignment(0.15, 0.0),
      child: pw.Container(
        width: 290,
        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.75),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            // Sección Médico Solicitante (solo si no es nulo ni vacío)
            if (hasDoctor) ...[
              pw.Text(
                'CON ATENCION A:',
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                  letterSpacing: 0.5,
                ),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                doctor.name.toUpperCase(),
                style: const pw.TextStyle(
                  fontSize: 9.5,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 7),
            ],

            // Sección Paciente
            pw.Text(
              'Resultados de paciente:',
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              patient.name.toUpperCase(),
              style: const pw.TextStyle(
                fontSize: 9.5,
                color: PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 7),

            // Sección Fecha
            pw.Text(
              'FECHA: $dateStr',
              style: const pw.TextStyle(
                fontSize: 8.5,
                color: PdfColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildFooterBox() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue300, width: 0.8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // 1. Dirección física de la sucursal
          if (branch.address.isNotEmpty)
            pw.Text(
              branch.address,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(
                fontSize: 7.2,
                color: PdfColors.black,
              ),
              maxLines: 1,
            ),
          pw.SizedBox(height: 3),

          // 2. Canales de contacto con iconos circulares
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              // Facebook / Nombre comercial
              _buildContactItem(
                label: 'f',
                text: 'Laboratorio clínico ${branch.name}',
                iconColor: PdfColors.blue700,
              ),
              pw.SizedBox(width: 14),

              // Correo electrónico
              _buildContactItem(
                label: '@',
                text: 'info@${branch.name.toLowerCase().replaceAll(' ', '')}.com',
                iconColor: PdfColors.blue500,
              ),

              // Teléfono / WhatsApp
              if (branch.phone.isNotEmpty) ...[
                pw.SizedBox(width: 14),
                _buildContactItem(
                  label: 'W',
                  text: branch.phone,
                  iconColor: PdfColors.teal,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildContactItem({
    required String label,
    required String text,
    required PdfColor iconColor,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 11,
          height: 11,
          decoration: pw.BoxDecoration(
            color: iconColor,
            shape: pw.BoxShape.circle,
          ),
          alignment: pw.Alignment.center,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 6.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          text,
          style: const pw.TextStyle(
            fontSize: 7,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }
}
