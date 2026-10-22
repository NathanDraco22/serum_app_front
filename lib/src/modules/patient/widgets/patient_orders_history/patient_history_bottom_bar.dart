import 'package:flutter/material.dart';

/// Barra inferior flotante cuando se activa el Modo Comparar en el historial de órdenes.
class PatientHistoryBottomBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClear;
  final VoidCallback? onCompare;

  const PatientHistoryBottomBar({
    super.key,
    required this.selectedCount,
    required this.onClear,
    required this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Icon(Icons.compare_arrows_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$selectedCount de 2 órdenes seleccionadas para comparación.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: onClear,
              child: const Text('Limpiar'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onCompare,
              icon: const Icon(Icons.insights_rounded),
              label: const Text('Comparar Exámenes'),
            ),
          ],
        ),
      ),
    );
  }
}
