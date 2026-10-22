import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/modules/branch/view/branch_screen.dart';
import 'package:serum_business/serum_business.dart';

class FakeAppSessionCubit extends Cubit<AppSessionState>
    implements AppSessionCubit {
  FakeAppSessionCubit([super.state = const AppSessionState()]);

  void emitState(AppSessionState newState) => emit(newState);

  @override
  bool get isRootUser => state.isRootUser;

  @override
  bool get hasMultipleBranches {
    final currentUser = state.currentUser;
    if (currentUser == null) return false;
    if (isRootUser) {
      return state.branches.length > 1;
    }
    return currentUser.branches.length > 1 && state.branches.length > 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeBranchesRepository implements BranchesRepository {
  @override
  List<BranchInDb> get branches => [];

  @override
  Stream<RepoEvent<BranchInDb>> get eventStream => const Stream.empty();

  @override
  Future<List<BranchInDb>> getAllBranches() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Branch Root Permission & Visibility Tests', () {
    test('UserInDb.isRoot se identifica correctamente', () {
      final rootById = UserInDb(
        id: 'root',
        username: 'admin',
        name: 'Root Admin',
        role: 'Admin',
        createdAt: 1000,
      );
      final rootByInternal = UserInDb(
        id: 'user_internal',
        username: 'some_user',
        name: 'Internal User',
        role: 'Admin',
        isInternal: true,
        createdAt: 1000,
      );
      final rootByUsername = UserInDb(
        id: 'u_123',
        username: 'Serum',
        name: 'Serum Admin',
        role: 'Admin',
        createdAt: 1000,
      );
      final standardUser = UserInDb(
        id: 'u_regular',
        username: 'operador1',
        name: 'Operador Regular',
        role: 'Operador',
        accessLevel: 3,
        createdAt: 1000,
      );

      expect(rootById.isRoot, isTrue);
      expect(rootByInternal.isRoot, isTrue);
      expect(rootByUsername.isRoot, isTrue);
      expect(standardUser.isRoot, isFalse);
    });

    testWidgets('El botón Nueva Sucursal NO aparece si el usuario no es root',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = FakeAppSessionCubit(
        AppSessionState(
          status: AppSessionStatus.authenticated,
          currentUser: UserInDb(
            id: 'regular_user',
            username: 'regular_user',
            name: 'Usuario Regular',
            role: 'Operador',
            accessLevel: 4,
            createdAt: 1000,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RepositoryProvider<BranchesRepository>(
            create: (_) => FakeBranchesRepository(),
            child: BlocProvider<AppSessionCubit>.value(
              value: cubit,
              child: const BranchesScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Nueva Sucursal'), findsNothing);
    });

    testWidgets('El botón Nueva Sucursal SÍ aparece cuando el usuario es root',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = FakeAppSessionCubit(
        AppSessionState(
          status: AppSessionStatus.authenticated,
          currentUser: UserInDb(
            id: 'root',
            username: 'Serum',
            name: 'Root Admin',
            role: 'Admin',
            isInternal: true,
            accessLevel: 5,
            createdAt: 1000,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RepositoryProvider<BranchesRepository>(
            create: (_) => FakeBranchesRepository(),
            child: BlocProvider<AppSessionCubit>.value(
              value: cubit,
              child: const BranchesScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Nueva Sucursal'), findsOneWidget);
    });

    test('Usuario Root tiene hasMultipleBranches=true cuando el sistema tiene > 1 sucursales', () {
      final rootUser = UserInDb(
        id: 'root',
        username: 'Serum',
        name: 'Root Admin',
        role: 'Admin',
        isInternal: true,
        accessLevel: 5,
        branches: ['ORIGIN_BRANCH'], // Array personal con solo 1 sucursal
        createdAt: 1000,
      );

      final branch1 = BranchInDb(
        id: 'ORIGIN_BRANCH',
        name: 'Matriz Principal',
        address: 'Calle 1',
        phone: '111',
        createdAt: 1000,
      );
      final branch2 = BranchInDb(
        id: 'BR-002',
        name: 'Sucursal Norte',
        address: 'Calle 2',
        phone: '222',
        createdAt: 1000,
      );

      final cubit = FakeAppSessionCubit(
        AppSessionState(
          status: AppSessionStatus.authenticated,
          currentUser: rootUser,
          currentBranch: branch1,
          branches: [branch1, branch2],
        ),
      );

      expect(cubit.isRootUser, isTrue);
      // Debe ser true gracias a que root tiene libertad sobre todas las sucursales del sistema
      expect(cubit.hasMultipleBranches, isTrue);
    });

    test('Usuario regular con solo 1 sucursal asignada tiene hasMultipleBranches=false', () {
      final regularUser = UserInDb(
        id: 'user_regular',
        username: 'cajero1',
        name: 'Cajero',
        role: 'Operador',
        accessLevel: 3,
        branches: ['ORIGIN_BRANCH'], // Solo 1 sucursal asignada
        createdAt: 1000,
      );

      final branch1 = BranchInDb(
        id: 'ORIGIN_BRANCH',
        name: 'Matriz Principal',
        address: 'Calle 1',
        phone: '111',
        createdAt: 1000,
      );
      final branch2 = BranchInDb(
        id: 'BR-002',
        name: 'Sucursal Norte',
        address: 'Calle 2',
        phone: '222',
        createdAt: 1000,
      );

      final cubit = FakeAppSessionCubit(
        AppSessionState(
          status: AppSessionStatus.authenticated,
          currentUser: regularUser,
          currentBranch: branch1,
          branches: [branch1, branch2],
        ),
      );

      expect(cubit.isRootUser, isFalse);
      // Para usuario común, depende de currentUser.branches.length > 1
      expect(cubit.hasMultipleBranches, isFalse);
    });
  });
}
