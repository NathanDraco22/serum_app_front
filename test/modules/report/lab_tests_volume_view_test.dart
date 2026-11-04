import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/report_cubit/report_cubit.dart';
import 'package:serum_app_front/src/cubits/report_cubit/report_state.dart';
import 'package:serum_app_front/src/modules/report/widgets/lab_tests_volume_view.dart';
import 'package:serum_business/serum_business.dart';

class _FakeReportCubit extends Cubit<ReportState> implements ReportCubit {
  _FakeReportCubit({ReportState? initialState})
      : super(
          initialState ??
              ReportState(
                startDate: DateTime(2026, 10, 4),
                endDate: DateTime(2026, 10, 4),
              ),
        );

  @override
  Future<void> setLabTestsSource(String source) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({
    required LabTestsVolumeReportResponse report,
    ReportState? reportState,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<ReportCubit>(
          create: (_) => _FakeReportCubit(initialState: reportState),
          child: LabTestsVolumeView(report: report),
        ),
      ),
    );
  }

  group('LabTestsVolumeView - Botón de Copiar Desglose al Portapapeles', () {
    final startMs = DateTime(2026, 10, 4, 0, 0).millisecondsSinceEpoch;
    final endMs = DateTime(2026, 10, 4, 23, 59).millisecondsSinceEpoch;
    String? capturedClipboardText;

    setUp(() {
      capturedClipboardText = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          capturedClipboardText = (methodCall.arguments as Map)['text'] as String?;
          return null;
        }
        if (methodCall.method == 'Clipboard.getData') {
          return <String, dynamic>{'text': capturedClipboardText};
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final sampleTests = [
      const LabTestVolumeItem(
        labTestId: 't1',
        name: 'Hemograma Completo',
        category: 'Hematología',
        isPack: false,
        timesOrdered: 15,
        totalRevenue: 450000,
      ),
      const LabTestVolumeItem(
        labTestId: 'p1',
        name: 'Perfil Lipídico',
        category: 'Química Clínica',
        isPack: true,
        timesOrdered: 10,
        totalRevenue: 600000,
      ),
    ];

    testWidgets('renderiza el botón de copiar con icono y tooltip adecuado', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final report = LabTestsVolumeReportResponse(
        startDate: startMs,
        endDate: endMs,
        source: 'orders',
        summary: LabTestsVolumeSummary(
          totalTestsCount: 25,
          totalRevenue: 1050000,
          topTests: sampleTests,
        ),
      );

      await tester.pumpWidget(buildTestWidget(report: report));
      await tester.pumpAndSettle();

      final copyButtonFinder = find.byKey(const Key('copy_lab_tests_volume_breakdown_button'));
      expect(copyButtonFinder, findsOneWidget);

      final iconFinder = find.descendant(
        of: copyButtonFinder,
        matching: find.byIcon(Icons.copy_rounded),
      );
      expect(iconFinder, findsOneWidget);

      final tooltipFinder = find.byWidgetPredicate(
        (widget) => widget is Tooltip && widget.message == 'Copiar desglose al portapapeles',
      );
      expect(tooltipFinder, findsOneWidget);
    });

    testWidgets('al pulsar el botón copia el texto formateado al portapapeles sin PACK/INDIVIDUAL y muestra SnackBar', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final report = LabTestsVolumeReportResponse(
        startDate: startMs,
        endDate: endMs,
        source: 'orders',
        summary: LabTestsVolumeSummary(
          totalTestsCount: 25,
          totalRevenue: 1050000,
          topTests: sampleTests,
        ),
      );

      await tester.pumpWidget(buildTestWidget(report: report));
      await tester.pumpAndSettle();

      final copyButtonFinder = find.byKey(const Key('copy_lab_tests_volume_breakdown_button'));
      await tester.tap(copyButtonFinder);
      await tester.pump();

      expect(find.text('Desglose de demanda copiado al portapapeles'), findsOneWidget);

      expect(capturedClipboardText, isNotNull);
      final text = capturedClipboardText!;

      // Verifica fecha única
      expect(text, contains('Fecha: 04/10/2026'));
      expect(text, contains('Fuente: Órdenes Clínicas'));
      expect(text, contains('Desglose de demanda:'));

      // Verifica los elementos formateados como: Nombre - Cantidad X Precio unitario
      expect(text, contains('Hemograma Completo - 15 X 300'));
      expect(text, contains('Perfil Lipídico - 10 X 600'));

      // Confirma que no contiene "veces", ni PACK/INDIVIDUAL
      expect(text, isNot(contains('veces')));
      expect(text, isNot(contains('(PACK)')));
      expect(text, isNot(contains('(INDIVIDUAL)')));

      // Verifica totales
      expect(text, contains('Total Solicitudes: 25'));
      expect(text, contains('Total Ingresos: 10,500'));

      // Drenar animación de SnackBar
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('formatea correctamente rango de fechas cuando abarcan varios días', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final multiDayStart = DateTime(2026, 10, 1, 0, 0).millisecondsSinceEpoch;
      final multiDayEnd = DateTime(2026, 10, 5, 23, 59).millisecondsSinceEpoch;

      final report = LabTestsVolumeReportResponse(
        startDate: multiDayStart,
        endDate: multiDayEnd,
        source: 'quotations',
        summary: LabTestsVolumeSummary(
          totalTestsCount: 25,
          totalRevenue: 1050000,
          topTests: sampleTests,
        ),
      );

      await tester.pumpWidget(buildTestWidget(report: report));
      await tester.pumpAndSettle();

      final copyButtonFinder = find.byKey(const Key('copy_lab_tests_volume_breakdown_button'));
      await tester.tap(copyButtonFinder);
      await tester.pump();

      expect(capturedClipboardText, isNotNull);
      final text = capturedClipboardText!;

      expect(text, contains('Fecha: 01/10/2026 al 05/10/2026'));
      expect(text, contains('Fuente: Cotizaciones'));

      // Drenar animación de SnackBar
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
