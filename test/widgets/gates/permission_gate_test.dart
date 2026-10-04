import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/widgets/gates/permission_gate.dart';
import 'package:serum_business/serum_business.dart';

class FakeAppSessionCubit extends Cubit<AppSessionState>
    implements AppSessionCubit {
  FakeAppSessionCubit([super.state = const AppSessionState()]);

  void emitState(AppSessionState newState) => emit(newState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  UserInDb createUser({
    required int accessLevel,
    bool isActive = true,
    bool isDeleted = false,
  }) {
    return UserInDb(
      id: 'test-user-id',
      username: 'test_user',
      name: 'Test User',
      role: 'User',
      accessLevel: accessLevel,
      isActive: isActive,
      isDeleted: isDeleted,
      createdAt: 1000,
    );
  }

  Widget createTestWidget({
    required FakeAppSessionCubit cubit,
    required Widget child,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<AppSessionCubit>.value(
          value: cubit,
          child: child,
        ),
      ),
    );
  }

  testWidgets(
      'PermissionGate otorga hasPermission=true cuando userLevel >= level (atLeast)',
      (WidgetTester tester) async {
    final cubit = FakeAppSessionCubit(
      AppSessionState(
        status: AppSessionStatus.authenticated,
        currentUser: createUser(accessLevel: 4),
      ),
    );

    await tester.pumpWidget(
      createTestWidget(
        cubit: cubit,
        child: PermissionGate(
          level: AccessLevels.operator, // nivel 3, usuario tiene 4
          builder: (context, hasPermission) {
            return ElevatedButton(
              onPressed: hasPermission ? () {} : null,
              child: Text(hasPermission ? 'Autorizado' : 'Restringido'),
            );
          },
        ),
      ),
    );

    expect(find.text('Autorizado'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.enabled, isTrue);
  });

  testWidgets(
      'PermissionGate otorga hasPermission=false cuando userLevel < level',
      (WidgetTester tester) async {
    final cubit = FakeAppSessionCubit(
      AppSessionState(
        status: AppSessionStatus.authenticated,
        currentUser: createUser(accessLevel: 2), // nivel 2 Asistente
      ),
    );

    await tester.pumpWidget(
      createTestWidget(
        cubit: cubit,
        child: PermissionGate(
          level: AccessLevels.operator, // requiere nivel 3
          builder: (context, hasPermission) {
            if (!hasPermission) {
              return const SizedBox.shrink();
            }
            return const Text('Panel de Operador');
          },
        ),
      ),
    );

    expect(find.text('Panel de Operador'), findsNothing);
  });

  testWidgets(
      'PermissionGate niega acceso si el usuario está inactivo o eliminado',
      (WidgetTester tester) async {
    final cubit = FakeAppSessionCubit(
      AppSessionState(
        status: AppSessionStatus.authenticated,
        currentUser: createUser(accessLevel: 5, isActive: false),
      ),
    );

    await tester.pumpWidget(
      createTestWidget(
        cubit: cubit,
        child: PermissionGate(
          level: AccessLevels.operator,
          builder: (context, hasPermission) {
            return Text(hasPermission ? 'Activo' : 'Inactivo');
          },
        ),
      ),
    );

    expect(find.text('Inactivo'), findsOneWidget);
  });

  testWidgets(
      'PermissionGate respeta allowedLevels cuando se proporciona la lista',
      (WidgetTester tester) async {
    final cubit = FakeAppSessionCubit(
      AppSessionState(
        status: AppSessionStatus.authenticated,
        currentUser: createUser(accessLevel: 3),
      ),
    );

    await tester.pumpWidget(
      createTestWidget(
        cubit: cubit,
        child: PermissionGate(
          level: AccessLevels.admin, // Ignorado porque hay allowedLevels
          allowedLevels: const [1, 2], // 3 no está incluido
          builder: (context, hasPermission) {
            return Text(hasPermission ? 'Permitido' : 'Denegado');
          },
        ),
      ),
    );

    expect(find.text('Denegado'), findsOneWidget);
  });

  testWidgets(
      'PermissionGate reacciona a cambios de estado en AppSessionCubit',
      (WidgetTester tester) async {
    final cubit = FakeAppSessionCubit(
      AppSessionState(
        status: AppSessionStatus.authenticated,
        currentUser: createUser(accessLevel: 1),
      ),
    );

    await tester.pumpWidget(
      createTestWidget(
        cubit: cubit,
        child: PermissionGate(
          level: AccessLevels.supervisor,
          builder: (context, hasPermission) {
            return Text(hasPermission ? 'Acceso Supervisor' : 'Sin Acceso');
          },
        ),
      ),
    );

    expect(find.text('Sin Acceso'), findsOneWidget);

    // Se actualiza el usuario a nivel 5
    cubit.emitState(
      AppSessionState(
        status: AppSessionStatus.authenticated,
        currentUser: createUser(accessLevel: 5),
      ),
    );
    await tester.pump();

    expect(find.text('Acceso Supervisor'), findsOneWidget);
  });

  testWidgets('PermissionGate respeta dimensiones width y height',
      (WidgetTester tester) async {
    final cubit = FakeAppSessionCubit(
      AppSessionState(
        status: AppSessionStatus.authenticated,
        currentUser: createUser(accessLevel: 5),
      ),
    );

    await tester.pumpWidget(
      createTestWidget(
        cubit: cubit,
        child: PermissionGate(
          level: AccessLevels.admin,
          width: 120,
          height: 50,
          builder: (context, hasPermission) => const Placeholder(),
        ),
      ),
    );

    final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
    expect(sizedBox.width, 120);
    expect(sizedBox.height, 50);
  });
}
