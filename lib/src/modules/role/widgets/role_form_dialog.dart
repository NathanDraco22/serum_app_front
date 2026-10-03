import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/role_cubit/write_roles_cubit.dart';

class RoleFormDialog extends StatefulWidget {
  const RoleFormDialog({super.key, this.role});

  final RoleInDb? role;

  @override
  State<RoleFormDialog> createState() => _RoleFormDialogState();
}

class _RoleFormDialogState extends State<RoleFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late int _accessLevel;

  bool _isSaving = false;

  bool get _isEditing => widget.role != null;

  static const Map<int, String> _levelDescriptions = {
    5: 'Nivel 5 — Administrador: Acceso total al sistema y configuraciones globales',
    4: 'Nivel 4 — Supervisor: Autorizaciones especiales, auditoría y cierres',
    3: 'Nivel 3 — Operador: Módulo POS, caja del turno, pacientes, cotizaciones y órdenes',
    2: 'Nivel 2 — Asistente: Registro inicial de pacientes y consultas operativas',
    1: 'Nivel 1 — Consulta: Solo lectura y visualización básica de expedientes',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.role?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.role?.description ?? '');
    _accessLevel = widget.role?.accessLevel ?? 3;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final writeCubit = context.read<WriteRoleCubit>();

    try {
      if (_isEditing) {
        await writeCubit.update(
          widget.role!.id,
          UpdateRole(
            name: _nameController.text.trim(),
            accessLevel: _accessLevel,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          ),
        );
      } else {
        await writeCubit.create(
          CreateRole(
            name: _nameController.text.trim(),
            accessLevel: _accessLevel,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  Color _getLevelColor(int level, ColorScheme colors) {
    switch (level) {
      case 5:
        return Colors.deepPurple;
      case 4:
        return Colors.indigo;
      case 3:
        return colors.primary;
      case 2:
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final levelColor = _getLevelColor(_accessLevel, colors);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: levelColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.security_rounded,
                          color: levelColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing ? 'Editar Rol' : 'Nuevo Rol',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Define el nombre y jerarquía de acceso del rol',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Role Name Field
                  Text(
                    'Nombre del Rol *',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Ej. Administrador, Supervisor, Operador...',
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'El nombre del rol es obligatorio.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Access Level Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nivel de Acceso (Jerarquía) *',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: levelColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: levelColor.withAlpha(80)),
                        ),
                        child: Text(
                          'Nivel $_accessLevel de 5',
                          style: TextStyle(
                            color: levelColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Segmented Level Selector
                  Row(
                    children: [1, 2, 3, 4, 5].map((lvl) {
                      final isSelected = _accessLevel == lvl;
                      final btnColor = _getLevelColor(lvl, colors);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _accessLevel = lvl;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? btnColor
                                    : colors.surfaceContainerHigh.withAlpha(80),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? btnColor
                                      : colors.outlineVariant.withAlpha(120),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Lvl $lvl',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : colors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Level Description Note
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: levelColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: levelColor.withAlpha(60)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: levelColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _levelDescriptions[_accessLevel] ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description Field
                  Text(
                    'Descripción Funcional (Opcional)',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText:
                          'Describe el propósito o alcance operativo de este rol...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: levelColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSaving ? null : _submit,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: Text(_isEditing ? 'Guardar Cambios' : 'Crear Rol'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
