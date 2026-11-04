import 'package:serum_business/serum_business.dart';

/// Representa un bloque o sección de estudio clínico independiente
/// (ej. Biometría Hemática Completa, Examen General de Orina, Examen General de Heces, Glucosa, etc.).
class ClinicalStudyGroup {
  /// Nombre principal del examen o paquete comercial (ej. "BIOMETRÍA HEMÁTICA COMPLETA").
  final String studyTitle;

  /// Área o especialidad médica del estudio (ej. "HEMATOLOGÍA", "UROANÁLISIS", "COPROLOGÍA", "QUÍMICA CLÍNICA").
  final String clinicalArea;

  /// Resultados analíticos agrupados por su subclasificación clínica
  /// (ej. "SERIE ROJA" -> [...], "SERIE BLANCA" -> [...], "EXAMEN FÍSICO-QUÍMICO" -> [...]).
  /// Si los parámetros no tienen subserie, se agrupan bajo clave vacía ('').
  final Map<String, List<OrderTestResult>> subclassificationGroups;

  /// Indica si este estudio contiene al menos una prueba tabular (numérica, cualitativa o booleana).
  final bool hasTabularTests;

  ClinicalStudyGroup({
    required this.studyTitle,
    required this.clinicalArea,
    required this.subclassificationGroups,
    required this.hasTabularTests,
  });
}

/// Herramienta pura para agrupar los resultados de una orden clínica por estudio individual o pack,
/// garantizando compatibilidad total tanto para órdenes nuevas (con `parentExamName`) como órdenes legadas.
class ClinicalOrderGrouper {
  /// Agrupa los resultados de la orden en una lista ordenada de [ClinicalStudyGroup].
  static List<ClinicalStudyGroup> groupResultsByStudy(
    OrderInDb order, {
    bool visibleOnly = true,
  }) {
    final rawResults = visibleOnly
        ? order.results.where((r) => r.showInPrint).toList()
        : order.results;

    final results =
        rawResults.isNotEmpty ? rawResults : order.results;
    if (results.isEmpty) return [];

    // 1. Preservar el orden de los ítems registrados en la orden
    final Map<String, List<OrderTestResult>> studyBuckets = {};
    for (final item in order.items) {
      if (item.name.trim().isNotEmpty) {
        studyBuckets[item.name.trim()] = [];
      }
    }

    // 2. Clasificar cada resultado en su estudio correspondiente
    for (final r in results) {
      final assignedStudy = _resolveStudyNameForResult(r, order);
      studyBuckets.putIfAbsent(assignedStudy, () => []).add(r);
    }

    // 3. Eliminar buckets vacíos y construir los objetos [ClinicalStudyGroup]
    final List<ClinicalStudyGroup> groups = [];
    for (final entry in studyBuckets.entries) {
      final studyItems = entry.value;
      if (studyItems.isEmpty) continue;

      final studyTitle = entry.key.toUpperCase();
      final area = _resolveClinicalAreaForStudy(studyTitle, studyItems);

      // Agrupar por subclasificación médica (ej. SERIE ROJA, SERIE BLANCA, etc.)
      final Map<String, List<OrderTestResult>> subGroups = {};
      for (final r in studyItems) {
        final sub = r.subclassification.trim();
        final groupKey = sub.isNotEmpty ? sub.toUpperCase() : '';
        subGroups.putIfAbsent(groupKey, () => []).add(r);
      }

      final hasTabular = studyItems.any(shouldRenderInTable);

      groups.add(
        ClinicalStudyGroup(
          studyTitle: studyTitle,
          clinicalArea: area,
          subclassificationGroups: subGroups,
          hasTabularTests: hasTabular,
        ),
      );
    }

    // Fallback defensivo si ningún bucket capturó resultados
    if (groups.isEmpty && results.isNotEmpty) {
      final fallbackTitle = order.examName.isNotEmpty
          ? order.examName.toUpperCase()
          : 'ESTUDIO CLÍNICO';
      final area = _resolveClinicalAreaForStudy(fallbackTitle, results);
      final Map<String, List<OrderTestResult>> subGroups = {};
      for (final r in results) {
        final sub = r.subclassification.trim();
        final groupKey = sub.isNotEmpty ? sub.toUpperCase() : '';
        subGroups.putIfAbsent(groupKey, () => []).add(r);
      }
      groups.add(
        ClinicalStudyGroup(
          studyTitle: fallbackTitle,
          clinicalArea: area,
          subclassificationGroups: subGroups,
          hasTabularTests: results.any(shouldRenderInTable),
        ),
      );
    }

    return groups;
  }

