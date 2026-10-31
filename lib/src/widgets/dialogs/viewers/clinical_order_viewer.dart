import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/service_locator.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../tools/exports/pdf/templates/clinical_order_pdf_template.dart';
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
        return _ClinicalOrderViewer(
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

class _ClinicalOrderViewer extends StatefulWidget {
  const _ClinicalOrderViewer({
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
  State<_ClinicalOrderViewer> createState() => _ClinicalOrderViewerState();
}

class _ClinicalOrderViewerState extends State<_ClinicalOrderViewer> {
  late PatientInfo? _patientInfo;
  late DoctorInfo? _doctorInfo;

  @override
  void initState() {
    super.initState();
    _patientInfo = widget.patientInfo ?? widget.order.patientInfo;
    _doctorInfo = widget.doctorInfo ?? widget.order.doctorInfo;

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

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: Text('Informe Clínico - Folio #$shortId'),
        actions: [
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
  });

  final OrderInDb order;
  final BranchInDb branch;
  final PatientInfo patientInfo;
  final DoctorInfo? doctorInfo;

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
    final patientAge = _calculateAge(patientInfo.dateOfBirth);
    final genderStr = _formatGender(patientInfo.gender);
    final shortId = order.id.length > 8
        ? order.id.substring(order.id.length - 8).toUpperCase()
        : order.id.toUpperCase();

    final totalPrice = order.totalPrice > 0 ? order.totalPrice : order.salePriceApplied;
    final isFullyPaid = order.status == 'paid' ||
        order.status == 'completed' ||
        (totalPrice > 0 && order.paidAmount >= totalPrice);

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

        // 3. Barra de acento teal superior
        Container(
          height: 3,
          color: const Color(0xFF26A69A),
        ),
        const SizedBox(height: 6),

        // 4. Encabezado de Área Clínica y Cabecera de Tabla
        Builder(
          builder: (context) {
            final titleUpper = order.examName.toUpperCase();
            String clinicalArea = 'LABORATORIO CLÍNICO';
            if (titleUpper.contains('HEMAT') ||
                titleUpper.contains('HEMOGLOBINA') ||
                titleUpper.contains('SANGRE') ||
                titleUpper.contains('BIOMETR')) {
              clinicalArea = 'HEMATOLOGÍA';
            } else if (titleUpper.contains('QUIMIC') ||
                titleUpper.contains('GLUCOSA') ||
                titleUpper.contains('PERFIL') ||
                titleUpper.contains('LIPID') ||
                titleUpper.contains('COLESTEROL')) {
              clinicalArea = 'QUÍMICA CLÍNICA';
            } else if (titleUpper.contains('ORINA') ||
                titleUpper.contains('URO') ||
                titleUpper.contains('GENERAL DE ORINA')) {
              clinicalArea = 'UROANÁLISIS';
            } else if (titleUpper.contains('HECES') ||
                titleUpper.contains('COPRO') ||
                titleUpper.contains('PARASIT')) {
              clinicalArea = 'COPROLOGÍA';
            } else if (titleUpper.contains('INMUNO') ||
                titleUpper.contains('SEROLOG') ||
                titleUpper.contains('VIH') ||
                titleUpper.contains('ANTIGEN')) {
              clinicalArea = 'INMUNOLOGÍA / SEROLOGÍA';
            } else {
              final visibleResults = order.results.where((r) => r.showInPrint).toList();
              final resultsToEvaluate = visibleResults.isNotEmpty ? visibleResults : order.results;
              for (final r in resultsToEvaluate) {
                final mc = r.medicalClassification.trim().toUpperCase();
                if (mc.contains('HEMAT')) {
                  clinicalArea = 'HEMATOLOGÍA';
                  break;
                }
                if (mc.contains('QUIMIC')) {
                  clinicalArea = 'QUÍMICA CLÍNICA';
                  break;
                }
              }
            }

            final examTitle = order.examName.isNotEmpty
                ? order.examName.toUpperCase()
                : 'ESTUDIO CLÍNICO';

            // Agrupar por subclasificación médica (subseries como SERIE ROJA, SERIE BLANCA, etc.) o clasificación general
            final Map<String, List<OrderTestResult>> groups = {};
            for (final r in order.results) {
              if (!r.showInPrint) continue;
              final sub = r.subclassification.trim();
              final classification = r.medicalClassification.trim();
              final groupKey = sub.isNotEmpty
                  ? sub.toUpperCase()
                  : (classification.isNotEmpty ? classification.toUpperCase() : '');
              groups.putIfAbsent(groupKey, () => []).add(r);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clinicalArea,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Divider(color: Colors.black, thickness: 1.2, height: 1),
                const SizedBox(height: 6),
                const Row(
                  children: [
                    Expanded(
                      flex: 42,
                      child: Text(
                        'Nombre del Test',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 31,
                      child: Text(
                        'Resultado',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 27,
                      child: Text(
                        'Valores de Referencia',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Divider(color: Colors.black, thickness: 1.2, height: 1),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    examTitle,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...groups.entries.map((entry) {
                  final groupTitle = entry.key;
                  final items = entry.value;
                  final bool hasGroupHeader =
                      groupTitle.isNotEmpty && groupTitle != clinicalArea;

                  return Column(
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
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(4.2),
                          1: FlexColumnWidth(1.8),
                          2: FlexColumnWidth(1.3),
                          3: FlexColumnWidth(2.7),
                        },
                        children: items.map((r) {
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
                          if (isNumeric && r.referenceValues.isNotEmpty) {
                            final ref = r.referenceValues.first;
                            final unit = r.unitOfMeasure.isNotEmpty
                                ? ' ${r.unitOfMeasure}'
                                : '';
                            referenceText =
                                '${ref.minValue} - ${ref.maxValue}$unit';
                          } else if (r.referenceText.trim().isNotEmpty) {
                            referenceText = r.referenceText.contains('\n') || r.referenceText.length > 25
                                ? 'Ver notas'
                                : r.referenceText.trim();
                          } else if (r.dataType == 'boolean' &&
                              r.expectedQualitativeValue != null) {
                            referenceText =
                                'Esperado: ${r.expectedQualitativeValue}';
                          } else if (r.expectedQualitativeValue != null) {
                            referenceText = r.expectedQualitativeValue!;
                          }

                          final isTotalRow =
                              r.parameterName.trim().toUpperCase() == 'TOTAL';

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
                                  left: hasGroupHeader ? 12 : 4,
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
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isNumeric && r.resultValue != null
                                          ? ThousandsSeparatorInputFormatter.formatText(r.resultValue!)
                                          : (r.resultValue ?? '—'),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: hasAlert || isTotalRow
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: Colors.black87,
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
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      Builder(
                        builder: (context) {
                          final referenceNotesItems =
                              items.where((r) => r.referenceText.trim().isNotEmpty).toList();
                          if (referenceNotesItems.isEmpty) return const SizedBox.shrink();

                          final showParameterName = order.results
                                  .where((x) => x.showInPrint && x.referenceText.trim().isNotEmpty)
                                  .length >
                              1;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              ...referenceNotesItems.map((r) {
                                final title = showParameterName
                                    ? 'NOTAS DE REFERENCIA (${r.parameterName.toUpperCase()}):'
                                    : 'NOTAS DE REFERENCIA:';

                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 4, bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    border: Border.all(
                                        color: Colors.grey.shade300, width: 0.8),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        r.referenceText.trim(),
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Colors.grey.shade800,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                    ],
                  );
                }),
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

        // 5. Resumen Financiero y Notas
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Nota: Los resultados corresponden exclusivamente a la muestra analizada y deben ser valorados en el contexto clínico por el médico tratante.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Orden: ${NumberFormatter.convertToMoneyLike(totalPrice)}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Estado de Pago: ${isFullyPaid ? 'PAGADO' : 'PENDIENTE'}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isFullyPaid
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),

        // 6. Firma y Sello del Responsable
        Center(
          child: Column(
            children: [
              Container(
                width: 220,
                height: 1,
                color: Colors.black87,
              ),
              const SizedBox(height: 6),
              if (branch.bioanalyst != null &&
                  branch.bioanalyst!.name.trim().isNotEmpty) ...[
                Text(
                  branch.bioanalyst!.name.trim(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (branch.bioanalyst!.title.trim().isNotEmpty)
                  Text(
                    branch.bioanalyst!.title.trim(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
                if (branch.bioanalyst!.code.trim().isNotEmpty)
                  Text(
                    branch.bioanalyst!.code.trim(),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
              ] else ...[
                const Text(
                  'Responsable de Laboratorio',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Firma y Sello de Validación Clínica',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
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
              'Vista Previa Oficial',
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
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
