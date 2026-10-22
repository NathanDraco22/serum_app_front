import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/service_locator.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../tools/exports/pdf/templates/clinical_comparison_pdf_template.dart';
import '../../../tools/exports/pdf_export_tool.dart';
import 'clinical_comparison_dialogs/clinical_comparison_filters_bar.dart';
import 'clinical_comparison_dialogs/clinical_comparison_header.dart';
import 'clinical_comparison_dialogs/clinical_comparison_kpi_cards.dart';
import 'clinical_comparison_dialogs/clinical_comparison_table.dart';

/// Abre la pantalla completa de comparativa evolutiva entre dos órdenes de laboratorio.
Future<void> showClinicalComparisonViewerDialog(
  BuildContext context, {
  required OrderInDb order1,
  required OrderInDb order2,
  PatientInfo? patientInfo,
  DoctorInfo? doctorInfo,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod('TextInput.hide');

  final appSession = sl<AppSessionCubit>();
  final branch = appSession.currentBranch ??
      BranchInDb(
        id: order1.branchId.isNotEmpty ? order1.branchId : 'BRANCH_DEFAULT',
        name: 'Laboratorio Clínico Serum',
        address: 'Sede Principal',
        phone: 'PBX: (505) 2222-0000',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) {
        return ClinicalComparisonViewerDialog(
          order1: order1,
          order2: order2,
          branch: branch,
          patientInfo: patientInfo,
          doctorInfo: doctorInfo,
        );
      },
    ),
  );
}

/// Pantalla completa interactiva para la comparativa clínica y evolutiva de exámenes.
class ClinicalComparisonViewerDialog extends StatefulWidget {
  final OrderInDb order1;
  final OrderInDb order2;
  final BranchInDb branch;
  final PatientInfo? patientInfo;
  final DoctorInfo? doctorInfo;

  const ClinicalComparisonViewerDialog({
    super.key,
    required this.order1,
    required this.order2,
    required this.branch,
    this.patientInfo,
    this.doctorInfo,
  });

  @override
  State<ClinicalComparisonViewerDialog> createState() =>
      _ClinicalComparisonViewerDialogState();
}

