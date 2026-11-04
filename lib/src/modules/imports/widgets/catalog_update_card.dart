import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/imports_cubit/imports_cubit.dart';

class CatalogUpdateCard extends StatefulWidget {
  final bool isLoading;

  const CatalogUpdateCard({
    super.key,
    required this.isLoading,
  });

  @override
  State<CatalogUpdateCard> createState() => _CatalogUpdateCardState();
}

class _CatalogUpdateCardState extends State<CatalogUpdateCard> {
  bool _overridePrice = false;
  bool _updateLabTest = true;

  void _confirmAndExecute() {
    if (!_updateLabTest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes activar al menos una entidad para actualizar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cubit = context.read<ImportsCubit>();

    showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.sync_rounded,
                color: _overridePrice ? Colors.amber.shade800 : theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Text('Confirmar Sincronización'),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Deseas sincronizar el catálogo de pruebas clínicas desde el archivo maestro estático?',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (!_overridePrice) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withAlpha(80)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, color: Colors.green, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Protección de Tarifas Activa: Se actualizarán nombres, subclasificaciones, valores de referencia y relaciones de perfiles. Los precios de venta y costo de tu laboratorio NO serán modificados.',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.withAlpha(120)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'ADVERTENCIA: Has seleccionado sobrescribir precios. Los precios personalizados de tu laboratorio serán reemplazados por las tarifas base del archivo estático.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Las pruebas o perfiles nuevos que no existían en tu base de datos se crearán automáticamente.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: _overridePrice
                  ? FilledButton.styleFrom(backgroundColor: Colors.amber.shade900)
                  : null,
              icon: const Icon(Icons.sync_rounded, size: 18),
              label: const Text('Iniciar Sincronización'),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        cubit.updateCatalog(
          overridePrice: _overridePrice,
          updateLabTest: _updateLabTest,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(120),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sync_rounded,
                    color: Colors.teal,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Actualización y Sincronización Incremental',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal.withAlpha(35),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Sincronización Segura',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Aplica refinamientos, nuevas subclasificaciones, parámetros analíticos o adiciones al catálogo estático sin destruir datos existentes.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Opciones de Sincronización
            Text(
              'Parámetros de Sincronización:',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Switch: Actualizar Pruebas
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Actualizar pruebas y paquetes clínicos (updateLabTest)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                'Sincroniza nombres, subclasificaciones clínicas, opciones cualitativas, valores de referencia y dependencias de packs.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              value: _updateLabTest,
              onChanged: widget.isLoading
                  ? null
                  : (val) => setState(() => _updateLabTest = val),
            ),

            const SizedBox(height: 6),

            // Switch: Sobrescribir Precios
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  const Text(
                    'Sobrescribir precios existentes (overridePrice)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  if (_overridePrice)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PRECAUCIÓN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                _overridePrice
                    ? 'ADVERTENCIA: Las tarifas de venta y costo actuales configuradas en tu laboratorio serán reemplazadas por las del archivo maestro.'
                    : 'Recomendado (Desactivado): Mantiene intactos todos los precios de venta y costo ya configurados por tu laboratorio.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _overridePrice
                      ? Colors.amber.shade900
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: _overridePrice ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              value: _overridePrice,
              activeTrackColor: Colors.amber.shade900,
              onChanged: widget.isLoading
                  ? null
                  : (val) => setState(() => _overridePrice = val),
            ),

            const SizedBox(height: 16),

            // Banner explicativo según estado
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _overridePrice
                    ? Colors.amber.withAlpha(20)
                    : theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _overridePrice
                      ? Colors.amber.withAlpha(100)
                      : theme.colorScheme.outlineVariant.withAlpha(80),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _overridePrice ? Icons.info_outline_rounded : Icons.lock_outline_rounded,
                    color: _overridePrice ? Colors.amber.shade900 : theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _overridePrice
                          ? 'Se actualizarán metadatos Y precios base del catálogo maestro.'
                          : 'Tus precios actuales están protegidos. Solo se sincronizará la estructura clínica.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _overridePrice
                            ? Colors.amber.shade900
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: _overridePrice ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botón de Acción
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: widget.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync_rounded, size: 20),
                label: Text(widget.isLoading ? 'Sincronizando...' : 'Sincronizar Catálogo'),
                onPressed: widget.isLoading ? null : _confirmAndExecute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
