import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'excel/excel_template.dart';

/// Herramienta institucional para guardar y exportar archivos Excel (.xlsx).
class ExcelExportTool {
  /// Exporta el archivo Excel utilizando el selector de guardado del sistema operativo.
  /// Retorna la ruta o URI guardada si fue exitoso, o `null` si el usuario canceló.
  static Future<String?> export(
    ExcelTemplate template, {
    required String fileName,
    String? dialogTitle,
  }) async {
    final bytes = await template.buildBytes();
    if (bytes == null || bytes.isEmpty) {
      throw Exception('No se pudieron generar los datos binarios del archivo Excel.');
    }

    final uint8Bytes = Uint8List.fromList(bytes);

    try {
      final savedUri = await FilePicker.saveFile(
        dialogTitle: dialogTitle ?? 'Guardar reporte en Excel',
        fileName: fileName,
        bytes: uint8Bytes,
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      return savedUri?.toString();
    } catch (_) {
      // Fallback para entornos móviles o específicos que no soporten FilePicker.saveFile
      final xFile = XFile.fromData(
        uint8Bytes,
        name: fileName,
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      final shareResult = await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: dialogTitle ?? 'Reporte Excel',
        ),
      );
      return shareResult.status == ShareResultStatus.success ? fileName : null;
    }
  }
}
