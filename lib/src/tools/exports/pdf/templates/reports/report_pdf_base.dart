import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Componentes base y utilidades compartidas para la generación de reportes en PDF.
class ReportPdfHelper {
  /// Formatea centavos a formato de moneda (\$X.XX)
  static String formatCurrency(int cents) {
    final isNegative = cents < 0;
    final absVal = cents.abs() / 100.0;
    final parts = absVal.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // Formatear separador de miles
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInt = integerPart.replaceAllMapped(reg, (Match m) => '${m[1]},');
    final result = '\$$formattedInt.$decimalPart';

    return isNegative ? '-$result' : result;
  }

  /// Formatea DateTime a DD/MM/YYYY
  static String formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}';
  }

  /// Formatea DateTime a DD/MM/YYYY HH:MM
  static String formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/${dt.year} $hour:$minute';
  }

  /// Construye el membrete superior estándar para todos los reportes analíticos.
  static pw.Widget buildHeader({
    required String reportTitle,
    String? subtitle,
    required String branchName,
    String? branchAddress,
    String? branchPhone,
    required DateTime startDate,
    required DateTime endDate,
    String? generatedBy,
    DateTime? generationDate,
  }) {
    final now = generationDate ?? DateTime.now();
    final periodText = '${formatDate(startDate)} al ${formatDate(endDate)}';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Identidad del laboratorio y sede
            pw.Expanded(
              flex: 6,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SERUM LIS - LABORATORIO CLÍNICO',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    branchName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                  if (branchAddress != null && branchAddress.isNotEmpty) ...[
                    pw.SizedBox(height: 1),
                    pw.Text(
                      'Dirección: $branchAddress',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                    ),
                  ],
                  if (branchPhone != null && branchPhone.isNotEmpty) ...[
                    pw.SizedBox(height: 1),
                    pw.Text(
                      'Teléfono: $branchPhone',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                    ),
                  ],
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Generado el: ${formatDateTime(now)}${generatedBy != null && generatedBy.isNotEmpty ? ' por $generatedBy' : ''}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            // Título del Reporte y Rango de Fechas
            pw.Expanded(
              flex: 5,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.blue200, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      reportTitle.toUpperCase(),
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        subtitle,
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.blueGrey700,
                        ),
                      ),
                    ],
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Período: ',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          periodText,
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            color: PdfColors.grey800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.blue900, thickness: 1.2),
      ],
    );
  }

  /// Construye el pie de página estándar con número de páginas.
  static pw.Widget buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Serum LIS - Sistema de Gestión de Laboratorio Clínico',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Tarjeta de KPI individual
  static pw.Widget buildKpiCard({
    required String label,
    required String value,
    String? subtitle,
    PdfColor? accentColor,
    PdfColor? backgroundColor,
  }) {
    final borderColor = accentColor ?? PdfColors.blue200;
    final bg = backgroundColor ?? PdfColors.grey100;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: borderColor, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: accentColor ?? PdfColors.blue900,
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              subtitle,
              style: const pw.TextStyle(
                fontSize: 7,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Título de sección dentro del reporte
  static pw.Widget buildSectionTitle(String title, {String? subtitle}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10, bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 3.5,
                height: 12,
                color: PdfColors.blue800,
                margin: const pw.EdgeInsets.only(right: 6),
              ),
              pw.Text(
                title.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
            ],
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 9.5),
              child: pw.Text(
                subtitle,
                style: const pw.TextStyle(
                  fontSize: 7.5,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Celda de encabezado para tablas
  static pw.Widget buildTableHeaderCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? backgroundColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      color: backgroundColor ?? PdfColors.blueGrey800,
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  /// Celda de contenido para tablas
  static pw.Widget buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
    PdfColor? textColor,
    PdfColor? backgroundColor,
    double fontSize = 7.5,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      color: backgroundColor,
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? PdfColors.grey900,
        ),
      ),
    );
  }
}
