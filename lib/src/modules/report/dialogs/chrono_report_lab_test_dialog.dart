import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/app_theme.dart';
import '../../../tools/exports/exports.dart';
import 'chrono_report_models.dart';

/// Abre la pantalla completa interactiva del Reporte Cronológico Mensual de Exámenes de Laboratorio vía Navigator.push.
Future<void> showChronoReportLabTestDialog(
  BuildContext context, {
  DateTime? initialDate,
  String? branchId,
  String source = 'orders',
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod('TextInput.hide');

  await Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) {
        return ChronoReportLabTestDialog(
          initialDate: initialDate ?? DateTime.now(),
          branchId: branchId,
          source: source,
        );
      },
    ),
  );
}

class ChronoReportLabTestDialog extends StatefulWidget {
  final DateTime initialDate;
  final String? branchId;
  final String source;

  const ChronoReportLabTestDialog({
    super.key,
    required this.initialDate,
    this.branchId,
    this.source = 'orders',
  });

  @override
  State<ChronoReportLabTestDialog> createState() =>
      _ChronoReportLabTestDialogState();
}

class _ChronoReportLabTestDialogState extends State<ChronoReportLabTestDialog> {
  late DateTime _selectedMonth;
  late String _source;
  late String? _branchId;

  bool _isLoading = true;
  String? _errorMessage;

  ChronoReportMonthData? _data;

  String _searchQuery = '';
  bool _onlyWithDemands = false;
  bool _isExporting = false;

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

  String _formatMonthYear(DateTime date) {
    final monthName = _spanishMonths[date.month - 1];
    return '$monthName ${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(widget.initialDate.year, widget.initialDate.month, 1);
    _source = widget.source;
    _branchId = widget.branchId;
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final labTestsRepo = context.read<LabTestsRepository>();
      final ordersRepo = context.read<OrdersRepository>();
      final quotationsRepo = context.read<QuotationsRepository>();

      final startMs = DateTime(_selectedMonth.year, _selectedMonth.month, 1).millisecondsSinceEpoch;
      final endMs = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59, 999).millisecondsSinceEpoch;

      // 1. Obtener catálogo general de exámenes
      final catalog = await labTestsRepo.getAllLabTests(branchId: _branchId);

      List<OrderInDb> orders = [];
      List<QuotationInDb> quotations = [];

      // 2. Obtener órdenes o cotizaciones del mes
      if (_source == 'orders') {
        orders = await ordersRepo.getAllOrders(
          queryParams: OrderQueryParams(
            startDate: startMs,
            endDate: endMs,
            branchId: _branchId,
            limit: 5000,
          ),
        );
      } else {
        quotations = await quotationsRepo.getAllQuotations(
          queryParams: QuotationQueryParams(
            startDate: startMs,
            endDate: endMs,
            branchId: _branchId,
            limit: 5000,
          ),
        );
      }

      final monthData = aggregateChronoReportData(
        year: _selectedMonth.year,
        month: _selectedMonth.month,
        catalog: catalog,
        orders: orders,
        quotations: quotations,
        isQuotations: _source == 'quotations',
      );

      if (!mounted) return;

