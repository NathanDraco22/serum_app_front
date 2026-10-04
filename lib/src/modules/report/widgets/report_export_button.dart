import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/report_cubit/report_cubit.dart';
import '../../../cubits/report_cubit/report_state.dart';
import '../../../tools/exports/exports.dart';

/// Botón interactivo para exportar o imprimir el reporte activo en formato PDF.
class ReportExportButton extends StatefulWidget {
  const ReportExportButton({super.key});

  @override
  State<ReportExportButton> createState() => _ReportExportButtonState();
}

class _ReportExportButtonState extends State<ReportExportButton> {
  bool _isExporting = false;

  PdfTemplate? _resolveTemplate({
    required ReportState state,
    required String branchName,
    String? branchAddress,
    String? branchPhone,
    String? operatorName,
  }) {
    switch (state.activeTab) {
      case ReportTab.financial:
        final report = state.financialReport;
        if (report == null) return null;
        return FinancialReportPdfTemplate(
          report: report,
          branchName: branchName,
          branchAddress: branchAddress,
          branchPhone: branchPhone,
          generatedBy: operatorName,
        );

      case ReportTab.topDoctors:
        final report = state.topDoctorsReport;
        if (report == null) return null;
        return TopDoctorsReportPdfTemplate(
          report: report,
          branchName: branchName,
          branchAddress: branchAddress,
          branchPhone: branchPhone,
          generatedBy: operatorName,
        );

      case ReportTab.labTestsVolume:
        final report = state.labTestsVolumeReport;
        if (report == null) return null;
        return LabTestsVolumeReportPdfTemplate(
          report: report,
          branchName: branchName,
          branchAddress: branchAddress,
          branchPhone: branchPhone,
          generatedBy: operatorName,
        );

      case ReportTab.pendingBalances:
        final report = state.pendingBalancesReport;
        if (report == null) return null;
        return PendingBalancesReportPdfTemplate(
          report: report,
          branchName: branchName,
          branchAddress: branchAddress,
          branchPhone: branchPhone,
          generatedBy: operatorName,
        );

      case ReportTab.shiftsAudit:
        final report = state.shiftsAuditReport;
        if (report == null) return null;
        return ShiftsAuditReportPdfTemplate(
          report: report,
          branchName: branchName,
          branchAddress: branchAddress,
          branchPhone: branchPhone,
          generatedBy: operatorName,
          discrepanciesOnly: state.onlyDiscrepancies,
        );
    }
  }

  String _generateFileName(ReportTab tab) {
    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    switch (tab) {
      case ReportTab.financial:
        return 'reporte_financiero_$dateStr.pdf';
      case ReportTab.topDoctors:
        return 'reporte_top_medicos_$dateStr.pdf';
      case ReportTab.labTestsVolume:
        return 'reporte_demanda_examenes_$dateStr.pdf';
      case ReportTab.pendingBalances:
        return 'reporte_saldos_pendientes_$dateStr.pdf';
      case ReportTab.shiftsAudit:
        return 'reporte_auditoria_turnos_$dateStr.pdf';
    }
  }

  Future<void> _handleAction({
    required bool isDirectPrint,
  }) async {
    final reportState = context.read<ReportCubit>().state;
    final sessionCubit = context.read<AppSessionCubit>();

    // Resolver datos de sede y operador
    String branchName = 'Todas las sucursales (Consolidado)';
    String? branchAddress;
    String? branchPhone;

    if (reportState.branchId != null) {
      final branch = sessionCubit.getBranchById(reportState.branchId!);
      branchName = branch?.name ?? 'Sucursal #${reportState.branchId}';
      branchAddress = branch?.address;
      branchPhone = branch?.phone;
    }

    final user = sessionCubit.user;
    final operatorName = user != null
        ? (user.name.isNotEmpty ? user.name : user.username)
        : null;

    final template = _resolveTemplate(
      state: reportState,
      branchName: branchName,
      branchAddress: branchAddress,
      branchPhone: branchPhone,
      operatorName: operatorName,
    );

    if (template == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay datos disponibles en este reporte para exportar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final fileName = _generateFileName(reportState.activeTab);
      if (isDirectPrint) {
        await PdfExportTool.printPdf(template, name: fileName);
      } else {
        await PdfExportTool.export(template, fileName: fileName);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar el PDF: $e'),
          backgroundColor: Colors.red,
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
    final reportState = context.watch<ReportCubit>().state;
    final isReady = !reportState.isLoading && !_isExporting;

    return PopupMenuButton<String>(
      enabled: isReady,
      tooltip: 'Opciones de exportación PDF',
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) {
        if (value == 'share') {
          _handleAction(isDirectPrint: false);
        } else if (value == 'print') {
          _handleAction(isDirectPrint: true);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.download_rounded, size: 20, color: Colors.blueGrey),
              SizedBox(width: 10),
              Text('Descargar / Compartir PDF'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'print',
          child: Row(
            children: [
              Icon(Icons.print_outlined, size: 20, color: Colors.blueGrey),
              SizedBox(width: 10),
              Text('Imprimir / Vista Previa'),
            ],
          ),
        ),
      ],
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withAlpha(200),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary.withAlpha(120),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isExporting)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.picture_as_pdf_outlined,
                size: 18,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            const SizedBox(width: 8),
            Text(
              _isExporting ? 'Generando...' : 'Exportar PDF',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}
