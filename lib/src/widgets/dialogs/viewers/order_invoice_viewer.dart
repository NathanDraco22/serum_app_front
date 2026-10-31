import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/service_locator.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../tools/exports/pdf/templates/order_invoice_pdf_template.dart';
import '../../../tools/exports/pdf_export_tool.dart';
import '../../common/app_cached_image.dart';

/// Abre el visor interactivo para el Comprobante de Factura de una orden médica.
Future<void> showOrderInvoiceViewerDialog(
  BuildContext context,
  OrderInDb order, {
  List<ReceiptInDb>? receipts,
  PatientInfo? patientInfo,
  DoctorInfo? doctorInfo,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod('TextInput.hide');

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
        return _OrderInvoiceViewer(
          order: order,
          branch: branch,
          receipts: receipts,
          patientInfo: patientInfo ?? order.patientInfo,
          doctorInfo: doctorInfo ?? order.doctorInfo,
        );
      },
    ),
  );
}

/// Consulta la orden por ID y abre el visor de Comprobante de Factura.
Future<void> showOrderInvoiceViewerDialogFromId(
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

  await showOrderInvoiceViewerDialog(context, order);
}

class _OrderInvoiceViewer extends StatefulWidget {
  const _OrderInvoiceViewer({
    required this.order,
    required this.branch,
    this.receipts,
    this.patientInfo,
    this.doctorInfo,
  });

  final OrderInDb order;
  final BranchInDb branch;
  final List<ReceiptInDb>? receipts;
  final PatientInfo? patientInfo;
  final DoctorInfo? doctorInfo;

  @override
  State<_OrderInvoiceViewer> createState() => _OrderInvoiceViewerState();
}

class _OrderInvoiceViewerState extends State<_OrderInvoiceViewer> {
  late OrderInDb _order;
  late PatientInfo? _patientInfo;
  late DoctorInfo? _doctorInfo;
  List<ReceiptInDb> _receipts = [];
  bool _isLoadingReceipts = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _patientInfo = widget.patientInfo ?? widget.order.patientInfo;
    _doctorInfo = widget.doctorInfo ?? widget.order.doctorInfo;

