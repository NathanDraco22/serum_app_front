import 'package:excel_plus/excel_plus.dart';

import '../../../../modules/report/dialogs/chrono_report_models.dart';
import '../excel_template.dart';

/// Plantilla oficial para la exportación de la matriz mensual del Reporte Cronológico a Excel (.xlsx).
class ChronoReportExcelTemplate implements ExcelTemplate {
  final ChronoReportMonthData data;
  final String searchQuery;
  final bool onlyWithDemands;
  final String sourceTitle;

  ChronoReportExcelTemplate({
    required this.data,
    this.searchQuery = '',
    this.onlyWithDemands = false,
    this.sourceTitle = 'Órdenes Clínicas',
  });

  static const _spanishMonths = [
    'ENERO',
    'FEBRERO',
    'MARZO',
    'ABRIL',
    'MAYO',
    'JUNIO',
    'JULIO',
    'AGOSTO',
    'SEPTIEMBRE',
    'OCTUBRE',
    'NOVIEMBRE',
    'DICIEMBRE',
  ];

  static const _spanishWeekdays = [
    'LUN',
    'MAR',
    'MIÉ',
    'JUE',
    'VIE',
    'SÁB',
    'DOM',
  ];

  @override
  Future<Excel> buildExcel() async {
    final excel = Excel.createExcel();
    final monthName = _spanishMonths[data.month - 1];
    final sheetName = '${data.month.toString().padLeft(2, '0')} $monthName ${data.year}';

    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);
    if (excel.sheets.containsKey('Sheet1') && sheetName != 'Sheet1') {
      excel.delete('Sheet1');
    }

    // Paleta de colores institucionales
    final deepNavy = ExcelColor.fromHexString('#0B1E36');
    final categoryBlue = ExcelColor.fromHexString('#1B365D');
    final softPatientBlue = ExcelColor.fromHexString('#E8EEF5');
    final yellowTotal = ExcelColor.fromHexString('#FFF2CC');
    final lightBorder = ExcelColor.fromHexString('#D9D9D9');

