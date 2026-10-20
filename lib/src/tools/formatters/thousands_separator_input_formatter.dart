import 'dart:math';
import 'package:flutter/services.dart';

/// Formateador de texto reutilizable para campos numéricos en Flutter.
///
/// Inserta separadores de miles (por defecto coma `,`) automáticamente conforme
/// el usuario escribe, manteniendo la posición precisa del cursor sin saltos inesperados.
///
/// Soporta:
/// - Separación de miles cada 3 dígitos (ej. `1000` -> `1,000`, `150000` -> `150,000`).
/// - Decimales configurables (ej. `1250.75` -> `1,250.75`).
/// - Eliminación inteligente de separadores con Backspace (evita quedar atrapado tras una coma).
/// - Pegado y edición arbitraria en cualquier punto del texto.
/// - Métodos estáticos de utilidad: [format], [formatText], [clean], [tryParseDouble] y [tryParseInt].
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  /// Si se permiten valores decimales. Por defecto `true`.
  final bool allowFraction;

  /// Cantidad máxima de dígitos decimales permitidos tras el separador decimal.
  /// Si es `null`, no se limita la cantidad de decimales.
  final int? maxDecimalDigits;

  /// Si se permiten valores negativos (signo `-` inicial). Por defecto `false`.
  final bool allowNegative;

  /// Carácter utilizado como separador decimal. Por defecto punto `.`.
  final String decimalSeparator;

  /// Carácter utilizado como separador de miles. Por defecto coma `,`.
  final String thousandsSeparator;

  ThousandsSeparatorInputFormatter({
    this.allowFraction = true,
    this.maxDecimalDigits,
    this.allowNegative = false,
    this.decimalSeparator = '.',
    this.thousandsSeparator = ',',
  }) : assert(
          decimalSeparator != thousandsSeparator,
          'El separador decimal y el separador de miles no pueden ser el mismo carácter.',
        );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    String textToProcess = newValue.text;
    int cursorAdjustment = 0;

    // -------------------------------------------------------------------------
    // 1. Manejo Inteligente de Backspace sobre Separadores de Miles
    // -------------------------------------------------------------------------
    // Si el usuario tenía el cursor tras una coma (ej. '1,|000') y pulsa Backspace,
    // Flutter borraría la coma ('1000'). Detectamos esto y eliminamos también el dígito
    // inmediatamente anterior a la coma para que el usuario no quede atrapado.
    final bool isDeletingSingleChar = oldValue.text.length - 1 == newValue.text.length;
    if (isDeletingSingleChar &&
        oldValue.selection.baseOffset > 0 &&
        oldValue.selection.baseOffset <= oldValue.text.length) {
      final deletedChar = oldValue.text[oldValue.selection.baseOffset - 1];
      if (deletedChar == thousandsSeparator) {
        final deleteIndexInNew = oldValue.selection.baseOffset - 2;
        if (deleteIndexInNew >= 0 && deleteIndexInNew < textToProcess.length) {
          textToProcess = textToProcess.substring(0, deleteIndexInNew) +
              textToProcess.substring(deleteIndexInNew + 1);
          cursorAdjustment = -1;
        }
      }
    }

    // -------------------------------------------------------------------------
    // 2. Detección y Extracción del Signo Negativo
    // -------------------------------------------------------------------------
    final bool isNegative = allowNegative && textToProcess.startsWith('-');
    if (isNegative) {
      textToProcess = textToProcess.substring(1);
    } else if (!allowNegative && textToProcess.startsWith('-')) {
      textToProcess = textToProcess.replaceAll('-', '');
    }

    // -------------------------------------------------------------------------
    // 3. Separación de Parte Entera y Parte Decimal
    // -------------------------------------------------------------------------
    final bool containsDecimal = textToProcess.contains(decimalSeparator);
    final bool hasDecimal = allowFraction && containsDecimal;
    String integerRaw = '';
    String decimalRaw = '';

    if (containsDecimal) {
      final parts = textToProcess.split(decimalSeparator);
      integerRaw = parts[0];
      if (allowFraction) {
        // Si el usuario ingresó más de un punto decimal, unificamos solo la primera fracción
        decimalRaw = parts.sublist(1).join();
      }
    } else {
      integerRaw = textToProcess;
    }

    // Limpiar caracteres no numéricos
    final integerDigits = integerRaw.replaceAll(RegExp(r'[^\d]'), '');
    var decimalDigits = decimalRaw.replaceAll(RegExp(r'[^\d]'), '');

    if (maxDecimalDigits != null && decimalDigits.length > maxDecimalDigits!) {
      decimalDigits = decimalDigits.substring(0, maxDecimalDigits!);
    }

    // Caso especial: si no hay dígitos enteros ni decimales pero se escribió el punto (ej. ".")
    if (integerDigits.isEmpty && hasDecimal) {
      integerRaw = '0';
    } else {
      integerRaw = integerDigits;
    }

    // Si después de limpiar no queda nada, retornar vacío
    if (integerRaw.isEmpty && decimalDigits.isEmpty && !hasDecimal) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // -------------------------------------------------------------------------
    // 4. Formateo de Miles de la Parte Entera
    // -------------------------------------------------------------------------
    final formattedInteger = _formatIntegerThousands(integerRaw, thousandsSeparator);

    // -------------------------------------------------------------------------
    // 5. Reconstrucción de la Cadena Formateada
    // -------------------------------------------------------------------------
    final buffer = StringBuffer();
    if (isNegative) {
      buffer.write('-');
    }
    buffer.write(formattedInteger);
    if (hasDecimal) {
      buffer.write(decimalSeparator);
      buffer.write(decimalDigits);
    }

    final formattedText = buffer.toString();

    // -------------------------------------------------------------------------
    // 6. Cálculo Preciso de la Posición del Cursor
    // -------------------------------------------------------------------------
    // Contamos cuántos caracteres significativos (dígitos, punto y signo) estaban
    // antes del cursor en [newValue.text], ajustados por el Backspace si aplicó.
    final rawCursorEnd = min(newValue.selection.end, newValue.text.length);
    final effectiveRawCursor = max(0, rawCursorEnd + cursorAdjustment);

    int significantCharsBefore = 0;
    for (int i = 0; i < effectiveRawCursor && i < newValue.text.length; i++) {
      final char = newValue.text[i];
      if (char != thousandsSeparator && (char == '-' || char == decimalSeparator || RegExp(r'\d').hasMatch(char))) {
        significantCharsBefore++;
      }
    }

    // Si el usuario tecleó '.' al inicio y autocompletamos con '0.', aumentamos el conteo
    if (newValue.text.startsWith(decimalSeparator) && formattedText.startsWith('0$decimalSeparator')) {
      significantCharsBefore++;
    }

    // Encontramos el índice en [formattedText] que contiene exactamente esa misma cantidad
    int newCursorOffset = 0;
    int matchedSignificantChars = 0;

    for (int i = 0; i < formattedText.length; i++) {
      final char = formattedText[i];
      if (char != thousandsSeparator) {
        matchedSignificantChars++;
      }
      if (matchedSignificantChars == significantCharsBefore) {
        newCursorOffset = i + 1;
        break;
      }
    }

    if (significantCharsBefore == 0) {
      newCursorOffset = 0;
    }

    newCursorOffset = newCursorOffset.clamp(0, formattedText.length);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }

  /// Inserta el separador de miles cada 3 dígitos de derecha a izquierda.
  static String _formatIntegerThousands(String digits, String separator) {
    if (digits.length <= 3) return digits;
    return digits.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}$separator',
    );
  }

  // ===========================================================================
  // MÉTODOS ESTÁTICOS DE UTILIDAD
  // ===========================================================================

  /// Formatea un valor numérico [num] a texto con separadores de miles.
  ///
  /// Ejemplos:
  /// ```dart
  /// ThousandsSeparatorInputFormatter.format(1000); // "1,000"
  /// ThousandsSeparatorInputFormatter.format(150000); // "150,000"
  /// ThousandsSeparatorInputFormatter.format(1250.5, decimalDigits: 2); // "1,250.50"
  /// ```
  static String format(
    num value, {
    int? decimalDigits,
    String thousandsSeparator = ',',
    String decimalSeparator = '.',
  }) {
    String rawStr;
    if (decimalDigits != null) {
      rawStr = value.toStringAsFixed(decimalDigits);
    } else if (value == value.roundToDouble()) {
      rawStr = value.toInt().toString();
    } else {
      rawStr = value.toString();
    }
    return formatText(
      rawStr,
      allowFraction: true,
      maxDecimalDigits: decimalDigits,
      thousandsSeparator: thousandsSeparator,
      decimalSeparator: decimalSeparator,
    );
  }

  /// Formatea un string numérico crudo (ej. proveniente de base de datos o cálculo).
  ///
  /// Ejemplos:
  /// ```dart
  /// ThousandsSeparatorInputFormatter.formatText("150000"); // "150,000"
  /// ThousandsSeparatorInputFormatter.formatText("1250.75"); // "1,250.75"
  /// ```
  static String formatText(
    String text, {
    bool allowFraction = true,
    int? maxDecimalDigits,
    bool allowNegative = false,
    String thousandsSeparator = ',',
    String decimalSeparator = '.',
  }) {
    final cleanStr = text.trim();
    if (cleanStr.isEmpty) return '';

    final formatter = ThousandsSeparatorInputFormatter(
      allowFraction: allowFraction,
      maxDecimalDigits: maxDecimalDigits,
      allowNegative: allowNegative,
      thousandsSeparator: thousandsSeparator,
      decimalSeparator: decimalSeparator,
    );

    return formatter
        .formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(
            text: cleanStr,
            selection: TextSelection.collapsed(offset: cleanStr.length),
          ),
        )
        .text;
  }

  /// Elimina los separadores de miles de una cadena de texto.
  ///
  /// Ejemplo:
  /// ```dart
  /// ThousandsSeparatorInputFormatter.clean("150,000.50"); // "150000.50"
  /// ```
  static String clean(String text, {String thousandsSeparator = ','}) {
    return text.replaceAll(thousandsSeparator, '').trim();
  }

  /// Parsea un texto con o sin separadores de miles a un [double] seguro.
  /// Retorna `null` si la cadena no representa un número válido.
  ///
  /// Tolera comas de miles y puntos decimales.
  ///
  /// Ejemplo:
  /// ```dart
  /// ThousandsSeparatorInputFormatter.tryParseDouble("150,000.50"); // 150000.5
  /// ThousandsSeparatorInputFormatter.tryParseDouble("1,000"); // 1000.0
  /// ```
  static double? tryParseDouble(
    String? text, {
    String thousandsSeparator = ',',
    String decimalSeparator = '.',
  }) {
    if (text == null) return null;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    var cleaned = clean(trimmed, thousandsSeparator: thousandsSeparator);
    if (decimalSeparator != '.') {
      cleaned = cleaned.replaceAll(decimalSeparator, '.');
    }
    return double.tryParse(cleaned);
  }

  /// Parsea un texto con o sin separadores de miles a un [int] seguro.
  /// Retorna `null` si la cadena no representa un entero válido.
  ///
  /// Ejemplo:
  /// ```dart
  /// ThousandsSeparatorInputFormatter.tryParseInt("150,000"); // 150000
  /// ```
  static int? tryParseInt(
    String? text, {
    String thousandsSeparator = ',',
  }) {
    if (text == null) return null;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final cleaned = clean(trimmed, thousandsSeparator: thousandsSeparator);
    final asInt = int.tryParse(cleaned);
    if (asInt != null) return asInt;

    // Si tenía decimales (ej. "150,000.00"), parsear como double y convertir a int
    final asDouble = double.tryParse(cleaned);
    return asDouble?.toInt();
  }
}
