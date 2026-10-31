import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import 'package:serum_business/serum_business.dart';

class _FakeLabTestsDataSource extends Fake implements LabTestsDataSource {
  @override
  Future<Map<String, dynamic>> getAllLabTests({String? branchId}) async {
    return {'data': [], 'count': 0};
  }
}

class FakeLabTestsRepository extends LabTestsRepository {
  FakeLabTestsRepository() : super(_FakeLabTestsDataSource());

  int getAllCallsCount = 0;
  List<LabTestInDb> mockTests = [];

  @override
  Future<List<LabTestInDb>> getAllLabTests({String? branchId}) async {
    getAllCallsCount++;
    return mockTests;
  }
}

class FakeAppSessionCubit extends Cubit<AppSessionState> implements AppSessionCubit {
  FakeAppSessionCubit() : super(const AppSessionState());

  @override
  String get currentBranchId => 'test-branch';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Widget representativo del botón de refrescar implementado en LabTestsScreen
Widget buildRefreshButton(ReadLabTestState readState) {
  return Builder(
    builder: (context) {
      return IconButton.outlined(
        tooltip: 'Actualizar catálogo',
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: (readState is ReadLabTestRefreshing || readState is ReadLabTestLoading)
            ? null
            : () {
                final branchId = context.read<AppSessionCubit>().currentBranchId;
                context.read<ReadLabTestCubit>().getAll(branchId: branchId);
              },
        icon: (readState is ReadLabTestRefreshing)
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh_rounded),
      );
    },
  );
}

void main() {
  late FakeLabTestsRepository repo;
  late ReadLabTestCubit readCubit;
  late FakeAppSessionCubit sessionCubit;

  final sampleTest = LabTestInDb(
    id: 't-1',
    name: 'Prueba Demo',
    commercialCategory: 'Hematología',
    salePrice: 1000,
    isPack: false,
    createdAt: 1000,
  );

  setUp(() {
    repo = FakeLabTestsRepository();
    repo.mockTests = [sampleTest];
    readCubit = ReadLabTestCubit(labTestsRepository: repo);
    sessionCubit = FakeAppSessionCubit();
  });

  tearDown(() async {
    await readCubit.close();
    await sessionCubit.close();
  });

  group('LabTest Refresh Button Tests', () {
    testWidgets('Muestra icono refresh_rounded y tooltip cuando estado es Success', (tester) async {
      await readCubit.loadIfNotLoaded();
      expect(repo.getAllCallsCount, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<AppSessionCubit>.value(value: sessionCubit),
                BlocProvider<ReadLabTestCubit>.value(value: readCubit),
              ],
              child: buildRefreshButton(readCubit.state),
            ),
          ),
        ),
      );

      expect(find.byTooltip('Actualizar catálogo'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Al presionar el botón, se llama a getAll
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(repo.getAllCallsCount, 2);
    });

    testWidgets('Muestra CircularProgressIndicator y queda deshabilitado en ReadLabTestRefreshing', (tester) async {
      final refreshingState = ReadLabTestRefreshing.fromSuccess(ReadLabTestSuccess([sampleTest]));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<AppSessionCubit>.value(value: sessionCubit),
                BlocProvider<ReadLabTestCubit>.value(value: readCubit),
              ],
              child: buildRefreshButton(refreshingState),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.onPressed, isNull);
    });
  });
}
