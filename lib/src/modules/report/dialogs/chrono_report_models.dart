import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/app_theme.dart';

/// Representa una fila de examen clínico en la matriz cronológica.
class ChronoReportExamRow {
  final String examId;
  final String examName;
  final String category;
  final bool isPack;
  final Map<int, int> dailyCounts;

  const ChronoReportExamRow({
    required this.examId,
    required this.examName,
    required this.category,
    this.isPack = false,
    required this.dailyCounts,
  });

  int get total => dailyCounts.values.fold<int>(0, (sum, val) => sum + val);
}

/// Representa una categoría clínica con sus exámenes asociados.
class ChronoReportCategory {
  final String name;
  final List<ChronoReportExamRow> rows;

  const ChronoReportCategory({
    required this.name,
    required this.rows,
  });

  int get totalCategoryCount =>
      rows.fold<int>(0, (sum, r) => sum + r.total);
}

/// Contenedor global de datos agregados para el mes seleccionado.
class ChronoReportMonthData {
  final int year;
  final int month;
  final int daysInMonth;
  final Map<int, int> dailyPatients;
  final List<ChronoReportCategory> categories;

  const ChronoReportMonthData({
    required this.year,
    required this.month,
    required this.daysInMonth,
    required this.dailyPatients,
    required this.categories,
  });

  int get totalMonthPatients =>
      dailyPatients.values.fold<int>(0, (sum, count) => sum + count);

  int get totalMonthExams =>
      categories.fold<int>(0, (sum, c) => sum + c.totalCategoryCount);
}

