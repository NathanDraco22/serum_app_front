import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/cubits/cash_shift_cubit/write_cash_shifts_cubit.dart';
import 'package:serum_app_front/src/modules/cash_shift/widgets/cash_shift_close_dialog.dart';
import 'package:serum_business/serum_business.dart';

class _FakeReceiptsDataSource extends Fake implements ReceiptsDataSource {
  @override
  Future<Map<String, dynamic>> getAllReceipts({ReceiptQueryParams? queryParams}) async {
    return {
      'data': [
        {
          'id': 'rec-1',
          'receiptNumber': '101',
          'orderId': 'ord-1',
          'branchId': 'b1',
          'shiftId': 'shift-100',
          'amount': 5500, // $55.00
          'paymentMethod': 'transfer',
          'bank': 'BAC',
          'referenceNumber': 'TRF-001',
          'performedBy': {'id': 'u1', 'name': 'Cajero'},
          'createdAt': 1000,
        },
        {
          'id': 'rec-2',
          'receiptNumber': '102',
          'orderId': 'ord-2',
          'branchId': 'b1',
          'shiftId': 'shift-100',
          'amount': 2500, // $25.00
          'paymentMethod': 'transfer',
          'bank': 'BANPRO',
          'referenceNumber': 'TRF-002',
          'performedBy': {'id': 'u1', 'name': 'Cajero'},
          'createdAt': 1000,
        },
      ],
      'count': 2,
    };
  }
}

class _FakeCashShiftsDataSource extends Fake implements CashShiftsDataSource {
  @override
  Future<Map<String, dynamic>> closeCashShift(
    String shiftId,
    Map<String, dynamic> body, {
    String? userId,
  }) async {
    return {
      'id': shiftId,
      'userId': 'u1',
      'branchId': 'b1',
      'status': 'CLOSED',
      'initialBalance': 10000,
      'cashBalance': 5000,
      'cardBalance': 0,
      'transferBalance': 8000,
      'bankTransfers': {'BAC': 5000, 'BANPRO': 3000},
      'openedAt': 1000,
      'closedAt': 2000,
      'createdAt': 1000,
    };
  }
}

class _FakeAppSessionCubit extends Cubit<AppSessionState> implements AppSessionCubit {
  _FakeAppSessionCubit()
      : super(AppSessionState(
          currentUser: UserInDb(
            id: 'u1',
            username: 'cajero',
            name: 'Operador Cajero',
            role: 'Operador',
            createdAt: 1000,
          ),
        ));

  @override
  UserInDb? get user => state.currentUser;

  @override
  void clearActiveShift() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeReceiptsDataSource fakeReceiptsDataSource;
  late ReceiptsRepository receiptsRepo;
  late _FakeCashShiftsDataSource fakeCashShiftsDataSource;
  late CashShiftsRepository cashShiftsRepo;
  late WriteCashShiftCubit writeCashShiftCubit;
  late _FakeAppSessionCubit fakeSessionCubit;

  final shiftWithTransfers = CashShiftInDb(
    id: 'shift-100',
    userId: 'u1',
    branchId: 'b1',
    initialBalance: 10000,
    cashBalance: 5000,
    cardBalance: 2000,
    transferBalance: 8000, // $80.00 total
    openedAt: 1000,
    createdAt: 1000,
    status: 'OPEN',
  );

  setUp(() {
    fakeReceiptsDataSource = _FakeReceiptsDataSource();
    receiptsRepo = ReceiptsRepository(fakeReceiptsDataSource);
    fakeCashShiftsDataSource = _FakeCashShiftsDataSource();
    cashShiftsRepo = CashShiftsRepository(fakeCashShiftsDataSource);
    writeCashShiftCubit =
        WriteCashShiftCubit(cashShiftsRepository: cashShiftsRepo);
    fakeSessionCubit = _FakeAppSessionCubit();
  });

  testWidgets('CashShiftCloseDialog carga y desglosa transferencias por banco en vivo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ReceiptsRepository>.value(value: receiptsRepo),
          RepositoryProvider<CashShiftsRepository>.value(value: cashShiftsRepo),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AppSessionCubit>.value(value: fakeSessionCubit),
            BlocProvider<WriteCashShiftCubit>.value(value: writeCashShiftCubit),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CashShiftCloseDialog(shift: shiftWithTransfers),
            ),
          ),
        ),
      ),
    );

    // Esperar a que se resuelvan las consultas asíncronas
    await tester.pumpAndSettle();

    // Validar indicadores generales
    expect(find.text('Transferencias'), findsOneWidget);
    expect(find.text('\$80.00'), findsOneWidget);

    // Validar encabezado del desglose por banco
    expect(find.text('Desglose por Banco (Referencia):'), findsOneWidget);

    // Validar los bancos desglosados y sus montos
    expect(find.text('BAC: '), findsOneWidget);
    expect(find.text('\$55.00'), findsOneWidget);

    expect(find.text('BANPRO: '), findsOneWidget);
    expect(find.text('\$25.00'), findsOneWidget);
  });
}
