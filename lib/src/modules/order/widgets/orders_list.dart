import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/patient_cubit/read_patients_cubit.dart';
import '../../../cubits/order_cubit/read_orders_cubit.dart';
import '../../../cubits/order_cubit/write_orders_cubit.dart';
import '../../../widgets/dialogs/viewers/clinical_order_viewer.dart';
import '../../../widgets/dialogs/viewers/order_invoice_viewer.dart';
import '../../../widgets/dialogs/viewers/patient_info_dialog.dart';
import '../../../widgets/dialogs/confirm_delete_dialog.dart';
import '../../../widgets/dialogs/selectors/doctor_selection_dialog.dart';
import 'supervisor_auth_dialog.dart';
import 'reopen_order_dialog.dart';

class OrdersList extends StatelessWidget {
  final List<OrderInDb> orders;
  final Function(OrderInDb) onEditResults;
  final Function(OrderInDb) onPayOrder;
  final Function(OrderInDb)? onEditOrder;

  const OrdersList({
    super.key,
    required this.orders,
    required this.onEditResults,
    required this.onPayOrder,
    this.onEditOrder,
  });

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _handleReopenOrder(
    BuildContext context,
    OrderInDb order,
    String patientName,
  ) async {
    final reason = await ReopenOrderDialog.show(context, order);
    if (reason == null || reason.trim().isEmpty || !context.mounted) return;

    await context.read<WriteOrderCubit>().reopenOrder(
      order.id,
      OrderReopenRequest(reason: reason.trim()),
    );
    if (context.mounted) {
      context.read<ReadOrderCubit>().getAll();
    }
  }

