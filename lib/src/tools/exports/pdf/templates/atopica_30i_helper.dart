import 'package:serum_business/serum_business.dart';

/// Definición de un formato de reporte clínico disponible para una orden.
class SpecialReportFormat {
  final String id;
  final String label;
  final bool isSpecial;

  const SpecialReportFormat({
    required this.id,
    required this.label,
    required this.isSpecial,
  });

  static const standard = SpecialReportFormat(
    id: 'standard',
    label: 'Formato Estándar',
    isSpecial: false,
  );

  static const atopica30i = SpecialReportFormat(
    id: 'atopica_30i',
    label: 'Especial: Atópica 30-I',
    isSpecial: true,
  );
}

class _SpecialFormatRule {
  final SpecialReportFormat format;
  final List<String> triggerParentExamKeywords;
  final Set<String> triggerAllergenPrefixes;

  const _SpecialFormatRule({
    required this.format,
    required this.triggerParentExamKeywords,
    required this.triggerAllergenPrefixes,
  });

  bool matches(OrderInDb order) {
    for (final r in order.results) {
      final parentName = (r.parentExamName ?? '').trim().toLowerCase();
      if (triggerParentExamKeywords.any(parentName.contains)) {
        return true;
      }
      final prefix = Atopica30iHelper.extractAllergenPrefix(r.parameterName);
      if (prefix != null && triggerAllergenPrefixes.contains(prefix)) {
        return true;
      }
    }
    return false;
  }
}

/// Diccionario/Registro de formatos especiales soportados por el frontend.
///
/// El formato estándar siempre existe por defecto; aquí solo se registran
/// los formatos especiales asociados a nombres de perfil o prefijos de parámetros.
class SpecialReportRegistry {
  static final List<_SpecialFormatRule> _rules = [
    _SpecialFormatRule(
      format: SpecialReportFormat.atopica30i,
      triggerParentExamKeywords: ['atópica 30-i', 'atopica 30-i'],
      triggerAllergenPrefixes: Atopica30iHelper.orderedAllergenPrefixes.toSet(),
    ),
  ];

  /// Devuelve los formatos disponibles para la orden.
  /// Si hay formatos especiales aplicables, los devuelve primero junto con [SpecialReportFormat.standard].
  /// Si no hay ninguno, devuelve únicamente `[SpecialReportFormat.standard]`.
  static List<SpecialReportFormat> resolveAvailableFormats(OrderInDb order) {
    final specials = <SpecialReportFormat>[
      for (final rule in _rules)
        if (rule.matches(order)) rule.format,
    ];
    if (specials.isEmpty) {
      return const [SpecialReportFormat.standard];
    }
    return [...specials, SpecialReportFormat.standard];
  }
}

class AtopicaClassDescriptor {
  final int classNumber;
  final String rangeLabel;
  final String description;

  const AtopicaClassDescriptor({
    required this.classNumber,
    required this.rangeLabel,
    required this.description,
  });
}

class Atopica30iHelper {
  static const String panelCode = 'PANEL-ATOP30I';

  /// Prefijos oficiales en minúsculas de los 30 alérgenos según el reporte Biocheck Atópica 30-I.
  static const List<String> orderedAllergenPrefixes = [
    'f02',
    'f76',
    'f77',
    'f78',
    'f01',
    'f75',
    'f03',
    'f13',
    'f93',
    'f14',
    'f49',
    'f31',
    'f25',
    'fx10',
    'f83',
    'fx29',
    'f09',
    'gx7',
    'g12',
    'e02/e05',
    'e01',
    'm02',
    'm06',
    'm03',
    'd01',
    'd02',
    't04',
    't03',
    'w06',
    'k20',
  ];

  static String? extractAllergenPrefix(String parameterName) {
    final trimmed = parameterName.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    final spaceIdx = trimmed.indexOf(' ');
    final token = spaceIdx == -1 ? trimmed : trimmed.substring(0, spaceIdx);
    return orderedAllergenPrefixes.contains(token) ? token : null;
  }

  static const List<double> scaleTicks = [0.15, 0.35, 0.7, 3.5, 17.5, 100.0];

  static const List<String> mixNotes = [
    'fx10  f04 / f05 / f06 / f07 - Trigo, centeno, cebada, avena (harinas que contienen gluten)',
    'fx29  f208 / f306 / f33 / f302 - Limón, lima, naranja, mandarín',
    'gx7   g03 / g04 / g05 / g06 / g08 / g13 - Polen de dactylis, Festuca pratensis, Ryegrass, Phleum pratense, Poa de los prados, Holcus lanatus',
  ];