    if (widget.receipts != null) {
      _receipts = widget.receipts!;
    } else {
      _loadReceipts();
    }
  }

  Future<void> _loadReceipts() async {
    setState(() => _isLoadingReceipts = true);
    try {
      final receiptsRepo = context.read<ReceiptsRepository>();
      final items = await receiptsRepo.getAllReceipts(
        queryParams: ReceiptQueryParams(orderId: _order.id),
      );
      if (mounted) {
        setState(() {
          _receipts = items;
          _isLoadingReceipts = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingReceipts = false);
      }
    }
  }

  OrderInvoicePdfTemplate _getTemplate() {
    return OrderInvoicePdfTemplate(
      order: _order,
      branch: widget.branch,
      receipts: _receipts,
      patientInfo: _patientInfo,
      doctorInfo: _doctorInfo,
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    final template = _getTemplate();
    final fileName = 'factura_orden_${_order.id}.pdf';
    await PdfExportTool.export(template, fileName: fileName);
  }

  Future<void> _printDocument(BuildContext context) async {
    final template = _getTemplate();
    final doc = await template.buildDocument();
    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: 'factura_orden_${_order.id}.pdf',
    );
  }

  Future<void> _shareDocument(BuildContext context) async {
    final template = _getTemplate();
    final doc = await template.buildDocument();
    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'factura_orden_${_order.id}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: Text('Comprobante de Factura - #${_order.id}'),
        actions: [
          IconButton(
            tooltip: 'Exportar PDF',
            onPressed: () => _exportPdf(context),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            tooltip: 'Imprimir Factura',
            onPressed: () => _printDocument(context),
            icon: const Icon(Icons.print_outlined),
          ),
          IconButton(
            tooltip: 'Compartir Factura',
            onPressed: () => _shareDocument(context),
            icon: const Icon(Icons.share_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: OrderInvoiceViewerContent(
                    order: _order,
                    branch: widget.branch,
                    receipts: _receipts,
                    isLoadingReceipts: _isLoadingReceipts,
                    patientInfo: _patientInfo,
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

class OrderInvoiceViewerContent extends StatelessWidget {
  const OrderInvoiceViewerContent({
    super.key,
    required this.order,
    required this.branch,
    required this.receipts,
    this.isLoadingReceipts = false,
    this.patientInfo,
    this.doctorInfo,
  });

  final OrderInDb order;
  final BranchInDb branch;
  final List<ReceiptInDb> receipts;
  final bool isLoadingReceipts;
  final PatientInfo? patientInfo;
  final DoctorInfo? doctorInfo;

  String _formatGender(String gender) {
    final g = gender.trim().toLowerCase();
    if (g == 'm' || g == 'male' || g == 'masculino') return 'Masculino';
    if (g == 'f' || g == 'female' || g == 'femenino') return 'Femenino';
    return gender;
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return 'Tarjeta';
      case 'transfer':
        return 'Transferencia';
      case 'cash':
      default:
        return 'Efectivo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderDate = DateTime.fromMillisecondsSinceEpoch(order.createdAt);
    final formattedDate =
        '${DateTimeTool.formatddMMyy(orderDate)} ${DateTimeTool.formatHHmm(orderDate)}';

    final totalOrder = order.totalPrice > 0 ? order.totalPrice : order.salePriceApplied;
    final totalPaid = order.paidAmount;
    final remainingBalance = max(0, totalOrder - totalPaid);
    final isFullyPaid = totalOrder > 0 && totalPaid >= totalOrder;

    final testsSum = order.items.fold<int>(0, (sum, i) => sum + i.salePriceApplied);
    final servicesSum = order.services.fold<int>(0, (sum, s) => sum + s.price);
    final discountsSum = order.discounts.fold<int>(0, (sum, d) => sum + d.appliedAmount);

    final isIsoLogo = branch.isoLogoUrl != null && branch.isoLogoUrl!.isNotEmpty;
    final headerImg = branch.effectiveIsoLogo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Encabezado institucional y badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Builder(
                builder: (context) {
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
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (branch.address.isNotEmpty)
                          Text(
                            'Dirección: ${branch.address}',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        Wrap(
                          spacing: 12,
                          children: [
                            if (branch.phone.isNotEmpty)
                              Text(
                                'Tel: ${branch.phone}',
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                            if (branch.email != null && branch.email!.isNotEmpty)
                              Text(
                                'Email: ${branch.email!}',
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                          ],
                        ),
                      ],
                    );
                  }

                  if (headerImg != null && headerImg.isNotEmpty) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(headerImg),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                branch.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Laboratorio Clínico y Diagnóstico Especializado',
                                style: TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                              if (branch.address.isNotEmpty)
                                Text(
                                  'Dirección: ${branch.address}',
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                              Wrap(
                                spacing: 12,
                                children: [
                                  if (branch.phone.isNotEmpty)
                                    Text(
                                      'Tel: ${branch.phone}',
                                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                                    ),
                                  if (branch.email != null && branch.email!.isNotEmpty)
                                    Text(
                                      'Email: ${branch.email!}',
                                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Laboratorio Clínico y Diagnóstico Especializado',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      if (branch.address.isNotEmpty)
                        Text(
                          'Dirección: ${branch.address}',
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      if (branch.phone.isNotEmpty)
                        Text(
                          'Teléfono: ${branch.phone}',
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      if (branch.email != null && branch.email!.isNotEmpty)
                        Text(
                          'Email: ${branch.email!}',
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade800, width: 1.0),
                    ),
                    child: const Text(
                      'COMPROBANTE DE FACTURA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ORDEN #${order.id}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Fecha: $formattedDate',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isFullyPaid
                            ? Colors.green.shade700
                            : (totalPaid > 0 ? Colors.blue.shade700 : Colors.amber.shade800),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      isFullyPaid
                          ? 'PAGADA EN SU TOTALIDAD'
                          : (totalPaid > 0
                              ? 'ABONADA PARCIALMENTE'
                              : 'PENDIENTE DE PAGO'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isFullyPaid
                            ? Colors.green.shade900
                            : (totalPaid > 0 ? Colors.blue.shade900 : Colors.amber.shade900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        Divider(color: Colors.grey.shade400, thickness: 1.0),
        const SizedBox(height: 8),

        // 2. Información de Paciente y Médico
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DATOS DEL PACIENTE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF37474F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (order.patientId.isNotEmpty)
                      _buildRow('Código Paciente:', '#${order.patientId}', isBold: true),
                    _buildRow('Nombre:', patientInfo?.name ?? 'Paciente General', isBold: true),
                    _buildRow('Identificación / Cédula:', patientInfo?.cardId ?? 'N/D'),
                    _buildRow(
                      'Edad / Sexo:',
                      '${patientInfo != null ? patientInfo!.age : 0} años  •  ${patientInfo != null ? _formatGender(patientInfo!.gender) : 'N/D'}',
                    ),
                    _buildRow('Teléfono:', patientInfo?.phone.isNotEmpty == true ? patientInfo!.phone : 'N/D'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MÉDICO REMITENTE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF37474F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildRow('Doctor(a):', doctorInfo?.name ?? 'No asignado / Consulta Externa', isBold: true),
                    _buildRow('Especialidad:', doctorInfo?.specialty ?? 'Medicina General'),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 3. Tabla de Análisis Clínicos y Perfiles
        const Text(
          'ANÁLISIS CLÍNICOS Y PERFILES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 0.8),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(36),
              1: FlexColumnWidth(6),
              2: FlexColumnWidth(2.5),
              3: FlexColumnWidth(2.2),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade400, width: 0.8),
                  ),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                    child: Text('#', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                    child: Text('Descripción del Análisis / Perfil', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                    child: Text('Tipo', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                    child: Text('Precio', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                  ),
                ],
              ),
              ...order.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return TableRow(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Text('${index + 1}', style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Text(item.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Text(
                        item.isPack ? 'Perfil / Pack' : 'Individual',
                        style: TextStyle(
                          fontSize: 11,
                          color: item.isPack ? Colors.purple.shade700 : Colors.grey.shade700,
                          fontWeight: item.isPack ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Text(
                        NumberFormatter.convertToMoneyLike(item.salePriceApplied),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),

        // 4. Tabla de Servicios Adicionales (si existen)
        if (order.services.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            'SERVICIOS ADICIONALES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400, width: 0.8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(36),
                1: FlexColumnWidth(6),
                2: FlexColumnWidth(2.5),
                3: FlexColumnWidth(2.2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade400, width: 0.8),
                    ),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                      child: Text('#', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                      child: Text('Descripción del Servicio', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                      child: Text('Detalle', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                      child: Text('Precio', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                    ),
                  ],
                ),
                ...order.services.asMap().entries.map((entry) {
                  final index = entry.key;
                  final service = entry.value;
                  return TableRow(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: Text('${index + 1}', style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: Text(service.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: Text('Servicio complementario', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: Text(
                          NumberFormatter.convertToMoneyLike(service.price),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),

        // 5. Totales
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 260,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade400, width: 0.8),
              ),
              child: Column(
                children: [
                  if (order.services.isNotEmpty || order.discounts.isNotEmpty) ...[
                    _buildTotalLine('Subtotal Análisis:', NumberFormatter.convertToMoneyLike(testsSum)),
                    if (order.services.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildTotalLine('Subtotal Servicios:', NumberFormatter.convertToMoneyLike(servicesSum)),
                    ],
                    if (order.discounts.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildTotalLine(
                        'Descuentos:',
                        '- ${NumberFormatter.convertToMoneyLike(discountsSum)}',
                        color: Colors.red.shade700,
                      ),
                    ],
                    const Divider(height: 12),
                  ],
                  _buildTotalLine(
                    'TOTAL ORDEN:',
                    NumberFormatter.convertToMoneyLike(totalOrder),
                    isBold: true,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 6. Historial de Abonos y Pagos
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'HISTORIAL DE ABONOS Y COBROS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (isLoadingReceipts)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                'Recibos vinculados: ${receipts.length}',
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (receipts.isEmpty && !isLoadingReceipts)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade400, width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'No se han registrado abonos ni pagos a la fecha.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                Text(
                  'Saldo Pendiente: ${NumberFormatter.convertToMoneyLike(remainingBalance)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          )
        else ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400, width: 0.8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2.0),
                1: FlexColumnWidth(2.2),
                2: FlexColumnWidth(2.0),
                3: FlexColumnWidth(3.5),
                4: FlexColumnWidth(2.2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade400, width: 0.8),
                    ),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                      child: Text('Recibo #', style: TextStyle(color: Colors.black87, fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                      child: Text('Fecha', style: TextStyle(color: Colors.black87, fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                      child: Text('Método', style: TextStyle(color: Colors.black87, fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                      child: Text('Concepto', style: TextStyle(color: Colors.black87, fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                      child: Text('Monto', style: TextStyle(color: Colors.black87, fontSize: 10.5, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                    ),
                  ],
                ),
                ...receipts.map((r) {
                  final rDate = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
                  final rDateStr =
                      '${DateTimeTool.formatddMMyy(rDate)} ${DateTimeTool.formatHHmm(rDate)}';
                  return TableRow(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                        child: Text(
                          r.receiptNumber.isNotEmpty
                              ? r.receiptNumber
                              : '#${r.id.substring(max(0, r.id.length - 6))}',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                        child: Text(rDateStr, style: const TextStyle(fontSize: 10.5)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                        child: Text(_formatPaymentMethod(r.paymentMethod), style: const TextStyle(fontSize: 10.5)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                        child: Text(r.concept, style: const TextStyle(fontSize: 10.5)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                        child: Text(
                          r.formattedAmount,
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black87),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade400, width: 0.8),
                bottom: BorderSide(color: Colors.grey.shade400, width: 0.8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricBox('Total de la Orden', NumberFormatter.convertToMoneyLike(totalOrder)),
                _buildMetricBox('Total Abonado', NumberFormatter.convertToMoneyLike(totalPaid), color: Colors.green.shade800),
                _buildMetricBox(
                  'Saldo Pendiente',
                  NumberFormatter.convertToMoneyLike(remainingBalance),
                  color: remainingBalance > 0 ? Colors.red.shade800 : Colors.black87,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // 7. Firmas y Condiciones
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'CONDICIONES GENERALES:',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '• Este comprobante certifica la facturación y los abonos recibidos para la orden médica indicada.\n'
                    '• Presente este comprobante para la entrega o consulta de sus resultados clínicos.\n'
                    '• Todo análisis adicional o ajuste debe ser coordinado directamente con recepción.',
                    style: TextStyle(fontSize: 9.5, color: Colors.black54, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Container(
                    width: 160,
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.black87, width: 1)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Caja / Recepción del Laboratorio',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    'Firma y Sello Autorizado',
                    style: TextStyle(fontSize: 9, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
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

  Widget _buildTotalLine(String label, String value, {bool isBold = false, double fontSize = 11, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBox(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
