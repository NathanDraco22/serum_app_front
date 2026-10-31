import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import 'package:serum_app_front/src/modules/lab_test/view/lab_test_screen.dart';
import 'package:serum_business/serum_business.dart';

class FakeLabTestsRepository extends LabTestsRepository {
  FakeLabTestsRepository() : super(LabTestsDataSource());

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

void main() {
  testWidgets('LabTestsScreen contiene el boton de refrescar y dispara getAll al pulsarlo', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = FakeLabTestsRepository();
    repo.mockTests = [
      LabTestInDb(
        id: 't-1',
        name: 'Prueba Demo',
        commercialCategory: 'Hematología',
        salePrice: 1000,
        isPack: false,
        createdAt: 1000,
      ),
    ];

    final readCubit = ReadLabTestCubit(labTestsRepository: repo);
    final sessionCubit = FakeAppSessionCubit();

    // Precargamos los datos iniciales
    await readCubit.loadIfNotLoaded();
    expect(repo.getAllCallsCount, 1);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<LabTestsRepository>.value(value: repo),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AppSessionCubit>.value(value: sessionCubit),
            BlocProvider<ReadLabTestCubit>.value(value: readCubit),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LabTestsScreen(),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verificamos que el botón de refrescar existe con su tooltip
    final refreshBtnFinder = find.byTooltip('Actualizar catálogo');
    expect(refreshBtnFinder, findsOneWidget);

    // Verificamos el icono
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

    // Hacemos tap en el botón de refrescar
    await tester.tap(refreshBtnFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Se debió disparar una nueva llamada a getAll()
    expect(repo.getAllCallsCount, 2);

    await tester.pump(const Duration(milliseconds: 500));

    await readCubit.close();
    await sessionCubit.close();
  });
}
