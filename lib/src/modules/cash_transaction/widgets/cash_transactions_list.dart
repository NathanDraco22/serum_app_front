import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

class CashTransactionsList extends StatelessWidget {
  final List<CashTransactionInDb> items;
  final List<CashRegisterInDb> registers;

  const CashTransactionsList({
    super.key,
    required this.items,
    required this.registers,
  });

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final tx = items[index];
        final isEnflow = tx.flowType == 'inflow';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isEnflow ? Colors.green.shade100 : Colors.red.shade100,
              foregroundColor: isEnflow ? Colors.green.shade800 : Colors.red.shade800,
              child: Icon(isEnflow ? Icons.arrow_upward : Icons.arrow_downward),
            ),
            title: Text(
              tx.concept,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Caja: ${registers.firstWhere((r) => r.id == tx.registerId, orElse: () => CashRegisterInDb(id: '', branchId: '', name: 'Desconocida', createdAt: 0)).name}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      'Método: ${tx.paymentMethod ?? "N/A"}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      _formatDate(tx.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Realizado por: ${tx.performedBy.name}',
                  style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isEnflow ? "+" : "-"}\$${tx.amount}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isEnflow ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Saldo: \$${tx.resultingBalance}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
