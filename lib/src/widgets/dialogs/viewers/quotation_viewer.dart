import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/service_locator.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../tools/exports/pdf/templates/quotation_pdf_template.dart';
import '../../../tools/exports/pdf_export_tool.dart';

Future<void> showQuotationViewerDialog(
  BuildContext context,
  QuotationInDb quotation, {
  PatientInfo? clientInfo,
  DoctorInfo? doctorInfo,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod('TextInput.hide');

  final appSession = sl<AppSessionCubit>();
  final branch = appSession.currentBranch ??
      BranchInDb(
        id: quotation.branchId.isNotEmpty ? quotation.branchId : 'BRANCH_DEFAULT',
        name: 'Laboratorio Clínico Serum',
        address: 'Sede Principal',
        phone: 'PBX: (505) 2222-0000',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) {
        return _QuotationViewer(
          quotation: quotation,
          branch: branch,
          clientInfo: clientInfo ?? quotation.clientInfo,
          doctorInfo: doctorInfo ?? quotation.doctorInfo,
        );
      },
    ),
  );
}

Future<void> showQuotationViewerDialogFromId(
  BuildContext context,
  String quotationId,
) async {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod('TextInput.hide');

  final quotationsRepo = context.read<QuotationsRepository>();
  final quotation = await quotationsRepo.getQuotationById(quotationId);

  if (!context.mounted) return;

  if (quotation == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se encontró la cotización solicitada')),
    );
    return;
  }

  await showQuotationViewerDialog(context, quotation);
}

class _QuotationViewer extends StatefulWidget {
  const _QuotationViewer({
    required this.quotation,
    required this.branch,
    this.clientInfo,
    this.doctorInfo,
  });

  final QuotationInDb quotation;
  final BranchInDb branch;
  final PatientInfo? clientInfo;
  final DoctorInfo? doctorInfo;

  @override
  State<_QuotationViewer> createState() => _QuotationViewerState();
}

class _QuotationViewerState extends State<_QuotationViewer> {
  late QuotationInDb _quotation;
  late PatientInfo? _clientInfo;
  late DoctorInfo? _doctorInfo;

