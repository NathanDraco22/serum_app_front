import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/common/app_cached_image.dart';
import '../../controllers/branch_form_mediator.dart';
import '../../controllers/branch_form_view_controller.dart';

/// Subsección para la identidad visual de la sucursal:
/// Logotipo (símbolo compacto) e IsoLogo (nombre comercial y logotipo integrados).
class BranchBrandingSection extends StatelessWidget {
  const BranchBrandingSection({super.key});

  Future<void> _pickLogo(
    BuildContext context,
    BranchFormViewController controller,
  ) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (file == null) return;
      final bytes = await file.readAsBytes();
      controller.setLogo(bytes: bytes, name: file.name);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar el logotipo: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _pickIsoLogo(
    BuildContext context,
    BranchFormViewController controller,
  ) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (file == null) return;
      final bytes = await file.readAsBytes();
      controller.setIsoLogo(bytes: bytes, name: file.name);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar el IsoLogo: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = BranchFormMediator.controllerOf(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasLogo = controller.hasLogo;
        final hasIsoLogo = controller.hasIsoLogo;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identidad Visual de la Sucursal',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                // 1. Selector de Logotipo (Símbolo / Icono)
                SizedBox(
                  width: 260,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Logotipo (Símbolo / Isotipo)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Icono compacto para avatares y marca de agua',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: controller.isSaving
                            ? null
                            : () => _pickLogo(context, controller),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withAlpha(90),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (controller.selectedLogoBytes != null)
                                  Image.memory(
                                    controller.selectedLogoBytes!,
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.contain,
                                  )
                                else if (controller.logoUrl != null &&
                                    controller.logoUrl!.isNotEmpty)
                                  AppCachedImage(
                                    imageUrl: controller.logoUrl!,
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.contain,
                                    fallbackWidget: Icon(
                                      Icons.broken_image_outlined,
                                      size: 32,
                                      color: theme.colorScheme.error,
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
                                        'Subir Logo',
                                        style:
                                            theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (controller.isUploadingLogo)
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
                      const SizedBox(height: 6),
                      if (hasLogo)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: controller.isSaving
                                  ? null
                                  : () => _pickLogo(context, controller),
                              icon: const Icon(Icons.sync, size: 14),
                              label: const Text(
                                'Cambiar',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: controller.isSaving
                                  ? null
                                  : controller.removeLogo,
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 14,
                              ),
                              label: const Text(
                                'Quitar',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // 2. Selector de IsoLogo (Símbolo + Nombre)
                SizedBox(
                  width: 280,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'IsoLogo (Nombre y Logo)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Para encabezados de informes, sobre y bienvenida',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: controller.isSaving
                            ? null
                            : () => _pickIsoLogo(context, controller),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 200,
                          height: 110,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withAlpha(90),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (controller.selectedIsoLogoBytes != null)
                                  Image.memory(
                                    controller.selectedIsoLogoBytes!,
                                    width: 200,
                                    height: 110,
                                    fit: BoxFit.contain,
                                  )
                                else if (controller.isoLogoUrl != null &&
                                    controller.isoLogoUrl!.isNotEmpty)
                                  AppCachedImage(
                                    imageUrl: controller.isoLogoUrl!,
                                    width: 200,
                                    height: 110,
                                    fit: BoxFit.contain,
                                    fallbackWidget: Icon(
                                      Icons.broken_image_outlined,
                                      size: 32,
                                      color: theme.colorScheme.error,
                                    ),
                                  )
                                else
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.branding_watermark_outlined,
                                        size: 32,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Subir IsoLogo',
                                        style:
                                            theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (controller.isUploadingIsoLogo)
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
                      const SizedBox(height: 6),
                      if (hasIsoLogo)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: controller.isSaving
                                  ? null
                                  : () => _pickIsoLogo(context, controller),
                              icon: const Icon(Icons.sync, size: 14),
                              label: const Text(
                                'Cambiar',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: controller.isSaving
                                  ? null
                                  : controller.removeIsoLogo,
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 14,
                              ),
                              label: const Text(
                                'Quitar',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
