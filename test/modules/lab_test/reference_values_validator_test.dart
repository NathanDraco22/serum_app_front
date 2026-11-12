import 'package:flutter_test/flutter_test.dart';
import 'package:serum_business/serum_business.dart';
import 'package:serum_app_front/src/modules/lab_test/controllers/reference_values_validator.dart';

ReferenceValue _ref({
  int minAgeDays = 0,
  int maxAgeDays = 36500,
  String gender = 'both',
  bool useAge = false,
  bool useGender = false,
  double minValue = 1.0,
  double maxValue = 2.0,
}) {
  return ReferenceValue(
    patientType: 'general',
    gender: gender,
    minAgeDays: minAgeDays,
    maxAgeDays: maxAgeDays,
    minValue: minValue,
    maxValue: maxValue,
    useAge: useAge,
    useGender: useGender,
  );
}

void main() {
  group('ReferenceValuesValidator', () {
    test('sin rangos no produce error ni advertencia', () {
      final result = ReferenceValuesValidator.validate(const []);

      expect(result.hasError, isFalse);
      expect(result.hasWarning, isFalse);
    });

    test('detecta edades negativas', () {
      final error = ReferenceValuesValidator.errorFor([
        _ref(minAgeDays: -1),
      ]);

      expect(error, contains('edad negativa'));
    });

    test('detecta edad mínima mayor que la máxima cuando useAge está activo', () {
      final error = ReferenceValuesValidator.errorFor([
        _ref(minAgeDays: 365, maxAgeDays: 100, useAge: true),
      ]);

      expect(error, contains('edad mínima mayor que la máxima'));
    });

    test('ignora la inversión de edades cuando useAge está desactivado', () {
      final error = ReferenceValuesValidator.errorFor([
        _ref(minAgeDays: 365, maxAgeDays: 100),
      ]);

      expect(error, isNull);
    });

    test('advierte edades distintas con useAge desactivado', () {
      final warning = ReferenceValuesValidator.warningFor([
        _ref(minAgeDays: 0, maxAgeDays: 365),
        _ref(minAgeDays: 365, maxAgeDays: 730),
      ]);

      expect(warning, contains('Rangos por edad'));
    });

    test('advierte rangos masculino/femenino con useGender desactivado', () {
      final warning = ReferenceValuesValidator.warningFor([
        _ref(gender: 'male'),
        _ref(gender: 'female'),
      ]);

      expect(warning, contains('Rangos por género'));
    });

    test('advierte varios rangos generales con ambos switches apagados', () {
      final warning = ReferenceValuesValidator.warningFor([
        _ref(),
        _ref(),
      ]);

      expect(warning, contains('varios rangos generales'));
    });

    test('no advierte con un único rango', () {
      final warning = ReferenceValuesValidator.warningFor([_ref()]);

      expect(warning, isNull);
    });

    test('usa el validador de edad y género derivados de any', () {
      final values = [
        _ref(useAge: true),
        _ref(useGender: true, gender: 'female'),
      ];

      expect(ReferenceValuesValidator.usesAge(values), isTrue);
      expect(ReferenceValuesValidator.usesGender(values), isTrue);
    });

    test('validate devuelve error y advertencia juntos', () {
      final result = ReferenceValuesValidator.validate([
        _ref(minAgeDays: 365, maxAgeDays: 100, useAge: true),
        _ref(gender: 'male'),
      ]);

      expect(result.hasError, isTrue);
      expect(result.hasWarning, isTrue);
    });
  });
}
