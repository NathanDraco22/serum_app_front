import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:serum_app_front/src/cubits/report_cubit/report_cubit.dart';
import 'package:serum_app_front/src/cubits/report_cubit/report_state.dart';
import 'package:serum_app_front/src/modules/report/dialogs/chrono_report_models.dart';
import 'package:serum_app_front/src/modules/report/widgets/lab_tests_volume_view.dart';
import 'package:serum_business/serum_business.dart';

class _FakeReportCubit extends Cubit<ReportState> implements ReportCubit {
  _FakeReportCubit({ReportState? initialState})
      : super(
          initialState ??
              ReportState(
                startDate: DateTime(2026, 11, 1),
                endDate: DateTime(2026, 11, 30),
              ),
        );

  @override
  Future<void> setLabTestsSource(String source) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChronoReport - Lógica de Agregación de Datos', () {
    final catalog = [
      LabTestInDb(
        id: 't_hem',
        name: 'Biometría Hemática Completa',
        commercialCategory: 'Hematología',
        createdAt: 0,
      ),
      LabTestInDb(
        id: 't_pla',
        name: 'Plaquetas',
        commercialCategory: 'Hematología',
        createdAt: 0,
      ),
      LabTestInDb(
        id: 't_ori',
        name: 'Examen General de Orina',
        commercialCategory: 'Uroanálisis',
        createdAt: 0,
      ),
      LabTestInDb(
        id: 't_cop',
        name: 'Examen General de Heces',
        commercialCategory: 'Coprología',
        createdAt: 0,
      ),
    ];

    test('Agrega órdenes correctamente por día, categoría y pacientes distintos', () {
      final nov2 = DateTime(2026, 11, 2, 10, 0).millisecondsSinceEpoch;
      final nov3 = DateTime(2026, 11, 3, 15, 30).millisecondsSinceEpoch;

      final orders = [
        OrderInDb(
          id: 'o1',
          patientId: 'p1',
          branchId: 'b1',
          createdAt: nov2,
          items: [
            OrderItem(labTestId: 't_hem', name: 'Biometría Hemática Completa', salePriceApplied: 100),
            OrderItem(labTestId: 't_ori', name: 'Examen General de Orina', salePriceApplied: 50),
          ],
        ),
        OrderInDb(
          id: 'o2',
          patientId: 'p1', // Mismo paciente en el día 2
          branchId: 'b1',
          createdAt: nov2,
          items: [
            OrderItem(labTestId: 't_hem', name: 'Biometría Hemática Completa', salePriceApplied: 100),
          ],
        ),
        OrderInDb(
          id: 'o3',
          patientId: 'p2', // Paciente 2 en el día 3
          branchId: 'b1',
          createdAt: nov3,
          items: [
            OrderItem(labTestId: 't_cop', name: 'Examen General de Heces', salePriceApplied: 80),
          ],
        ),
      ];

      final data = aggregateChronoReportData(
        year: 2026,
        month: 11,
        catalog: catalog,
        orders: orders,
      );

      // Verificación de días en el mes (Noviembre = 30 días)
      expect(data.daysInMonth, 30);
      expect(data.year, 2026);
      expect(data.month, 11);

      // Conteo de pacientes por día:
      // Día 2: 1 paciente único ('p1')
      expect(data.dailyPatients[2], 1);
      // Día 3: 1 paciente único ('p2')
      expect(data.dailyPatients[3], 1);
      // Día 1: 0 pacientes
      expect(data.dailyPatients[1], 0);
      expect(data.totalMonthPatients, 2);

      // Verificación de Categorías
      final hemCategory = data.categories.firstWhere((c) => c.name == 'HEMATOLOGÍA');
      final uroCategory = data.categories.firstWhere((c) => c.name == 'UROANÁLISIS');
      final copCategory = data.categories.firstWhere((c) => c.name == 'COPROLOGÍA');

      // Biometría Hemática Completa: 2 en día 2, 0 en día 3 -> Total = 2
      final hemRow = hemCategory.rows.firstWhere((r) => r.examId == 't_hem');
      expect(hemRow.dailyCounts[2], 2);
      expect(hemRow.dailyCounts[3], 0);
      expect(hemRow.total, 2);

      // Plaquetas: 0 en todos los días -> Total = 0
      final plaRow = hemCategory.rows.firstWhere((r) => r.examId == 't_pla');
      expect(plaRow.total, 0);

      // Examen General de Orina: 1 en día 2 -> Total = 1
      final oriRow = uroCategory.rows.firstWhere((r) => r.examId == 't_ori');
      expect(oriRow.dailyCounts[2], 1);
      expect(oriRow.total, 1);

      // Examen General de Heces: 1 en día 3 -> Total = 1
      final copRow = copCategory.rows.firstWhere((r) => r.examId == 't_cop');
      expect(copRow.dailyCounts[3], 1);
      expect(copRow.total, 1);

      // Total acumulado del mes
      expect(data.totalMonthExams, 4);
    });

