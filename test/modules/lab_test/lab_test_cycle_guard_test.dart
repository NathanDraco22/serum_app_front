import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/lab_test/controllers/lab_test_cycle_guard.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  group('LabTestCycleGuard — wouldCreateCycle & filterAvailableTestsForPack', () {
    final atomic1 = LabTestInDb(
      id: 'atom_1',
      name: 'Glucosa',
      isPack: false,
      createdAt: 0,
    );

    final param1 = LabTestInDb(
      id: 'param_1',
      name: 'Proteína C Reactiva Cualitativa',
      isPack: false,
      isProfileParameter: true,
      createdAt: 0,
    );

    final packA = LabTestInDb(
      id: 'pack_a',
      name: 'Pack A (Perfil Básico)',
      isPack: true,
      childTestIds: ['atom_1', 'param_1'],
      createdAt: 0,
    );

    final packB = LabTestInDb(
      id: 'pack_b',
      name: 'Pack B (Perfil Intermedio)',
      isPack: true,
      childTestIds: ['pack_a'], // Contiene a Pack A
      createdAt: 0,
    );

    final packC = LabTestInDb(
      id: 'pack_c',
      name: 'Pack C (Perfil Completo)',
      isPack: true,
      childTestIds: ['pack_b'], // Contiene a Pack B (que contiene a Pack A)
      createdAt: 0,
    );

    final packIndependent = LabTestInDb(
      id: 'pack_indep',
      name: 'Pack Independiente',
      isPack: true,
      childTestIds: ['atom_1'],
      createdAt: 0,
    );

    final allTests = [atomic1, param1, packA, packB, packC, packIndependent];
    final testsById = {for (final t in allTests) t.id: t};

    test('currentPackId nulo o vacío retorna todos los análisis sin filtrar', () {
      final resNull = filterAvailableTestsForPack(allTests: allTests, currentPackId: null);
      expect(resNull.length, allTests.length);

      final resEmpty = filterAvailableTestsForPack(allTests: allTests, currentPackId: '');
      expect(resEmpty.length, allTests.length);
    });

    test('Auto-referencia directa: Pack A intentando agregarse a sí mismo es bloqueado', () {
      expect(
        wouldCreateCycle(
          currentPackId: 'pack_a',
          candidate: packA,
          testsById: testsById,
        ),
        isTrue,
      );
    });

    test('Pruebas atómicas y parámetros de perfil nunca producen ciclos', () {
      expect(
        wouldCreateCycle(
          currentPackId: 'pack_a',
          candidate: atomic1,
          testsById: testsById,
        ),
        isFalse,
      );
      expect(
        wouldCreateCycle(
          currentPackId: 'pack_a',
          candidate: param1,
          testsById: testsById,
        ),
        isFalse,
      );
    });

    test('Packs independientes sin dependencia son permitidos', () {
      expect(
        wouldCreateCycle(
          currentPackId: 'pack_a',
          candidate: packIndependent,
          testsById: testsById,
        ),
        isFalse,
      );
    });

    test('Ciclo directo: Pack B contiene a Pack A; al editar Pack A, Pack B es bloqueado', () {
      expect(
        wouldCreateCycle(
          currentPackId: 'pack_a',
          candidate: packB,
          testsById: testsById,
        ),
        isTrue,
      );
    });

    test(
      'Ciclo indirecto transitivo: Pack C contiene a Pack B que contiene a Pack A; al editar Pack A, Pack C es bloqueado',
      () {
        expect(
          wouldCreateCycle(
            currentPackId: 'pack_a',
            candidate: packC,
            testsById: testsById,
          ),
          isTrue,
        );
      },
    );

    test('filterAvailableTestsForPack excluye Pack A, Pack B y Pack C al editar Pack A', () {
      final available = filterAvailableTestsForPack(
        allTests: allTests,
        currentPackId: 'pack_a',
      );

      final availableIds = available.map((t) => t.id).toList();
      // Permite pruebas atómicas, parámetros y packs independientes
      expect(availableIds, containsAll(['atom_1', 'param_1', 'pack_indep']));
      // Excluye a sí mismo y a sus ancestros
      expect(availableIds.contains('pack_a'), isFalse);
      expect(availableIds.contains('pack_b'), isFalse);
      expect(availableIds.contains('pack_c'), isFalse);
    });

    test('Defensiva contra ciclos corruptos preexistentes no genera desbordamiento de pila', () {
      final circular1 = LabTestInDb(
        id: 'circ_1',
        name: 'Circular 1',
        isPack: true,
        childTestIds: ['circ_2'],
        createdAt: 0,
      );
      final circular2 = LabTestInDb(
        id: 'circ_2',
        name: 'Circular 2',
        isPack: true,
        childTestIds: ['circ_1'], // Ciclo 1 <-> 2
        createdAt: 0,
      );

      final corruptMap = {
        'circ_1': circular1,
        'circ_2': circular2,
      };

      // Debe terminar limpiamente sin StackOverflowError
      final result = wouldCreateCycle(
        currentPackId: 'other_pack',
        candidate: circular1,
        testsById: corruptMap,
      );
      expect(result, isFalse);
    });
  });
}