    final thinBorder = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: lightBorder,
    );

    // 1. Estilos de celda
    final headerStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: deepNavy,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
    );

    final headerConceptStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: deepNavy,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
    );

    final weekdayHeaderStyle = CellStyle(
      bold: true,
      fontSize: 9,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: categoryBlue,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
    );

    final weekdayConceptStyle = CellStyle(
      bold: true,
      fontSize: 9,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: categoryBlue,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
    );

    final patientTotalLabelStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: softPatientBlue,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
    );

    final patientTotalValueStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: softPatientBlue,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
    );

    final categoryRowStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: categoryBlue,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
    );

    final examNameStyle = CellStyle(
      fontSize: 10,
      fontColorHex: ExcelColor.black,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
    );

    final examCountStyle = CellStyle(
      fontSize: 10,
      fontColorHex: ExcelColor.black,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
    );

    final yellowTotalStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: yellowTotal,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
    );

    // Estilos dedicados para domingos en rojo suave (estilo Red 300 / pastel)
    final sundayRedHeader = ExcelColor.fromHexString('#E57373'); // Red 300
    final sundayRedBg = ExcelColor.fromHexString('#FFCDD2');     // Red 100
    final sundayRedText = ExcelColor.fromHexString('#B71C1C');   // Rojo oscuro legible
    final sundayLightCountBg = ExcelColor.fromHexString('#FFEBEE'); // Rojo tenue de fondo

    final sundayWeekdayStyle = CellStyle(
      bold: true,
      fontSize: 9,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: sundayRedHeader,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
    );

    final sundayPatientValueStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: sundayRedText,
      backgroundColorHex: sundayRedBg,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
    );

    final sundayExamCountStyle = CellStyle(
      fontSize: 10,
      fontColorHex: sundayRedText,
      backgroundColorHex: sundayLightCountBg,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
    );

    final days = data.daysInMonth;
    final totalColIdx = days + 1;

    // Configurar anchos de columna
    sheet.setColumnWidth(0, 38.0);
    for (int d = 1; d <= days; d++) {
      sheet.setColumnWidth(d, 5.0);
    }
    sheet.setColumnWidth(totalColIdx, 12.0);

    int currentRow = 0;

    // Fila 0: INFORMACION DE PACIENTES / DÍAS DEL MES / TOTAL
    sheet.setRowHeight(currentRow, 26.0);
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      TextCellValue('INFORMACION DE PACIENTES'),
      cellStyle: headerConceptStyle,
    );

    for (int d = 1; d <= days; d++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: d, rowIndex: currentRow),
        IntCellValue(d),
        cellStyle: headerStyle,
      );
    }

    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: totalColIdx, rowIndex: currentRow),
      TextCellValue('TOTAL'),
      cellStyle: headerStyle,
    );

    currentRow++;

    // Fila 1: NOMBRES DE DÍAS (LUN, MAR, MIÉ, ...)
    sheet.setRowHeight(currentRow, 20.0);
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      TextCellValue('DÍA'),
      cellStyle: weekdayConceptStyle,
    );

    for (int d = 1; d <= days; d++) {
      final dt = DateTime(data.year, data.month, d);
      final weekdayName = _spanishWeekdays[dt.weekday - 1];
      final isSunday = dt.weekday == DateTime.sunday;
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: d, rowIndex: currentRow),
        TextCellValue(weekdayName),
        cellStyle: isSunday ? sundayWeekdayStyle : weekdayHeaderStyle,
      );
    }

    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: totalColIdx, rowIndex: currentRow),
      TextCellValue(''),
      cellStyle: weekdayHeaderStyle,
    );

    currentRow++;

    // Fila 2: PACIENTES TOTAL
    sheet.setRowHeight(currentRow, 22.0);
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      TextCellValue('PACIENTES TOTAL'),
      cellStyle: patientTotalLabelStyle,
    );

    int totalMonthPatients = 0;
    for (int d = 1; d <= days; d++) {
      final dt = DateTime(data.year, data.month, d);
      final isSunday = dt.weekday == DateTime.sunday;
      final pCount = data.dailyPatients[d] ?? 0;
      totalMonthPatients += pCount;
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: d, rowIndex: currentRow),
        IntCellValue(pCount),
        cellStyle: isSunday ? sundayPatientValueStyle : patientTotalValueStyle,
      );
    }

    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: totalColIdx, rowIndex: currentRow),
      IntCellValue(totalMonthPatients),
      cellStyle: yellowTotalStyle,
    );

    currentRow++;

    // Filtrado de exámenes según búsqueda y demanda
    final query = searchQuery.trim().toLowerCase();

    for (final category in data.categories) {
      final filteredRows = category.rows.where((row) {
        if (onlyWithDemands && row.total == 0) return false;
        if (query.isNotEmpty && !row.examName.toLowerCase().contains(query)) {
          return false;
        }
        return true;
      }).toList();

      if (filteredRows.isEmpty) continue;

      // Fila de Categoría combinada
      final catRowIdx = currentRow;
      sheet.setRowHeight(catRowIdx, 24.0);

      // Pintamos todas las celdas de la fila de la categoría para consistencia visual
      for (int c = 0; c <= totalColIdx; c++) {
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: catRowIdx),
          TextCellValue(c == 0 ? category.name.toUpperCase() : ''),
          cellStyle: categoryRowStyle,
        );
      }

      // Combinamos desde la columna 0 hasta la columna de total
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: catRowIdx),
        CellIndex.indexByColumnRow(columnIndex: totalColIdx, rowIndex: catRowIdx),
        customValue: TextCellValue(category.name.toUpperCase()),
      );

      currentRow++;

      // Filas de Exámenes
      for (final exam in filteredRows) {
        sheet.setRowHeight(currentRow, 20.0);

        // Nombre del examen
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
          TextCellValue(exam.examName),
          cellStyle: examNameStyle,
        );

        // Conteos por día
        for (int d = 1; d <= days; d++) {
          final dt = DateTime(data.year, data.month, d);
          final isSunday = dt.weekday == DateTime.sunday;
          final count = exam.dailyCounts[d] ?? 0;
          sheet.updateCell(
            CellIndex.indexByColumnRow(columnIndex: d, rowIndex: currentRow),
            IntCellValue(count),
            cellStyle: isSunday ? sundayExamCountStyle : examCountStyle,
          );
        }

        // Columna TOTAL en amarillo pastel
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: totalColIdx, rowIndex: currentRow),
          IntCellValue(exam.total),
          cellStyle: yellowTotalStyle,
        );

        currentRow++;
      }
    }

    // Inmovilizar filas de encabezado (3 filas: días numéricos, días de la semana y pacientes totales) y columna de conceptos (1 columna)
    sheet.freezePanes(rows: 3, columns: 1);

    return excel;
  }

  @override
  Future<List<int>?> buildBytes() async {
    final excel = await buildExcel();
    return excel.save();
  }
}