  /// Determina si un resultado clínico es un sub-parámetro subordinado
  /// (como "Título" o "Concentración" en PCR, ASLO o Factor Reumatoide)
  /// que requiere sangría/indentación visual jerárquica bajo su análisis padre.
  static bool isSubParameter(OrderTestResult r) {
    final id = r.labTestId.toUpperCase();
    if (id == 'PCR-TIT' ||
        id == 'PCR-CONC' ||
        id == 'ASLO-TIT' ||
        id == 'ASLO-CONC' ||
        id == 'FR-TIT' ||
        id == 'FR-CONC') {
      return true;
    }
    final name = r.parameterName.trim().toLowerCase();
    return name == 'título' ||
        name == 'titulo' ||
        name == 'concentración' ||
        name == 'concentracion';
  }

  /// Evalúa si el parámetro debe renderizarse dentro de la estructura tabular
  /// del examen (incluyendo sub-parámetros analíticos libres como Título y Concentración)
  /// en lugar de expulsarse a bloques de párrafo multilínea.
  static bool shouldRenderInTable(OrderTestResult r) {
    if (r.dataType != 'text') return true;
    if (isSubParameter(r)) return true;
    return false;
  }

  /// Determina el área clínica general para la cabecera superior del documento.
  /// Si todos los estudios son de una misma área (ej. "HEMATOLOGÍA"), retorna dicha área.
  /// Si conviven estudios de múltiples disciplinas, retorna "LABORATORIO CLÍNICO".
  static String determineOverallClinicalArea(List<ClinicalStudyGroup> groups) {
    if (groups.isEmpty) return 'LABORATORIO CLÍNICO';
    final firstArea = groups.first.clinicalArea;
    final allSame = groups.every((g) => g.clinicalArea == firstArea);
    if (allSame && firstArea.isNotEmpty) {
      return firstArea;
    }
    return 'LABORATORIO CLÍNICO';
  }

  /// Resuelve a qué estudio pertenece un resultado específico con orden de prioridades.
  static String _resolveStudyNameForResult(OrderTestResult r, OrderInDb order) {
    // Prioridad 1: Trazabilidad explícita inmutable
    if (r.parentExamName != null && r.parentExamName!.trim().isNotEmpty) {
      return r.parentExamName!.trim();
    }

    // Prioridad 2: Orden mono-estudio
    if (order.items.length == 1) {
      return order.items.first.name.trim();
    }

    // Prioridad 3: Coincidencia directa por ID de prueba individual
    for (final item in order.items) {
      if (item.labTestId.toLowerCase() == r.labTestId.toLowerCase()) {
        return item.name.trim();
      }
    }

    // Prioridad 4: Resolución inteligente de perfiles clínicos estándar
    final rTestId = r.labTestId.toUpperCase();
    final rMedClass = r.medicalClassification.toUpperCase();
    final rSubClass = r.subclassification.toUpperCase();

    // 4.A Uroanálisis / General de Orina
    if (rTestId.contains('-ORI') ||
        rMedClass.contains('URO') ||
        rMedClass.contains('ORINA') ||
        rSubClass.contains('FÍSICO-QUÍMICO') ||
        rSubClass.contains('FISICO-QUIMICO') ||
        rSubClass.contains('SEDIMENTO')) {
      final egoItem = order.items.firstWhere(
        (i) {
          final n = i.name.toUpperCase();
          final id = i.labTestId.toUpperCase();
          return n.contains('ORINA') || n.contains('EGO') || id.contains('EGO');
        },
        orElse: () => OrderItem(labTestId: '', name: '', salePriceApplied: 0),
      );
      if (egoItem.name.isNotEmpty) return egoItem.name.trim();
    }

    // 4.B Coprología / General de Heces
    if (rTestId.contains('-HEC') ||
        rMedClass.contains('COPRO') ||
        rMedClass.contains('HECES') ||
        rSubClass.contains('EXAMEN FÍSICO') ||
        rSubClass.contains('EXAMEN FISICO') ||
        rSubClass.contains('EXAMEN MICROSCÓPICO') ||
        rSubClass.contains('EXAMEN MICROSCOPICO')) {
      final eghItem = order.items.firstWhere(
        (i) {
          final n = i.name.toUpperCase();
          final id = i.labTestId.toUpperCase();
          return n.contains('HECES') || n.contains('EGH') || id.contains('EGH');
        },
        orElse: () => OrderItem(labTestId: '', name: '', salePriceApplied: 0),
      );
      if (eghItem.name.isNotEmpty) return eghItem.name.trim();
    }

    // 4.C Hematología / Biometría Hemática
    const bhcCodes = {
      'ERI',
      'HB',
      'HTC',
      'HTO',
      'VCM',
      'HCM',
      'CHCM',
      'LEU',
      'PLAQ',
      'SEG',
      'LINF',
      'EOS',
      'MON',
      'BAN',
      'BAS',
      'LINF-ATIP',
    };
    if (bhcCodes.contains(rTestId) ||
        rMedClass.contains('HEMAT') ||
        rSubClass.contains('SERIE ROJA') ||
        rSubClass.contains('SERIE BLANCA') ||
        rSubClass.contains('DIFERENCIAL')) {
      final bhcItem = order.items.firstWhere(
        (i) {
          final n = i.name.toUpperCase();
          final id = i.labTestId.toUpperCase();
          return n.contains('BIOMETR') ||
              n.contains('HEMAT') ||
              n.contains('BHC') ||
              id.contains('BHC');
        },
        orElse: () => OrderItem(labTestId: '', name: '', salePriceApplied: 0),
      );
      if (bhcItem.name.isNotEmpty) return bhcItem.name.trim();
    }

    // 4.D Pruebas de Látex / Inmunología (PCR, ASLO, FR)
    if (rTestId.startsWith('PCR-') || rTestId == 'PCR') {
      final pcrItem = order.items.firstWhere(
        (i) => i.name.toUpperCase().contains('PROTEÍNA C') ||
            i.name.toUpperCase().contains('PROTEINA C') ||
            i.name.toUpperCase().contains('PCR') ||
            i.labTestId.toUpperCase() == 'PCR',
        orElse: () => OrderItem(labTestId: '', name: '', salePriceApplied: 0),
      );
      if (pcrItem.name.isNotEmpty) return pcrItem.name.trim();
    }

    if (rTestId.startsWith('ASLO-') || rTestId == 'ASLO') {
      final asloItem = order.items.firstWhere(
        (i) => i.name.toUpperCase().contains('ANTIESTREPTO') ||
            i.name.toUpperCase().contains('ASLO') ||
            i.labTestId.toUpperCase() == 'ASLO',
        orElse: () => OrderItem(labTestId: '', name: '', salePriceApplied: 0),
      );
      if (asloItem.name.isNotEmpty) return asloItem.name.trim();
    }

    if (rTestId.startsWith('FR-') || rTestId == 'FR') {
      final frItem = order.items.firstWhere(
        (i) => i.name.toUpperCase().contains('FACTOR REUM') ||
            i.name.toUpperCase().contains('FR') ||
            i.labTestId.toUpperCase() == 'FR',
        orElse: () => OrderItem(labTestId: '', name: '', salePriceApplied: 0),
      );
      if (frItem.name.isNotEmpty) return frItem.name.trim();
    }

    // Prioridad 5: Coincidencia semántica con ítems registrados en la orden
    for (final item in order.items) {
      final itemName = item.name.toUpperCase();
      if (rMedClass.isNotEmpty && itemName.contains(rMedClass)) {
        return item.name.trim();
      }
    }

    // Fallback: Clasificación médica o primer ítem disponible
    if (r.medicalClassification.trim().isNotEmpty) {
      return r.medicalClassification.trim();
    }
    return order.items.isNotEmpty ? order.items.first.name.trim() : 'Estudio Clínico';
  }

