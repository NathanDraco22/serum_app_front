import 'package:serum_business/serum_business.dart';

/// Evalúa si agregar [candidate] como prueba hija dentro de [currentPackId] generaría una referencia circular.
///
/// Casos prevenidos:
/// 1. Auto-referencia directa: el candidato es el mismo pack en edición (`candidate.id == currentPackId`).
/// 2. Referencia circular transitiva: el candidato es un pack que ya contiene a `currentPackId`
///    como hijo directo o en alguno de sus niveles anidados.
bool wouldCreateCycle({
  required String currentPackId,
  required LabTestInDb candidate,
  required Map<String, LabTestInDb> testsById,
  Set<String>? visited,
}) {
  if (candidate.id == currentPackId) return true;
  if (!candidate.isPack || candidate.childTestIds.isEmpty) return false;

  final visitedSet = visited ?? <String>{};
  if (!visitedSet.add(candidate.id)) return false; // Prevención defensiva de ciclos previos

  for (final childId in candidate.childTestIds) {
    if (childId == currentPackId) return true;
    final child = testsById[childId];
    if (child != null &&
        wouldCreateCycle(
          currentPackId: currentPackId,
          candidate: child,
          testsById: testsById,
          visited: visitedSet,
        )) {
      return true;
    }
  }

  return false;
}

/// Filtra los análisis y perfiles disponibles para ser agregados como hijos de [currentPackId],
/// permitiendo seleccionar otros perfiles y descartando exclusivamente el pack en edición
/// y cualquier pack que produzca una referencia circular.
List<LabTestInDb> filterAvailableTestsForPack({
  required List<LabTestInDb> allTests,
  String? currentPackId,
}) {
  if (currentPackId == null || currentPackId.isEmpty) {
    return allTests;
  }

  final testsById = {for (final t in allTests) t.id: t};

  return allTests.where((candidate) {
    return !wouldCreateCycle(
      currentPackId: currentPackId,
      candidate: candidate,
      testsById: testsById,
    );
  }).toList();
}
