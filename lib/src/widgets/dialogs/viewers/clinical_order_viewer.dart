import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/service_locator.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../tools/exports/pdf/templates/clinical_order_pdf_template.dart';
import '../../../tools/exports/pdf/templates/clinical_order_study_group.dart';
import '../../../tools/exports/pdf_export_tool.dart';
import '../../../tools/formatters/thousands_separator_input_formatter.dart';
import '../../common/app_cached_image.dart';
import 'order_envelope_viewer.dart';

Future<void> showClinicalOrderViewerDialog(
  BuildContext context,
  OrderInDb order, {
  PatientInfo? patientInfo,
  DoctorInfo? doctorInfo,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod('TextInput.hide');

  // Obtener sucursal actual
  final appSession = sl<AppSessionCubit>();
  final branch = appSession.currentBranch ??
      BranchInDb(
        id: order.branchId.isNotEmpty ? order.branchId : 'BRANCH_DEFAULT',
        name: 'Laboratorio Clínico Serum',
        address: 'Sede Principal',
        phone: 'PBX: (505) 2222-0000',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

  // Apertura INMEDIATA a 0 ms. No se espera ninguna llamada de red antes de abrir la pantalla.
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) {
        return ClinicalOrderViewer(
          order: order,
          branch: branch,
          patientInfo: patientInfo ?? order.patientInfo,
          doctorInfo: doctorInfo ?? order.doctorInfo,
        );
      },
    ),
  );
}

Future<void> showClinicalOrderViewerDialogFromId(
  BuildContext context,
  String orderId,
) async {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod('TextInput.hide');

  final ordersRepo = context.read<OrdersRepository>();
  final order = await ordersRepo.getOrderById(orderId);

  if (!context.mounted) return;

  if (order == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se encontró la orden solicitada')),
    );
    return;
  }

  await showClinicalOrderViewerDialog(context, order);
}

class ClinicalOrderViewer extends StatefulWidget {
  const ClinicalOrderViewer({
    super.key,
    required this.order,
    required this.branch,
    this.patientInfo,
    this.doctorInfo,
  });

  final OrderInDb order;
  final BranchInDb branch;
  final PatientInfo? patientInfo;
  final DoctorInfo? doctorInfo;

  @override
  State<ClinicalOrderViewer> createState() => _ClinicalOrderViewerState();
}

class _ClinicalOrderViewerState extends State<ClinicalOrderViewer> {
  late PatientInfo? _patientInfo;
  late DoctorInfo? _doctorInfo;
  late BioanalystInfo? _selectedSigner;

  @override
  void initState() {
    super.initState();
    _patientInfo = widget.patientInfo ?? widget.order.patientInfo;
    _doctorInfo = widget.doctorInfo ?? widget.order.doctorInfo;
    _selectedSigner = widget.branch.bioanalyst;

    // Solo si se trata de una orden previa que no guardó snapshots, resolver en background sin trabar la UI
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
              age: p.age,
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

  Future<void> _exportPdf(BuildContext context) async {
    final template = SingleClinicalOrderTemplate(
      order: widget.order,
      branch: widget.branch,
      patientInfo: _patientInfo,
      doctorInfo: _doctorInfo,
      signer: _selectedSigner,
    );
    final fileName =
        'orden_clinica_${widget.order.id.length > 8 ? widget.order.id.substring(widget.order.id.length - 8) : widget.order.id}.pdf';
    await PdfExportTool.export(template, fileName: fileName);
  }

  Future<void> _printDocument(BuildContext context) async {
    final template = SingleClinicalOrderTemplate(
      order: widget.order,
      branch: widget.branch,
      patientInfo: _patientInfo,
      doctorInfo: _doctorInfo,
      signer: _selectedSigner,
    );
    final doc = await template.buildDocument();
    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: 'orden_clinica_${widget.order.id}.pdf',
    );
  }