      setState(() {
        _data = monthData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al generar el reporte cronológico: $e';
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1);
    });
    _loadReportData();
  }

  Future<void> _exportToExcel() async {
    if (_data == null || _isExporting) return;

    setState(() => _isExporting = true);

    try {
      final template = ChronoReportExcelTemplate(
        data: _data!,
        searchQuery: _searchQuery,
        onlyWithDemands: _onlyWithDemands,
        sourceTitle: _source == 'orders' ? 'Órdenes Clínicas' : 'Cotizaciones',
      );

      final prefix = _source == 'orders'
          ? 'reporte_cronologico_ordenes'
          : 'reporte_cronologico_cotizaciones';
      final fileName = '${prefix}_${_selectedMonth.year}_${_selectedMonth.month.toString().padLeft(2, '0')}.xlsx';

      final saved = await ExcelExportTool.export(
        template,
        fileName: fileName,
        dialogTitle: 'Exportar Reporte Cronológico Mensual',
      );

      if (!mounted) return;

      if (saved != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Reporte exportado exitosamente: $fileName'),
                ),
              ],
            ),
            backgroundColor: ColorPalette.deepNavy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar a Excel: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedMonth = _formatMonthYear(_selectedMonth);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ColorPalette.deepNavy,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Volver a reportes',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Reporte Cronológico de Exámenes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Distribución diaria de demanda y actividad clínica por categoría',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Navegación de mes: [<] MES AÑO [>]
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withAlpha(60),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                  tooltip: 'Mes anterior',
                  onPressed: _isLoading ? null : () => _changeMonth(-1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    formattedMonth,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                  tooltip: 'Mes siguiente',
                  onPressed: _isLoading ? null : () => _changeMonth(1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Filtros rápidos y acciones
          _buildQuickBar(theme),
          const Divider(height: 1),

          // Contenedor principal: Estado de carga, error o PlutoGrid
          Expanded(
            child: _buildBody(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: theme.colorScheme.surface,
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Conmutador de Fuente: Órdenes Clínicas vs Cotizaciones
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'orders',
                label: Text('Órdenes Clínicas'),
                icon: Icon(Icons.receipt_long, size: 16),
              ),
              ButtonSegment<String>(
                value: 'quotations',
                label: Text('Cotizaciones'),
                icon: Icon(Icons.request_quote, size: 16),
              ),
            ],
            selected: {_source},
            onSelectionChanged: _isLoading
                ? null
                : (selection) {
                    setState(() => _source = selection.first);
                    _loadReportData();
                  },
          ),

          // Buscador en tiempo real de exámenes
          SizedBox(
            width: 260,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Filtrar examen por nombre...',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),

          // Filtro: Solo con demanda
          FilterChip(
            label: const Text('Solo con demanda'),
            avatar: Icon(
              _onlyWithDemands ? Icons.check : Icons.filter_alt_outlined,
              size: 16,
            ),
            selected: _onlyWithDemands,
            onSelected: (val) {
              setState(() => _onlyWithDemands = val);
            },
          ),

          // Botón: Exportar a Excel
          OutlinedButton.icon(
            key: const Key('chrono_export_excel_button'),
            icon: _isExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.table_view_outlined, size: 18),
            label: Text(_isExporting ? 'Exportando...' : 'Exportar a Excel'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: (_data == null || _isLoading || _isExporting) ? null : _exportToExcel,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Cargando distribución cronológica del mes...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              onPressed: _loadReportData,
            ),
          ],
        ),
      );
    }

    if (_data == null) {
      return const Center(child: Text('Sin datos disponibles.'));
    }

    final initialColumns = buildChronoPlutoColumns(
      year: _data!.year,
      month: _data!.month,
      daysInMonth: _data!.daysInMonth,
      theme: theme,
    );

    final initialRows = buildChronoPlutoRows(
      data: _data!,
      searchQuery: _searchQuery,
      onlyWithDemands: _onlyWithDemands,
    );

    return PlutoGrid(
      key: ValueKey('chrono_grid_${_selectedMonth.year}_${_selectedMonth.month}_${_source}_${_searchQuery}_$_onlyWithDemands'),
      columns: initialColumns,
      rows: initialRows,
      rowColorCallback: (rowCtx) {
        if (rowCtx.row.cells['is_category']?.value == true) {
          return ColorPalette.primary;
        }
        if (rowCtx.row.cells['is_weekday_row']?.value == true) {
          return theme.colorScheme.surfaceContainerHigh;
        }
        if (rowCtx.row.cells['is_patient_row']?.value == true) {
          return theme.colorScheme.surfaceContainerHigh;
        }
        return rowCtx.rowIdx % 2 == 0
            ? theme.colorScheme.surface
            : theme.colorScheme.surfaceContainerLowest;
      },
      configuration: PlutoGridConfiguration(
        style: PlutoGridStyleConfig(
          gridBorderColor: theme.colorScheme.outlineVariant.withAlpha(70),
          borderColor: theme.colorScheme.outlineVariant.withAlpha(50),
          cellColorInReadOnlyState: Colors.transparent,
          columnHeight: 44,
          rowHeight: 32,
          defaultCellPadding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
    );
  }
}
