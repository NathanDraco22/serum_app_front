import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../controllers/lab_test_form_mediator.dart';
import '../../controllers/lab_test_form_view_controller.dart';
import '../pack_composition_editor_dialog.dart';

/// Sección del formulario encargada de la gestión y visualización de los análisis incluidos
/// en un paquete o perfil clínico (`isPack == true`).
///
/// Siguiendo los principios de Clinical Precision y el estándar OKF v0.2:
/// - Desacopla la selección pesada y el reordenamiento hacia [PackCompositionEditorDialog].
/// - En pantalla presenta un panel claro, profesional y libre de "scroll traps", con la
///   lista exhaustiva de pruebas asignadas, métricas financieras y acciones directas.
class LabTestPackChildrenSection extends StatelessWidget {
  final List<LabTestInDb> allAvailableTests;
  final VoidCallback onQuickCreateParameter;
  final ValueChanged<LabTestInDb> onQuickEditParameter;
  final String? branchId;

  const LabTestPackChildrenSection({
    super.key,
    required this.allAvailableTests,
    required this.onQuickCreateParameter,
    required this.onQuickEditParameter,
    this.branchId,
  });

  String _resolveBranchId(BuildContext context) {
    if (branchId != null && branchId!.isNotEmpty) return branchId!;
    try {
      return context.read<AppSessionCubit>().currentBranchId;
    } catch (_) {
      return '';
    }
  }

  Future<void> _openEditorDialog(
    BuildContext context,
    LabTestFormViewController controller,
  ) async {
    final effectiveBranchId = _resolveBranchId(context);
    final updatedIds = await PackCompositionEditorDialog.show(
      context,
      availableTests: allAvailableTests,
      initialSelectedIds: controller.childTestIds,
      packName: controller.name,
      packSalePrice: controller.salePrice,
      useChildTestsPriceSum: controller.useChildTestsPriceSum,
      branchId: effectiveBranchId,
      onEditTest: onQuickEditParameter,
    );

    if (updatedIds != null) {
      controller.setChildTestIds(updatedIds, allAvailableTests);
    }
  }