/// Agrega órdenes clínicas (o cotizaciones) y catálogo en la matriz cronológica mensual.
ChronoReportMonthData aggregateChronoReportData({
  required int year,
  required int month,
  required List<LabTestInDb> catalog,
  required List<OrderInDb> orders,
  List<QuotationInDb> quotations = const [],
  bool isQuotations = false,
}) {
  final daysInMonth = DateTime(year, month + 1, 0).day;

  // 1. Conteo de pacientes únicos por día
  final Map<int, Set<String>> patientsByDay = {
    for (int d = 1; d <= daysInMonth; d++) d: <String>{},
  };

  // 2. Conteo de exámenes por ID y día: {examId: {day: count}}
  final Map<String, Map<int, int>> examCountsById = {};
  // Conteo secundario por nombre (fallback si no hay ID coincidente): {normalizedName: {day: count}}
  final Map<String, Map<int, int>> examCountsByName = {};

  if (!isQuotations) {
    for (final order in orders) {
      if (order.isDeleted || order.status.toLowerCase() == 'cancelled') continue;
      final dt = DateTime.fromMillisecondsSinceEpoch(order.createdAt);
      if (dt.year != year || dt.month != month) continue;
      final day = dt.day;

      // Paciente
      final pKey = order.patientId.isNotEmpty
          ? order.patientId
          : (order.patientInfo?.name.trim().isNotEmpty ?? false)
              ? order.patientInfo!.name.trim()
              : order.id;
      patientsByDay[day]?.add(pKey);

      // Ítems de la orden
      for (final item in order.items) {
        if (item.labTestId.isNotEmpty) {
          examCountsById.putIfAbsent(
            item.labTestId,
            () => {for (int d = 1; d <= daysInMonth; d++) d: 0},
          );
          examCountsById[item.labTestId]![day] =
              (examCountsById[item.labTestId]![day] ?? 0) + 1;
        }

        final normName = item.name.trim().toLowerCase();
        if (normName.isNotEmpty) {
          examCountsByName.putIfAbsent(
            normName,
            () => {for (int d = 1; d <= daysInMonth; d++) d: 0},
          );
          examCountsByName[normName]![day] =
              (examCountsByName[normName]![day] ?? 0) + 1;
        }
      }
    }
  } else {
    for (final quotation in quotations) {
      if (quotation.isDeleted) continue;
      final dt = DateTime.fromMillisecondsSinceEpoch(quotation.createdAt);
      if (dt.year != year || dt.month != month) continue;
      final day = dt.day;

      final pKey = quotation.patientId != null && quotation.patientId!.isNotEmpty
          ? quotation.patientId!
          : (quotation.clientInfo?.name.trim().isNotEmpty ?? false)
              ? quotation.clientInfo!.name.trim()
              : quotation.clientName.trim().isNotEmpty
                  ? quotation.clientName.trim()
                  : quotation.id;
      patientsByDay[day]?.add(pKey);

      for (final item in quotation.exams) {
        if (item.labTestId.isNotEmpty) {
          examCountsById.putIfAbsent(
            item.labTestId,
            () => {for (int d = 1; d <= daysInMonth; d++) d: 0},
          );
          examCountsById[item.labTestId]![day] =
              (examCountsById[item.labTestId]![day] ?? 0) + 1;
        }

        final normName = item.name.trim().toLowerCase();
        if (normName.isNotEmpty) {
          examCountsByName.putIfAbsent(
            normName,
            () => {for (int d = 1; d <= daysInMonth; d++) d: 0},
          );
          examCountsByName[normName]![day] =
              (examCountsByName[normName]![day] ?? 0) + 1;
        }
      }
    }
  }

  final Map<int, int> dailyPatients = {
    for (int d = 1; d <= daysInMonth; d++) d: patientsByDay[d]?.length ?? 0,
  };

  // 3. Agrupación por categoría
  final Map<String, List<ChronoReportExamRow>> categoryRows = {};
  final Set<String> processedExamIds = {};

  // Normalizador de nombre de categoría
  String normalizeCategoryName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'GENERAL';
    final upper = trimmed.toUpperCase();
    if (upper.contains('HEMAT') || upper.contains('SANGRE')) {
      return 'HEMATOLOGÍA';
    }
    if (upper.contains('URIN') || upper.contains('ORINA') || upper.contains('URO')) {
      return 'UROANÁLISIS';
    }
    if (upper.contains('COPRO') || upper.contains('HECES') || upper.contains('PARASIT')) {
      return 'COPROLOGÍA';
    }
    if (upper.contains('QUIMIC') || upper.contains('QUÍMIC') || upper.contains('BIOQUIM')) {
      return 'QUÍMICA CLÍNICA';
    }
    if (upper.contains('INMUNO') || upper.contains('SEROL')) {
      return 'INMUNOLOGÍA / SEROLOGÍA';
    }
    if (upper.contains('HORMON') || upper.contains('ENDOCRIN')) {
      return 'HORMONAS';
    }
    return upper;
  }

  // Recolectar IDs de todos los análisis que son componentes hijos de algún pack
  final packChildIds = <String>{};
  for (final test in catalog) {
    if (test.isPack) {
      packChildIds.addAll(test.childTestIds);
    }
  }

  // Iterar catálogo existente
  for (final test in catalog) {
    if (test.isDeleted) continue;
    // Excluir parámetros internos de perfiles: solo incluir exámenes y estudios clínicos completos
    if (test.isProfileParameter) continue;

    // Obtener conteos por ID o por nombre
    Map<int, int>? counts = examCountsById[test.id];
    if (counts == null) {
      final normName = test.name.trim().toLowerCase();
      counts = examCountsByName[normName];
    }
    counts ??= {for (int d = 1; d <= daysInMonth; d++) d: 0};

    // Si es un parámetro hijo de un pack y no fue vendido de forma atómica individual (demanda 0),
    // se oculta para no saturar la tabla con parámetros internos como Leucocitos, VCM, Plaquetas, etc.
    final totalDemand = counts.values.fold<int>(0, (sum, val) => sum + val);
    if (!test.isPack && packChildIds.contains(test.id) && totalDemand == 0) {
      continue;
    }

    final catName = normalizeCategoryName(test.commercialCategory);
    processedExamIds.add(test.id);

    categoryRows.putIfAbsent(catName, () => []);
    categoryRows[catName]!.add(
      ChronoReportExamRow(
        examId: test.id,
        examName: test.name,
        category: catName,
        isPack: test.isPack,
        dailyCounts: Map<int, int>.from(counts),
      ),
    );
  }

  // Orden prioritario estándar institucional de categorías clínicas
  const priorityOrder = [
    'HEMATOLOGÍA',
    'UROANÁLISIS',
    'COPROLOGÍA',
    'QUÍMICA CLÍNICA',
    'INMUNOLOGÍA / SEROLOGÍA',
    'HORMONAS',
    'PERFILES / PACKS',
    'GENERAL',
    'OTROS',
  ];

  final sortedCategoryKeys = categoryRows.keys.toList()
    ..sort((a, b) {
      final indexA = priorityOrder.indexOf(a);
      final indexB = priorityOrder.indexOf(b);
      if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
      if (indexA != -1) return -1;
      if (indexB != -1) return 1;
      return a.compareTo(b);
    });

  final List<ChronoReportCategory> categories = [];
  for (final catKey in sortedCategoryKeys) {
    final rows = categoryRows[catKey] ?? [];
    // Ordenar exámenes alfabéticamente dentro de su categoría
    rows.sort((a, b) => a.examName.toLowerCase().compareTo(b.examName.toLowerCase()));
    categories.add(ChronoReportCategory(name: catKey, rows: rows));
  }

  return ChronoReportMonthData(
    year: year,
    month: month,
    daysInMonth: daysInMonth,
    dailyPatients: dailyPatients,
    categories: categories,
  );
}