class _ClinicalComparisonViewerDialogState
    extends State<ClinicalComparisonViewerDialog> {
  late OrderInDb _baseOrder;
  late OrderInDb _comparisonOrder;
  late PatientInfo _resolvedPatient;
  late List<ClinicalComparisonPdfRow> _allRows;
  String _searchQuery = '';
  String _selectedCategoryFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    if (widget.order1.createdAt <= widget.order2.createdAt) {
      _baseOrder = widget.order1;
      _comparisonOrder = widget.order2;
    } else {
      _baseOrder = widget.order2;
      _comparisonOrder = widget.order1;
    }

    _resolvedPatient = widget.patientInfo ??
        _comparisonOrder.patientInfo ??
        _baseOrder.patientInfo ??
        PatientInfo(name: 'Paciente sin registrar');

    _allRows = ClinicalComparisonPdfTemplate.buildComparisonRows(
      _baseOrder,
      _comparisonOrder,
    );
  }

  String _getCategoryForRow(ClinicalComparisonPdfRow row) {
    final key = row.key.toUpperCase();
    if (['ERI', 'HB', 'HTC', 'VCM', 'HCM', 'CHCM'].contains(key)) return 'Serie Roja';
    if (['LEU', 'SEG', 'LINF', 'EOS', 'MON', 'BAN', 'BAS', 'LINF-ATIP'].contains(key)) {
      return 'Serie Blanca';
    }
    if (['PLAQ'].contains(key)) return 'Serie Plaquetaria';
    final mc = row.medicalClassification.trim().toUpperCase();
    if (mc.contains('ROJA') || mc.contains('ERITRO')) return 'Serie Roja';
    if (mc.contains('BLANCA') || mc.contains('LEUCO')) return 'Serie Blanca';
    if (mc.contains('PLAQ')) return 'Serie Plaquetaria';
    if (mc.isNotEmpty) return row.medicalClassification;
    return 'General';
  }

  List<ClinicalComparisonPdfRow> get _filteredRows {
    return _allRows.where((row) {
      if (_selectedCategoryFilter != 'ALL') {
        final cat = _getCategoryForRow(row);
        if (_selectedCategoryFilter == 'RED' && cat != 'Serie Roja') return false;
        if (_selectedCategoryFilter == 'WHITE' && cat != 'Serie Blanca') return false;
        if (_selectedCategoryFilter == 'PLATELET' && cat != 'Serie Plaquetaria') return false;
        if (_selectedCategoryFilter == 'DELTA_ONLY' &&
            (row.deltaAbsolute == null || row.deltaAbsolute!.abs() < 0.001)) {
          return false;
        }
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchesName = row.parameterName.toLowerCase().contains(q);
        final matchesKey = row.key.toLowerCase().contains(q);
        final matchesCategory = _getCategoryForRow(row).toLowerCase().contains(q);
        return matchesName || matchesKey || matchesCategory;
      }

      return true;
    }).toList();
  }

  Future<void> _exportPdf(BuildContext context) async {
    final template = ClinicalComparisonPdfTemplate(
      order1: _baseOrder,
      order2: _comparisonOrder,
      branch: widget.branch,
      patientInfo: _resolvedPatient,
      doctorInfo: widget.doctorInfo,
      rows: _allRows,
    );
    final fileName = 'comparativa_ordenes_${_baseOrder.id}_vs_${_comparisonOrder.id}.pdf';
    await PdfExportTool.export(template, fileName: fileName);
  }

  Future<void> _printDocument(BuildContext context) async {
    final template = ClinicalComparisonPdfTemplate(
      order1: _baseOrder,
      order2: _comparisonOrder,
      branch: widget.branch,
      patientInfo: _resolvedPatient,
      doctorInfo: widget.doctorInfo,
      rows: _allRows,
    );
    final doc = await template.buildDocument();
    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: 'comparativa_${_baseOrder.id}_vs_${_comparisonOrder.id}.pdf',
    );
  }

  Future<void> _shareDocument(BuildContext context) async {
    final template = ClinicalComparisonPdfTemplate(
      order1: _baseOrder,
      order2: _comparisonOrder,
      branch: widget.branch,
      patientInfo: _resolvedPatient,
      doctorInfo: widget.doctorInfo,
      rows: _allRows,
    );
    final doc = await template.buildDocument();
    final fileName = 'comparativa_${_baseOrder.id}_vs_${_comparisonOrder.id}.pdf';
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: fileName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final baseDate = DateTime.fromMillisecondsSinceEpoch(_baseOrder.createdAt);
    final compDate = DateTime.fromMillisecondsSinceEpoch(_comparisonOrder.createdAt);
    final daysElapsed = compDate.difference(baseDate).inDays;

    final shortBaseId = _baseOrder.id.length > 8
        ? _baseOrder.id.substring(_baseOrder.id.length - 8).toUpperCase()
        : _baseOrder.id.toUpperCase();
    final shortCompId = _comparisonOrder.id.length > 8
        ? _comparisonOrder.id.substring(_comparisonOrder.id.length - 8).toUpperCase()
        : _comparisonOrder.id.toUpperCase();

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(80),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparativa Evolutiva de Exámenes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              '${_resolvedPatient.name}  •  #$shortBaseId vs #$shortCompId ($daysElapsed días)',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Exportar PDF (A4)',
            onPressed: () => _exportPdf(context),
            icon: const Icon(Icons.picture_as_pdf),
          ),
          IconButton(
            tooltip: 'Imprimir Reporte',
            onPressed: () => _printDocument(context),
            icon: const Icon(Icons.print),
          ),
          IconButton(
            tooltip: 'Compartir PDF',
            onPressed: () => _shareDocument(context),
            icon: const Icon(Icons.share),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                ClinicalComparisonHeader(
                  resolvedPatient: _resolvedPatient,
                  baseOrder: _baseOrder,
                  comparisonOrder: _comparisonOrder,
                  daysElapsed: daysElapsed,
                ),
                const SizedBox(height: 12),
                ClinicalComparisonKpiCards(allRows: _allRows),
                const SizedBox(height: 12),
                ClinicalComparisonFiltersBar(
                  searchQuery: _searchQuery,
                  selectedCategory: _selectedCategoryFilter,
                  totalRowsCount: _allRows.length,
                  onSearchChanged: (val) => setState(() => _searchQuery = val),
                  onCategoryChanged: (cat) => setState(() => _selectedCategoryFilter = cat),
                  onClearSearch: () => setState(() => _searchQuery = ''),
                ),
                const SizedBox(height: 12),
                ClinicalComparisonTable(rows: _filteredRows),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