    test('Agrega cotizaciones cuando isQuotations es verdadero', () {
      final nov5 = DateTime(2026, 11, 5, 11, 0).millisecondsSinceEpoch;

      final quotations = [
        QuotationInDb(
          id: 'q1',
          clientName: 'Cliente Casual',
          branchId: 'b1',
          totalAmount: 150,
          createdAt: nov5,
          exams: [
            QuotedExam(labTestId: 't_hem', name: 'Biometría Hemática Completa', quotedPrice: 100),
          ],
        ),
      ];

      final data = aggregateChronoReportData(
        year: 2026,
        month: 11,
        catalog: catalog,
        orders: const [],
        quotations: quotations,
        isQuotations: true,
      );

      expect(data.dailyPatients[5], 1);
      final hemCat = data.categories.firstWhere((c) => c.name == 'HEMATOLOGÍA');
      final hemRow = hemCat.rows.firstWhere((r) => r.examId == 't_hem');
      expect(hemRow.dailyCounts[5], 1);
      expect(hemRow.total, 1);
    });

    test('Excluye parámetros internos de perfiles (isProfileParameter == true)', () {
      final customCatalog = [
        ...catalog,
        LabTestInDb(
          id: 'param_leuco',
          name: 'Leucocitos',
          commercialCategory: 'Hematología',
          isProfileParameter: true,
          createdAt: 0,
        ),
      ];

      final data = aggregateChronoReportData(
        year: 2026,
        month: 11,
        catalog: customCatalog,
        orders: const [],
      );

      final hemCat = data.categories.firstWhere((c) => c.name == 'HEMATOLOGÍA');
      final examIds = hemCat.rows.map((r) => r.examId).toList();
      expect(examIds, contains('t_hem'));
      expect(examIds, isNot(contains('param_leuco')));
    });