  /// Determina el área clínica de un estudio en particular.
  static String _resolveClinicalAreaForStudy(
    String studyTitle,
    List<OrderTestResult> items,
  ) {
    final title = studyTitle.toUpperCase();
    if (title.contains('HEMAT') ||
        title.contains('HEMOGLOBINA') ||
        title.contains('SANGRE') ||
        title.contains('BIOMETR')) {
      return 'HEMATOLOGÍA';
    }
    if (title.contains('QUIMIC') ||
        title.contains('GLUCOSA') ||
        title.contains('PERFIL LIP') ||
        title.contains('LIPID') ||
        title.contains('COLESTEROL') ||
        title.contains('TRIGLIC') ||
        title.contains('UREA') ||
        title.contains('CREATININA')) {
      return 'QUÍMICA CLÍNICA';
    }
    if (title.contains('ORINA') ||
        title.contains('URO') ||
        title.contains('GENERAL DE ORINA')) {
      return 'UROANÁLISIS';
    }
    if (title.contains('HECES') ||
        title.contains('COPRO') ||
        title.contains('PARASIT')) {
      return 'COPROLOGÍA';
    }
    if (title.contains('INMUNO') ||
        title.contains('SEROLOG') ||
        title.contains('VIH') ||
        title.contains('ANTIGEN') ||
        title.contains('PCR') ||
        title.contains('ASLO') ||
        title.contains('FACTOR REUM')) {
      return 'INMUNOLOGÍA / SEROLOGÍA';
    }
    if (title.contains('HORMON') || title.contains('TIROID')) {
      return 'HORMONAS / ENDOCRINOLOGÍA';
    }

    for (final r in items) {
      final mc = r.medicalClassification.trim().toUpperCase();
      if (mc.contains('HEMAT')) return 'HEMATOLOGÍA';
      if (mc.contains('QUIMIC')) return 'QUÍMICA CLÍNICA';
      if (mc.contains('URO')) return 'UROANÁLISIS';
      if (mc.contains('COPRO')) return 'COPROLOGÍA';
      if (mc.contains('INMUNO') || mc.contains('SEROL')) {
        return 'INMUNOLOGÍA';
      }
    }

    return 'LABORATORIO CLÍNICO';
  }
}
