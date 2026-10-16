import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/service_locator.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../tools/exports/pdf/templates/receipt_pdf_template.dart';
import '../../../tools/exports/pdf_export_tool.dart';

/// Abre el visor interactivo para un comprobante de recibo de caja.
Future<void> showReceiptViewerDialog(
  BuildContext context,
  ReceiptInDb receipt, {
  BranchInDb? branch,
  OrderInDb? order,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod('TextInput.hide');

  final appSession = sl<AppSessionCubit>();
  final resolvedBranch = branch ??
      appSession.currentBranch ??
      BranchInDb(
        id: receipt.branchId.isNotEmpty ? receipt.branchId : 'BRANCH_DEFAULT',
        name: 'Laboratorio Clínico Serum',
        address: 'Sede Principal',
        phone: 'PBX: (505) 2222-0000',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) {
        return _ReceiptViewer(
          receipt: receipt,
          branch: resolvedBranch,
          order: order,
        );
      },
    ),
  );
}

/// Consulta el recibo por su ID y abre el visor de comprobante.
Future<void> showReceiptViewerDialogFromId(
  BuildContext context,
  String receiptId,
) async {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod('TextInput.hide');

  final receiptsRepo = context.read<ReceiptsRepository>();
  final receipt = await receiptsRepo.getReceiptById(receiptId);

  if (!context.mounted) return;

  if (receipt == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se encontró el recibo solicitado')),
    );
    return;
  }

  await showReceiptViewerDialog(context, receipt);
}

class _ReceiptViewer extends StatefulWidget {
  const _ReceiptViewer({
    required this.receipt,
    required this.branch,
    this.order,
  });

  final ReceiptInDb receipt;
  final BranchInDb branch;
  final OrderInDb? order;

  @override
  State<_ReceiptViewer> createState() => _ReceiptViewerState();
}

class _ReceiptViewerState extends State<_ReceiptViewer> {
  late ReceiptInDb _receipt;
  late OrderInDb? _order;

  @override
  void initState() {
    super.initState();
    _receipt = widget.receipt;
    _order = widget.order;

    // Si no se proporcionó la orden pero el recibo tiene orderId, resolverla en background
    if (_order == null && _receipt.orderId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resolveMissingOrder();
      });
    }
  }

  Future<void> _resolveMissingOrder() async {
    try {
      final ordersRepo = context.read<OrdersRepository>();
      final orderFound = await ordersRepo.getOrderById(_receipt.orderId);
      if (orderFound != null && mounted) {
        setState(() {
          _order = orderFound;
        });
      }
    } catch (_) {}
  }

  ReceiptPdfTemplate _getTemplate() {
    return ReceiptPdfTemplate(
      receipt: _receipt,
      branch: widget.branch,
      order: _order,
    );
  }

  Future<void> _exportPdf() async {
    final template = _getTemplate();
    final fileName = 'recibo_${_receipt.receiptNumber}.pdf';
    await PdfExportTool.export(template, fileName: fileName);
  }

  Future<void> _printDocument() async {
    final template = _getTemplate();
    final doc = await template.buildDocument();
    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: 'recibo_${_receipt.receiptNumber}.pdf',
    );
  }

  Future<void> _shareDocument() async {
    final template = _getTemplate();
    final doc = await template.buildDocument();
    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'recibo_${_receipt.receiptNumber}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: Text('Recibo de Caja - #${_receipt.receiptNumber}'),
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
            tooltip: 'Compartir Recibo',
            onPressed: _shareDocument,
            icon: const Icon(Icons.share),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: PdfPreview(
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: false,
          maxPageWidth: 720,
          previewPageMargin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          actions: const [],
          loadingWidget: const Center(child: CircularProgressIndicator()),
          build: (format) async {
            final template = _getTemplate();
            final doc = await template.buildDocument();
            return doc.save();
          },
        ),
      ),
    );
  }
}
