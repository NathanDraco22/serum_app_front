import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/report/dialogs/chrono_report_models.dart';
import 'package:serum_app_front/src/tools/exports/exports.dart';

void main() {
  group('ChronoReportExcelTemplate Tests', () {
    late ChronoReportMonthData sampleMonthData;

    setUp(() {
      sampleMonthData = ChronoReportMonthData(
        year: 2026,
        month: 11,
        daysInMonth: 30,
        dailyPatients: {
          1: 4,
          2: 5,
          15: 8,
          30: 2,
        },
        categories: [
          ChronoReportCategory(
            name: 'HEMATOLOGÍA',
            rows: [
              ChronoReportExamRow(
                examId: 'bh-1',
                examName: 'HEMOGRAMA COMPLETO',
                category: 'HEMATOLOGÍA',
                dailyCounts: {1: 2, 2: 3, 15: 4},
              ),
              ChronoReportExamRow(
                examId: 'bh-2',
                examName: 'HEMATOCRITO',
                category: 'HEMATOLOGÍA',
                dailyCounts: {1: 1, 30: 1},
              ),
            ],
          ),
          ChronoReportCategory(
            name: 'UROANALISIS',
            rows: [
              ChronoReportExamRow(
                examId: 'uro-1',
                examName: 'EXAMEN GENERAL DE ORINA',
                category: 'UROANALISIS',
                dailyCounts: {2: 2, 15: 4},
              ),
              ChronoReportExamRow(
                examId: 'uro-2',
                examName: 'PROTEINURIA 24H',
                category: 'UROANALISIS',
                dailyCounts: {}, // Demanda 0
              ),
            ],
          ),
        ],
      );
    });

    test('buildExcel genera la hoja con el nombre en español y congelación de paneles', () async {
      final template = ChronoReportExcelTemplate(data: sampleMonthData);
      final excel = await template.buildExcel();

      expect(excel.sheets.containsKey('11 NOVIEMBRE 2026'), isTrue);
      final sheet = excel['11 NOVIEMBRE 2026'];

      expect(sheet.frozenRows, equals(3));
      expect(sheet.frozenColumns, equals(1));
    });

    test('buildExcel estructura fila 0 (Días), fila 1 (Nombres de Días) y fila 2 (Pacientes Totales)', () async {
      final template = ChronoReportExcelTemplate(data: sampleMonthData);
      final excel = await template.buildExcel();
      final sheet = excel['11 NOVIEMBRE 2026'];

      // Fila 0: Concepto y días numéricos
      final c0r0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
      expect(c0r0.value?.toString(), contains('INFORMACION DE PACIENTES'));

      final c1r0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0));
      expect(c1r0.value?.toString(), equals('1'));

      final c30r0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 30, rowIndex: 0));
      expect(c30r0.value?.toString(), equals('30'));

      final totalHeader = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 31, rowIndex: 0));
      expect(totalHeader.value?.toString(), equals('TOTAL'));

      // Fila 1: Nombres de días de la semana en español
      final c0r1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
      expect(c0r1.value?.toString(), equals('DÍA'));

      // 1 de Noviembre 2026 fue Domingo -> DOM
      final c1r1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1));
      expect(c1r1.value?.toString(), equals('DOM'));

      // 2 de Noviembre 2026 fue Lunes -> LUN
      final c2r1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1));
      expect(c2r1.value?.toString(), equals('LUN'));

      // 30 de Noviembre 2026 fue Lunes -> LUN
      final c30r1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 30, rowIndex: 1));
      expect(c30r1.value?.toString(), equals('LUN'));

      // Fila 2: PACIENTES TOTAL
      final c0r2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2));
      expect(c0r2.value?.toString(), contains('PACIENTES TOTAL'));

      final pDay1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2));
      expect(pDay1.value?.toString(), equals('4'));

      final pDay2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 2));
      expect(pDay2.value?.toString(), equals('5'));

      // Total pacientes mes: 4 + 5 + 8 + 2 = 19
      final pTotal = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 31, rowIndex: 2));
      expect(pTotal.value?.toString(), equals('19'));
    });

    test('buildExcel combina celdas para franjas de categoría transversal', () async {
      final template = ChronoReportExcelTemplate(data: sampleMonthData);
      final excel = await template.buildExcel();
      final sheet = excel['11 NOVIEMBRE 2026'];

      final mergedCells = sheet.spannedItems;
      expect(mergedCells.isNotEmpty, isTrue);

      // Fila 3 corresponde a la primera categoría (HEMATOLOGÍA)
      final catCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3));
      expect(catCell.value?.toString(), contains('HEMATOLOGÍA'));
    });

    test('buildExcel incluye filas de exámenes con sus conteos diarios y totales', () async {
      final template = ChronoReportExcelTemplate(data: sampleMonthData);
      final excel = await template.buildExcel();
      final sheet = excel['11 NOVIEMBRE 2026'];

      // Fila 4: HEMOGRAMA COMPLETO
      final examCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4));
      expect(examCell.value?.toString(), equals('HEMOGRAMA COMPLETO'));

      final day1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4));
      expect(day1.value?.toString(), equals('2'));

      final day2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 4));
      expect(day2.value?.toString(), equals('3'));

      // Total de HEMOGRAMA COMPLETO: 2 + 3 + 4 = 9
      final examTotal = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 31, rowIndex: 4));
      expect(examTotal.value?.toString(), equals('9'));
    });

    test('Filtro onlyWithDemands excluye exámenes con conteo cero', () async {
      final template = ChronoReportExcelTemplate(
        data: sampleMonthData,
        onlyWithDemands: true,
      );
      final excel = await template.buildExcel();
      final sheet = excel['11 NOVIEMBRE 2026'];

      final allExamTexts = <String>[];
      for (int r = 0; r < 20; r++) {
        final val = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).value?.toString();
        if (val != null) allExamTexts.add(val);
      }

      expect(allExamTexts.contains('PROTEINURIA 24H'), isFalse);
      expect(allExamTexts.contains('EXAMEN GENERAL DE ORINA'), isTrue);
    });

    test('Filtro searchQuery incluye solo exámenes coincidentes', () async {
      final template = ChronoReportExcelTemplate(
        data: sampleMonthData,
        searchQuery: 'HEMATOCRITO',
      );
      final excel = await template.buildExcel();
      final sheet = excel['11 NOVIEMBRE 2026'];

      final allExamTexts = <String>[];
      for (int r = 0; r < 20; r++) {
        final val = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).value?.toString();
        if (val != null) allExamTexts.add(val);
      }

      expect(allExamTexts.contains('HEMATOCRITO'), isTrue);
      expect(allExamTexts.contains('HEMOGRAMA COMPLETO'), isFalse);
    });

    test('buildBytes genera un buffer binario .xlsx válido que puede ser decodificado', () async {
      final template = ChronoReportExcelTemplate(data: sampleMonthData);
      final bytes = await template.buildBytes();

      expect(bytes, isNotNull);
      expect(bytes!.isNotEmpty, isTrue);

      final decoded = Excel.decodeBytes(bytes);
      expect(decoded.sheets.containsKey('11 NOVIEMBRE 2026'), isTrue);
    });
  });
}
