import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import 'package:serum_business/serum_business.dart';

class FakeLabTestsRepository extends LabTestsRepository {
  FakeLabTestsRepository() : super(LabTestsDataSource());

  int getAllCallsCount = 0;
  List<LabTestInDb> mockTests = [];
  bool shouldThrow = false;

  @override
  Future<List<LabTestInDb>> getAllLabTests({String? branchId}) async {
    getAllCallsCount++;
    if (shouldThrow) {
      throw Exception('Network error');
    }
    return mockTests;
  }
}

void main() {
  late FakeLabTestsRepository repository;
  late ReadLabTestCubit cubit;

  final sampleTest = LabTestInDb(
    id: 'test-1',
    name: 'Glucosa en Ayunas',
    commercialCategory: 'Química Clínica',
    salePrice: 12000,
    isPack: false,
    createdAt: 1000,
  );

  setUp(() {
    repository = FakeLabTestsRepository();
    cubit = ReadLabTestCubit(labTestsRepository: repository);
  });

  tearDown(() async {
    await cubit.close();
  });

  group('ReadLabTestCubit - loadIfNotLoaded', () {
    test('llama a getAll y emite ReadLabTestSuccess cuando el estado es inicial', () async {
      repository.mockTests = [sampleTest];

      expect(cubit.state, isA<ReadLabTestInitial>());
      expect(repository.getAllCallsCount, 0);

      await cubit.loadIfNotLoaded();

      expect(cubit.state, isA<ReadLabTestSuccess>());
      expect((cubit.state as ReadLabTestSuccess).items, [sampleTest]);
      expect(repository.getAllCallsCount, 1);
    });

    test('no realiza peticion de red adicional si el estado ya es ReadLabTestSuccess', () async {
      repository.mockTests = [sampleTest];

      // Primera carga: estado inicial -> éxito
      await cubit.loadIfNotLoaded();
      expect(cubit.state, isA<ReadLabTestSuccess>());
      expect(repository.getAllCallsCount, 1);

      // Segunda llamada: ya está en éxito, no debe llamar al repo
      await cubit.loadIfNotLoaded();
      expect(cubit.state, isA<ReadLabTestSuccess>());
      expect(repository.getAllCallsCount, 1);

      // Tercera llamada (ej. Crear Orden abierta nuevamente): sigue sin llamar a red
      await cubit.loadIfNotLoaded();
      expect(repository.getAllCallsCount, 1);
    });

    test('reintenta llamada si el estado anterior fue ReadLabTestError', () async {
      repository.shouldThrow = true;

      // Intento fallido
      await cubit.loadIfNotLoaded();
      expect(cubit.state, isA<ReadLabTestError>());
      expect(repository.getAllCallsCount, 1);

      // Se soluciona el problema de red y se reintenta
      repository.shouldThrow = false;
      repository.mockTests = [sampleTest];

      await cubit.loadIfNotLoaded();
      expect(cubit.state, isA<ReadLabTestSuccess>());
      expect(repository.getAllCallsCount, 2);
    });

    test('getAll fuerza la recarga emitiendo ReadLabTestRefreshing cuando ya hay éxito', () async {
      repository.mockTests = [sampleTest];

      // Estado inicial a éxito
      await cubit.loadIfNotLoaded();
      expect(cubit.state, isA<ReadLabTestSuccess>());
      expect(repository.getAllCallsCount, 1);

      // Ahora llamamos explícitamente a getAll (como hace el botón de refrescar)
      final states = <ReadLabTestState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.getAll();
      await Future.delayed(Duration.zero);
      await sub.cancel();

      expect(repository.getAllCallsCount, 2);
      expect(states.any((s) => s is ReadLabTestRefreshing), isTrue);
      expect(states.last, isA<ReadLabTestSuccess>());
    });
  });
}