    test('Excluye parámetros componentes de un pack cuando no tienen demanda individual', () {
      final packCatalog = [
        LabTestInDb(
          id: 'pack_bhc',
          name: 'Biometría Hemática Completa',
          commercialCategory: 'Hematología',
          isPack: true,
          childTestIds: ['param_leuco', 'param_hb', 'param_htc'],
          createdAt: 0,
        ),
        LabTestInDb(
          id: 'param_leuco',
          name: 'Leucocitos',
          commercialCategory: 'Hematología',
          createdAt: 0,
        ),
        LabTestInDb(
          id: 'param_hb',
          name: 'Hemoglobina',
          commercialCategory: 'Hematología',
          createdAt: 0,
        ),
        LabTestInDb(
          id: 'param_htc',
          name: 'Hematocrito',
          commercialCategory: 'Hematología',
          createdAt: 0,
        ),
      ];

      final orders = [
        OrderInDb(
          id: 'o_pack',
          patientId: 'p1',
          branchId: 'b1',
          createdAt: DateTime(2026, 11, 2).millisecondsSinceEpoch,
          items: [
            OrderItem(labTestId: 'pack_bhc', name: 'Biometría Hemática Completa', salePriceApplied: 300),
            OrderItem(labTestId: 'param_htc', name: 'Hematocrito', salePriceApplied: 40),
          ],
        ),
      ];

      final data = aggregateChronoReportData(
        year: 2026,
        month: 11,
        catalog: packCatalog,
        orders: orders,
      );

      final hemCat = data.categories.firstWhere((c) => c.name == 'HEMATOLOGÍA');
      final examIds = hemCat.rows.map((r) => r.examId).toList();

      // El Pack siempre se muestra
      expect(examIds, contains('pack_bhc'));
      // El Hematocrito se muestra porque tuvo demanda atómica > 0
      expect(examIds, contains('param_htc'));
      // Leucocitos y Hemoglobina se excluyen porque son hijos del pack y tuvieron demanda 0
      expect(examIds, isNot(contains('param_leuco')));
      expect(examIds, isNot(contains('param_hb')));
    });
  });

  group('ChronoReport - Construcción de Columnas y Filas PlutoGrid', () {
    final data = ChronoReportMonthData(
      year: 2026,
      month: 11,
      daysInMonth: 30,
      dailyPatients: {for (int d = 1; d <= 30; d++) d: d == 2 ? 5 : 0},
      categories: [
        ChronoReportCategory(
          name: 'HEMATOLOGÍA',
          rows: [
            ChronoReportExamRow(
              examId: 'e1',
              examName: 'Hemograma',
              category: 'HEMATOLOGÍA',
              dailyCounts: {for (int d = 1; d <= 30; d++) d: d == 2 ? 3 : 0},
            ),
            ChronoReportExamRow(
              examId: 'e2',
              examName: 'Plaquetas',
              category: 'HEMATOLOGÍA',
              dailyCounts: {for (int d = 1; d <= 30; d++) d: 0},
            ),
          ],
        ),
      ],
    );

    test('buildChronoPlutoColumns genera columnas fijas y días del mes', () {
      final columns = buildChronoPlutoColumns(
        year: 2026,
        month: 11,
        daysInMonth: 30,
        theme: ThemeData.light(),
      );

      // 1 (Nombre) + 30 (Días) + 1 (Total) = 32 columnas
      expect(columns.length, 32);

      // Primera columna es fija al inicio
      expect(columns.first.field, 'exam_name');
      expect(columns.first.frozen, PlutoColumnFrozen.start);

      // Última columna es TOTAL fija al final
      expect(columns.last.field, 'total');
      expect(columns.last.frozen, PlutoColumnFrozen.end);

      // Verificación de encabezados de días
      expect(columns[1].field, 'day_1');
      expect(columns[1].title, '1');
      expect(columns[30].field, 'day_30');
      expect(columns[30].title, '30');
    });

    test('buildChronoPlutoRows genera fila de día, pacientes, categoría y exámenes', () {
      final rows = buildChronoPlutoRows(data: data);

      // Fila 0: DÍA (nombres de días en español)
      expect(rows[0].cells['exam_name']?.value, 'DÍA');
      expect(rows[0].cells['is_weekday_row']?.value, true);
      expect(rows[0].cells['day_1']?.value, 'DOM'); // 1 Nov 2026 es Domingo
      expect(rows[0].cells['day_2']?.value, 'LUN'); // 2 Nov 2026 es Lunes

      // Fila 1: PACIENTES TOTAL (30 días + total)
      expect(rows[1].cells['exam_name']?.value, 'PACIENTES TOTAL');
      expect(rows[1].cells['day_2']?.value, 5);
      expect(rows[1].cells['total']?.value, 5);

      // Fila 2: Categoría HEMATOLOGÍA
      expect(rows[2].cells['exam_name']?.value, 'HEMATOLOGÍA');
      expect(rows[2].cells['is_category']?.value, true);

      // Fila 3 y 4: Exámenes individuales
      expect(rows[3].cells['exam_name']?.value, 'Hemograma');
      expect(rows[3].cells['day_2']?.value, 3);
      expect(rows[3].cells['total']?.value, 3);

      expect(rows[4].cells['exam_name']?.value, 'Plaquetas');
      expect(rows[4].cells['total']?.value, 0);
    });

    test('buildChronoPlutoRows respeta filtro onlyWithDemands', () {
      final rows = buildChronoPlutoRows(
        data: data,
        onlyWithDemands: true,
      );

      // Debe incluir fila de pacientes, categoría y solo 'Hemograma' (excluyendo 'Plaquetas')
      final examNames = rows.map((r) => r.cells['exam_name']?.value).toList();
      expect(examNames, contains('Hemograma'));
      expect(examNames, isNot(contains('Plaquetas')));
    });

    test('buildChronoPlutoRows respeta filtro searchQuery', () {
      final rows = buildChronoPlutoRows(
        data: data,
        searchQuery: 'plaqueta',
      );

      final examNames = rows.map((r) => r.cells['exam_name']?.value).toList();
      expect(examNames, contains('Plaquetas'));
      expect(examNames, isNot(contains('Hemograma')));
    });
  });

  group('LabTestsVolumeView - Botón Reporte Cronológico en UI', () {
    testWidgets('renderiza el botón Reporte cronológico alineado arriba del segmented', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final report = LabTestsVolumeReportResponse(
        startDate: DateTime(2026, 11, 1).millisecondsSinceEpoch,
        endDate: DateTime(2026, 11, 30).millisecondsSinceEpoch,
        source: 'orders',
        summary: const LabTestsVolumeSummary(
          totalTestsCount: 10,
          totalRevenue: 20000,
          topTests: [],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<ReportCubit>(
              create: (_) => _FakeReportCubit(),
              child: LabTestsVolumeView(report: report),
            ),
          ),
        ),
      );

      // Verificar existencia del botón por Key y por Texto
      final buttonFinder = find.byKey(const Key('chrono_report_button'));
      expect(buttonFinder, findsOneWidget);
      expect(find.text('Reporte cronológico'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    });
  });
}
