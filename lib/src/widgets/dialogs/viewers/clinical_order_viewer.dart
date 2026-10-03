import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/service_locator.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../tools/exports/pdf/templates/clinical_order_pdf_template.dart';
import '../../../tools/exports/pdf_export_tool.dart';

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
              address: p.address,
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
              phone: d.phone,
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
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: ClinicalOrderViewerContent(
                    order: widget.order,
                    branch: widget.branch,
                    patientInfo: resolvedPatient,
                    doctorInfo: _doctorInfo,
                  ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.biotech, size: 28, color: Colors.blue.shade800),
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
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Dirección: ${branch.address}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                  Text('Teléfono: ${branch.phone}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                ],
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

        // 3. Encabezado del Estudio Solicitado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade900,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ESTUDIO: ${order.examName.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'TOTAL ANÁLISIS: ${order.results.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 4. Tabla de Resultados Clínicos
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Table(
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey.shade200),
            ),
            columnWidths: const {
              0: FlexColumnWidth(4.0), // Parámetro
              1: FlexColumnWidth(2.5), // Resultado
              2: FlexColumnWidth(1.8), // Unidades
              3: FlexColumnWidth(3.2), // Referencia
              4: FlexColumnWidth(2.0), // Alerta
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                ),
                children: [
                  _buildTableCell('ANÁLISIS / PARÁMETRO',
                      isHeader: true, align: TextAlign.left),
                  _buildTableCell('RESULTADO',
                      isHeader: true, align: TextAlign.center),
                  _buildTableCell('UNIDADES',
                      isHeader: true, align: TextAlign.center),
                  _buildTableCell('VALOR REFERENCIAL',
                      isHeader: true, align: TextAlign.center),
                  _buildTableCell('ESTADO',
                      isHeader: true, align: TextAlign.center),
                ],
              ),
              ...order.results.map((r) {
                final hasAlert = r.alertFlag != null && r.alertFlag!.isNotEmpty;
                final isNumeric = r.dataType == 'numeric';

                String referenceText = '—';
                if (isNumeric && r.referenceValues.isNotEmpty) {
                  final ref = r.referenceValues.first;
                  referenceText = '${ref.minValue} - ${ref.maxValue}';
                } else if (r.dataType == 'boolean' &&
                    r.expectedQualitativeValue != null) {
                  referenceText = 'Esperado: ${r.expectedQualitativeValue}';
                }

                final alertLabel = hasAlert
                    ? (r.alertFlag == 'HIGH'
                        ? 'ALTO'
                        : r.alertFlag == 'LOW'
                            ? 'BAJO'
                            : r.alertFlag == 'ABNORMAL'
                                ? 'ANORMAL'
                                : r.alertFlag!)
                    : 'NORMAL';

                return TableRow(
                  decoration: BoxDecoration(
                    color: hasAlert
                        ? Colors.red.shade50.withValues(alpha: 0.6)
                        : Colors.white,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.parameterName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: hasAlert
                                  ? Colors.red.shade900
                                  : Colors.black87,
                            ),
                          ),
                          if (r.medicalClassification.isNotEmpty)
                            Text(
                              r.medicalClassification,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                      child: Text(
                        r.resultValue ?? '—',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color:
                              hasAlert ? Colors.red.shade900 : Colors.black87,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                      child: Text(
                        r.unitOfMeasure.isNotEmpty ? r.unitOfMeasure : '—',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade800),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                      child: Text(
                        referenceText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 8),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: hasAlert
                                ? Colors.red.shade100
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: hasAlert
                                  ? Colors.red.shade300
                                  : Colors.green.shade300,
                            ),
                          ),
                          child: Text(
                            alertLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: hasAlert
                                  ? Colors.red.shade900
                                  : Colors.green.shade900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 20),

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
              const Text(
                'Responsable de Laboratorio',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                'Firma y Sello de Validación Clínica',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
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

  Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    TextAlign align = TextAlign.left,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: isHeader ? 11 : 12,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.grey.shade800 : Colors.black87,
        ),
      ),
    );
  }
}
