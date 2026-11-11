import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/cubits/branch_cubit/write_branches_cubit.dart';
import 'package:serum_app_front/src/modules/branch/widgets/branch_form_dialog.dart';
import 'package:serum_business/serum_business.dart';

class MockWriteBranchCubit extends Cubit<WriteBranchState>
    implements WriteBranchCubit {
  MockWriteBranchCubit() : super(WriteBranchInitial());

  CreateBranch? lastCreated;
  UpdateBranch? lastUpdated;
  String? lastUpdatedId;

  @override
  Future<void> create(CreateBranch branch) async {
    lastCreated = branch;
    emit(WriteBranchSuccess(BranchInDb(
      id: 'NEW-ID',
      name: branch.name,
      address: branch.address,
      city: branch.city,
      phone: branch.phone,
      bioanalyst: branch.bioanalyst,
      createdAt: 1000,
    )));
  }

  @override
  Future<void> update(String id, UpdateBranch branch) async {
    lastUpdatedId = id;
    lastUpdated = branch;
    emit(WriteBranchSuccess(BranchInDb(
      id: id,
      name: branch.name ?? '',
      address: branch.address ?? '',
      city: branch.city ?? '',
      phone: branch.phone ?? '',
      bioanalyst: branch.bioanalyst,
      createdAt: 1000,
    )));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAppSessionCubit extends Cubit<AppSessionState>
    implements AppSessionCubit {
  MockAppSessionCubit({this.isRoot = true})
      : super(
          AppSessionState(
            currentUser: UserInDb(
              id: isRoot ? 'root' : 'u-std',
              username: isRoot ? 'root' : 'user',
              name: isRoot ? 'Root' : 'User',
              role: isRoot ? 'Root' : 'Operador',
              createdAt: 100,
            ),
          ),
        );

  final bool isRoot;

  @override
  bool get isRootUser => isRoot;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('BranchFormDialog Integration Tests', () {
    testWidgets('Renderiza todas las subsecciones modulares en modo creación',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final writeCubit = MockWriteBranchCubit();
      final sessionCubit = MockAppSessionCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<WriteBranchCubit>.value(value: writeCubit),
              BlocProvider<AppSessionCubit>.value(value: sessionCubit),
            ],
            child: const Scaffold(
              body: BranchFormDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nueva Sucursal / Sede'), findsOneWidget);
      expect(find.text('Identidad Visual de la Sucursal'), findsOneWidget);
      expect(find.text('Información General'), findsOneWidget);
      expect(find.text('Ciudad / Localidad'), findsOneWidget);
      expect(find.text('Bioanalista Representante de la Sede'), findsOneWidget);
      expect(find.text('Bioanalistas Auxiliares'), findsOneWidget);
      expect(find.text('Crear Sucursal'), findsOneWidget);
    });

    testWidgets('Envío exitoso de CreateBranch al validar campos',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final writeCubit = MockWriteBranchCubit();
      final sessionCubit = MockAppSessionCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<WriteBranchCubit>.value(value: writeCubit),
              BlocProvider<AppSessionCubit>.value(value: sessionCubit),
            ],
            child: const Scaffold(
              body: BranchFormDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Completar campos obligatorios
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre de la Sucursal *'),
        'Sucursal Central',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Dirección Completa *'),
        'Av. Independencia 123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ciudad / Localidad'),
        'Matagalpa',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Teléfono de Contacto *'),
        '2255-0000',
      );

      // Pulsar Crear Sucursal
      await tester.ensureVisible(find.text('Crear Sucursal'));
      await tester.tap(find.text('Crear Sucursal'));
      await tester.pumpAndSettle();

      expect(writeCubit.lastCreated, isNotNull);
      expect(writeCubit.lastCreated!.name, equals('Sucursal Central'));
      expect(writeCubit.lastCreated!.address, equals('Av. Independencia 123'));
      expect(writeCubit.lastCreated!.city, equals('Matagalpa'));
      expect(writeCubit.lastCreated!.phone, equals('2255-0000'));
    });

    testWidgets('Envío exitoso de UpdateBranch en modo edición',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockBranch = BranchInDb(
        id: 'BR-99',
        name: 'Sucursal Vieja',
        address: 'Calle Vieja',
        city: 'Estelí',
        phone: '1111-2222',
        createdAt: 1000,
      );

      final writeCubit = MockWriteBranchCubit();
      final sessionCubit = MockAppSessionCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<WriteBranchCubit>.value(value: writeCubit),
              BlocProvider<AppSessionCubit>.value(value: sessionCubit),
            ],
            child: Scaffold(
              body: BranchFormDialog(branch: mockBranch),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Editar Sucursal'), findsOneWidget);
      expect(find.text('Guardar Cambios'), findsOneWidget);

      // Modificar nombre
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre de la Sucursal *'),
        'Sucursal Renovada',
      );

      await tester.ensureVisible(find.text('Guardar Cambios'));
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pumpAndSettle();

      expect(writeCubit.lastUpdatedId, equals('BR-99'));
      expect(writeCubit.lastUpdated, isNotNull);
      expect(writeCubit.lastUpdated!.name, equals('Sucursal Renovada'));
      expect(writeCubit.lastUpdated!.city, equals('Estelí'));
    });
  });
}
