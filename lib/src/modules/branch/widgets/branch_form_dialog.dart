import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/branch_cubit/write_branches_cubit.dart';
import '../../../tools/uploaders/image_uploader.dart';

class BranchFormDialog extends StatefulWidget {
  const BranchFormDialog({super.key, this.branch});

  final BranchInDb? branch;

  @override
  State<BranchFormDialog> createState() => _BranchFormDialogState();
}

class _BranchFormDialogState extends State<BranchFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;

  String? _imageUrl;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isUploadingImage = false;
  bool _isSaving = false;

  bool get _isEditing => widget.branch != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.branch?.name ?? '');
    _addressController =
        TextEditingController(text: widget.branch?.address ?? '');
    _phoneController = TextEditingController(text: widget.branch?.phone ?? '');
    _imageUrl = widget.branch?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      Uint8List? bytes = file.bytes;

      if (bytes == null && file.path != null && !kIsWeb) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) return;

      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = file.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar la imagen: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _imageUrl = null;
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final writeCubit = context.read<WriteBranchCubit>();

    try {
      String? finalImageUrl = _imageUrl;

      // Si hay una nueva imagen seleccionada, subirla con ImageUploader
      if (_selectedImageBytes != null) {
        setState(() => _isUploadingImage = true);
        final fileName = _selectedImageName ??
            'branch_logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        finalImageUrl = await ImageUploader.uploadImage(
          bytes: _selectedImageBytes!,
          fileName: fileName,
        );
      }

      if (_isEditing) {
        await writeCubit.update(
          widget.branch!.id,
          UpdateBranch(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            phone: _phoneController.text.trim(),
            imageUrl: finalImageUrl,
          ),
        );
      } else {
        await writeCubit.create(
          CreateBranch(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            phone: _phoneController.text.trim(),
            imageUrl: finalImageUrl,
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isUploadingImage = false;
      });
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
    final hasImage = _selectedImageBytes != null ||
        (_imageUrl != null && _imageUrl!.isNotEmpty);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                      CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.primaryContainer.withAlpha(90),
                        foregroundColor: theme.colorScheme.primary,
                        child: Icon(
                          _isEditing
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
                              _isEditing
                                  ? 'Editar Sucursal'
                                  : 'Nueva Sucursal / Sede',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _isEditing
                                  ? 'Actualiza los datos y el logotipo de la sede'
                                  : 'Ingresa la información y sube el logotipo de la sede',
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

                  // Sección de Selección de Logo
                  Center(
                    child: Column(
                      children: [
                        InkWell(
                          onTap: _isSaving ? null : _pickImage,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withAlpha(90),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (_selectedImageBytes != null)
                                    Image.memory(
                                      _selectedImageBytes!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    )
                                  else if (_imageUrl != null &&
                                      _imageUrl!.isNotEmpty)
                                    Image.network(
                                      _imageUrl!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        Icons.broken_image_outlined,
                                        size: 40,
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
                                          size: 36,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Subir Logo',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (_isUploadingImage)
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
                        if (hasImage)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: _isSaving ? null : _pickImage,
                                icon: const Icon(Icons.sync, size: 16),
                                label: const Text('Cambiar'),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: _isSaving ? null : _removeImage,
                                icon: const Icon(Icons.delete_outline, size: 16),
                                label: const Text('Quitar'),
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            'Logo institucional (aparecerá en informes clínicos y marca de agua)',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nombre
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Sucursal *',
                      hintText: 'Ej. Sucursal Matriz, Centro, Norte...',
                      prefixIcon: Icon(Icons.storefront_rounded),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingresa el nombre de la sucursal';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dirección
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección Completa *',
                      hintText: 'Calle, número, colonia, ciudad...',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingresa la dirección de la sede';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Teléfono
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono de Contacto *',
                      hintText: 'Ej. 555-123-4567',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingresa un teléfono de contacto';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _submit,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(_isSaving
                            ? (_isUploadingImage
                                ? 'Subiendo imagen...'
                                : 'Guardando...')
                            : (_isEditing
                                ? 'Guardar Cambios'
                                : 'Crear Sucursal')),
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
