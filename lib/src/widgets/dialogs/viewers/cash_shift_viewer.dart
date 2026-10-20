import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/service_locator.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../tools/exports/pdf/templates/cash_shift_pdf_template.dart';
import '../../../tools/exports/pdf_export_tool.dart';

/// Abre el visor interactivo para el comprobante de turno de caja y arqueo contable.
Future<void> showCashShiftViewerDialog(
  BuildContext context,
  CashShiftInDb shift, {
  BranchInDb? branch,
  List<CashMovementInDb>? movements,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod('TextInput.hide');

  final appSession = sl<AppSessionCubit>();
  final resolvedBranch = branch ??
      appSession.getBranchById(shift.branchId) ??
      appSession.currentBranch ??
      BranchInDb(
        id: shift.branchId.isNotEmpty ? shift.branchId : 'BRANCH_DEFAULT',
        name: shift.branchName?.isNotEmpty == true
            ? shift.branchName!
            : 'Laboratorio Clínico Serum',
        address: 'Sede Principal',
        phone: 'PBX: (505) 2222-0000',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) {
        return _CashShiftViewer(
          shift: shift,
          branch: resolvedBranch,
          initialMovements: movements,
        );
      },
    ),
  );
}

/// Consulta el turno por su identificador y despliega el visor de comprobante y arqueo.
Future<void> showCashShiftViewerDialogFromId(
  BuildContext context,
  String shiftId,
) async {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod('TextInput.hide');

  final shiftsRepo = context.read<CashShiftsRepository>();
  final shift = await shiftsRepo.getCashShiftById(shiftId);

  if (!context.mounted) return;

  if (shift == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se encontró el turno solicitado')),
    );
    return;
  }

  await showCashShiftViewerDialog(context, shift);
}

class _CashShiftViewer extends StatefulWidget {
  final CashShiftInDb shift;
  final BranchInDb branch;
  final List<CashMovementInDb>? initialMovements;

  const _CashShiftViewer({
    required this.shift,
    required this.branch,
    this.initialMovements,
  });

  @override
  State<_CashShiftViewer> createState() => _CashShiftViewerState();
}

class _CashShiftViewerState extends State<_CashShiftViewer> {
  late CashShiftInDb _shift;
  late BranchInDb _branch;
  List<CashMovementInDb> _movements = [];
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _shift = widget.shift;
    _branch = widget.branch;
    _movements = widget.initialMovements ?? [];

    if (widget.initialMovements == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadShiftDetails();
      });
    }
  }

  Future<void> _loadShiftDetails() async {
    setState(() => _isLoadingDetails = true);
    try {
      final movementsRepo = context.read<CashMovementsRepository>();

      final movements = await movementsRepo.getAllCashMovements(
        queryParams: CashMovementQueryParams(
          shiftId: _shift.id,
          limit: 100,
        ),
      );

      if (mounted) {
        setState(() {
          _movements = movements;
          _isLoadingDetails = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  CashShiftPdfTemplate _getTemplate() {
    return CashShiftPdfTemplate(
      shift: _shift,
      branch: _branch,
      movements: _movements,
      pageFormat: PdfPageFormat.a4,
    );
  }

  String _buildFileName() {
    final shortId = _shift.id.length >= 8 ? _shift.id.substring(0, 8) : _shift.id;
    return 'corte_arqueo_turno_$shortId.pdf';
  }

  Future<void> _exportPdf() async {
    final template = _getTemplate();
    final fileName = _buildFileName();
    await PdfExportTool.export(template, fileName: fileName);
  }

  Future<void> _printDocument() async {
    final template = _getTemplate();
    final doc = await template.buildDocument();
    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: _buildFileName(),
    );
  }

  Future<void> _shareDocument() async {
    final template = _getTemplate();
    final doc = await template.buildDocument();
    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: _buildFileName(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortId = _shift.id.length >= 8
        ? _shift.id.substring(0, 8).toUpperCase()
        : _shift.id.toUpperCase();

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Corte y Arqueo - Turno #$shortId'),
            Text(
              _shift.isOpen ? 'Turno en curso' : 'Turno cerrado',
              style: theme.textTheme.labelSmall?.copyWith(
                color: _shift.isOpen ? Colors.green.shade700 : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Exportar PDF',
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf),
          ),
          IconButton(
            tooltip: 'Imprimir Comprobante',
            onPressed: _printDocument,
            icon: const Icon(Icons.print),
          ),
          IconButton(
            tooltip: 'Compartir Comprobante',
            onPressed: _shareDocument,
            icon: const Icon(Icons.share),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            PdfPreview(
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              maxPageWidth: 760,
              previewPageMargin: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 16,
              ),
              actions: const [],
              loadingWidget: const Center(child: CircularProgressIndicator()),
              build: (format) async {
                final template = _getTemplate();
                final doc = await template.buildDocument();
                return doc.save();
              },
            ),
            if (_isLoadingDetails)
              Positioned(
                top: 10,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withAlpha(220),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cargando movimientos...',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
