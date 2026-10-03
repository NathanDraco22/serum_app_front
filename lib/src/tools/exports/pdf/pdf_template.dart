import 'package:pdf/widgets.dart' as pw;

abstract class PdfTemplate {
  Future<pw.Document> buildDocument();
}
