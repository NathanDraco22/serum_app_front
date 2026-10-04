import 'package:printing/printing.dart';
import 'pdf/pdf_template.dart';

class PdfExportTool {
  /// Comparte o descarga el archivo PDF en el sistema de archivos del usuario.
  static Future<void> export(
    PdfTemplate template, {
    String fileName = "documento.pdf",
  }) async {
    final doc = await template.buildDocument();
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: fileName,
    );
  }

  /// Despliega el visor nativo de impresión y previsualización del sistema operativo o navegador.
  static Future<void> printPdf(
    PdfTemplate template, {
    String name = "documento.pdf",
  }) async {
    final doc = await template.buildDocument();
    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: name,
    );
  }
}