  String _formatReferenceSummary(LabTestInDb test) {
    if (test.isPack) {
      final count = test.childTestIds.length;
      return count > 0 ? '$count análisis incluidos' : 'Pack comercial';
    }
    if (test.dataType == 'numeric') {
      final unit = test.unitOfMeasure.isNotEmpty ? ' ${test.unitOfMeasure}' : '';
      if (test.referenceValues.isNotEmpty) {
        if (test.referenceValues.length > 1) {
          return 'Ref: ${test.referenceValues.length} rangos';
        }
        final ref = test.referenceValues.first;
        final minStr = ref.minValue % 1 == 0
            ? ref.minValue.toInt().toString()
            : ref.minValue.toString();
        final maxStr = ref.maxValue % 1 == 0
            ? ref.maxValue.toInt().toString()
            : ref.maxValue.toString();
        return 'Ref: $minStr - $maxStr$unit';
      }
      return 'Numérico${unit.isNotEmpty ? ' ($unit)' : ''}';
    } else if (test.dataType == 'qualitative') {
      final exp = test.expectedQualitativeValue;
      if (exp != null && exp.isNotEmpty) {
        return 'Cualitativo [Esperado: $exp]';
      }
      return 'Cualitativo';
    } else {
      return 'Texto Libre';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = LabTestFormMediator.controllerOf(context);
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isPack) return const SizedBox.shrink();

        // Mapear objetos incluidos en el perfil preservando el orden de childTestIds
        final selectedTests = <LabTestInDb>[];
        for (final id in controller.childTestIds) {
          final found = allAvailableTests.where((t) => t.id == id).firstOrNull;
          if (found != null) {
            selectedTests.add(found);
          }
        }

        final totalIndividualCents =
            selectedTests.fold<int>(0, (sum, t) => sum + t.salePrice);
        final totalIndividualPrice = totalIndividualCents / 100.0;
        final packPrice = controller.salePrice;
        final savings = totalIndividualPrice - packPrice;

        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Encabezado de Sección y Acciones Principales
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Composición del Perfil / Pack',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selectedTests.isNotEmpty
                                        ? theme.colorScheme.primaryContainer
                                        : theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${selectedTests.length} análisis',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: selectedTests.isNotEmpty
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Gestione los análisis incluidos y su secuencia analítica.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: onQuickCreateParameter,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Crear Parámetro'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () => _openEditorDialog(context, controller),
                          icon: const Icon(Icons.tune_rounded, size: 16),
                          label: Text(
                            selectedTests.isEmpty
                                ? 'Configurar Análisis'
                                : 'Gestionar Composición (${selectedTests.length})',
                          ),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Resumen Financiero en Tiempo Real
                if (selectedTests.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.monetization_on_outlined,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Suma individual: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              NumberFormatter.currencyFormat.format(totalIndividualPrice),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Precio del Pack: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              NumberFormatter.currencyFormat.format(packPrice),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (savings > 0 && !controller.useChildTestsPriceSum)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green.shade400),
                            ),
                            child: Text(
                              'Ahorro: ${NumberFormatter.currencyFormat.format(savings)} (${((savings / totalIndividualPrice) * 100).toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 3. Lista Completa de Análisis Incluidos en el Perfil
                if (selectedTests.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.playlist_add_check_rounded,
                            size: 42,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Este perfil aún no contiene análisis o parámetros',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Haga clic en el botón inferior para abrir el editor y seleccionar las pruebas desde el catálogo.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.tonalIcon(
                            onPressed: () => _openEditorDialog(context, controller),
                            icon: const Icon(Icons.tune_rounded, size: 16),
                            label: const Text('Abrir Editor de Composición'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Encabezado de la tabla/lista
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                          child: Row(
                            children: [
                              Text(
                                'Análisis y parámetros incluidos (Secuencia de captura e impresión):',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                onPressed: () => _openEditorDialog(context, controller),
                                icon: const Icon(Icons.tune_rounded, size: 15),
                                label: const Text(
                                  'Modificar o Reordenar',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Filas de cada análisis incluido
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: selectedTests.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            indent: 44,
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                          itemBuilder: (context, index) {
                            final test = selectedTests[index];
                            final testPrice =
                                NumberFormatter.convertToMoneyLike(test.salePrice);
                            final refSummary = _formatReferenceSummary(test);

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              child: Row(
                                children: [
                                  // Número de orden
                                  Container(
                                    width: 24,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${index + 1}.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Nombre y código
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                test.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (test.code != null &&
                                                test.code!.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 5,
                                                  vertical: 1,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme
                                                      .surfaceContainerHigh,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  test.code!,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontFamily: 'monospace',
                                                    color: theme.colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (test.isPack) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 5,
                                                  vertical: 1,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme
                                                      .tertiaryContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Pack',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.colorScheme
                                                        .onTertiaryContainer,
                                                  ),
                                                ),
                                              ),
                                            ] else if (test.isProfileParameter) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 5,
                                                  vertical: 1,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme
                                                      .secondaryContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Parámetro',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.colorScheme
                                                        .onSecondaryContainer,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              test.commercialCategory.isNotEmpty
                                                  ? test.commercialCategory
                                                  : 'Sin Categoría',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                            if (test.subclassification.isNotEmpty) ...[
                                              const Text(' • ',
                                                  style: TextStyle(
                                                      fontSize: 10, color: Colors.grey)),
                                              Text(
                                                test.subclassification,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: theme.colorScheme.tertiary,
                                                ),
                                              ),
                                            ],
                                            const Text(' • ',
                                                style: TextStyle(
                                                    fontSize: 10, color: Colors.grey)),
                                            Text(
                                              refSummary,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Precio individual
                                  Text(
                                    testPrice,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Botón de Edición rápida (si aplica)
                                  if (test.isProfileParameter)
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 16),
                                      color: theme.colorScheme.primary,
                                      tooltip: 'Editar parámetro "${test.name}"',
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ),
                                      onPressed: () => onQuickEditParameter(test),
                                    ),

                                  // Botón de Remoción directa desde la pantalla
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                    color: theme.colorScheme.error,
                                    tooltip: 'Quitar "${test.name}" del perfil',
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    onPressed: () {
                                      controller.removeChildTestId(
                                        test.id,
                                        allAvailableTests,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
