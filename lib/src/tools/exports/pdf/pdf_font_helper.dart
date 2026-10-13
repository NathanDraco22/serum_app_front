import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

/// Utilidad para la gestión de fuentes Unicode offline en el motor de generación PDF.
class PdfFontHelper {
  static bool _initialized = false;
  static pw.Font? _fallbackFont;

  /// Retorna la fuente fallback Unicode cargada desde los assets locales de la aplicación.
  static Future<pw.Font> getFallbackFont() async {
    if (_fallbackFont != null) return _fallbackFont!;
    final fontData = await rootBundle.load('assets/fonts/OpenSans.ttf');
    _fallbackFont = pw.Font.ttf(fontData);
    return _fallbackFont!;
  }

  /// Inicializa globalmente `pw.ThemeData.buildThemeData` para que cualquier
  /// documento o página generada con `pdf` use `OpenSans.ttf` como fuente
  /// fallback Unicode para cualquier caracter o símbolo que no soporte la fuente base.
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    try {
      final font = await getFallbackFont();
      pw.ThemeData.buildThemeData = () => pw.ThemeData.withFont(
            fontFallback: [font],
          );
      _initialized = true;
    } catch (_) {
      // Si ocurre un error al cargar el asset (por ejemplo, en tests unitarios sin bundle),
      // se continúa sin bloquear la ejecución.
    }
  }
}
