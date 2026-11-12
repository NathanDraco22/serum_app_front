import 'package:serum_business/serum_business.dart';

/// Resultado de la validación de una lista de rangos de referencia.
class ReferenceValuesValidationResult {
  final String? error;
  final String? warning;

  const ReferenceValuesValidationResult({this.error, this.warning});

  bool get hasError => error != null;
  bool get hasWarning => warning != null;
}

/// Validaciones compartidas para los rangos de referencia de una prueba.
///
/// Es una utilidad pura (sin dependencias de Flutter) para que el formulario
/// completo y el editor reutilizable apliquen exactamente las mismas reglas.
class ReferenceValuesValidator {
  const ReferenceValuesValidator._();

  /// Indica si al menos un rango evalúa la edad.
  static bool usesAge(List<ReferenceValue> values) => values.any((ref) => ref.useAge);

  /// Indica si al menos un rango evalúa el género.
  static bool usesGender(List<ReferenceValue> values) => values.any((ref) => ref.useGender);

  /// Error bloqueante de configuración de rangos.
  static String? errorFor(List<ReferenceValue> values) {
    for (var i = 0; i < values.length; i++) {
      final ref = values[i];
      if (ref.minAgeDays < 0 || ref.maxAgeDays < 0) {
        return 'El rango ${i + 1} tiene una edad negativa.';
      }
      if (ref.useAge && ref.maxAgeDays > 0 && ref.minAgeDays > ref.maxAgeDays) {
        return 'El rango ${i + 1} tiene una edad mínima mayor que la máxima.';
      }
    }
    return null;
  }

  /// Advertencia de configuración ambigua de rangos.
  static String? warningFor(List<ReferenceValue> values) {
    if (values.length <= 1) return null;

    final usesAgeFlag = usesAge(values);
    final usesGenderFlag = usesGender(values);
    final distinctAges = values.map((ref) => '${ref.minAgeDays}-${ref.maxAgeDays}').toSet();
    final hasGenderSpecific = values.any((ref) {
      final gender = ReferenceValueResolver.normalizeGender(ref.gender);
      return gender == 'male' || gender == 'female';
    });

    if (!usesAgeFlag && distinctAges.length > 1) {
      return 'La prueba tiene varios rangos con edades distintas, pero "Rangos por edad" está desactivado. Los rangos se aplicarían a todas las edades.';
    }
    if (!usesGenderFlag && hasGenderSpecific) {
      return 'La prueba tiene rangos para masculino/femenino, pero "Rangos por género" está desactivado. Los rangos se aplicarían a ambos géneros.';
    }
    if (!usesAgeFlag && !usesGenderFlag && values.length > 1) {
      return 'La prueba tiene varios rangos generales. Esto puede ser ambiguo; considera consolidarlos en uno solo.';
    }
    return null;
  }

  /// Valida la lista completa y devuelve el error y la advertencia resultantes.
  static ReferenceValuesValidationResult validate(
    List<ReferenceValue> values,
  ) {
    return ReferenceValuesValidationResult(
      error: errorFor(values),
      warning: warningFor(values),
    );
  }
}