  static const List<AtopicaClassDescriptor> classDescriptors = [
    AtopicaClassDescriptor(
      classNumber: 0,
      rangeLabel: '<0.35',
      description: 'No se detectó anticuerpo específico.',
    ),
    AtopicaClassDescriptor(
      classNumber: 1,
      rangeLabel: '0.35 - <0.7',
      description: 'Anticuerpo muy débil.',
    ),
    AtopicaClassDescriptor(
      classNumber: 2,
      rangeLabel: '0.7 - <3.5',
      description: 'Detección débil de anticuerpo.',
    ),
    AtopicaClassDescriptor(
      classNumber: 3,
      rangeLabel: '3.5 - <17.5',
      description: 'Detección clara de anticuerpos.',
    ),
    AtopicaClassDescriptor(
      classNumber: 4,
      rangeLabel: '17.5 - <50',
      description: 'Fuerte detección de anticuerpos.',
    ),
    AtopicaClassDescriptor(
      classNumber: 5,
      rangeLabel: '50 - <100',
      description: 'Detección muy fuerte de anticuerpos.',
    ),
    AtopicaClassDescriptor(
      classNumber: 6,
      rangeLabel: '>= 100',
      description: 'Títulos extremadamente altos de anticuerpos.',
    ),
  ];

  /// Separa y ordena los resultados del panel Atópica 30-I y los restantes de la orden.
  static ({List<OrderTestResult> atopica, List<OrderTestResult> others}) splitResults(
    OrderInDb order,
  ) {
    final prefixOrder = <String, int>{
      for (var i = 0; i < orderedAllergenPrefixes.length; i++) orderedAllergenPrefixes[i]: i,
    };

    final atopica = <OrderTestResult>[];
    final others = <OrderTestResult>[];

    for (final r in order.results) {
      final parentName = (r.parentExamName ?? '').trim().toLowerCase();
      final prefix = extractAllergenPrefix(r.parameterName);
      if (prefix != null ||
          parentName.contains('atópica 30-i') ||
          parentName.contains('atopica 30-i')) {
        atopica.add(r);
      } else {
        others.add(r);
      }
    }

    atopica.sort((a, b) {
      final ia = prefixOrder[extractAllergenPrefix(a.parameterName)] ?? 999;
      final ib = prefixOrder[extractAllergenPrefix(b.parameterName)] ?? 999;
      return ia.compareTo(ib);
    });

    return (atopica: atopica, others: others);
  }

  /// Crea una copia filtrada de [order] con una lista específica de [results].
  static OrderInDb filterOrder(OrderInDb order, List<OrderTestResult> results) {
    return OrderInDb.fromJson({
      ...order.toJson(),
      'results': results.map((e) => e.toJson()).toList(),
    });
  }

  /// Parsea el valor numérico de IgE [kU/L] aceptando prefijos como `<0.15` o `>=100`.
  static double? parseNumericIge(String? rawValue) {
    if (rawValue == null) return null;
    final cleaned = rawValue
        .trim()
        .replaceAll(',', '')
        .replaceFirst(RegExp(r'^[<>]=?\s*'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Calcula la Clase IgE (0..6) o null si no hay valor numérico capturado.
  static int? computeIgeClass(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) return null;
    final trimmed = rawValue.trim();
    final value = parseNumericIge(trimmed);
    if (value == null) return null;

    if (trimmed.startsWith('<') && value <= 0.35) {
      return 0;
    }
    if (value < 0.35) return 0;
    if (value < 0.7) return 1;
    if (value < 3.5) return 2;
    if (value < 17.5) return 3;
    if (value < 50.0) return 4;
    if (value < 100.0) return 5;
    return 6;
  }

  /// Calcula el ancho normalizado [0.0..1.0] de la barra gráfica sobre los 6 tramos:
  /// `[0..0.15, 0.15..0.35, 0.35..0.7, 0.7..3.5, 3.5..17.5, 17.5..100]`.
  static double computeScaleFraction(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) return 0.0;
    final trimmed = rawValue.trim();
    final value = parseNumericIge(trimmed);
    if (value == null || value <= 0) return 0.0;
    if (trimmed.startsWith('<') && value <= 0.15) return 0.0;

    const bounds = [0.0, 0.15, 0.35, 0.7, 3.5, 17.5, 100.0];
    final segments = bounds.length - 1;

    if (value >= bounds.last) return 1.0;

    for (var i = 0; i < segments; i++) {
      final low = bounds[i];
      final high = bounds[i + 1];
      if (value <= high) {
        final local = ((value - low) / (high - low)).clamp(0.0, 1.0);
        return ((i + local) / segments).clamp(0.0, 1.0);
      }
    }
    return 1.0;
  }
}
