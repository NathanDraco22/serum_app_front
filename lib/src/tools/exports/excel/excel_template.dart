import 'package:excel_plus/excel_plus.dart';

/// Interfaz base para cualquier plantilla de exportación a hojas de cálculo Excel (.xlsx).
abstract class ExcelTemplate {
  /// Construye y retorna la instancia del libro de trabajo [Excel].
  Future<Excel> buildExcel();

  /// Compila el libro de trabajo en una lista de bytes listos para su persistencia o transmisión.
  Future<List<int>?> buildBytes() async {
    final excel = await buildExcel();
    return excel.save();
  }
}
