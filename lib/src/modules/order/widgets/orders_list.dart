import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/patient_cubit/read_patients_cubit.dart';
import '../../../cubits/order_cubit/read_orders_cubit.dart';
import '../../../cubits/order_cubit/write_orders_cubit.dart';
import '../../../widgets/dialogs/viewers/clinical_order_viewer.dart';
import '../../../widgets/dialogs/viewers/order_invoice_viewer.dart';
import '../../../widgets/dialogs/viewers/order_envelope_viewer.dart';
import '../../../widgets/dialogs/viewers/patient_info_dialog.dart';
import 'supervisor_auth_dialog.dart';

class OrdersList extends StatelessWidget {
  final List<OrderInDb> orders;
  final Function(OrderInDb) onEditResults;
  final Function(OrderInDb) onPayOrder;

  const OrdersList({
    super.key,
    required this.orders,
    required this.onEditResults,
    required this.onPayOrder,
  });

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Obtener pacientes para mapear los nombres si es posible
    final patientsState = context.watch<ReadPatientCubit>().state;
    Map<String, String> patientNames = {};
    if (patientsState is ReadPatientSuccess) {
      for (var p in patientsState.items) {
        patientNames[p.id] = p.name;
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final isBlocked = order.isBlocked;
        final patientName =
            order.patientInfo?.name ?? patientNames[order.patientId] ?? 'Paciente';
        final totalPrice =
            order.totalPrice > 0 ? order.totalPrice : order.salePriceApplied;
        final isFullyPaid = order.status == 'paid' ||
            order.status == 'completed' ||
            (totalPrice > 0 && order.paidAmount >= totalPrice);
        final hasResults = order.results.isNotEmpty &&
            order.results.every((r) => r.resultValue != null && r.resultValue!.trim().isNotEmpty);
        final isCompleted = order.status == 'completed' || (isFullyPaid && hasResults);
        final isPartiallyPaid = order.paidAmount > 0 && !isFullyPaid;
        final showPayButton = !isFullyPaid &&
            order.status != 'completed' &&
            order.status != 'paid' &&
            order.status != 'cancelled';
        final canDelete = (order.status == 'pending' || isBlocked) && order.paidAmount == 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isBlocked
                      ? Colors.red.shade100
                      : (isCompleted
                          ? Colors.green.shade100
                          : isFullyPaid
                              ? Colors.blue.shade100
                              : hasResults
                                  ? Colors.amber.shade100
                                  : theme.colorScheme.primaryContainer),
                  foregroundColor: isBlocked
                      ? Colors.red.shade800
                      : (isCompleted
                          ? Colors.green.shade800
                          : isFullyPaid
                              ? Colors.blue.shade800
                              : hasResults
                                  ? Colors.amber.shade900
                                  : theme.colorScheme.onPrimaryContainer),
                  child: Icon(
                    isBlocked
                        ? Icons.lock
                        : (isCompleted
                            ? Icons.check_circle
                            : isFullyPaid
                                ? Icons.paid
                                : hasResults
                                    ? Icons.assignment_turned_in
                                    : Icons.pending_actions),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () {
                          showOrderPatientInfoDialog(
                            context,
                            order,
                            patientsState is ReadPatientSuccess ? patientsState.items : null,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'Paciente: $patientName',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Tooltip(
                                message: 'Ver y copiar datos del paciente',
                                child: Icon(
                                  Icons.info_outline,
                                  size: 17,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Examen: ${order.examName}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.sticky_note_2_outlined, size: 13, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Nota: ${order.notes!}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today, size: 12, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(_formatDate(order.createdAt), style: theme.textTheme.bodySmall),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.payments, size: 12, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(NumberFormatter.convertToMoneyLike(totalPrice), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          // Badge de Bloqueo
                          if (isBlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock, size: 11, color: Colors.red.shade900),
                                  const SizedBox(width: 4),
                                  Text(
                                    'BLOQUEADA (REQ. AUTORIZACIÓN)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (order.approval?.isApproved == true && order.approval?.approvedBy != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.teal.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_user_outlined, size: 11, color: Colors.teal.shade800),
                                  const SizedBox(width: 4),
                                  Text(
                                    'AUTORIZADO: ${order.approval!.approvedBy!.name}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Badge Clínico
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: hasResults ? Colors.purple.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: hasResults ? Colors.purple.shade200 : Colors.orange.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasResults ? Icons.check_circle_outline : Icons.hourglass_top,
                                  size: 11,
                                  color: hasResults ? Colors.purple.shade800 : Colors.orange.shade900,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hasResults ? 'RESULTADOS LISTOS' : 'PEND. RESULTADOS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: hasResults ? Colors.purple.shade800 : Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Badge Financiero
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isFullyPaid
                                  ? Colors.green.shade50
                                  : isPartiallyPaid
                                      ? Colors.blue.shade50
                                      : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isFullyPaid
                                  ? Colors.green.shade200
                                  : isPartiallyPaid
                                      ? Colors.blue.shade200
                                      : Colors.amber.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isFullyPaid
                                      ? Icons.check
                                      : isPartiallyPaid
                                          ? Icons.pie_chart_outline
                                          : Icons.attach_money,
                                  size: 11,
                                  color: isFullyPaid
                                      ? Colors.green.shade800
                                      : isPartiallyPaid
                                          ? Colors.blue.shade800
                                          : Colors.amber.shade900,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isFullyPaid
                                      ? 'PAGADA'
                                      : isPartiallyPaid
                                          ? 'ABONO: ${NumberFormatter.convertToMoneyLike(order.paidAmount)} / ${NumberFormatter.convertToMoneyLike(totalPrice)}'
                                          : 'PENDIENTE DE PAGO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isFullyPaid
                                        ? Colors.green.shade800
                                        : isPartiallyPaid
                                            ? Colors.blue.shade800
                                            : Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Badge de Notas Clínicas
                          if (order.notes != null && order.notes!.trim().isNotEmpty)
                            Tooltip(
                              message: 'Observaciones: ${order.notes!}',
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.blueGrey.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.note_alt_outlined,
                                      size: 11,
                                      color: Colors.blueGrey.shade800,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'CON OBSERVACIONES',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Botón de Desbloqueo / Autorización
                if (isBlocked) ...[
                  IconButton(
                    icon: const Icon(Icons.lock_open),
                    tooltip: 'Autorizar y Desbloquear Orden',
                    color: Colors.amber.shade900,
                    onPressed: () async {
                      final currentUser = context.read<AppSessionCubit>().user;
                      final isSupervisor = (currentUser?.accessLevel ?? 0) > 3;

                      if (isSupervisor) {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            title: const Text('Autorizar Orden'),
                            content: Text(
                              '¿Deseas autorizar la orden #${order.id} con precio modificado como supervisor (${currentUser?.name})?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogCtx, false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(dialogCtx, true),
                                child: const Text('Autorizar'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          final req = OrderApproveRequest(
                            reason: 'Autorizado directamente por supervisor (${currentUser?.name})',
                          );
                          context.read<WriteOrderCubit>().approveOrder(order.id, req).then((_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Orden autorizada y desbloqueada')),
                              );
                              context.read<ReadOrderCubit>().getAll();
                            }
                          });
                        }
                      } else {
                        // En ventanilla: pedir credenciales de supervisor
                        final req = await SupervisorAuthDialog.show(context, order.id);
                        if (req != null && context.mounted) {
                          context.read<WriteOrderCubit>().approveOrder(order.id, req).then((_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Orden autorizada y desbloqueada exitosamente')),
                              );
                              context.read<ReadOrderCubit>().getAll();
                            }
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                ],
                IconButton(
                  icon: Icon(isCompleted ? Icons.visibility_outlined : Icons.assignment_outlined),
                  tooltip: isBlocked
                      ? 'Orden bloqueada: Requiere autorización para capturar resultados'
                      : (isCompleted ? 'Ver resultados' : 'Editar resultados'),
                  color: isBlocked
                      ? theme.colorScheme.outline
                      : (isCompleted ? theme.colorScheme.secondary : theme.colorScheme.primary),
                  onPressed: isBlocked
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Esta orden está bloqueada por precio especial. Requiere autorización antes de registrar resultados.',
                              ),
                            ),
                          );
                        }
                      : (isCompleted
                          ? () => showClinicalOrderViewerDialog(context, order)
                          : () => onEditResults(order)),
                ),
                if (hasResults || isCompleted) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    tooltip: 'Exportar / Imprimir PDF',
                    onPressed: () => showClinicalOrderViewerDialog(context, order),
                  ),
                ],
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.receipt_long_outlined),
                  tooltip: 'Comprobante de Factura',
                  color: theme.colorScheme.primary,
                  onPressed: () => showOrderInvoiceViewerDialog(context, order),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.mail_outline),
                  tooltip: 'Imprimir Sobre',
                  onPressed: () => showOrderEnvelopeViewerDialog(context, order),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  tooltip: 'Información del Paciente',
                  onPressed: () {
                    showOrderPatientInfoDialog(
                      context,
                      order,
                      patientsState is ReadPatientSuccess ? patientsState.items : null,
                    );
                  },
                ),
                if (showPayButton) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.payments_outlined),
                    tooltip: isBlocked
                        ? 'Orden bloqueada: Requiere autorización para cobrar'
                        : 'Pagar',
                    color: isBlocked ? theme.colorScheme.outline : Colors.green.shade700,
                    onPressed: isBlocked
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Esta orden está bloqueada por precio especial. Requiere autorización antes de cobrar.',
                                ),
                              ),
                            );
                          }
                        : () => onPayOrder(order),
                  ),
                ],
                if (canDelete) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Eliminar Orden',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          title: const Text('Eliminar Orden'),
                          content: const Text('¿Está seguro de eliminar esta orden pendiente?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<WriteOrderCubit>().delete(order.id).then((_) {
                                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                                  if (context.mounted) context.read<ReadOrderCubit>().getAll();
                                });
                              },
                              child: Text(
                                'Eliminar',
                                style: TextStyle(color: theme.colorScheme.error),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    color: theme.colorScheme.error,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
