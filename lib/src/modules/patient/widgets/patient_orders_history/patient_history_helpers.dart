import 'package:serum_business/serum_business.dart';
import '../../../../tools/calculators/clinical_formulas_registry.dart';

/// Funciones auxiliares y reglas clínicas para el historial de órdenes del paciente.
class PatientHistoryHelpers {
  /// Determina si una orden contiene un estudio de Biometría Hemática o perfil hematológico completo.
  static bool isBiometryOrder(OrderInDb order) {
    final title = order.examName.toLowerCase();
    if (title.contains('biometr') ||
        title.contains('hematolog') ||
        title.contains('hemograma')) {
      return true;
    }
    for (final item in order.items) {
      final iname = item.name.toLowerCase();
      if (iname.contains('biometr') ||
          iname.contains('hematolog') ||
          iname.contains('hemograma')) {
        return true;
      }
    }
    final hematologyKeys = {'ERI', 'HB', 'HTC', 'VCM', 'LEU', 'PLAQ'};
    int matches = 0;
    for (final r in order.results) {
      final key = ClinicalFormulasRegistry.resolveCanonicalKey(r.parameterName);
      if (key != null && hematologyKeys.contains(key)) {
        matches++;
      }
    }
    return matches >= 2;
  }
}