/// Genera la definición de columnas de PlutoGrid para el mes.
List<PlutoColumn> buildChronoPlutoColumns({
  required int year,
  required int month,
  required int daysInMonth,
  required ThemeData theme,
}) {
  final List<PlutoColumn> columns = [];

  // 1. Columna fija izquierda: Examen / Estudio Clínico
  columns.add(
    PlutoColumn(
      title: 'EXAMEN / ESTUDIO CLÍNICO',
      field: 'exam_name',
      type: PlutoColumnType.text(),
      frozen: PlutoColumnFrozen.start,
      enableSorting: false,
      enableColumnDrag: false,
      enableEditingMode: false,
      width: 250,
      renderer: (ctx) {
        final isCategory = ctx.row.cells['is_category']?.value == true;
        final isPatientRow = ctx.row.cells['is_patient_row']?.value == true;
        final title = ctx.cell.value?.toString() ?? '';

        if (isCategory) {
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }

        if (isPatientRow) {
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                fontSize: 12,
              ),
            ),
          );
        }

        return Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    ),
  );

  // 2. Columnas de días: 1 al 28..31
  for (int day = 1; day <= daysInMonth; day++) {
    final dt = DateTime(year, month, day);
    final isSunday = dt.weekday == DateTime.sunday;
    final isSaturday = dt.weekday == DateTime.saturday;

    columns.add(
      PlutoColumn(
        title: '$day',
        field: 'day_$day',
        type: PlutoColumnType.text(),
        enableSorting: false,
        enableColumnDrag: false,
        enableEditingMode: false,
        width: 48,
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (ctx) {
          final isCategory = ctx.row.cells['is_category']?.value == true;
          if (isCategory) {
            return const SizedBox.shrink();
          }

          final isWeekdayRow = ctx.row.cells['is_weekday_row']?.value == true;
          final isPatientRow = ctx.row.cells['is_patient_row']?.value == true;

          // Color de fondo: Domingo en rojo suave (estilo Red 300 / pastel)
          Color cellBgColor;
          if (isSunday) {
            cellBgColor = Colors.red.shade300.withAlpha(90);
          } else if (isSaturday) {
            cellBgColor = theme.colorScheme.surfaceContainerHighest.withAlpha(40);
          } else if (isWeekdayRow || isPatientRow) {
            cellBgColor = theme.colorScheme.surfaceContainerHigh.withAlpha(50);
          } else {
            cellBgColor = Colors.transparent;
          }

          if (isWeekdayRow) {
            final dayName = ctx.cell.value?.toString() ?? '';
            return Container(
              alignment: Alignment.center,
              color: cellBgColor,
              child: Text(
                dayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSunday ? Colors.red.shade900 : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          final val = (ctx.cell.value as num?)?.toInt() ??
              int.tryParse(ctx.cell.value?.toString() ?? '0') ??
              0;

          return Container(
            alignment: Alignment.center,
            color: cellBgColor,
            child: Text(
              val.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isPatientRow || val > 0 ? FontWeight.bold : FontWeight.normal,
                color: val > 0
                    ? (isPatientRow
                        ? (isSunday ? Colors.red.shade900 : ColorPalette.primary)
                        : (isSunday ? Colors.red.shade900 : theme.colorScheme.onSurface))
                    : (isSunday
                        ? Colors.red.shade700.withAlpha(140)
                        : theme.colorScheme.outline.withAlpha(150)),
              ),
            ),
          );
        },
      ),
    );
  }

  // 3. Columna fija derecha: TOTAL
  columns.add(
    PlutoColumn(
      title: 'TOTAL',
      field: 'total',
      type: PlutoColumnType.number(),
      frozen: PlutoColumnFrozen.end,
      enableSorting: false,
      enableColumnDrag: false,
      enableEditingMode: false,
      width: 75,
      textAlign: PlutoColumnTextAlign.center,
      titleTextAlign: PlutoColumnTextAlign.center,
      renderer: (ctx) {
        final isCategory = ctx.row.cells['is_category']?.value == true;
        if (isCategory) {
          final catTotal = (ctx.cell.value as num?)?.toInt() ?? 0;
          return Container(
            alignment: Alignment.center,
            color: ColorPalette.primary,
            child: Text(
              catTotal.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          );
        }

        final isWeekdayRow = ctx.row.cells['is_weekday_row']?.value == true;
        if (isWeekdayRow) {
          return Container(
            alignment: Alignment.center,
            color: const Color(0xFFFFF9C4),
            child: const Text(
              '-',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          );
        }

        final totalVal = (ctx.cell.value as num?)?.toInt() ?? 0;
        final isPatientRow = ctx.row.cells['is_patient_row']?.value == true;

        return Container(
          alignment: Alignment.center,
          color: const Color(0xFFFFF9C4), // Amarillo suave institucional como en el Excel
          child: Text(
            totalVal.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isPatientRow ? Colors.brown.shade900 : Colors.black87,
            ),
          ),
        );
      },
    ),
  );

  return columns;
}

/// Genera la lista de PlutoRows a partir de los datos agregados.
List<PlutoRow> buildChronoPlutoRows({
  required ChronoReportMonthData data,
  String searchQuery = '',
  bool onlyWithDemands = false,
}) {
  final List<PlutoRow> rows = [];
  final q = searchQuery.trim().toLowerCase();

  // Fila 0: DÍA (LUN, MAR, MIÉ, JUE, VIE, SÁB, DOM)
  const spanishWeekdays = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
  final Map<String, PlutoCell> weekdayCells = {
    'exam_name': PlutoCell(value: 'DÍA'),
    'is_category': PlutoCell(value: false),
    'is_patient_row': PlutoCell(value: false),
    'is_weekday_row': PlutoCell(value: true),
  };
  for (int day = 1; day <= data.daysInMonth; day++) {
    final dt = DateTime(data.year, data.month, day);
    final weekdayName = spanishWeekdays[dt.weekday - 1];
    weekdayCells['day_$day'] = PlutoCell(value: weekdayName);
  }
  weekdayCells['total'] = PlutoCell(value: '-');
  rows.add(PlutoRow(cells: weekdayCells));

  // Fila 1: INFORMACIÓN DE PACIENTES / PACIENTES TOTAL
  final Map<String, PlutoCell> patientCells = {
    'exam_name': PlutoCell(value: 'PACIENTES TOTAL'),
    'is_category': PlutoCell(value: false),
    'is_patient_row': PlutoCell(value: true),
    'is_weekday_row': PlutoCell(value: false),
  };
  for (int day = 1; day <= data.daysInMonth; day++) {
    patientCells['day_$day'] = PlutoCell(value: data.dailyPatients[day] ?? 0);
  }
  patientCells['total'] = PlutoCell(value: data.totalMonthPatients);

  rows.add(PlutoRow(cells: patientCells));

  // Filas de Categorías y Exámenes
  for (final cat in data.categories) {
    // Filtrar exámenes de la categoría
    final filteredRows = cat.rows.where((exam) {
      if (onlyWithDemands && exam.total == 0) return false;
      if (q.isNotEmpty && !exam.examName.toLowerCase().contains(q)) return false;
      return true;
    }).toList();

    if (filteredRows.isEmpty && (q.isNotEmpty || onlyWithDemands)) {
      continue;
    }

    // Fila Encabezado de Categoría
    final Map<String, PlutoCell> catCells = {
      'exam_name': PlutoCell(value: cat.name),
      'is_category': PlutoCell(value: true),
      'is_patient_row': PlutoCell(value: false),
      'is_weekday_row': PlutoCell(value: false),
    };
    for (int day = 1; day <= data.daysInMonth; day++) {
      catCells['day_$day'] = PlutoCell(value: 0);
    }
    catCells['total'] = PlutoCell(value: cat.totalCategoryCount);

    rows.add(PlutoRow(cells: catCells));

    // Filas individuales de cada examen
    for (final exam in filteredRows) {
      final Map<String, PlutoCell> examCells = {
        'exam_name': PlutoCell(value: exam.examName),
        'is_category': PlutoCell(value: false),
        'is_patient_row': PlutoCell(value: false),
        'is_weekday_row': PlutoCell(value: false),
      };
      for (int day = 1; day <= data.daysInMonth; day++) {
        examCells['day_$day'] = PlutoCell(value: exam.dailyCounts[day] ?? 0);
      }
      examCells['total'] = PlutoCell(value: exam.total);

      rows.add(PlutoRow(cells: examCells));
    }
  }

  return rows;
}
