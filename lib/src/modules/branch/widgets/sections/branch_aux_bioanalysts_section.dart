import 'package:flutter/material.dart';

import '../../../../widgets/common/app_cached_image.dart';
import '../../controllers/branch_form_mediator.dart';
import '../aux_bioanalyst_dialog.dart';

/// Subsección para la administración en memoria de los bioanalistas auxiliares
/// facultados para firmar reportes de laboratorio en esta sucursal.
class BranchAuxBioanalystsSection extends StatelessWidget {
  const BranchAuxBioanalystsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = BranchFormMediator.controllerOf(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final auxBioList = controller.auxBioList;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bioanalistas Auxiliares',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.isSaving
                        ? null
                        : () async {
                            final newAux =
                                await AuxBioanalystDialog.show(context);
                            if (newAux != null) {
                              controller.addAuxBioanalyst(newAux);
                            }
                          },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Agregar Auxiliar'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Permite registrar otros bioanalistas facultados para firmar reportes de laboratorio en esta sucursal. En la pantalla de impresión podrás seleccionar quién firma el examen.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (auxBioList.isEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No hay bioanalistas auxiliares configurados. Por defecto, solo el representante principal firmará los resultados.',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: auxBioList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final aux = auxBioList[index];
                    final hasSeal = aux.bioanalyst.sealUrl != null &&
                        aux.bioanalyst.sealUrl!.isNotEmpty;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.7),
                          child: hasSeal
                              ? ClipOval(
                                  child: AppCachedImage(
                                    imageUrl: aux.bioanalyst.sealUrl!,
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  Icons.person_outline,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                        ),
                        title: Text(
                          aux.bioanalyst.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${aux.bioanalyst.title} • ${aux.bioanalyst.code}\nUsuario: ${aux.user.name}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasSeal)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.teal.shade300,
                                  ),
                                ),
                                child: Text(
                                  'SELLO',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade900,
                                  ),
                                ),
                              ),
                            IconButton(
                              tooltip: 'Editar',
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: controller.isSaving
                                  ? null
                                  : () async {
                                      final updated =
                                          await AuxBioanalystDialog.show(
                                        context,
                                        initialAux: aux,
                                      );
                                      if (updated != null) {
                                        controller.updateAuxBioanalyst(
                                          index,
                                          updated,
                                        );
                                      }
                                    },
                            ),
                            IconButton(
                              tooltip: 'Eliminar',
                              icon: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: theme.colorScheme.error,
                              ),
                              onPressed: controller.isSaving
                                  ? null
                                  : () => controller.removeAuxBioanalyst(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
