import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/cubits/order_cubit/write_orders_cubit.dart';
import 'package:serum_app_front/src/modules/cash_shift/widgets/cash_shift_open_dialog.dart';
import 'package:serum_app_front/src/modules/order/widgets/order_pay_dialog.dart';
import 'package:serum_business/serum_business.dart';

class _TestAppSessionCubit extends Cubit<AppSessionState> implements AppSessionCubit {
  String? switchedBranchId;

  _TestAppSessionCubit({
    required UserInDb user,
    required BranchInDb currentBranch,
    CashShiftInDb? activeShift,
  }) : super(AppSessionState(
          status: AppSessionStatus.authenticated,
          currentUser: user,
          currentBranch: currentBranch,
          activeShift: activeShift,
        ));

  @override
  UserInDb? get user => state.currentUser;

  @override
  String get currentBranchId => state.currentBranch?.id ?? 'b1';

  @override
  String get currentBranchName => state.currentBranch?.name ?? 'Sucursal Matriz';

  @override
  String get currentBranchDisplayName =>
      state.currentBranch?.displayName ?? 'Sucursal Matriz';

  @override
  String displayNameForBranch(String branchId, {String? fallbackName}) {
    if (branchId == state.currentBranch?.id) {
      return state.currentBranch!.displayName;
    }
    if (fallbackName != null && fallbackName.trim().isNotEmpty) {
      return fallbackName;
    }
    return branchId;
  }

  @override
  CashShiftInDb? get activeShift => state.activeShift;

  @override
  bool get hasActiveShift => state.hasActiveShift;

  @override
  bool get isShiftInCurrentBranch => state.isShiftInCurrentBranch;

  @override
  bool get hasShiftBranchMismatch => state.hasShiftBranchMismatch;

  @override
  Future<void> changeBranch(String branchId) async {
    switchedBranchId = branchId;
    emit(state.copyWith(
      currentBranch: BranchInDb(
        id: branchId,
        name: branchId == 'b1' ? 'Sucursal Matriz' : 'Sucursal Norte',
        address: 'Dirección',
        phone: '12345678',
        createdAt: 1000,
      ),
    ));
  }

  @override
  Future<void> fetchActiveShift([String? branchId]) async {}

  @override
  void setActiveShift(CashShiftInDb shift) {
    emit(state.copyWith(activeShift: shift));
  }

  @override
  void clearActiveShift() {
    emit(state.copyWith(clearActiveShift: true));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWriteOrderCubit extends Cubit<WriteOrderState> implements WriteOrderCubit {
  _FakeWriteOrderCubit() : super(WriteOrderInitial());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final testUser = UserInDb(
    id: 'u1',
    username: 'cajero',
    name: 'Operador Cajero',
    role: 'Operador',
    createdAt: 1000,
  );

  final branchA = BranchInDb(
    id: 'b1',
    name: 'Sucursal Matriz',
    address: 'Av Principal 123',
    phone: '555-0001',
    createdAt: 1000,
  );

  final branchB = BranchInDb(
    id: 'b2',
    name: 'Sucursal Norte',
    address: 'Av Norte 456',
    phone: '555-0002',
    createdAt: 1000,
  );

  final shiftInBranchA = CashShiftInDb(
    id: 'shift-101',
    userId: 'u1',
    userName: 'Operador Cajero',
    branchId: 'b1',
    branchName: 'Sucursal Matriz',
    status: 'OPEN',
    initialBalance: 15000, // $150.00
    cashBalance: 5000,
    totalBalance: 20000,
    openedAt: 1000,
    createdAt: 1000,
  );

  final sampleOrder = OrderInDb(
    id: 'ORD-001',
    patientId: 'p1',
    branchId: 'b2',
    totalPrice: 25000, // $250.00
    paidAmount: 0,
    status: 'pending',
    createdAt: 1000,
  );

  group('Cross-Branch Cash Shift Logic and Visual Constraints', () {
    test('AppSessionState detecta correctamente discrepancia de sucursales (mismatch)', () {
      final stateInSameBranch = AppSessionState(
        status: AppSessionStatus.authenticated,
        currentUser: testUser,
        currentBranch: branchA,
        activeShift: shiftInBranchA,
      );

      expect(stateInSameBranch.hasActiveShift, isTrue);
      expect(stateInSameBranch.isShiftInCurrentBranch, isTrue);
      expect(stateInSameBranch.hasShiftBranchMismatch, isFalse);

      final stateInDifferentBranch = AppSessionState(
        status: AppSessionStatus.authenticated,
        currentUser: testUser,
        currentBranch: branchB,
        activeShift: shiftInBranchA,
      );

      expect(stateInDifferentBranch.hasActiveShift, isTrue);
      expect(stateInDifferentBranch.isShiftInCurrentBranch, isFalse);
      expect(stateInDifferentBranch.hasShiftBranchMismatch, isTrue);
    });

    testWidgets('CashShiftOpenDialog bloquea la apertura si el usuario ya tiene turno abierto en otra sucursal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final sessionCubit = _TestAppSessionCubit(
        user: testUser,
        currentBranch: branchB, // Estamos en Sucursal Norte
        activeShift: shiftInBranchA, // Pero tiene turno en Sucursal Matriz
      );

      await tester.pumpWidget(
        BlocProvider<AppSessionCubit>.value(
          value: sessionCubit,
          child: const MaterialApp(
            home: Scaffold(
              body: CashShiftOpenDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe mostrar el diálogo de advertencia 'Turno Ya Abierto'
      expect(find.text('Turno Ya Abierto'), findsOneWidget);
      expect(find.textContaining('Actualmente tienes el turno abierto #shift-101 en la sucursal "Sucursal Matriz"'), findsOneWidget);
      expect(find.text('Ir a Sucursal Matriz'), findsOneWidget);

      // Al presionar 'Ir a Sucursal Matriz', se debe cambiar la sucursal
      await tester.tap(find.text('Ir a Sucursal Matriz'));
      await tester.pumpAndSettle();

      expect(sessionCubit.switchedBranchId, equals('b1'));
    });

    testWidgets('OrderPayDialog bloquea el cobro cuando la sucursal activa no coincide con la del turno', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final sessionCubit = _TestAppSessionCubit(
        user: testUser,
        currentBranch: branchB, // Estamos en Sucursal Norte
        activeShift: shiftInBranchA, // Turno pertenece a Sucursal Matriz
      );
      final fakeWriteOrderCubit = _FakeWriteOrderCubit();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AppSessionCubit>.value(value: sessionCubit),
            BlocProvider<WriteOrderCubit>.value(value: fakeWriteOrderCubit),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: OrderPayDialog(order: sampleOrder),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe mostrar el banner de advertencia informativa
      expect(find.text('Turno en Otra Sucursal'), findsOneWidget);
      expect(find.textContaining('Tu turno activo (#shift-101) pertenece a "Sucursal Matriz"'), findsOneWidget);
      expect(find.text('Cambiar a Sucursal Matriz'), findsOneWidget);

      // El botón de 'Registrar Pago' debe estar deshabilitado
      final payButtonFinder = find.widgetWithText(ElevatedButton, 'Registrar Pago');
      expect(payButtonFinder, findsOneWidget);
      final ElevatedButton payButton = tester.widget(payButtonFinder);
      expect(payButton.onPressed, isNull);

      // Al presionar 'Cambiar a Sucursal Matriz', ejecuta el cambio
      await tester.tap(find.text('Cambiar a Sucursal Matriz'));
      await tester.pumpAndSettle();

      expect(sessionCubit.switchedBranchId, equals('b1'));
    });
  });
}
