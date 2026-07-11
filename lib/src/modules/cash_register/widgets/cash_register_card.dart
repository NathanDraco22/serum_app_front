import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

class CashRegisterCard extends StatelessWidget {
  final CashRegisterInDb register;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CashRegisterCard({
    super.key,
    required this.register,
    required this.onOpen,
    required this.onClose,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOpen = register.isOpen;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isOpen ? Colors.green.shade100 : theme.colorScheme.outlineVariant,
                  foregroundColor: isOpen ? Colors.green.shade800 : theme.colorScheme.onSurface,
                  child: const Icon(Icons.point_of_sale),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        register.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sucursal: ${register.branchId}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isOpen ? Colors.green.shade200 : Colors.red.shade200),
                  ),
                  child: Text(
                    isOpen ? 'ABIERTA' : 'CERRADA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isOpen ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: isOpen ? onClose : onOpen,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isOpen ? theme.colorScheme.error : Colors.green,
                  ),
                  child: Text(isOpen ? 'Cerrar Caja' : 'Abrir Caja'),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.edit), onPressed: onEdit, color: theme.colorScheme.primary),
                IconButton(icon: const Icon(Icons.delete), onPressed: onDelete, color: theme.colorScheme.error),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BalanceIndicator(title: 'Efectivo', amount: register.cashBalance),
                _BalanceIndicator(title: 'Tarjeta', amount: register.cardBalance),
                _BalanceIndicator(title: 'Transferencia', amount: register.transferBalance),
                _BalanceIndicator(title: 'Total General', amount: register.totalBalance, isTotal: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceIndicator extends StatelessWidget {
  final String title;
  final int amount;
  final bool isTotal;

  const _BalanceIndicator({
    required this.title,
    required this.amount,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$$amount',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
