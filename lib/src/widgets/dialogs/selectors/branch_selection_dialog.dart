import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

Future<BranchInDb?> showBranchSelectionDialog(
  BuildContext context,
  List<BranchInDb> branches,
) async {
  return await showDialog<BranchInDb?>(
    context: context,
    builder: (context) => BranchSelectionDialog(branches: branches),
  );
}

class BranchSelectionDialog extends StatelessWidget {
  final List<BranchInDb> branches;

  const BranchSelectionDialog({super.key, required this.branches});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.store, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text("Seleccionar Sucursal"),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: branches.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text("No hay sucursales disponibles"),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: branches.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final branch = branches[index];
                  final initial = branch.name.isNotEmpty
                      ? branch.name.substring(0, 1).toUpperCase()
                      : 'S';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      child: Text(initial),
                    ),
                    title: Text(
                      branch.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      branch.address.isNotEmpty
                          ? branch.address
                          : (branch.phone.isNotEmpty ? 'Tel: ${branch.phone}' : 'Sin dirección'),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.pop(context, branch);
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
      ],
    );
  }
}
