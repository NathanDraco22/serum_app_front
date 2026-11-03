import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../tools/cache/app_image_cache.dart';
import '../../../tools/uploaders/image_uploader.dart';
import '../../../widgets/common/app_cached_image.dart';

class AuxBioanalystDialog extends StatefulWidget {
  final AuxBioanalyst? initialAux;

  const AuxBioanalystDialog({
    super.key,
    this.initialAux,
  });

  static Future<AuxBioanalyst?> show(
    BuildContext context, {
    AuxBioanalyst? initialAux,
  }) {
    return showDialog<AuxBioanalyst>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AuxBioanalystDialog(initialAux: initialAux),
    );
  }

  @override
  State<AuxBioanalystDialog> createState() => _AuxBioanalystDialogState();
}

class _AuxBioanalystDialogState extends State<AuxBioanalystDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _titleController;
  late final TextEditingController _codeController;

  UserInfo? _selectedUser;
  List<UserInDb> _availableUsers = [];
  bool _isLoadingUsers = true;

  String? _sealUrl;
  Uint8List? _selectedSealBytes;
  String? _selectedSealName;
  bool _isUploadingSeal = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final bio = widget.initialAux?.bioanalyst;
    _nameController = TextEditingController(text: bio?.name ?? '');
    _titleController = TextEditingController(text: bio?.title ?? '');
    _codeController = TextEditingController(text: bio?.code ?? '');
    _sealUrl = bio?.sealUrl;
    _selectedUser = widget.initialAux?.user;

    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final repo = context.read<UsersRepository>();
      final users = await repo.getAllUsers();
      if (mounted) {
        setState(() {
          _availableUsers = users;
          _isLoadingUsers = false;
          if (_selectedUser != null) {
            final match = _availableUsers.where((u) => u.id == _selectedUser!.id);
            if (match.isNotEmpty) {
              _selectedUser = UserInfo(id: match.first.id, name: match.first.name);
            }
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _pickSeal() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      );

      if (file == null) return;
      final bytes = await file.readAsBytes();

      setState(() {
        _selectedSealBytes = bytes;
        _selectedSealName = file.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar el sello: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _removeSeal() {
    if (_sealUrl != null) {
      AppImageCache.evict(_sealUrl!);
    }
    setState(() {
      _sealUrl = null;
      _selectedSealBytes = null;
      _selectedSealName = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, selecciona el usuario del sistema.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? finalSealUrl = _sealUrl;

      if (_selectedSealBytes != null) {
        setState(() => _isUploadingSeal = true);
        final fileName = _selectedSealName ??
            'aux_seal_${DateTime.now().millisecondsSinceEpoch}.png';
        finalSealUrl = await ImageUploader.uploadImage(
          bytes: _selectedSealBytes!,
          fileName: fileName,
        );
      }

      final result = AuxBioanalyst(
        user: _selectedUser!,
        bioanalyst: BioanalystInfo(
          name: _nameController.text.trim(),
          title: _titleController.text.trim(),
          code: _codeController.text.trim(),
          sealUrl: finalSealUrl,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isUploadingSeal = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar el bioanalista auxiliar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSeal =
        _selectedSealBytes != null || (_sealUrl != null && _sealUrl!.isNotEmpty);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(widget.initialAux == null
              ? 'Agregar Bioanalista Auxiliar'
              : 'Editar Bioanalista Auxiliar'),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Asocia un usuario del sistema y configura sus credenciales para que pueda firmar reportes de laboratorio.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // Selección de Usuario
                if (_isLoadingUsers)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUser?.id,
                    decoration: const InputDecoration(
                      labelText: 'Usuario del Sistema *',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    items: _availableUsers.map((u) {
                      return DropdownMenuItem(
                        value: u.id,
                        child: Text('${u.name} (${u.role})'),
                      );
                    }).toList(),
                    onChanged: (userId) {
                      if (userId == null) return;
                      final u = _availableUsers.firstWhere((x) => x.id == userId);
                      setState(() {
                        _selectedUser = UserInfo(id: u.id, name: u.name);
                        if (_nameController.text.trim().isEmpty) {
                          _nameController.text = u.name;
                        }
                      });
                    },
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Selecciona un usuario' : null,
                  ),
                const SizedBox(height: 14),

                // Nombre completo para la firma
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo para Firma *',
                    hintText: 'Ej. Lic. María José Pérez',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'El nombre es requerido' : null,
                ),
                const SizedBox(height: 14),

                // Título Profesional
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título Profesional / Cargo *',
                    hintText: 'Ej. Bioanalista Clínica / Microbióloga',
                    prefixIcon: Icon(Icons.school_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'El título es requerido' : null,
                ),
                const SizedBox(height: 14),

                // Código Profesional / MINSA
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Código Profesional / Registro *',
                    hintText: 'Ej. Reg. MINSA 88921',
                    prefixIcon: Icon(Icons.verified_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'El código es requerido' : null,
                ),
                const SizedBox(height: 16),

                // Tarjeta de Sello de Tinta
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.approval_rounded,
                              size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Sello Físico de Tinta',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Column(
                          children: [
                            InkWell(
                              onTap: _isSaving ? null : _pickSeal,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 130,
                                height: 95,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: hasSeal
                                        ? theme.colorScheme.primary
                                            .withValues(alpha: 0.5)
                                        : theme.colorScheme.outlineVariant,
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (_selectedSealBytes != null)
                                        Transform.rotate(
                                          angle: -0.087,
                                          child: Image.memory(
                                            _selectedSealBytes!,
                                            width: 105,
                                            height: 80,
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      else if (_sealUrl != null &&
                                          _sealUrl!.isNotEmpty)
                                        Transform.rotate(
                                          angle: -0.087,
                                          child: AppCachedImage(
                                            imageUrl: _sealUrl!,
                                            width: 105,
                                            height: 80,
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      else
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate_outlined,
                                              size: 26,
                                              color: theme.colorScheme.primary,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Subir Sello',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                color: theme
                                                    .colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (_isUploadingSeal)
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
                            if (hasSeal) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton.icon(
                                    onPressed: _isSaving ? null : _pickSeal,
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 14),
                                    label: const Text('Cambiar'),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  TextButton.icon(
                                    onPressed: _isSaving ? null : _removeSeal,
                                    icon: const Icon(Icons.delete_outline,
                                        size: 14),
                                    label: const Text('Eliminar'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: theme.colorScheme.error,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar Auxiliar'),
        ),
      ],
    );
  }
}
