import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/imports_cubit/imports_cubit.dart';

class BranchPricesImportCard extends StatefulWidget {
  final bool isLoading;

  const BranchPricesImportCard({
    super.key,
    required this.isLoading,
  });

  @override
  State<BranchPricesImportCard> createState() => _BranchPricesImportCardState();
}

class _BranchPricesImportCardState extends State<BranchPricesImportCard> {
  String? _sourceBranchId;
  String? _targetBranchId;
  bool _mustOverridePrice = false;
  List<BranchInDb> _branches = [];
  bool _isLoadingBranches = true;
  String? _loadBranchesError;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final repo = RepositoryProvider.of<BranchesRepository>(context);
      final branches = await repo.getAllBranches();
      if (mounted) {
        setState(() {
          _branches = branches;
          _isLoadingBranches = false;
          // Si hay al menos 2 sucursales, podemos preseleccionar por comodidad
          if (branches.length >= 2) {
            _sourceBranchId ??= branches[0].id;
            _targetBranchId ??= branches[1].id;
          } else if (branches.isNotEmpty) {
            _sourceBranchId ??= branches[0].id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadBranchesError = e.toString();
          _isLoadingBranches = false;
        });
      }
    }
  }

  void _confirmAndExecute() {
    if (_sourceBranchId == null || _targetBranchId == null) return;
    if (_sourceBranchId == _targetBranchId) return;

    final sourceBranch = _branches.firstWhere(
      (b) => b.id == _sourceBranchId,
      orElse: () => BranchInDb(id: _sourceBranchId!, name: _sourceBranchId!, address: '', phone: '', createdAt: 0),
    );
    final targetBranch = _branches.firstWhere(
      (b) => b.id == _targetBranchId,
      orElse: () => BranchInDb(id: _targetBranchId!, name: _targetBranchId!, address: '', phone: '', createdAt: 0),
    );

    final cubit = context.read<ImportsCubit>();

    showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: Colors.teal),
              SizedBox(width: 12),
              Text('Confirmar Importación de Precios'),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Deseas transferir los precios de las pruebas clínicas entre sedes?',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(80)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.outbox_rounded, size: 18, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          const Text('Sede Origen: ', style: TextStyle(fontWeight: FontWeight.w600)),
                          Expanded(
                            child: Text(
                              sourceBranch.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.move_to_inbox_rounded, size: 18, color: Colors.teal),
                          const SizedBox(width: 8),
                          const Text('Sede Destino: ', style: TextStyle(fontWeight: FontWeight.w600)),
                          Expanded(
                            child: Text(
                              targetBranch.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _mustOverridePrice
                        ? Colors.amber.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _mustOverridePrice
                          ? Colors.amber.shade300
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _mustOverridePrice
                            ? Icons.warning_amber_rounded
                            : Icons.info_outline_rounded,
                        size: 20,
                        color: _mustOverridePrice
                            ? Colors.amber.shade900
                            : Colors.blue.shade800,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _mustOverridePrice
                              ? 'MODO SOBREESCRITURA: Todos los precios en la sede destino serán reemplazados por los de origen, incluso si ya tenían un valor establecido.'
                              : 'MODO ACTUALIZACIÓN EN \$0: Solo se asignarán precios a las pruebas que tengan su valor en \$0 en la sede destino. Los precios existentes se mantendrán intactos.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _mustOverridePrice
                                ? Colors.amber.shade900
                                : Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
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
              icon: const Icon(Icons.sync_alt_rounded, size: 18),
              label: const Text('Ejecutar Importación'),
              style: FilledButton.styleFrom(
                backgroundColor: _mustOverridePrice ? Colors.amber.shade800 : null,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        cubit.importBranchPrices(
          sourceBranchId: _sourceBranchId!,
          targetBranchId: _targetBranchId!,
          mustOverridePrice: _mustOverridePrice,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSameBranch = _sourceBranchId != null &&
        _targetBranchId != null &&
        _sourceBranchId == _targetBranchId;
    final canSubmit = !widget.isLoading &&
        !_isLoadingBranches &&
        _sourceBranchId != null &&
        _targetBranchId != null &&
        !isSameBranch;

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
            // Encabezado
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Icon(
                    Icons.currency_exchange_rounded,
                    color: Colors.teal.shade700,
                    size: 30,
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
                              'Importación de Precios entre Sucursales',
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
                              color: Colors.teal.shade100.withAlpha(150),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Multi-Sede',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Copia las listas de precios (Precio 1, Precio 2 y Costo) desde una sucursal base hacia otra sucursal del sistema.',
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
            const SizedBox(height: 20),

            if (_isLoadingBranches)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_loadBranchesError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withAlpha(80),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Error al cargar sedes: $_loadBranchesError',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadBranches,
                    ),
                  ],
                ),
              )
            else if (_branches.length < 2)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.amber.shade900),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Se requieren al menos 2 sucursales registradas en el sistema para realizar transferencias de precios entre sedes.',
                        style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selectores de Sedes (Fila o Columna según ancho)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 650;
                      return isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildSourceSelector(theme)),
                                const SizedBox(width: 16),
                                Padding(
                                  padding: const EdgeInsets.only(top: 24),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTargetSelector(theme)),
                              ],
                            )
                          : Column(
                              children: [
                                _buildSourceSelector(theme),
                                const SizedBox(height: 12),
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(height: 12),
                                _buildTargetSelector(theme),
                              ],
                            );
                    },
                  ),

                  if (isSameBranch) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 18, color: theme.colorScheme.error),
                        const SizedBox(width: 8),
                        Text(
                          'La sucursal origen y la sucursal destino deben ser diferentes.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Switch de Sobreescritura
                  Material(
                    color: _mustOverridePrice
                        ? Colors.amber.shade50.withAlpha(120)
                        : theme.colorScheme.surfaceContainerHighest.withAlpha(60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _mustOverridePrice
                            ? Colors.amber.shade300
                            : theme.colorScheme.outlineVariant.withAlpha(80),
                      ),
                    ),
                    child: SwitchListTile(
                      value: _mustOverridePrice,
                      onChanged: widget.isLoading
                          ? null
                          : (val) => setState(() => _mustOverridePrice = val),
                      secondary: Icon(
                        _mustOverridePrice
                            ? Icons.edit_note_rounded
                            : Icons.add_task_rounded,
                        color: _mustOverridePrice
                            ? Colors.amber.shade900
                            : theme.colorScheme.primary,
                      ),
                      title: Text(
                        'Sobrescribir precios existentes (mustOverridePrice)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        _mustOverridePrice
                            ? 'ACTIVO: Sobrescribe todos los precios en la sede destino con los valores de origen.'
                            : 'INACTIVO: Solo actualiza aquellas pruebas cuyo precio sea \$0 en la sede destino.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _mustOverridePrice
                              ? Colors.amber.shade900
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
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
                          : const Icon(Icons.sync_alt_rounded, size: 18),
                      label: Text(widget.isLoading
                          ? 'Importando Precios...'
                          : 'Iniciar Importación de Precios'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                      onPressed: canSubmit ? _confirmAndExecute : null,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sucursal Origen (Copiar desde)',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _sourceBranchId,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.outbox_rounded, color: Colors.blueGrey),
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: _branches.map((branch) {
            return DropdownMenuItem<String>(
              value: branch.id,
              child: Text(
                branch.name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: widget.isLoading
              ? null
              : (val) {
                  setState(() => _sourceBranchId = val);
                },
        ),
      ],
    );
  }

  Widget _buildTargetSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sucursal Destino (Pegar en)',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _targetBranchId,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.move_to_inbox_rounded, color: Colors.teal),
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: _branches.map((branch) {
            return DropdownMenuItem<String>(
              value: branch.id,
              child: Text(
                branch.name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: widget.isLoading
              ? null
              : (val) {
                  setState(() => _targetBranchId = val);
                },
        ),
      ],
    );
  }
}
