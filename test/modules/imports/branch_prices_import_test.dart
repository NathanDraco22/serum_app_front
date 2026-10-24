import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/cubits/imports_cubit/imports_cubit.dart';
import 'package:serum_app_front/src/cubits/imports_cubit/imports_state.dart';
import 'package:serum_app_front/src/modules/imports/view/imports_screen.dart';
import 'package:serum_app_front/src/modules/imports/widgets/branch_prices_import_card.dart';
import 'package:serum_business/serum_business.dart';

class _FakeImportsDataSource extends Fake implements ImportsDataSource {
  ImportBranchPricesResult? stubbedPricesResult;
  String? lastSourceBranchId;
  String? lastTargetBranchId;
  bool? lastMustOverridePrice;

  @override
  Future<Map<String, dynamic>> importBranchPrices({
    required String sourceBranchId,
    required String targetBranchId,
    bool mustOverridePrice = false,
  }) async {
    lastSourceBranchId = sourceBranchId;
    lastTargetBranchId = targetBranchId;
    lastMustOverridePrice = mustOverridePrice;

    return stubbedPricesResult?.toJson() ??
        {
          'success': true,
          'message': 'Precios importados exitosamente',
          'sourceBranchId': sourceBranchId,
          'sourceBranchName': 'Sucursal Central',
          'targetBranchId': targetBranchId,
          'targetBranchName': 'Sucursal Norte',
          'mustOverridePrice': mustOverridePrice,
          'totalEvaluated': 10,
          'updatedCount': 5,
          'createdCount': 2,
          'skippedCount': 3,
        };
  }
}

class _FakeBranchesDataSource extends Fake implements BranchesDataSource {
  @override
  Future<Map<String, dynamic>> getAllBranches() async {
    return {
      'count': 2,
      'data': [
        {
          'id': 'branch-1',
          'name': 'Sucursal Central',
          'address': 'Av. Principal',
          'phone': '555-1111',
          'createdAt': 1000,
        },
        {
          'id': 'branch-2',
          'name': 'Sucursal Norte',
          'address': 'Calle Norte',
          'phone': '555-2222',
          'createdAt': 2000,
        },
      ],
    };
  }
}

class _MockAppSessionCubit extends Cubit<AppSessionState>
    implements AppSessionCubit {
  _MockAppSessionCubit()
      : super(AppSessionState(
          status: AppSessionStatus.authenticated,
          currentUser: UserInDb(
            id: 'admin-1',
            username: 'admin',
            name: 'Administrador',
            role: 'admin',
            accessLevel: 5,
            branches: const ['branch-1', 'branch-2'],
            createdAt: 1000,
          ),
        ));

  @override
  String get currentBranchId => 'branch-1';

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

  group('ImportsCubit - Importación de Precios entre Sucursales', () {
    test('importBranchPrices emite ImportsLoading y luego ImportsPricesSuccess',
        () async {
      final cubit = ImportsCubit(importsRepository: importsRepo);

      final futureExpect = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ImportsLoading>(),
          isA<ImportsPricesSuccess>(),
        ]),
      );

      final result = await cubit.importBranchPrices(
        sourceBranchId: 'branch-1',
        targetBranchId: 'branch-2',
        mustOverridePrice: true,
      );

      await futureExpect;

      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(result.mustOverridePrice, isTrue);
      expect(result.totalEvaluated, equals(10));
      expect(result.updatedCount, equals(5));
      expect(fakeImportsDs.lastSourceBranchId, equals('branch-1'));
      expect(fakeImportsDs.lastTargetBranchId, equals('branch-2'));
      expect(fakeImportsDs.lastMustOverridePrice, isTrue);

      expect(cubit.state, isA<ImportsPricesSuccess>());
      expect((cubit.state as ImportsPricesSuccess).result.sourceBranchId,
          equals('branch-1'));

      await cubit.close();
    });
  });

  group('BranchPricesImportCard Widget Tests', () {
    testWidgets('Renderiza selectores de sedes y switch de mustOverridePrice',
        (tester) async {
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
                body: BranchPricesImportCard(isLoading: false),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar título de la tarjeta
      expect(
        find.text('Importación de Precios entre Sucursales'),
        findsOneWidget,
      );
      expect(find.text('Multi-Sede'), findsOneWidget);

      // Verificar selectores
      expect(find.text('Sucursal Origen (Copiar desde)'), findsOneWidget);
      expect(find.text('Sucursal Destino (Pegar en)'), findsOneWidget);

      // Verificar switch
      expect(
        find.text('Sobrescribir precios existentes (mustOverridePrice)'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Solo actualiza aquellas pruebas'),
        findsOneWidget,
      );

      // Cambiar el switch a activo
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Verificar que el texto descriptivo cambie a modo sobrescritura
      expect(
        find.textContaining('Sobrescribe todos los precios en la sede destino'),
        findsOneWidget,
      );

      // Botón de acción
      expect(find.text('Iniciar Importación de Precios'), findsOneWidget);
    });
  });

  group('ImportsScreen Integration Test', () {
    testWidgets(
        'ImportsScreen muestra catálogo por defecto y tarjeta de precios',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));

      await tester.pumpWidget(
        MaterialApp(
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<BranchesRepository>.value(value: branchesRepo),
              RepositoryProvider<ImportsRepository>.value(value: importsRepo),
            ],
            child: BlocProvider<AppSessionCubit>(
              create: (context) => _MockAppSessionCubit(),
              child: const ImportsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que ambas tarjetas estén presentes
      expect(find.text('Catálogo Clínico Maestro por Defecto'), findsOneWidget);
      expect(
        find.text('Importación de Precios entre Sucursales'),
        findsOneWidget,
      );
    });
  });
}
