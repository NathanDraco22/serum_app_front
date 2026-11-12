import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/cubits/imports_cubit/imports_cubit.dart';
import 'package:serum_app_front/src/cubits/imports_cubit/imports_state.dart';
import 'package:serum_app_front/src/modules/imports/view/imports_screen.dart';
import 'package:serum_app_front/src/modules/imports/widgets/catalog_update_card.dart';
import 'package:serum_business/serum_business.dart';

class _FakeImportsDataSource extends Fake implements ImportsDataSource {
  UpdateImportResult? stubbedUpdateResult;
  bool? lastOverridePrice;
  bool? lastUpdateLabTest;
  bool? lastPreserveReferenceValues;

  @override
  Future<Map<String, dynamic>> updateCatalog({
    bool overridePrice = false,
    bool updateLabTest = true,
    bool preserveReferenceValues = true,
  }) async {
    lastOverridePrice = overridePrice;
    lastUpdateLabTest = updateLabTest;
    lastPreserveReferenceValues = preserveReferenceValues;

    return stubbedUpdateResult?.toJson() ??
        {
          'success': true,
          'message': 'Catálogo actualizado exitosamente',
          'totalProcessed': 254,
          'updatedTestsCount': 230,
          'createdTestsCount': 24,
          'updatedAccountsCount': 10,
          'createdAccountsCount': 5,
          'skippedPricesCount': 230,
          'preservedReferenceValuesCount': 230,
        };
  }

  @override
  Future<Map<String, dynamic>> importBranchPrices({
    required String sourceBranchId,
    required String targetBranchId,
    bool mustOverridePrice = false,
  }) async {
    return {'success': true, 'message': 'OK'};
  }
}

class _FakeBranchesDataSource extends Fake implements BranchesDataSource {
  @override
  Future<Map<String, dynamic>> getAllBranches() async {
    return {
      'count': 1,
      'data': [
        {
          'id': 'ORIGIN_BRANCH',
          'name': 'Sucursal Matriz',
          'address': 'Av. Central',
          'phone': '555-1111',
          'createdAt': 1000,
        },
      ],
    };
  }
}

class _MockAppSessionCubit extends Cubit<AppSessionState> implements AppSessionCubit {
  _MockAppSessionCubit()
    : super(
        AppSessionState(
          status: AppSessionStatus.authenticated,
          currentUser: UserInDb(
            id: 'admin-1',
            username: 'admin',
            name: 'Administrador',
            role: 'admin',
            accessLevel: 5,
            branches: const ['ORIGIN_BRANCH'],
            createdAt: 1000,
          ),
        ),
      );

  @override
  String get currentBranchId => 'ORIGIN_BRANCH';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeImportsDataSource fakeImportsDs;
  late ImportsRepository importsRepo;
  late _FakeBranchesDataSource fakeBranchesDs;
  late BranchesRepository branchesRepo;

  setUp(() {
    fakeImportsDs = _FakeImportsDataSource();
    importsRepo = ImportsRepository(fakeImportsDs);
    fakeBranchesDs = _FakeBranchesDataSource();
    branchesRepo = BranchesRepository(fakeBranchesDs);
  });

  group('ImportsCubit - Actualización y Sincronización de Catálogo', () {
    test(
      'updateCatalog emite ImportsLoading y luego ImportsUpdateSuccess con precios preservados',
      () async {
        final cubit = ImportsCubit(importsRepository: importsRepo);

        final futureExpect = expectLater(
          cubit.stream,
          emitsInOrder([
            isA<ImportsLoading>(),
            isA<ImportsUpdateSuccess>(),
          ]),
        );

        final result = await cubit.updateCatalog(
          overridePrice: false,
          updateLabTest: true,
        );

        await futureExpect;

        expect(result, isNotNull);
        expect(result!.success, isTrue);
        expect(result.totalProcessed, equals(254));
        expect(result.updatedTestsCount, equals(230));
        expect(result.skippedPricesCount, equals(230));
        expect(fakeImportsDs.lastOverridePrice, isFalse);
        expect(fakeImportsDs.lastUpdateLabTest, isTrue);

        expect(cubit.state, isA<ImportsUpdateSuccess>());
        expect((cubit.state as ImportsUpdateSuccess).result.updatedTestsCount, equals(230));

        await cubit.close();
      },
    );

    test('updateCatalog propaga overridePrice: true cuando se solicita', () async {
      final cubit = ImportsCubit(importsRepository: importsRepo);

      await cubit.updateCatalog(
        overridePrice: true,
        updateLabTest: true,
      );

      expect(fakeImportsDs.lastOverridePrice, isTrue);
      expect(fakeImportsDs.lastUpdateLabTest, isTrue);

      await cubit.close();
    });
  });

