import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/tools/formatters/thousands_separator_input_formatter.dart';

void main() {
  group('ThousandsSeparatorInputFormatter - Formateo Básico y de Miles', () {
    final formatter = ThousandsSeparatorInputFormatter();

    test('Formatea números enteros menores a 1000 sin modificar', () {
      final res = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '999',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      expect(res.text, '999');
      expect(res.selection.baseOffset, 3);
    });

    test('Separa 1000 en 1,000', () {
      final res = formatter.formatEditUpdate(
        const TextEditingValue(text: '100', selection: TextSelection.collapsed(offset: 3)),
        const TextEditingValue(text: '1000', selection: TextSelection.collapsed(offset: 4)),
      );
      expect(res.text, '1,000');
      expect(res.selection.baseOffset, 5);
    });

    test('Separa 150000 en 150,000 (caso típico de Plaquetas)', () {
      final res = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '150000', selection: TextSelection.collapsed(offset: 6)),
      );
      expect(res.text, '150,000');
      expect(res.selection.baseOffset, 7);
    });

    test('Separa 4500000 en 4,500,000 (caso típico de Eritrocitos)', () {
      final res = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '4500000', selection: TextSelection.collapsed(offset: 7)),
      );
      expect(res.text, '4,500,000');
      expect(res.selection.baseOffset, 9);
    });

    test('Cadena vacía permanece vacía', () {
      final res = formatter.formatEditUpdate(
        const TextEditingValue(text: '5', selection: TextSelection.collapsed(offset: 1)),
        TextEditingValue.empty,
      );
      expect(res.text, '');
      expect(res.selection.baseOffset, 0);
    });
  });

  group('ThousandsSeparatorInputFormatter - Decimales y Fracciones', () {
    test('Permite decimales por defecto (ej. 1250.75 -> 1,250.75)', () {
      final formatter = ThousandsSeparatorInputFormatter();
      final res = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1250.75', selection: TextSelection.collapsed(offset: 7)),
      );
      expect(res.text, '1,250.75');
      expect(res.selection.baseOffset, 8);
    });

    test('Al teclear punto al inicio, genera 0.', () {
      final formatter = ThousandsSeparatorInputFormatter();
      final res = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '.', selection: TextSelection.collapsed(offset: 1)),
      );
      expect(res.text, '0.');
      expect(res.selection.baseOffset, 2);
    });

    test('Respeta limitación de maxDecimalDigits si se especifica', () {
      final formatter = ThousandsSeparatorInputFormatter(maxDecimalDigits: 2);
      final res = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1250.7599', selection: TextSelection.collapsed(offset: 9)),
      );
      expect(res.text, '1,250.75');
    });

    test('Ignora decimales si allowFraction es false', () {
      final formatter = ThousandsSeparatorInputFormatter(allowFraction: false);
      final res = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1500.50', selection: TextSelection.collapsed(offset: 7)),
      );
      expect(res.text, '1,500');
    });
  });

  group('ThousandsSeparatorInputFormatter - Estabilidad del Cursor y Edición en Medio', () {
    final formatter = ThousandsSeparatorInputFormatter();

    test('Mantiene el cursor en la posición correcta al escribir en medio del número', () {
      // Estado previo: 15,000 con cursor entre '1' y '5' (offset 1)
      // Usuario teclea '2' -> texto intermedio antes de formato: '125,000' con cursor en 2
      final res = formatter.formatEditUpdate(
        const TextEditingValue(text: '15,000', selection: TextSelection.collapsed(offset: 1)),
        const TextEditingValue(text: '125,000', selection: TextSelection.collapsed(offset: 2)),
      );
      expect(res.text, '125,000');
      expect(res.selection.baseOffset, 2);
    });

    test('Borrado inteligente con Backspace sobre separador de miles elimina el dígito anterior', () {
      // Estado previo: '1,000' con cursor tras la coma (offset 2)
      // El usuario presiona Backspace: Flutter borra la coma generando '1000' con cursor en 1
      final res = formatter.formatEditUpdate(
        const TextEditingValue(text: '1,000', selection: TextSelection.collapsed(offset: 2)),
        const TextEditingValue(text: '1000', selection: TextSelection.collapsed(offset: 1)),
      );
      // Nuestro formateador detecta que se borró una coma y remueve el '1'
      expect(res.text, '000');
      expect(res.selection.baseOffset, 0);
    });
  });

  group('ThousandsSeparatorInputFormatter - Métodos Estáticos de Utilidad', () {
    test('format(num) convierte números a texto con comas', () {
      expect(ThousandsSeparatorInputFormatter.format(1000), '1,000');
      expect(ThousandsSeparatorInputFormatter.format(150000), '150,000');
      expect(ThousandsSeparatorInputFormatter.format(1250.5, decimalDigits: 2), '1,250.50');
      expect(ThousandsSeparatorInputFormatter.format(4.85, decimalDigits: 3), '4.850');
    });

    test('formatText(String) limpia y formatea cadenas', () {
      expect(ThousandsSeparatorInputFormatter.formatText('1000'), '1,000');
      expect(ThousandsSeparatorInputFormatter.formatText('150000'), '150,000');
      expect(ThousandsSeparatorInputFormatter.formatText('1250.75'), '1,250.75');
      expect(ThousandsSeparatorInputFormatter.formatText('   '), '');
    });

    test('clean(String) remueve comas', () {
      expect(ThousandsSeparatorInputFormatter.clean('150,000.50'), '150000.50');
      expect(ThousandsSeparatorInputFormatter.clean('1,000'), '1000');
    });

    test('tryParseDouble parsea correctamente con y sin comas', () {
      expect(ThousandsSeparatorInputFormatter.tryParseDouble('150,000.50'), 150000.50);
      expect(ThousandsSeparatorInputFormatter.tryParseDouble('1,000'), 1000.0);
      expect(ThousandsSeparatorInputFormatter.tryParseDouble('45.2'), 45.2);
      expect(ThousandsSeparatorInputFormatter.tryParseDouble(''), null);
      expect(ThousandsSeparatorInputFormatter.tryParseDouble(null), null);
      expect(ThousandsSeparatorInputFormatter.tryParseDouble('abc'), null);
    });

    test('tryParseInt parsea enteros con y sin comas', () {
      expect(ThousandsSeparatorInputFormatter.tryParseInt('150,000'), 150000);
      expect(ThousandsSeparatorInputFormatter.tryParseInt('1,000'), 1000);
      expect(ThousandsSeparatorInputFormatter.tryParseInt('999'), 999);
      expect(ThousandsSeparatorInputFormatter.tryParseInt(''), null);
    });
  });
}
