import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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
  late final TextEditingController _emailController;
  late final TextEditingController _facebookController;

  // Logotipo (símbolo o icono compacto)
  String? _logoUrl;
  Uint8List? _selectedLogoBytes;
  String? _selectedLogoName;
  bool _isUploadingLogo = false;

  // IsoLogo (símbolo + nombre comercial integrado)
  String? _isoLogoUrl;
  Uint8List? _selectedIsoLogoBytes;
  String? _selectedIsoLogoName;
  bool _isUploadingIsoLogo = false;

  bool _isSaving = false;

  bool get _isEditing => widget.branch != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.branch?.name ?? '');
    _addressController =
        TextEditingController(text: widget.branch?.address ?? '');
    _phoneController = TextEditingController(text: widget.branch?.phone ?? '');
    _emailController = TextEditingController(text: widget.branch?.email ?? '');
    _facebookController =
        TextEditingController(text: widget.branch?.facebook ?? '');

    _logoUrl = widget.branch?.effectiveLogo;
    _isoLogoUrl = widget.branch?.isoLogoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      setState(() {
        _selectedLogoBytes = bytes;
        _selectedLogoName = file.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar el logotipo: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _removeLogo() {
    setState(() {
      _logoUrl = null;
      _selectedLogoBytes = null;
      _selectedLogoName = null;
    });
  }

  Future<void> _pickIsoLogo() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      setState(() {
        _selectedIsoLogoBytes = bytes;
        _selectedIsoLogoName = file.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar el IsoLogo: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _removeIsoLogo() {
    setState(() {
      _isoLogoUrl = null;
      _selectedIsoLogoBytes = null;
      _selectedIsoLogoName = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final writeCubit = context.read<WriteBranchCubit>();

    try {
      String? finalLogoUrl = _logoUrl;
      String? finalIsoLogoUrl = _isoLogoUrl;

      // Subida de nuevo Logotipo si fue seleccionado
      if (_selectedLogoBytes != null) {
        setState(() => _isUploadingLogo = true);
        final fileName = _selectedLogoName ??
            'branch_logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        finalLogoUrl = await ImageUploader.uploadImage(
          bytes: _selectedLogoBytes!,
          fileName: fileName,
        );
      }

      // Subida de nuevo IsoLogo si fue seleccionado
      if (_selectedIsoLogoBytes != null) {
        setState(() => _isUploadingIsoLogo = true);
        final fileName = _selectedIsoLogoName ??
            'branch_isologo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        finalIsoLogoUrl = await ImageUploader.uploadImage(
          bytes: _selectedIsoLogoBytes!,
          fileName: fileName,
        );
      }

      final emailText = _emailController.text.trim();
      final facebookText = _facebookController.text.trim();

      if (_isEditing) {
        await writeCubit.update(
          widget.branch!.id,
          UpdateBranch(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            phone: _phoneController.text.trim(),
            email: emailText.isNotEmpty ? emailText : null,
            facebook: facebookText.isNotEmpty ? facebookText : null,
            logoUrl: finalLogoUrl,
            imageUrl: finalLogoUrl,
            isoLogoUrl: finalIsoLogoUrl,
          ),
        );
      } else {
        await writeCubit.create(
          CreateBranch(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            phone: _phoneController.text.trim(),
            email: emailText.isNotEmpty ? emailText : null,
            facebook: facebookText.isNotEmpty ? facebookText : null,
            logoUrl: finalLogoUrl,
            imageUrl: finalLogoUrl,
            isoLogoUrl: finalIsoLogoUrl,
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isUploadingLogo = false;
        _isUploadingIsoLogo = false;
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
    final hasLogo = _selectedLogoBytes != null ||
        (_logoUrl != null && _logoUrl!.isNotEmpty);
    final hasIsoLogo = _selectedIsoLogoBytes != null ||
        (_isoLogoUrl != null && _isoLogoUrl!.isNotEmpty);

    return Dialog(
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

                  // Sección de Imágenes de Marca (Logotipo e IsoLogo)
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
                              onTap: _isSaving ? null : _pickLogo,
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
                                      if (_selectedLogoBytes != null)
                                        Image.memory(
                                          _selectedLogoBytes!,
                                          width: 110,
                                          height: 110,
                                          fit: BoxFit.contain,
                                        )
                                      else if (_logoUrl != null &&
                                          _logoUrl!.isNotEmpty)
                                        Image.network(
                                          _logoUrl!,
                                          width: 110,
                                          height: 110,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
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
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (_isUploadingLogo)
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
                                    onPressed: _isSaving ? null : _pickLogo,
                                    icon: const Icon(Icons.sync, size: 14),
                                    label: const Text('Cambiar',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                  TextButton.icon(
                                    onPressed: _isSaving ? null : _removeLogo,
                                    icon: const Icon(Icons.delete_outline,
                                        size: 14),
                                    label: const Text('Quitar',
                                        style: TextStyle(fontSize: 12)),
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
                              onTap: _isSaving ? null : _pickIsoLogo,
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
                                      if (_selectedIsoLogoBytes != null)
                                        Image.memory(
                                          _selectedIsoLogoBytes!,
                                          width: 200,
                                          height: 110,
                                          fit: BoxFit.contain,
                                        )
                                      else if (_isoLogoUrl != null &&
                                          _isoLogoUrl!.isNotEmpty)
                                        Image.network(
                                          _isoLogoUrl!,
                                          width: 200,
                                          height: 110,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
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
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (_isUploadingIsoLogo)
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
                                    onPressed: _isSaving ? null : _pickIsoLogo,
                                    icon: const Icon(Icons.sync, size: 14),
                                    label: const Text('Cambiar',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                  TextButton.icon(
                                    onPressed: _isSaving ? null : _removeIsoLogo,
                                    icon: const Icon(Icons.delete_outline,
                                        size: 14),
                                    label: const Text('Quitar',
                                        style: TextStyle(fontSize: 12)),
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
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Sección Datos Generales
                  Text(
                    'Información General',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),

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
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico (Email)',
                      hintText: 'Ej. contacto@laboratorio.com',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Facebook
                  TextFormField(
                    controller: _facebookController,
                    decoration: const InputDecoration(
                      labelText: 'Página de Facebook',
                      hintText: 'Ej. facebook.com/laboratorioclinico o @laboratorio',
                      prefixIcon: Icon(Icons.facebook_outlined),
                      border: OutlineInputBorder(),
                    ),
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(_isSaving
                            ? (_isUploadingLogo || _isUploadingIsoLogo
                                ? 'Subiendo imágenes...'
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