  @override
  void initState() {
    super.initState();
    _quotation = widget.quotation;
    _clientInfo = widget.clientInfo ?? widget.quotation.clientInfo;
    _doctorInfo = widget.doctorInfo ?? widget.quotation.doctorInfo;

    // Si tiene patientId pero no se guardó snapshot, intentar resolver en background sin bloquear
    if (_clientInfo == null &&
        _quotation.patientId != null &&
        _quotation.patientId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolveMissingPatient());
    }
    if (_doctorInfo == null &&
        _quotation.doctorId != null &&
        _quotation.doctorId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolveMissingDoctor());
    }
  }

  Future<void> _resolveMissingPatient() async {
    try {
      final patientsRepo = context.read<PatientsRepository>();
      final p = await patientsRepo.getPatientById(_quotation.patientId!);
      if (p != null && mounted) {
        setState(() {
          _clientInfo = PatientInfo(
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

  Future<void> _resolveMissingDoctor() async {
    try {
      final doctorsRepo = context.read<DoctorsRepository>();
      final d = await doctorsRepo.getDoctorById(_quotation.doctorId!);
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

  Future<void> _exportPdf(BuildContext context) async {
    final template = SingleQuotationTemplate(
      quotation: _quotation,
      branch: widget.branch,
      clientInfo: _clientInfo,
      doctorInfo: _doctorInfo,
    );
    final fileName =
        'cotizacion_${_quotation.id.length > 8 ? _quotation.id.substring(_quotation.id.length - 8) : _quotation.id}.pdf';
    await PdfExportTool.export(template, fileName: fileName);
  }

  Future<void> _printDocument(BuildContext context) async {
    final template = SingleQuotationTemplate(
      quotation: _quotation,
      branch: widget.branch,
      clientInfo: _clientInfo,
      doctorInfo: _doctorInfo,
    );
    final doc = await template.buildDocument();
    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: 'cotizacion_${_quotation.id}.pdf',
    );
  }

  Future<void> _shareDocument(BuildContext context) async {
    final template = SingleQuotationTemplate(
      quotation: _quotation,
      branch: widget.branch,
      clientInfo: _clientInfo,
      doctorInfo: _doctorInfo,
    );
    final doc = await template.buildDocument();
    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'cotizacion_${_quotation.id}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortId = _quotation.id.length > 8
        ? _quotation.id.substring(_quotation.id.length - 8).toUpperCase()
        : _quotation.id.toUpperCase();

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: Text('Cotización de Análisis - #$shortId'),
        actions: [
          IconButton(
            tooltip: 'Exportar PDF',
            onPressed: () => _exportPdf(context),
            icon: const Icon(Icons.picture_as_pdf),
          ),
          IconButton(
            tooltip: 'Imprimir Presupuesto',
            onPressed: () => _printDocument(context),
            icon: const Icon(Icons.print),
          ),
          IconButton(
            tooltip: 'Compartir Cotización',
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
                  child: QuotationViewerContent(
                    quotation: _quotation,
                    branch: widget.branch,
                    clientInfo: _clientInfo,
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

class QuotationViewerContent extends StatelessWidget {
  const QuotationViewerContent({
    super.key,
    required this.quotation,
    required this.branch,
    this.clientInfo,
    this.doctorInfo,
  });

  final QuotationInDb quotation;
  final BranchInDb branch;
  final PatientInfo? clientInfo;
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
    final quoteDate = DateTime.fromMillisecondsSinceEpoch(quotation.createdAt);
    final formattedDate =
        '${DateTimeTool.formatddMMyy(quoteDate)} ${DateTimeTool.formatHHmm(quoteDate)}';
    final shortId = quotation.id.length > 8
        ? quotation.id.substring(quotation.id.length - 8).toUpperCase()
        : quotation.id.toUpperCase();

    final totalFormatted = NumberFormatter.convertToMoneyLike(quotation.totalAmount);
    final clientDisplayName = clientInfo?.name.isNotEmpty == true
        ? clientInfo!.name
        : (quotation.clientName.isNotEmpty ? quotation.clientName : 'Cliente General');

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
                        child: Icon(Icons.request_quote_outlined, size: 28, color: Colors.blue.shade800),
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
                  const SizedBox(height: 6),
                  Text(
                    'Dirección: ${branch.address}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                  Text(
                    'Teléfono: ${branch.phone}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Text(
                      'PRESUPUESTO / COTIZACIÓN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
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
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      'PRESUPUESTO INFORMATIVO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const Divider(height: 32, thickness: 1.5, color: Color(0xFF1E3A8A)),

        // 2. Información del Cliente y Médico
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cliente
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DATOS DEL CLIENTE / PACIENTE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildRowText('Nombre:', clientDisplayName, isBold: true),
                    if (clientInfo != null && clientInfo!.dateOfBirth > 0)
                      _buildRowText(
                        'Edad / Sexo:',
                        '${_calculateAge(clientInfo!.dateOfBirth)} años | ${_formatGender(clientInfo!.gender)}',
                      ),
                    if (clientInfo?.cardId != null && clientInfo!.cardId!.isNotEmpty)
                      _buildRowText('Identificación:', clientInfo!.cardId!),
                    if (clientInfo != null && clientInfo!.phone.isNotEmpty)
                      _buildRowText('Teléfono:', clientInfo!.phone),
                    if (clientInfo != null && clientInfo!.address.isNotEmpty)
                      _buildRowText('Dirección:', clientInfo!.address),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 70,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 14),
              ),
              // Médico
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MÉDICO REFERENTE (OPCIONAL)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (doctorInfo != null && doctorInfo!.name.isNotEmpty) ...[
                      _buildRowText('Médico:', doctorInfo!.name, isBold: true),
                      _buildRowText('Especialidad:', doctorInfo!.specialty),
                      if (doctorInfo!.phone.isNotEmpty)
                        _buildRowText('Teléfono:', doctorInfo!.phone),
                    ] else ...[
                      Text(
                        'No asignado (Venta directa / Solicitud particular)',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 3. Tabla de Análisis y Perfiles
        Text(
          'ANÁLISIS Y PERFILES PRESUPUESTADOS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Header
              Container(
                color: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '#',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Text(
                        'Descripción del Análisis / Perfil',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Tipo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Tarifa',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Precio Cotizado',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              ...quotation.exams.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final item = entry.value;
                final isEven = entry.key.isEven;
                final itemPrice = NumberFormatter.convertToMoneyLike(item.quotedPrice);

                return Container(
                  color: isEven ? Colors.white : Colors.grey.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          '$idx',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.isPack ? Colors.purple.shade50 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: item.isPack ? Colors.purple.shade200 : Colors.blue.shade200,
                              ),
                            ),
                            child: Text(
                              item.isPack ? 'PERFIL / PACK' : 'INDIVIDUAL',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: item.isPack ? Colors.purple.shade800 : Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'P${item.priceLevel}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          itemPrice,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 4. Totales
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 280,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL PRESUPUESTADO:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  Text(
                    totalFormatted,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 5. Términos y Validez
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TÉRMINOS Y CONDICIONES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '1. Presupuesto válido por 15 días a partir de su emisión.\n'
                '2. Tarifas congeladas durante la vigencia del documento.\n'
                '3. Presentar este comprobante en ventanilla al momento de la toma de muestras.',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade700, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRowText(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
