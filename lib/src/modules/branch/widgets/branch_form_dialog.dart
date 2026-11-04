import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/branch_cubit/write_branches_cubit.dart';
import '../controllers/branch_form_mediator.dart';
import '../controllers/branch_form_view_controller.dart';
import 'sections/branch_aux_bioanalysts_section.dart';
import 'sections/branch_bioanalyst_section.dart';
import 'sections/branch_branding_section.dart';
import 'sections/branch_general_info_section.dart';

/// Diálogo modal para la creación y edición integral de sucursales/sedes.
/// Sigue el patrón ViewController + Mediator (OKF v0.2), delegando la gestión de estado
/// y generación de DTOs en [BranchFormViewController].
class BranchFormDialog extends StatefulWidget {
  const BranchFormDialog({super.key, this.branch});

  final BranchInDb? branch;

  @override
  State<BranchFormDialog> createState() => _BranchFormDialogState();
}

class _BranchFormDialogState extends State<BranchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final BranchFormViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BranchFormViewController(initialBranch: widget.branch);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isRoot = context.read<AppSessionCubit>().state.isRootUser;
    if (widget.branch == null && !isRoot) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Solo el usuario root puede crear nuevas sucursales'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    _controller.setSaving(true);
    final writeCubit = context.read<WriteBranchCubit>();

    try {
      if (_controller.isEditing) {
        final updateDto = await _controller.generateUpdateDto();
        await writeCubit.update(widget.branch!.id, updateDto);
      } else {
        final createDto = await _controller.generateCreateDto();
        await writeCubit.create(createDto);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _controller.setSaving(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la sucursal: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = _controller.isEditing;

    return BranchFormMediator(
      viewController: _controller,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.primaryContainer.withAlpha(90),
                          foregroundColor: theme.colorScheme.primary,
                          child: Icon(
                            isEditing
                                ? Icons.edit_location_alt_rounded
                                : Icons.add_business_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing
                                    ? 'Editar Sucursal'
                                    : 'Nueva Sucursal / Sede',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                isEditing
                                    ? 'Actualiza los datos, contactos e imágenes de marca de la sede'
                                    : 'Ingresa la información, contactos y marcas de la sede',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    // Subsección 1: Identidad Visual
                    const BranchBrandingSection(),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    // Subsección 2: Información General
                    const BranchGeneralInfoSection(),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    // Subsección 3: Bioanalista Representante
                    const BranchBioanalystSection(),
                    const SizedBox(height: 24),

                    // Subsección 4: Bioanalistas Auxiliares
                    const BranchAuxBioanalystsSection(),
                    const SizedBox(height: 28),

                    // Botones de Acción
                    ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) {
                        final isSaving = _controller.isSaving;
                        final isUploadingAny = _controller.isUploadingAny;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: isSaving ? null : _submit,
                              icon: isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded, size: 18),
                              label: Text(
                                isSaving
                                    ? (isUploadingAny
                                        ? 'Subiendo imágenes y sello...'
                                        : 'Guardando...')
                                    : (isEditing
                                        ? 'Guardar Cambios'
                                        : 'Crear Sucursal'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
