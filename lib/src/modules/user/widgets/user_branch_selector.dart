import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

/// Widget institucional y estructurado para la asignación de sucursales
/// a colaboradores del sistema, reemplazando selecciones triviales por
/// una interfaz seria y orientada a la seguridad operativa.
class UserBranchSelector extends StatefulWidget {
  const UserBranchSelector({
    super.key,
    required this.branches,
    required this.selectedBranchIds,
    required this.onChanged,
    this.hasError = false,
  });

  final List<BranchInDb> branches;
  final List<String> selectedBranchIds;
  final ValueChanged<List<String>> onChanged;
  final bool hasError;

  @override
  State<UserBranchSelector> createState() => _UserBranchSelectorState();
}

class _UserBranchSelectorState extends State<UserBranchSelector> {
  final TextEditingController _searchController = TextEditingController();
  String _searchFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleBranch(String branchId) {
    final updated = List<String>.from(widget.selectedBranchIds);
    if (updated.contains(branchId)) {
      updated.remove(branchId);
    } else {
      updated.add(branchId);
    }
    widget.onChanged(updated);
  }

  void _selectAll() {
    final allIds = widget.branches.map((b) => b.id).toList();
    widget.onChanged(allIds);
  }

  void _deselectAll() {
    widget.onChanged([]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = widget.selectedBranchIds.length;
    final total = widget.branches.length;

    final filteredBranches = widget.branches.where((b) {
      if (_searchFilter.isEmpty) return true;
      final query = _searchFilter.toLowerCase();
      final nameMatches = b.name.toLowerCase().contains(query);
      final addressMatches = b.address.toLowerCase().contains(query);
      return nameMatches || addressMatches;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.hasError && count == 0
              ? theme.colorScheme.error
              : theme.colorScheme.outlineVariant.withAlpha(90),
          width: widget.hasError && count == 0 ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header Institucional ──────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (widget.hasError && count == 0)
                      ? theme.colorScheme.errorContainer.withAlpha(80)
                      : theme.colorScheme.primaryContainer.withAlpha(90),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.domain_verification_rounded,
                  size: 20,
                  color: (widget.hasError && count == 0)
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sedes y Sucursales Autorizadas *',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Determina los establecimientos clínicos en los que este usuario tiene potestad operativa y apertura de turnos.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge de contador reactivo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: count > 0
                      ? theme.colorScheme.primary.withAlpha(20)
                      : theme.colorScheme.error.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: count > 0
                        ? theme.colorScheme.primary.withAlpha(80)
                        : theme.colorScheme.error.withAlpha(80),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      count > 0
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      size: 14,
                      color: count > 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      count > 0
                          ? '$count de $total autorizada${count > 1 ? 's' : ''}'
                          : 'Sin sedes asignadas',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: count > 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ─── Barra de Acciones y Búsqueda (si hay más de 1 sucursal) ──
          if (total > 1) ...[
            Row(
              children: [
                if (total > 3)
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            setState(() => _searchFilter = val.trim()),
                        style: theme.textTheme.bodySmall,
                        decoration: InputDecoration(
                          hintText: 'Filtrar sedes por nombre o dirección...',
                          hintStyle: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                          ),
                          prefixIcon: const Icon(Icons.search, size: 16),
                          suffixIcon: _searchFilter.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 14),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchFilter = '');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: count == total ? null : _selectAll,
                  icon: const Icon(Icons.select_all_rounded, size: 16),
                  label: const Text('Autorizar todas'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                TextButton.icon(
                  onPressed: count == 0 ? null : _deselectAll,
                  icon: const Icon(Icons.deselect_rounded, size: 16),
                  label: const Text('Deseleccionar'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // ─── Listado de Tarjetas de Sede ─────────────────────────────
          if (filteredBranches.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  _searchFilter.isEmpty
                      ? 'No hay sucursales registradas en el sistema.'
                      : 'No se encontraron sucursales que coincidan con la búsqueda.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredBranches.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final branch = filteredBranches[index];
                final isSelected = widget.selectedBranchIds.contains(branch.id);
                final isOrigin = branch.id == kOriginBranchId;
                final isPrimary = widget.selectedBranchIds.isNotEmpty &&
                    widget.selectedBranchIds.first == branch.id;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _toggleBranch(branch.id),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer.withAlpha(30)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant.withAlpha(90),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Checkbox estilizado
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),

                          // Icono de la sede
                          Icon(
                            isOrigin
                                ? Icons.corporate_fare_rounded
                                : Icons.storefront_rounded,
                            size: 22,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant.withAlpha(160),
                          ),
                          const SizedBox(width: 12),

                          // Información principal de la sede
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        branch.name,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? theme.colorScheme.onSurface
                                              : theme.colorScheme.onSurface
                                                  .withAlpha(200),
                                        ),
                                      ),
                                    ),
                                    if (isOrigin) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.secondaryContainer
                                              .withAlpha(80),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Sede Matriz',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.secondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (isPrimary && widget.selectedBranchIds.length > 1) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.tertiaryContainer
                                              .withAlpha(80),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Acceso Inicial',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.tertiary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  branch.address.isNotEmpty
                                      ? branch.address
                                      : (branch.phone.isNotEmpty
                                          ? 'Teléfono: ${branch.phone}'
                                          : 'Sede operativa registrada'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Estado Autorizado / Restringido
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer.withAlpha(90)
                                  : theme.colorScheme.surfaceContainerHighest
                                      .withAlpha(40),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isSelected ? 'Autorizado' : 'Sin acceso',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant
                                        .withAlpha(140),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          // ─── Alerta / Nota de Validación al pie ──────────────────────
          if (widget.hasError && count == 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Se requiere autorizar al menos una sede para que el colaborador pueda operar en el sistema.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
