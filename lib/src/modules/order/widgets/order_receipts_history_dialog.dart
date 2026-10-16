import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/app_theme.dart';
import '../../receipt/widgets/receipt_detail_dialog.dart';
import '../../../widgets/dialogs/viewers/receipt_viewer.dart';

class OrderReceiptsHistoryDialog extends StatefulWidget {
  final OrderInDb order;

  const OrderReceiptsHistoryDialog({super.key, required this.order});

  static Future<void> show(BuildContext context, OrderInDb order) {
    return showDialog<void>(
      context: context,
      builder: (_) => OrderReceiptsHistoryDialog(order: order),
    );
  }

  @override
  State<OrderReceiptsHistoryDialog> createState() =>
      _OrderReceiptsHistoryDialogState();
}

class _OrderReceiptsHistoryDialogState
    extends State<OrderReceiptsHistoryDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ReceiptInDb> _receipts = [];

  int get _totalPrice => widget.order.totalPrice > 0
      ? widget.order.totalPrice
      : widget.order.salePriceApplied;

  int get _remainingBalance => max(0, _totalPrice - widget.order.paidAmount);

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<ReceiptsRepository>();
      final items = await repo.getAllReceipts(
        queryParams: ReceiptQueryParams(orderId: widget.order.id),
      );
      if (!mounted) return;
      setState(() {
        _receipts = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return Colors.blue;
      case 'transfer':
        return Colors.purple;
      case 'cash':
      default:
        return Colors.green;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return Icons.credit_card;
      case 'transfer':
        return Icons.account_balance;
      case 'cash':
      default:
        return Icons.money;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.history_edu_rounded,
                      color: theme.colorScheme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Historial de Abonos y Recibos',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Orden #${widget.order.id} • ${widget.order.patientInfo?.name ?? 'Paciente'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Resumen financiero de la orden
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Orden',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              )),
                          Text(
                            NumberFormatter.convertToMoneyLike(_totalPrice),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 30, width: 1, color: theme.colorScheme.outlineVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Pagado',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              )),
                          Text(
                            NumberFormatter.convertToMoneyLike(widget.order.paidAmount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 30, width: 1, color: theme.colorScheme.outlineVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saldo Pendiente',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              )),
                          Text(
                            NumberFormatter.convertToMoneyLike(_remainingBalance),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _remainingBalance > 0
                                  ? ColorPalette.error
                                  : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lista de recibos
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline,
                                    size: 36, color: ColorPalette.error),
                                const SizedBox(height: 8),
                                Text('Error al cargar recibos: $_errorMessage'),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: _loadReceipts,
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          )
                        : _receipts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 48,
                                      color: theme.colorScheme.outline,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Aún no hay abonos ni recibos para esta orden.',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: _receipts.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final r = _receipts[index];
                                  final methodColor =
                                      _getPaymentMethodColor(r.paymentMethod);
                                  final methodIcon =
                                      _getPaymentMethodIcon(r.paymentMethod);

                                  return InkWell(
                                    onTap: () => ReceiptDetailDialog.show(context, r),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: theme.colorScheme.outlineVariant,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: methodColor.withAlpha(25),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(methodIcon,
                                                color: methodColor, size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Recibo #${r.receiptNumber}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: methodColor
                                                            .withAlpha(20),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Text(
                                                        r.paymentMethodLabel,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: methodColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${r.formattedDate} • Cajero: ${r.performedBy.name}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: theme.colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                                if (r.concept.isNotEmpty)
                                                  Text(
                                                    r.concept,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      color: theme.colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                r.formattedAmount,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Colors.green.shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            tooltip: 'Ver Comprobante (PDF)',
                                            icon: Icon(
                                              Icons.picture_as_pdf_outlined,
                                              size: 20,
                                              color: theme.colorScheme.primary,
                                            ),
                                            onPressed: () => showReceiptViewerDialog(
                                              context,
                                              r,
                                              order: widget.order,
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right,
                                            size: 16,
                                            color: theme.colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
              const SizedBox(height: 16),

              // Footer
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
