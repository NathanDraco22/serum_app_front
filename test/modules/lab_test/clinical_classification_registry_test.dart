import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/lab_test/widgets/clinical_classification_registry.dart';

void main() {
  group('ClinicalClassificationRegistry Tests', () {
    test('Retorna clasificaciones ordenadas alfabéticamente', () {
      final list = ClinicalClassificationRegistry.classifications;
      expect(list.isNotEmpty, true);
      expect(list.contains('Hematología'), true);
      expect(list.contains('Química Sanguínea'), true);
      expect(list.contains('Uroanálisis'), true);

      // Verificar orden A-Z
      for (int i = 0; i < list.length - 1; i++) {
        expect(list[i].toLowerCase().compareTo(list[i + 1].toLowerCase()) <= 0, true);
      }
    });

    test('Retorna subclasificaciones correctas para Hematología', () {
      final subs = ClinicalClassificationRegistry.getSubclassificationsFor('Hematología');
      expect(subs.contains('Serie Roja'), true);
      expect(subs.contains('Serie Blanca'), true);
      expect(subs.contains('Serie Plaquetaria / Coagulación'), true);
    });

    test('Retorna subclasificaciones correctas para Uroanálisis', () {
      final subs = ClinicalClassificationRegistry.getSubclassificationsFor('Uroanálisis');
      expect(subs.contains('Examen Físico-Químico'), true);
      expect(subs.contains('Sedimento Microscópico'), true);
    });

    test('Retorna General para categoría desconocida', () {
      final subs = ClinicalClassificationRegistry.getSubclassificationsFor('Otra Categoría Desconocida');
      expect(subs, ['General']);
    });
  });
}