  group('CatalogUpdateCard Widget Tests', () {
    testWidgets('Renderiza switches de configuración y ejecuta diálogo de confirmación', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        MaterialApp(
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<BranchesRepository>.value(value: branchesRepo),
              RepositoryProvider<ImportsRepository>.value(value: importsRepo),
            ],
            child: BlocProvider<ImportsCubit>(
              create: (context) => ImportsCubit(importsRepository: importsRepo),
              child: const Scaffold(
                body: CatalogUpdateCard(isLoading: false),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar títulos y switches
      expect(find.text('Actualización y Sincronización Incremental'), findsOneWidget);
      expect(find.text('Sincronización Segura'), findsOneWidget);
      expect(find.text('Actualizar pruebas y paquetes clínicos (updateLabTest)'), findsOneWidget);
      expect(find.text('Sobrescribir precios existentes (overridePrice)'), findsOneWidget);

      // Activar overridePrice switch
      final switchFinder = find.byType(Switch).last;
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Debe aparecer el badge de PRECAUCIÓN
      expect(find.text('PRECAUCIÓN'), findsOneWidget);

      // Pulsar botón de Sincronizar
      final syncButton = find.widgetWithText(FilledButton, 'Sincronizar Catálogo');
      expect(syncButton, findsOneWidget);
      await tester.tap(syncButton);
      await tester.pumpAndSettle();

      // Debe abrirse el diálogo de confirmación
      expect(find.text('Confirmar Sincronización'), findsOneWidget);
      expect(
        find.textContaining('ADVERTENCIA: Has seleccionado sobrescribir precios'),
        findsOneWidget,
      );

      // Confirmar en el diálogo
      final confirmBtn = find.widgetWithText(FilledButton, 'Iniciar Sincronización');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Validar que se invocó al DataSource con overridePrice: true
      expect(fakeImportsDs.lastOverridePrice, isTrue);
      expect(fakeImportsDs.lastUpdateLabTest, isTrue);
    });
  });

  group('ImportsScreen Integration with CatalogUpdateCard and Results', () {
    testWidgets('Muestra KPIs detallados cuando el estado es ImportsUpdateSuccess', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));

      final cubit = ImportsCubit(importsRepository: importsRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<BranchesRepository>.value(value: branchesRepo),
              RepositoryProvider<ImportsRepository>.value(value: importsRepo),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<AppSessionCubit>(
                  create: (_) => _MockAppSessionCubit(),
                ),
              ],
              child: ImportsScreen(cubit: cubit),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Emular emisión de resultado de actualización
      cubit.emit(
        const ImportsUpdateSuccess(
          UpdateImportResult(
            success: true,
            message: 'Sincronización completada exitosamente',
            totalProcessed: 254,
            updatedTestsCount: 230,
            createdTestsCount: 24,
            updatedAccountsCount: 15,
            skippedPricesCount: 230,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Validar tarjeta de resultados y KPIs
      expect(find.text('Resultado de la Sincronización'), findsOneWidget);
      expect(find.text('Sincronización completada exitosamente'), findsAtLeastNWidgets(1));
      expect(find.text('Total Evaluadas'), findsOneWidget);
      expect(find.text('254'), findsOneWidget);
      expect(find.text('Pruebas Actualizadas'), findsOneWidget);
      expect(find.text('230'), findsAtLeastNWidgets(1));
      expect(find.text('Nuevas Creadas'), findsOneWidget);
      expect(find.text('24'), findsOneWidget);
      expect(find.text('Precios Preservados'), findsOneWidget);

      await cubit.close();
    });
  });
}
