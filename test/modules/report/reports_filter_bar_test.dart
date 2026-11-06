import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/cubits/report_cubit/report_cubit.dart';
import 'package:serum_app_front/src/cubits/report_cubit/report_state.dart';
import 'package:serum_app_front/src/modules/report/widgets/reports_filter_bar.dart';
import 'package:serum_business/serum_business.dart';

class _MockAppSessionCubit extends Cubit<AppSessionState>
    implements AppSessionCubit {
  _MockAppSessionCubit()
      : super(
          AppSessionState(
            currentUser: UserInDb(
              id: 'u1',
              username: 'admin',
              name: 'Admin',
              role: 'Admin',
              createdAt: 0,
            ),
            branches: const [],
          ),
        );

  @override
  List<BranchInDb> get branches => state.branches;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SpyReportCubit extends Cubit<ReportState> implements ReportCubit {
  DateTime? lastSetStart;
  DateTime? lastSetEnd;

  _SpyReportCubit()
      : super(
          ReportState(
            startDate: DateTime.now(),
            endDate: DateTime.now(),
          ),
        );

  @override
  Future<void> setDateRange(DateTime start, DateTime end) async {
    lastSetStart = start;
    lastSetEnd = end;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ReportsFilterBar muestra el botón Ayer y configura el rango del día anterior',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final spyReportCubit = _SpyReportCubit();
    final mockSessionCubit = _MockAppSessionCubit();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<ReportCubit>.value(value: spyReportCubit),
              BlocProvider<AppSessionCubit>.value(value: mockSessionCubit),
            ],
            child: const ReportsFilterBar(),
          ),
        ),
      ),
    );

    // Verificar que los botones de presets existen
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Ayer'), findsOneWidget);
    expect(find.text('7 días'), findsOneWidget);
    expect(find.text('Este mes'), findsOneWidget);

    // Tocar el botón 'Ayer'
    await tester.tap(find.text('Ayer'));
    await tester.pumpAndSettle();

    final expectedYesterday = DateTime.now().subtract(const Duration(days: 1));
    expect(spyReportCubit.lastSetStart, isNotNull);
    expect(spyReportCubit.lastSetEnd, isNotNull);
    expect(spyReportCubit.lastSetStart!.day, equals(expectedYesterday.day));
    expect(spyReportCubit.lastSetStart!.month, equals(expectedYesterday.month));
    expect(spyReportCubit.lastSetStart!.year, equals(expectedYesterday.year));
    expect(spyReportCubit.lastSetEnd!.day, equals(expectedYesterday.day));
  });
}
