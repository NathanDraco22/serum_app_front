/// Estructura de datos inmutable que define una fórmula clínica para el
/// cálculo automático de resultados analíticos de laboratorio.
class ClinicalFormula {
  /// Identificador único interno de la fórmula (ej. 'wintrobe_vcm').
  final String id;

  /// Nombre descriptivo del examen o parámetro resultante (ej. 'Volumen Corpuscular Medio (VCM)').
  final String name;

  /// Código canónico del parámetro calculado (ej. 'VCM').
  final String targetCanonical;

  /// Lista de alias, abreviaturas o fragmentos de texto que identifican a este parámetro.
  final List<String> targetAliases;

  /// Claves canónicas de los parámetros que deben estar presentes y con valor numérico válido.
  final List<String> requiredInputs;

  /// Representación matemática legible de la fórmula para el usuario (ej. '(Hematocrito * 10) / Eritrocitos').
  final String formulaDisplay;

  /// Cantidad de decimales clínicos estándar a redondear (ej. 1 para VCM, 2 para Bilirrubinas).
  final int decimalPlaces;

  /// Función pura de cómputo matemático.
  /// Recibe un mapa de valores numéricos indexado por las claves canónicas de [requiredInputs].
  /// Retorna `null` si no es posible computar (ej. división por cero).
  final double? Function(Map<String, double> inputs) compute;

  const ClinicalFormula({
    required this.id,
    required this.name,
    required this.targetCanonical,
    required this.targetAliases,
    required this.requiredInputs,
    required this.formulaDisplay,
    this.decimalPlaces = 1,
    required this.compute,
  });

  /// Verifica si un texto (código o nombre de examen) corresponde al parámetro que esta fórmula calcula.
  bool matchesTarget(String text) {
    final clean = text.trim().toLowerCase();
    if (clean == targetCanonical.toLowerCase()) return true;
    for (final alias in targetAliases) {
      final cleanAlias = alias.trim().toLowerCase();
      if (clean == cleanAlias || clean.contains(cleanAlias)) {
        return true;
      }
    }
    return false;
  }
}

/// Resultado de una evaluación exitosa de una fórmula clínica.
class ClinicalCalculationResult {
  final String formulaId;
  final String formulaName;
  final String formulaDisplay;
  final double value;
  final String formattedValue;

  const ClinicalCalculationResult({
    required this.formulaId,
    required this.formulaName,
    required this.formulaDisplay,
    required this.value,
    required this.formattedValue,
  });

  @override
  String toString() => '$formulaName = $formattedValue ($formulaDisplay)';
}
