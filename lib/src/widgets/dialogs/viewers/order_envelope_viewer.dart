import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/service_locator.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../tools/exports/pdf/templates/clinical_order_envelope_pdf_template.dart';
import '../../../tools/exports/pdf_export_tool.dart';

/// Abre el visor y panel de impresión del sobre para una orden clínica.
Future<void> showOrderEnvelopeViewerDialog(
  BuildContext context,
  OrderInDb order, {
  PatientInfo? patientInfo,
  DoctorInfo? doctorInfo,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod('TextInput.hide');

  // Obtener sucursal actual de la sesión
  final appSession = sl<AppSessionCubit>();
  final branch = appSession.currentBranch ??
      BranchInDb(
        id: order.branchId.isNotEmpty ? order.branchId : 'BRANCH_DEFAULT',
        name: 'Laboratorio Clínico Serum',
        address: 'Sede Principal',
        phone: 'PBX: (505) 2222-0000',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) {
        return _OrderEnvelopeViewer(
          order: order,
          branch: branch,
          patientInfo: patientInfo ?? order.patientInfo,
          doctorInfo: doctorInfo ?? order.doctorInfo,
        );
      },
    ),
  );
}

class _OrderEnvelopeViewer extends StatefulWidget {
  final OrderInDb order;
  final BranchInDb branch;
  final PatientInfo? patientInfo;
  final DoctorInfo? doctorInfo;

  const _OrderEnvelopeViewer({
    required this.order,
    required this.branch,
    this.patientInfo,
    this.doctorInfo,
  });

  @override
  State<_OrderEnvelopeViewer> createState() => _OrderEnvelopeViewerState();
}

class _OrderEnvelopeViewerState extends State<_OrderEnvelopeViewer> {
  late PatientInfo? _patientInfo;
  late DoctorInfo? _doctorInfo;
  bool _rotate180 = false;

  @override
  void initState() {
    super.initState();
    _patientInfo = widget.patientInfo ?? widget.order.patientInfo;
    _doctorInfo = widget.doctorInfo ?? widget.order.doctorInfo;

    if (_patientInfo == null ||
        (_doctorInfo == null &&
            widget.order.doctorId != null &&
            widget.order.doctorId!.isNotEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resolveMissingSnapshotsInBackground();
      });
    }
  }

  Future<void> _resolveMissingSnapshotsInBackground() async {
    final patientsRepo = context.read<PatientsRepository>();
    final doctorsRepo = context.read<DoctorsRepository>();

    if (_patientInfo == null) {
      try {
        final p = await patientsRepo.getPatientById(widget.order.patientId);
        if (p != null && mounted) {
          setState(() {
            _patientInfo = PatientInfo(
              name: p.name,
              dateOfBirth: p.dateOfBirth,
              gender: p.gender,
              phone: p.phone,
              address: p.address ?? '',
              cardId: p.cardId,
              email: p.email,
            );
          });
        }
      } catch (_) {}
    }

    if (_doctorInfo == null &&
        widget.order.doctorId != null &&
        widget.order.doctorId!.isNotEmpty) {
      try {
        final d = await doctorsRepo.getDoctorById(widget.order.doctorId!);
        if (d != null && mounted) {
          setState(() {
            _doctorInfo = DoctorInfo(
              name: d.name,
              specialty: d.specialty,
              phone: d.phone ?? '',
              cardId: d.cardId,
              email: d.email,
            );
          });
        }
      } catch (_) {}
    }
  }

  ClinicalOrderEnvelopePdfTemplate _buildTemplate() {
    return ClinicalOrderEnvelopePdfTemplate(
      order: widget.order,
      branch: widget.branch,
      patientInfo: _patientInfo,
      doctorInfo: _doctorInfo,
      rotate180: _rotate180,
    );
  }

  Future<void> _exportPdf() async {
    final template = _buildTemplate();
    final shortId = widget.order.id.length > 8
        ? widget.order.id.substring(widget.order.id.length - 8)
        : widget.order.id;
    await PdfExportTool.export(template, fileName: 'sobre_orden_$shortId.pdf');
  }

  Future<void> _printDocument() async {
    final template = _buildTemplate();
    final doc = await template.buildDocument();
    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: 'sobre_orden_${widget.order.id}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortId = widget.order.id.length > 8
        ? widget.order.id.substring(widget.order.id.length - 8).toUpperCase()
        : widget.order.id.toUpperCase();

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: Text('Sobre de Entrega - Folio #$shortId'),
        actions: [
          IconButton(
            tooltip: _rotate180
                ? 'Orientación Normal'
                : 'Invertir Sentido (180°)',
            onPressed: () {
              setState(() {
                _rotate180 = !_rotate180;
              });
            },
            icon: Icon(
              _rotate180
                  ? Icons.screen_rotation_alt
                  : Icons.screen_rotation_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Exportar PDF',
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf),
          ),
          IconButton(
            tooltip: 'Imprimir Sobre',
            onPressed: _printDocument,
            icon: const Icon(Icons.print),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner de orientación para el operador de laboratorio
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Coloque el sobre en vertical en el centro de la bandeja manual (el lado angosto de 10.5 cm entra primero). Si su impresora alimenta por el extremo opuesto, use el botón de invertir orientación (180°).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Visor interactivo del sobre
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: PdfPreview(
                    build: (format) async {
                      final template = _buildTemplate();
                      final doc = await template.buildDocument();
                      return doc.save();
                    },
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    allowPrinting: true,
                    allowSharing: true,
                    initialPageFormat:
                        ClinicalOrderEnvelopePdfTemplate.envelopeVerticalFormat,
                    pdfFileName: 'sobre_orden_$shortId.pdf',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
