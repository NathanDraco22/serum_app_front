import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/branch_cubit/read_branches_cubit.dart';
import 'package:serum_app_front/src/cubits/user_cubit/write_users_cubit.dart';
import 'package:serum_app_front/src/modules/user/widgets/user_form_dialog.dart';
import 'package:serum_business/serum_business.dart';

class MockReadBranchCubit extends Cubit<ReadBranchState>
    implements ReadBranchCubit {
  MockReadBranchCubit(super.initial);

  @override
  Future<void> getAll() async {}

  void emitState(ReadBranchState newState) => emit(newState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockWriteUserCubit extends Cubit<WriteUserState>
    implements WriteUserCubit {
  MockWriteUserCubit() : super(WriteUserInitial());

  CreateUser? lastCreateUser;
  UpdateUser? lastUpdateUser;

  @override
  Future<void> create(CreateUser user) async {
    lastCreateUser = user;
    emit(UserCreated(UserInDb(
      id: 'USR-TEST-1',
      username: user.username,
      name: user.name,
      role: user.role,
      accessLevel: user.accessLevel,
      branches: user.branches,
      isActive: user.isActive,
      password: user.password,
      createdAt: 1000,
    )));
  }

  @override
  Future<void> update(String id, UpdateUser user) async {
    lastUpdateUser = user;
    emit(UserUpdated(UserInDb(
      id: id,
      username: user.username ?? 'test',
      name: user.name ?? 'test',
      role: user.role ?? 'Operador',
      accessLevel: user.accessLevel ?? 3,
      branches: user.branches ?? [],
      isActive: user.isActive ?? true,
      password: user.password ?? '123456',
      createdAt: 1000,
    )));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRolesRepository implements RolesRepository {
  @override
  Future<List<RoleInDb>> getAllRoles() async {
    return [
      RoleInDb(
        id: 'ROL-1',
        name: 'Operador',
        accessLevel: 3,
        createdAt: 1000,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final branch1 = BranchInDb(
    id: 'BR-1',
    name: 'Sucursal Central',
    address: 'Av. Bolívar 123',
    phone: '2222-3333',
    createdAt: 1000,
  );

  final branch2 = BranchInDb(
    id: 'BR-2',
    name: 'Sucursal Norte',
    address: 'Km 5 Carretera Norte',
    phone: '2222-4444',
    createdAt: 1000,
  );

  Widget createWidgetUnderTest({
    required MockReadBranchCubit readBranchCubit,
    required MockWriteUserCubit writeUserCubit,
    UserInDb? user,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 700,
            height: 900,
            child: RepositoryProvider<RolesRepository>.value(
              value: FakeRolesRepository(),
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<ReadBranchCubit>.value(value: readBranchCubit),
                  BlocProvider<WriteUserCubit>.value(value: writeUserCubit),
                ],
                child: UserFormDialog(user: user),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void configureTesterSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('UserFormDialog - Auto-selección de Sucursal Única', () {
    testWidgets(
      'Si solo existe 1 sucursal cargada, se auto-selecciona automáticamente al crear usuario',
      (tester) async {
        configureTesterSize(tester);

        final readBranchCubit = MockReadBranchCubit(
          ReadBranchSuccess([branch1]),
        );
        final writeUserCubit = MockWriteUserCubit();

        await tester.pumpWidget(createWidgetUnderTest(
          readBranchCubit: readBranchCubit,
          writeUserCubit: writeUserCubit,
        ));
        await tester.pumpAndSettle();

        // Verificar que UserBranchSelector muestra los indicadores de auto-selección
        expect(find.text('Sede única asignada'), findsOneWidget);
        expect(find.text('Única Sede (Autoasignada)'), findsOneWidget);
        expect(find.text('Autoasignado'), findsOneWidget);
        expect(
          find.textContaining('Esta es la única sede registrada en el sistema'),
          findsOneWidget,
        );

        // Completar formulario sin interactuar manualmente con la sucursal
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre Completo *'),
          'Carlos López',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre de Usuario *'),
          'clopez',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Contraseña *'),
          'password123',
        );

        // Pulsar Guardar
        final submitButton = find.text('Crear Usuario');
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Verificar que se envió la sucursal única de forma automática
        expect(writeUserCubit.lastCreateUser, isNotNull);
        expect(writeUserCubit.lastCreateUser!.branches, equals(['BR-1']));
      },
    );

    testWidgets(
      'Si la carga de 1 sucursal es asíncrona (Loading -> Success), se auto-selecciona reactivamente',
      (tester) async {
        configureTesterSize(tester);

        final readBranchCubit = MockReadBranchCubit(ReadBranchLoading());
        final writeUserCubit = MockWriteUserCubit();

        await tester.pumpWidget(createWidgetUnderTest(
          readBranchCubit: readBranchCubit,
          writeUserCubit: writeUserCubit,
        ));
        await tester.pump();

        // Se encuentra cargando
        expect(find.byType(CircularProgressIndicator), findsWidgets);

        // Emite éxito con 1 sucursal
        readBranchCubit.emitState(ReadBranchSuccess([branch1]));
        await tester.pumpAndSettle();

        // Debe haber auto-seleccionado la sucursal
        expect(find.text('Sede única asignada'), findsOneWidget);
        expect(find.text('Única Sede (Autoasignada)'), findsOneWidget);

        // Llenar campos y guardar
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre Completo *'),
          'Ana Morales',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre de Usuario *'),
          'amorales',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Contraseña *'),
          'secreto123',
        );

        final submitButton = find.text('Crear Usuario');
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(writeUserCubit.lastCreateUser, isNotNull);
        expect(writeUserCubit.lastCreateUser!.branches, equals(['BR-1']));
      },
    );

    testWidgets(
      'Si existen múltiples sucursales (>1), NO se auto-selecciona ninguna por defecto',
      (tester) async {
        configureTesterSize(tester);

        final readBranchCubit = MockReadBranchCubit(
          ReadBranchSuccess([branch1, branch2]),
        );
        final writeUserCubit = MockWriteUserCubit();

        await tester.pumpWidget(createWidgetUnderTest(
          readBranchCubit: readBranchCubit,
          writeUserCubit: writeUserCubit,
        ));
        await tester.pumpAndSettle();

        // No debe auto-seleccionar ninguna
        expect(find.text('Sin sedes asignadas'), findsOneWidget);
        expect(find.text('Única Sede (Autoasignada)'), findsNothing);

        // Al intentar enviar sin seleccionar, debe mostrar error
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre Completo *'),
          'Pedro Ruiz',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre de Usuario *'),
          'pruiz',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Contraseña *'),
          'clave123',
        );

        final submitButton = find.text('Crear Usuario');
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // No se debe haber creado y debe advertir de sucursal
        expect(writeUserCubit.lastCreateUser, isNull);
        expect(
          find.text('Debes autorizar al menos una sucursal para el usuario.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Si solo hay 1 sucursal, no se permite deseleccionarla por error',
      (tester) async {
        configureTesterSize(tester);

        final readBranchCubit = MockReadBranchCubit(
          ReadBranchSuccess([branch1]),
        );
        final writeUserCubit = MockWriteUserCubit();

        await tester.pumpWidget(createWidgetUnderTest(
          readBranchCubit: readBranchCubit,
          writeUserCubit: writeUserCubit,
        ));
        await tester.pumpAndSettle();

        // Pulsar sobre la única sucursal asignada
        final branchCard = find.text('Sucursal Central');
        await tester.ensureVisible(branchCard);
        await tester.tap(branchCard);
        await tester.pump();

        // Debe seguir asignada y mostrar aviso
        expect(find.text('Sede única asignada'), findsOneWidget);
        expect(
          find.textContaining(
            'Esta es la única sucursal del sistema y debe permanecer asignada',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'En modo edición, se conservan las sucursales asignadas originalmente al usuario',
      (tester) async {
        configureTesterSize(tester);

        final existingUser = UserInDb(
          id: 'USR-EXISTING',
          username: 'existing',
          name: 'Usuario Existente',
          role: 'Operador',
          accessLevel: 3,
          branches: ['BR-2'],
          isActive: true,
          createdAt: 1000,
        );

        final readBranchCubit = MockReadBranchCubit(
          ReadBranchSuccess([branch1, branch2]),
        );
        final writeUserCubit = MockWriteUserCubit();

        await tester.pumpWidget(createWidgetUnderTest(
          readBranchCubit: readBranchCubit,
          writeUserCubit: writeUserCubit,
          user: existingUser,
        ));
        await tester.pumpAndSettle();

        // Debe tener 1 de 2 autorizada (la BR-2)
        expect(find.text('1 de 2 autorizada'), findsOneWidget);

        // Guardar sin cambios de sucursal
        final saveButton = find.text('Guardar Cambios');
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(writeUserCubit.lastUpdateUser, isNotNull);
        expect(writeUserCubit.lastUpdateUser!.branches, equals(['BR-2']));
      },
    );
  });
}