  Future<void> _shareDocument(BuildContext context) async {
    final template = SingleClinicalOrderTemplate(
      order: widget.order,
      branch: widget.branch,
      patientInfo: _patientInfo,
      doctorInfo: _doctorInfo,
      signer: _selectedSigner,
    );
    final doc = await template.buildDocument();
    final fileName =
        'orden_clinica_${widget.order.id.length > 8 ? widget.order.id.substring(widget.order.id.length - 8) : widget.order.id}.pdf';
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: fileName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortId = widget.order.id.length > 8
        ? widget.order.id.substring(widget.order.id.length - 8).toUpperCase()
        : widget.order.id.toUpperCase();

    final resolvedPatient = _patientInfo ??
        PatientInfo(
          name: 'Paciente #${widget.order.patientId}',
          dateOfBirth: 0,
          gender: 'M',
        );

    final auxBioList = widget.branch.auxBio ?? [];
    final hasAuxBio = auxBioList.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: Text('Informe Clínico - Folio #$shortId'),
        actions: [
          if (hasAuxBio) ...[
            PopupMenuButton<BioanalystInfo>(
              tooltip: 'Seleccionar Bioanalista Firmante',
              initialValue: _selectedSigner,
              onSelected: (signer) {
                setState(() {
                  _selectedSigner = signer;
                });
              },
              itemBuilder: (context) => [
                if (widget.branch.bioanalyst != null)
                  PopupMenuItem(
                    value: widget.branch.bioanalyst,
                    child: Row(
                      children: [
                        Icon(Icons.verified_user_outlined,
                            size: 18, color: Colors.teal.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.branch.bioanalyst!.name} (Titular)',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ...auxBioList.map((aux) {
                  return PopupMenuItem(
                    value: aux.bioanalyst,
                    child: Row(
                      children: [
                        Icon(Icons.badge_outlined,
                            size: 18, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${aux.bioanalyst.name.isNotEmpty ? aux.bioanalyst.name : aux.user.name} (Auxiliar)',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.draw_outlined,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        _selectedSigner?.name.isNotEmpty == true
                            ? _selectedSigner!.name
                            : 'Seleccionar Firmante',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down,
                        size: 18, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            tooltip: 'Exportar PDF (A4)',
            onPressed: () => _exportPdf(context),
            icon: const Icon(Icons.picture_as_pdf),
          ),
          IconButton(
            tooltip: 'Imprimir Sobre',
            onPressed: () => showOrderEnvelopeViewerDialog(
              context,
              widget.order,
              patientInfo: _patientInfo,
              doctorInfo: _doctorInfo,
            ),
            icon: const Icon(Icons.mail_outline),
          ),
          IconButton(
            tooltip: 'Imprimir Informe',
            onPressed: () => _printDocument(context),
            icon: const Icon(Icons.print),
          ),
          IconButton(
            tooltip: 'Compartir Informe',
            onPressed: () => _shareDocument(context),
            icon: const Icon(Icons.share),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Card(
                elevation: 3,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Stack(
                  children: [
                    Builder(
                      builder: (context) {
                        final watermarkImg = widget.branch.effectiveLogo ??
                            widget.branch.effectiveIsoLogo;
                        if (watermarkImg == null || watermarkImg.isEmpty) {
                          return const SizedBox();
                        }

                        return Positioned.fill(
                          child: IgnorePointer(
                            child: Center(
                              child: Opacity(
                                opacity: 0.12,
                                child: AppCachedImage(
                                  imageUrl: watermarkImg,
                                  width: 340,
                                  fit: BoxFit.contain,
                                  fallbackWidget: const SizedBox(),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: ClinicalOrderViewerContent(
                        order: widget.order,
                        branch: widget.branch,
                        patientInfo: resolvedPatient,
                        doctorInfo: _doctorInfo,
                        signer: _selectedSigner,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ClinicalOrderViewerContent extends StatelessWidget {
  const ClinicalOrderViewerContent({
    super.key,
    required this.order,
    required this.branch,
    required this.patientInfo,
    this.doctorInfo,
    this.signer,
  });

  final OrderInDb order;
  final BranchInDb branch;
  final PatientInfo patientInfo;
  final DoctorInfo? doctorInfo;
  final BioanalystInfo? signer;

  int _calculateAge(int birthDateMs) {
    if (birthDateMs <= 0) return 0;
    final birthDate = DateTime.fromMillisecondsSinceEpoch(birthDateMs);
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age >= 0 ? age : 0;
  }

  String _formatGender(String gender) {
    final g = gender.trim().toLowerCase();
    if (g == 'm' || g == 'male' || g == 'masculino') return 'Masculino';
    if (g == 'f' || g == 'female' || g == 'femenino') return 'Femenino';
    return gender;
  }

  @override
  Widget build(BuildContext context) {
    final orderDate = DateTime.fromMillisecondsSinceEpoch(order.createdAt);
    final formattedDate =
        '${DateTimeTool.formatddMMyy(orderDate)} ${DateTimeTool.formatHHmm(orderDate)}';
    final patientAge =
        patientInfo.age > 0 ? patientInfo.age : _calculateAge(patientInfo.dateOfBirth);
    final genderStr = _formatGender(patientInfo.gender);
    final shortId = order.id.length > 8
        ? order.id.substring(order.id.length - 8).toUpperCase()
        : order.id.toUpperCase();

    final totalPrice = order.totalPrice > 0 ? order.totalPrice : order.salePriceApplied;
    final isFullyPaid = order.isFullyPaid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Membrete de Laboratorio / Sucursal
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Builder(
                builder: (context) {
                  final isIsoLogo =
                      branch.isoLogoUrl != null && branch.isoLogoUrl!.isNotEmpty;
                  final headerImg = branch.effectiveIsoLogo;

                  if (isIsoLogo && headerImg != null && headerImg.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppCachedImage(
                          imageUrl: headerImg,
                          height: 48,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                          fallbackWidget: Text(
                            branch.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (branch.address.isNotEmpty)
                          Text('Dirección: ${branch.address}',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade800)),
                        Wrap(
                          spacing: 12,
                          children: [
                            if (branch.phone.isNotEmpty)
                              Text('Tel: ${branch.phone}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade800)),
                            if (branch.email != null &&
                                branch.email!.isNotEmpty)
                              Text('Email: ${branch.email!}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade800)),
                          ],
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              image: headerImg != null && headerImg.isNotEmpty
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(headerImg),
                                      fit: BoxFit.contain,
                                    )
                                  : null,
                            ),
                            child: headerImg == null || headerImg.isEmpty
                                ? Icon(Icons.biotech,
                                    size: 28, color: Colors.blue.shade800)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  branch.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                Text(
                                  'Laboratorio Clínico y Diagnóstico Especializado',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (branch.address.isNotEmpty)
                        Text('Dirección: ${branch.address}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade800)),
                      Wrap(
                        spacing: 12,
                        children: [
                          if (branch.phone.isNotEmpty)
                            Text('Teléfono: ${branch.phone}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade800)),
                          if (branch.email != null &&
                              branch.email!.isNotEmpty)
                            Text('Email: ${branch.email!}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade800)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      'INFORME CLÍNICO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Folio: #$shortId',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Fecha: $formattedDate',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: order.status == 'completed'
                          ? Colors.green.shade50
                          : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: order.status == 'completed'
                            ? Colors.green.shade300
                            : Colors.amber.shade300,
                      ),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: order.status == 'completed'
                            ? Colors.green.shade800
                            : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        const Divider(color: Colors.black54, thickness: 1.2),
        const SizedBox(height: 12),

        // 2. Ficha del Paciente y Médico Referente
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Datos del Paciente
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.blue.shade900),
                        const SizedBox(width: 6),
                        Text(
                          'DATOS DEL PACIENTE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (order.patientId.isNotEmpty)
                      _buildDataRow('Código Paciente:', '#${order.patientId}', isBold: true),
                    _buildDataRow('Nombre:', patientInfo.name, isBold: true),
                    _buildDataRow(
                      'Edad / Sexo:',
                      '${patientAge > 0 ? '$patientAge años' : 'N/D'} | $genderStr',
                    ),
                    if (patientInfo.cardId != null && patientInfo.cardId!.isNotEmpty)
                      _buildDataRow('Identificación:', patientInfo.cardId!),
                    if (patientInfo.phone.isNotEmpty)
                      _buildDataRow('Teléfono:', patientInfo.phone),
                    if (patientInfo.address.isNotEmpty)
                      _buildDataRow('Dirección:', patientInfo.address),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 100, color: Colors.grey.shade300),
              const SizedBox(width: 16),
              // Datos del Médico Referente
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medical_services_outlined,
                            size: 16, color: Colors.blue.shade900),
                        const SizedBox(width: 6),
                        Text(
                          'MÉDICO REFERENTE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (doctorInfo != null) ...[
                      _buildDataRow('Médico:', doctorInfo!.name, isBold: true),
                      _buildDataRow('Especialidad:', doctorInfo!.specialty),
                      if (doctorInfo!.cardId != null && doctorInfo!.cardId!.isNotEmpty)
                        _buildDataRow('Colegiatura:', doctorInfo!.cardId!),
                      if (doctorInfo!.phone.isNotEmpty)
                        _buildDataRow('Contacto:', doctorInfo!.phone),
                    ] else ...[
                      _buildDataRow(
                          'Médico:', 'Particular / Sin médico asignado',
                          isBold: true),
                      _buildDataRow('Atención:', 'Directa en ventanilla'),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 4. Encabezado de Área Clínica y Resultados Agrupados por Estudio
        Builder(
          builder: (context) {
            final studyGroups = ClinicalOrderGrouper.groupResultsByStudy(order);
            final overallArea =
                ClinicalOrderGrouper.determineOverallClinicalArea(studyGroups);

            TableRow buildTableRow(OrderTestResult r, bool hasGroupHeader) {
              final isNumeric = r.dataType == 'numeric';
              final numVal = isNumeric && r.resultValue != null
                  ? ThousandsSeparatorInputFormatter.tryParseDouble(r.resultValue)
                  : null;

              String? alertFlag = r.alertFlag;
              if (alertFlag == null &&
                  numVal != null &&
                  r.referenceValues.isNotEmpty) {
                final ref = r.referenceValues.first;
                if (numVal > ref.maxValue) {
                  alertFlag = 'H';
                } else if (numVal < ref.minValue) {
                  alertFlag = 'L';
                }
              } else if (alertFlag != null) {
                final f = alertFlag.toUpperCase();
                if (f == 'HIGH' || f == 'ALTO') alertFlag = 'H';
                if (f == 'LOW' || f == 'BAJO') alertFlag = 'L';
                if (f == 'ABNORMAL' || f == 'ANORMAL') alertFlag = '*';
              }

              final hasAlert =
                  alertFlag != null && alertFlag.isNotEmpty;

              String referenceText = '—';
              if (r.referenceText.trim().isNotEmpty) {
                referenceText = r.referenceText.trim();
              } else if (isNumeric && r.referenceValues.isNotEmpty) {
                final ref = r.referenceValues.first;
                final unit = r.unitOfMeasure.isNotEmpty
                    ? ' ${r.unitOfMeasure}'
                    : '';
                referenceText =
                    '${ref.minValue} - ${ref.maxValue}$unit';
              } else if (r.dataType == 'boolean' &&
                  r.expectedQualitativeValue != null) {
                referenceText =
                    'Esperado: ${r.expectedQualitativeValue}';
              } else if (r.expectedQualitativeValue != null) {
                referenceText = r.expectedQualitativeValue!;
              }

              final isTotalRow =
                  r.parameterName.trim().toUpperCase() == 'TOTAL';
              final isSubParam = ClinicalOrderGrouper.isSubParameter(r);
              final double leftIndent = isSubParam
                  ? (hasGroupHeader ? 28.0 : 20.0)
                  : (hasGroupHeader ? 12.0 : 4.0);

              return TableRow(
                decoration: isTotalRow
                    ? BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: Colors.grey.shade300,
                              width: 0.8),
                        ),
                      )
                    : null,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      left: leftIndent,
                      top: 4,
                      bottom: 4,
                      right: 4,
                    ),
                    child: Text(
                      r.parameterName,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isTotalRow
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSubParam ? Colors.grey.shade900 : Colors.black87,
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isNumeric && r.resultValue != null
                                ? ThousandsSeparatorInputFormatter.formatText(r.resultValue!)
                                : (r.resultValue ?? '—'),
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: hasAlert || isTotalRow
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (hasAlert) ...[
                          const SizedBox(width: 8),
                          Text(
                            alertFlag,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD32F2F),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      r.unitOfMeasure.isNotEmpty
                          ? r.unitOfMeasure
                          : '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      referenceText,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: referenceText.contains('\n')
                            ? 11.5
                            : 12,
                        height: referenceText.contains('\n')
                            ? 1.25
                            : null,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              );
            }

            Widget buildTextResultBlock(OrderTestResult r, bool hasGroupHeader) {
              final hasContent =
                  r.resultValue != null && r.resultValue!.trim().isNotEmpty;
              final displayValue = hasContent ? r.resultValue!.trim() : '—';
              final refText = r.referenceText.trim();
              final isSubParam = ClinicalOrderGrouper.isSubParameter(r);
              final double leftIndent = isSubParam
                  ? (hasGroupHeader ? 28.0 : 20.0)
                  : (hasGroupHeader ? 12.0 : 4.0);

              return Padding(
                padding: EdgeInsets.only(
                  left: leftIndent,
                  top: 6,
                  bottom: 8,
                  right: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.parameterName,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300, width: 0.8),
                      ),
                      child: Text(
                        displayValue,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (refText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          'Criterio / Valor de Referencia: $refText',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            height: 1.25,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            List<Widget> buildStudySectionWidgets(
              ClinicalStudyGroup study,
              bool isFirst,
              bool isLast,
            ) {
              final List<Widget> studyWidgets = [];

              // 1. Separador visual entre estudios
              if (!isFirst) {
                studyWidgets.add(const SizedBox(height: 18));
                studyWidgets.add(
                  Divider(color: Colors.grey.shade400, thickness: 1.0, height: 1),
                );
                studyWidgets.add(const SizedBox(height: 16));
              }

              // 2. Título destacado del estudio (ej. BIOMETRÍA HEMÁTICA COMPLETA)
              studyWidgets.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          study.studyTitle,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (studyGroups.length > 1 && study.clinicalArea != overallArea)
                        Text(
                          study.clinicalArea,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
              );

              // 3. Encabezados de tabla si contiene pruebas tabulares
              if (study.hasTabularTests) {
                studyWidgets.add(
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.black, width: 1.0),
                        bottom: BorderSide(color: Colors.black, width: 1.0),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 42,
                          child: Text(
                            'Nombre del Test',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 31,
                          child: Text(
                            'Resultado',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 27,
                          child: Text(
                            'Valores de Referencia',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                studyWidgets.add(const SizedBox(height: 6));
              }

              // 4. Subclasificaciones y parámetros del estudio
              for (final entry in study.subclassificationGroups.entries) {
                final groupTitle = entry.key;
                final items = entry.value;
                final bool hasGroupHeader = groupTitle.isNotEmpty &&
                    groupTitle != study.studyTitle &&
                    groupTitle != overallArea;

                final List<Widget> groupWidgets = [];
                List<OrderTestResult> currentTabularChunk = [];

                void flushTabularChunk() {
                  if (currentTabularChunk.isEmpty) return;
                  final chunk = List<OrderTestResult>.from(currentTabularChunk);
                  currentTabularChunk.clear();
                  groupWidgets.add(
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(4.2),
                        1: FlexColumnWidth(1.8),
                        2: FlexColumnWidth(1.3),
                        3: FlexColumnWidth(2.7),
                      },
                      children: chunk
                          .map((r) => buildTableRow(r, hasGroupHeader))
                          .toList(),
                    ),
                  );
                }

                for (final r in items) {
                  if (ClinicalOrderGrouper.shouldRenderInTable(r)) {
                    currentTabularChunk.add(r);
                  } else {
                    flushTabularChunk();
                    groupWidgets.add(buildTextResultBlock(r, hasGroupHeader));
                  }
                }
                flushTabularChunk();

                studyWidgets.add(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasGroupHeader) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          margin: const EdgeInsets.only(top: 6, bottom: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            groupTitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey.shade800,
                            ),
                          ),
                        ),
                      ],
                      ...groupWidgets,
                      const SizedBox(height: 4),
                    ],
                  ),
                );
              }

              return studyWidgets;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Encabezado de área clínica general
                Text(
                  overallArea,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Divider(color: Colors.black, thickness: 1.2, height: 1),
                const SizedBox(height: 10),

                // 2. Renderizar cada estudio clínico con sus clasificaciones y separadores
                for (int i = 0; i < studyGroups.length; i++) ...[
                  ...buildStudySectionWidgets(
                    studyGroups[i],
                    i == 0,
                    i == studyGroups.length - 1,
                  ),
                ],
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        // 4.5 Observaciones Clínicas / Notas del Bioanalista
        if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blueGrey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.rate_review_outlined, size: 16, color: Colors.blueGrey.shade800),
                    const SizedBox(width: 6),
                    Text(
                      'OBSERVACIONES / NOTAS CLÍNICAS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  order.notes!.trim(),
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade900, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 5. Resumen Financiero
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estado de Pago: ${isFullyPaid ? 'PAGADO' : 'PENDIENTE'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isFullyPaid
                      ? Colors.green.shade800
                      : Colors.orange.shade800,
                ),
              ),
              Text(
                'Total Orden: ${NumberFormatter.convertToMoneyLike(totalPrice)}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 6. Firma y Sello del Responsable
        Builder(
          builder: (context) {
            final effectiveSigner = signer ?? branch.bioanalyst;

            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (effectiveSigner?.sealUrl != null &&
                      effectiveSigner!.sealUrl!.trim().isNotEmpty) ...[
                    Transform.rotate(
                      angle: -0.087, // ~ -5 grados de inclinación realista
                      child: AppCachedImage(
                        imageUrl: effectiveSigner.sealUrl!,
                        width: 125,
                        height: 95,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ] else ...[
                    const SizedBox(height: 48), // Espacio para firma manuscrita y sello manual
                  ],
                  Container(
                    width: 220,
                    height: 1,
                    color: Colors.black87,
                  ),
                  const SizedBox(height: 6),
                  if (effectiveSigner != null &&
                      effectiveSigner.name.trim().isNotEmpty) ...[
                    Text(
                      effectiveSigner.name.trim(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (effectiveSigner.title.trim().isNotEmpty)
                      Text(
                        effectiveSigner.title.trim(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade800,
                        ),
                      ),
                    if (effectiveSigner.code.trim().isNotEmpty)
                      Text(
                        effectiveSigner.code.trim(),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                  ] else ...[
                    const Text(
                      'Responsable de Laboratorio',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Firma y Sello de Validación Clínica',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 36),

        // 7. Pie de Página Institucional (Dirección y Contactos)
        _buildViewerFooter(branch),
      ],
    );
  }

  Widget _buildViewerFooter(BranchInDb branch) {
    final contactItems = <Widget>[];

    // Facebook
    if (branch.facebook != null && branch.facebook!.trim().isNotEmpty) {
      contactItems.add(
        _buildViewerContactItem(
          label: 'f',
          text: branch.facebook!.trim(),
          color: Colors.blue.shade700,
        ),
      );
    }

    // Teléfono / WhatsApp
    if (branch.phone.trim().isNotEmpty) {
      if (contactItems.isNotEmpty) contactItems.add(const SizedBox(width: 16));
      contactItems.add(
        _buildViewerContactItem(
          label: 'W',
          text: branch.phone.trim(),
          color: Colors.teal,
        ),
      );
    }

    // Correo electrónico
    if (branch.email != null && branch.email!.trim().isNotEmpty) {
      if (contactItems.isNotEmpty) contactItems.add(const SizedBox(width: 16));
      contactItems.add(
        _buildViewerContactItem(
          label: '@',
          text: branch.email!.trim(),
          color: Colors.blue.shade600,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        children: [
          if (branch.address.trim().isNotEmpty) ...[
            Text(
              branch.address.trim(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (contactItems.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: contactItems,
            ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Página 1 de 1',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewerContactItem({
    required String label,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