  Future<void> _handleFinalizeOrder(
    BuildContext context,
    OrderInDb order,
    String patientName,
  ) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Finalizar Orden Médica',
      message:
          '¿Desea finalizar esta orden? Los resultados quedarán validados y la orden pasará a completada.',
      itemName: 'Orden #${order.id} ($patientName - ${order.examName})',
      confirmLabel: 'Finalizar Orden',
      cancelLabel: 'Cancelar',
      countdownSeconds: 0,
      icon: Icons.task_alt_rounded,
      confirmIcon: Icons.check_circle_rounded,
      isDestructive: false,
    );
    if (!confirmed || !context.mounted) return;

    await context.read<WriteOrderCubit>().finalizeOrder(order.id);
    if (context.mounted) {
      context.read<ReadOrderCubit>().getAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.read<AppSessionCubit?>();
    final canManageClinical =
        (session?.state.currentUser?.accessLevel ?? 0) >= 3;

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
        final patientName = order.patientInfo?.name ?? patientNames[order.patientId] ?? 'Paciente';
        final totalPrice = order.totalPrice > 0 ? order.totalPrice : order.salePriceApplied;
        final isFullyPaid = order.isFullyPaid;
        final hasResults = order.hasAllResults;
        final hasAnyResult = order.results.any(
          (r) => r.resultValue != null && r.resultValue!.trim().isNotEmpty,
        );
        final isInReview = order.isInReview;
        final isCompleted = order.isCompleted;
        final canReopen = isCompleted &&
            order.results.isNotEmpty &&
            !isBlocked &&
            canManageClinical;
        final isPartiallyPaid = order.isPartiallyPaid;
        final showPayButton =
            !isFullyPaid &&
            order.status != 'cancelled';
        final canDelete = (order.status == 'pending' || isBlocked) &&
            order.status != 'completed' &&
            !isInReview &&
            order.paidAmount == 0 &&
            !hasAnyResult;
        final canEditOrder = order.paidAmount == 0 &&
            !isCompleted &&
            !isInReview &&
            order.status != 'cancelled';

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
                Tooltip(
                  message: isBlocked
                      ? 'Orden bloqueada'
                      : canReopen
                      ? 'Orden completada (clic para reabrir)'
                      : isCompleted
                      ? 'Orden completada'
                      : isInReview
                      ? 'Orden en revisión: usa Finalizar Orden'
                      : 'Pendiente de resultados',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: canReopen
                        ? () => _handleReopenOrder(context, order, patientName)
                        : null,
                    child: CircleAvatar(
                      backgroundColor: isBlocked
                          ? Colors.red.shade100
                          : isCompleted
                          ? Colors.green.shade100
                          : isInReview
                          ? Colors.amber.shade100
                          : isFullyPaid
                          ? Colors.blue.shade100
                          : hasResults
                          ? Colors.purple.shade100
                          : theme.colorScheme.primaryContainer,
                      foregroundColor: isBlocked
                          ? Colors.red.shade800
                          : isCompleted
                          ? Colors.green.shade800
                          : isInReview
                          ? Colors.amber.shade900
                          : isFullyPaid
                          ? Colors.blue.shade800
                          : hasResults
                          ? Colors.purple.shade800
                          : theme.colorScheme.onPrimaryContainer,
                      child: Icon(
                        isBlocked
                            ? Icons.lock
                            : isCompleted
                            ? Icons.check_circle
                            : isInReview
                            ? Icons.fact_check_outlined
                            : isFullyPaid
                            ? Icons.paid
                            : hasResults
                            ? Icons.assignment_turned_in
                            : Icons.pending_actions,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge con el número de orden arriba del nombre del paciente
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${order.id}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Tooltip(
                        message: 'Ver y copiar datos del paciente',
                        child: InkWell(
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
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 5),
                                if (order.patientId.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '#${order.patientId}',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    patientName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.science_outlined,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              order.examName,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildDoctorTag(
                        context,
                        order,
                        theme,
                        isEditable: !isCompleted && order.status != 'cancelled',
                      ),
                      if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.sticky_note_2_outlined,
                              size: 13,
                              color: theme.colorScheme.primary,
                            ),
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
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(_formatDate(order.createdAt), style: theme.textTheme.bodySmall),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.payments,
                                size: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                NumberFormatter.convertToMoneyLike(totalPrice),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                                  Flexible(
                                    child: Text(
                                      'BLOQUEADA (REQ. AUTORIZACIÓN)',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (order.approval?.isApproved == true &&
                              order.approval?.approvedBy != null)
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
                                  Icon(
                                    Icons.verified_user_outlined,
                                    size: 11,
                                    color: Colors.teal.shade800,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'AUTORIZADO: ${order.approval!.approvedBy!.name}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Badge Clínico
                          Tooltip(
                            message: isBlocked
                                ? 'Orden bloqueada'
                                : canReopen
                                ? 'Completada (clic para reabrir)'
                                : isCompleted
                                ? 'Completada'
                                : isInReview
                                ? 'En revisión: usa Finalizar Orden'
                                : 'Pendiente de resultados',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: canReopen
                                  ? () => _handleReopenOrder(context, order, patientName)
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? Colors.green.shade50
                                      : isInReview
                                      ? Colors.amber.shade50
                                      : hasResults
                                      ? Colors.purple.shade50
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isCompleted
                                        ? Colors.green.shade200
                                        : isInReview
                                        ? Colors.amber.shade300
                                        : hasResults
                                        ? Colors.purple.shade200
                                        : Colors.orange.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isCompleted
                                          ? Icons.check_circle
                                          : isInReview
                                          ? Icons.fact_check_outlined
                                          : hasResults
                                          ? Icons.check_circle_outline
                                          : Icons.hourglass_top,
                                      size: 11,
                                      color: isCompleted
                                          ? Colors.green.shade800
                                          : isInReview
                                          ? Colors.amber.shade900
                                          : hasResults
                                          ? Colors.purple.shade800
                                          : Colors.orange.shade900,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isCompleted
                                          ? 'ORDEN COMPLETADA'
                                          : isInReview
                                          ? 'EN REVISIÓN'
                                          : hasResults
                                          ? 'RESULTADOS LISTOS'
                                          : 'PEND. RESULTADOS',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isCompleted
                                            ? Colors.green.shade800
                                            : isInReview
                                            ? Colors.amber.shade900
                                            : hasResults
                                            ? Colors.purple.shade800
                                            : Colors.orange.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (isInReview && !isBlocked && canManageClinical)
                            FilledButton.icon(
                              onPressed: () =>
                                  _handleFinalizeOrder(context, order, patientName),
                              icon: const Icon(Icons.task_alt_rounded, size: 14),
                              label: const Text('Finalizar Orden'),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
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
                    icon: const Icon(Icons.sync_rounded),
                    tooltip: 'Verificar si ya fue autorizada remotamente',
                    color: theme.colorScheme.primary,
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final fresh = await context.read<ReadOrderCubit>().refreshOrder(order.id);
                      if (!context.mounted) return;
                      if (fresh == null) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No se pudo verificar el estado de la orden. Verifica tu conexión.',
                            ),
                          ),
                        );
                      } else if (!fresh.isBlocked) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('¡Orden #${order.id} autorizada y desbloqueada!'),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.green.shade800,
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'La orden #${order.id} continúa pendiente de autorización por el supervisor.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.lock_open),
                    tooltip: 'Autorizar y Desbloquear Orden (en este equipo)',
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
                                const SnackBar(
                                  content: Text('Orden autorizada y desbloqueada exitosamente'),
                                ),
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
                if (canEditOrder && onEditOrder != null) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Modificar Orden (Agregar / Quitar Exámenes)',
                    color: theme.colorScheme.primary,
                    onPressed: () => onEditOrder!(order),
                  ),
                  const SizedBox(width: 4),
                ],
                IconButton(
                  icon: Icon(isCompleted ? Icons.visibility_outlined : Icons.assignment_outlined),
                  tooltip: isBlocked
                      ? 'Orden bloqueada: Requiere autorización para capturar resultados'
                      : 'Capturar / Editar Resultados',
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
                      : () => onEditResults(order),
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
                    onPressed: () async {
                      final confirmed = await ConfirmDeleteDialog.show(
                        context,
                        title: 'Eliminar Orden',
                        message:
                            '¿Está seguro de eliminar esta orden del sistema? Esta acción no se puede deshacer.',
                        itemName: 'Orden #${order.id} ($patientName - ${order.examName})',
                      );
                      if (confirmed && context.mounted) {
                        context.read<WriteOrderCubit>().delete(order.id).then((_) {
                          if (context.mounted) context.read<ReadOrderCubit>().getAll();
                        });
                      }
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

  Widget _buildDoctorTag(
    BuildContext context,
    OrderInDb order,
    ThemeData theme, {
    required bool isEditable,
  }) {
    final hasDoctor =
        (order.doctorInfo != null && order.doctorInfo!.name.trim().isNotEmpty) ||
        (order.doctorId != null && order.doctorId!.trim().isNotEmpty);

    if (hasDoctor) {
      final doctorName = order.doctorInfo != null && order.doctorInfo!.name.trim().isNotEmpty
          ? order.doctorInfo!.name.trim()
          : 'Dr. #${order.doctorId}';

      final doctorContent = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withValues(alpha: isEditable ? 0.35 : 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: isEditable ? 0.35 : 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 13,
              color: isEditable ? theme.colorScheme.secondary : theme.colorScheme.outline,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                doctorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isEditable ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (isEditable) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.edit_outlined,
                size: 12,
                color: theme.colorScheme.secondary,
              ),
            ],
          ],
        ),
      );

      if (!isEditable) {
        return Tooltip(
          message: 'Orden completada: el médico remitente no puede modificarse',
          child: doctorContent,
        );
      }

      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          Tooltip(
            message: 'Click para cambiar médico remitente',
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _handleAssignOrChangeDoctor(context, order),
              child: doctorContent,
            ),
          ),
          Tooltip(
            message: 'Desvincular médico remitente',
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _handleRemoveDoctor(context, order),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final noDoctorContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isEditable ? 0.35 : 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: isEditable ? 1.0 : 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEditable ? Icons.person_add_alt_1_outlined : Icons.medical_services_outlined,
            size: 13,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: isEditable ? 1.0 : 0.6),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              isEditable ? 'Sin médico remitente (Click para asignar)' : 'Sin médico remitente',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: isEditable ? 1.0 : 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );

    if (!isEditable) {
      return Tooltip(
        message: 'Orden completada: sin médico asignado',
        child: noDoctorContent,
      );
    }

    return Tooltip(
      message: 'Click para asignar médico remitente',
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _handleAssignOrChangeDoctor(context, order),
        child: noDoctorContent,
      ),
    );
  }

  Future<void> _handleAssignOrChangeDoctor(
    BuildContext context,
    OrderInDb order,
  ) async {
    if (order.status == 'completed' || order.status == 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede modificar el médico de una orden completada o cerrada.'),
        ),
      );
      return;
    }

    final selectedDoctor = await showDoctorSelectionDialog(context);
    if (selectedDoctor == null || !context.mounted) return;

    final doctorInfo = DoctorInfo(
      name: selectedDoctor.name,
      specialty: selectedDoctor.specialty.isNotEmpty
          ? selectedDoctor.specialty
          : 'Medicina General',
      phone: selectedDoctor.phone ?? '',
      cardId: selectedDoctor.cardId,
      email: selectedDoctor.email,
    );

    await context.read<WriteOrderCubit>().update(
      order.id,
      UpdateOrder(
        doctorId: selectedDoctor.id,
        doctorInfo: doctorInfo,
      ),
    );
  }

  Future<void> _handleRemoveDoctor(
    BuildContext context,
    OrderInDb order,
  ) async {
    if (order.status == 'completed' || order.status == 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede modificar el médico de una orden completada o cerrada.'),
        ),
      );
      return;
    }

    final doctorName = order.doctorInfo != null && order.doctorInfo!.name.trim().isNotEmpty
        ? order.doctorInfo!.name.trim()
        : 'asignado';

    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Quitar Médico Remitente',
      message: '¿Deseas desvincular el médico "$doctorName" de la orden #${order.id}?',
      itemName: 'Médico: $doctorName',
      confirmLabel: 'Quitar Médico',
      cancelLabel: 'Cancelar',
      countdownSeconds: 0,
      icon: Icons.person_remove_outlined,
      confirmIcon: Icons.delete_outline,
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      await context.read<WriteOrderCubit>().update(
        order.id,
        UpdateOrder(
          clearDoctor: true,
        ),
      );
    }
  }
}
