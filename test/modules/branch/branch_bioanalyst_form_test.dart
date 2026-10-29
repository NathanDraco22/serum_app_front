import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/cubits/branch_cubit/write_branches_cubit.dart';
import 'package:serum_app_front/src/modules/branch/widgets/branch_form_dialog.dart';
import 'package:serum_app_front/src/modules/branch/widgets/branches_list.dart';
import 'package:serum_business/serum_business.dart';

class MockWriteBranchCubit extends Cubit<WriteBranchState>
    implements WriteBranchCubit {
  MockWriteBranchCubit() : super(WriteBranchInitial());

  UpdateBranch? lastUpdateBranch;
  String? lastUpdateId;

  @override
  Future<void> update(String id, UpdateBranch branch) async {
    lastUpdateId = id;
    lastUpdateBranch = branch;
    emit(WriteBranchSuccess(BranchInDb(
      id: id,
      name: branch.name ?? '',
      address: branch.address ?? '',
      phone: branch.phone ?? '',
      bioanalyst: branch.bioanalyst,
      createdAt: 1000,
    )));
  }

  @override
  Future<void> create(CreateBranch branch) async {
    emit(WriteBranchSuccess(BranchInDb(
      id: 'NEW',
      name: branch.name,
      address: branch.address,
      phone: branch.phone,
      bioanalyst: branch.bioanalyst,
      createdAt: 1000,
    )));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAppSessionCubit extends Cubit<AppSessionState>
    implements AppSessionCubit {
  MockAppSessionCubit()
      : super(
          AppSessionState(
            currentUser: UserInDb(
              id: 'root',
              username: 'root',
              name: 'Root',
              role: 'Root',
              createdAt: 100,
            ),
          ),
        );

  @override
  bool get isRootUser => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Branch Bioanalyst Form & List Tests', () {
    testWidgets('BranchFormDialog precarga los datos del Bioanalista Representante', (tester) async {
      final mockBranch = BranchInDb(
        id: 'BR-01',
        name: 'Sucursal Matriz',
        address: 'Av. Bolívar',
        phone: '2222-3333',
        bioanalyst: BranchBioanalyst(
          name: 'Lic. Joselin Lopez',
          title: 'TECNOLOGO MEDICO',
          code: 'Codigo MINSA 88027',
        ),
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

      expect(find.text('Bioanalista Representante de la Sede'), findsOneWidget);
      expect(find.text('Lic. Joselin Lopez'), findsOneWidget);
      expect(find.text('TECNOLOGO MEDICO'), findsOneWidget);
      expect(find.text('Codigo MINSA 88027'), findsOneWidget);
    });

    testWidgets('BranchesList muestra el chip del Bioanalista cuando está definido', (tester) async {
      final branches = [
        BranchInDb(
          id: 'BR-01',
          name: 'Sucursal Matriz',
          address: 'Av. Bolívar',
          phone: '2222-3333',
          bioanalyst: BranchBioanalyst(
            name: 'Lic. Joselin Lopez',
            title: 'TECNOLOGO MEDICO',
            code: 'Codigo MINSA 88027',
          ),
          createdAt: 1000,
        ),
        BranchInDb(
          id: 'BR-02',
          name: 'Sucursal Secundaria',
          address: 'Calle Real',
          phone: '2222-4444',
          createdAt: 1000,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BranchesList(
              branches: branches,
              onEdit: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bioanalista: Lic. Joselin Lopez'), findsOneWidget);
      expect(find.text('Sucursal Secundaria'), findsOneWidget);
    });
  });
}
