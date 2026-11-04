import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/common/app_cached_image.dart';
import '../../controllers/branch_form_mediator.dart';
import '../../controllers/branch_form_view_controller.dart';

/// Subsección para la configuración del Bioanalista Representante de la sucursal
/// y su sello físico de tinta institucional.
class BranchBioanalystSection extends StatelessWidget {
  const BranchBioanalystSection({super.key});

  Future<void> _pickSeal(
    BuildContext context,
    BranchFormViewController controller,
  ) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      );

      if (file == null) return;
      final bytes = await file.readAsBytes();
      controller.setSeal(bytes: bytes, name: file.name);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar el sello: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = BranchFormMediator.controllerOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Row(
          children: [
            Icon(
              Icons.badge_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bioanalista Representante de la Sede',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Profesional responsable que figurará en el pie de firma y validación de los resultados clínicos de esta sucursal.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),

        // Nombre del Bioanalista
        TextFormField(
          controller: controller.bioanalystNameController,
          decoration: const InputDecoration(
            labelText: 'Nombre Completo del Bioanalista',
            hintText: 'Ingresa el nombre completo',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Título Profesional
        TextFormField(
          controller: controller.bioanalystTitleController,
          decoration: const InputDecoration(
            labelText: 'Título Profesional / Cargo',
            hintText: 'Ingresa el título profesional o especialidad',
            prefixIcon: Icon(Icons.school_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Código Profesional
        TextFormField(
          controller: controller.bioanalystCodeController,
          decoration: const InputDecoration(
            labelText: 'Código Profesional / Registro',
            hintText: 'Ingresa el código profesional o número de registro',
            prefixIcon: Icon(Icons.card_membership_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 18),

        // Caja de Sello de Tinta
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final hasSeal = controller.hasSeal;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.approval_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sello Físico de Tinta del Representante',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sube la imagen del sello del profesional (preferiblemente PNG sin fondo). Aparecerá inclinado sobre la línea de firma en los reportes clínicos.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Column(
                      children: [
                        InkWell(
                          onTap: controller.isSaving
                              ? null
                              : () => _pickSeal(context, controller),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 140,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: hasSeal
                                    ? theme.colorScheme.primary
                                        .withValues(alpha: 0.5)
                                    : theme.colorScheme.outlineVariant,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (controller.selectedSealBytes != null)
                                    Transform.rotate(
                                      angle: -0.087,
                                      child: Opacity(
                                        opacity: 0.9,
                                        child: Image.memory(
                                          controller.selectedSealBytes!,
                                          width: 110,
                                          height: 90,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    )
                                  else if (controller.sealUrl != null &&
                                      controller.sealUrl!.isNotEmpty)
                                    Transform.rotate(
                                      angle: -0.087,
                                      child: Opacity(
                                        opacity: 0.9,
                                        child: AppCachedImage(
                                          imageUrl: controller.sealUrl!,
                                          width: 110,
                                          height: 90,
                                          fit: BoxFit.contain,
                                          fallbackWidget: Icon(
                                            Icons.broken_image_outlined,
                                            size: 32,
                                            color: theme.colorScheme.error,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 30,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Subir Sello',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (controller.isUploadingSeal)
                                    Container(
                                      color: Colors.black45,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (hasSeal)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: controller.isSaving
                                    ? null
                                    : () => _pickSeal(context, controller),
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                ),
                                label: const Text('Cambiar'),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: controller.isSaving
                                    ? null
                                    : controller.removeSeal,
                                icon: const Icon(Icons.delete_outline,
                                    size: 16),
                                label: const Text('Eliminar'),
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.error,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
