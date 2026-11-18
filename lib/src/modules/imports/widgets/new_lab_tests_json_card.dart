import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/imports_cubit/imports_cubit.dart';

typedef JsonFilePicker = Future<({String name, Uint8List bytes})?> Function();

class _ParsedJsonPreview {
  final String fileName;
  final Uint8List bytes;
  final int totalCount;
  final int atomicsCount;
  final int packsCount;

  const _ParsedJsonPreview({
    required this.fileName,
    required this.bytes,
    required this.totalCount,
    required this.atomicsCount,
    required this.packsCount,
  });
}

class NewLabTestsJsonCard extends StatefulWidget {
  final bool isLoading;
  final JsonFilePicker? onPickFile;

  const NewLabTestsJsonCard({
    super.key,
    required this.isLoading,
    this.onPickFile,
  });

  @override
  State<NewLabTestsJsonCard> createState() => _NewLabTestsJsonCardState();
}

class _NewLabTestsJsonCardState extends State<NewLabTestsJsonCard> {
  _ParsedJsonPreview? _preview;
  String? _validationError;

  Future<void> _pickAndParseJson() async {
    try {
      final picked = widget.onPickFile != null
          ? await widget.onPickFile!()
          : await _defaultPickFile();

      if (picked == null) return;

      final preview = _parseAndValidate(picked.name, picked.bytes);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _validationError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _preview = null;
        _validationError = e.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  Future<({String name, Uint8List bytes})?> _defaultPickFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return (name: file.name, bytes: bytes);
  }

  _ParsedJsonPreview _parseAndValidate(String fileName, Uint8List bytes) {
    var content = utf8.decode(bytes);
    if (content.startsWith('\uFEFF')) {
      content = content.substring(1);
    }

    final decoded = jsonDecode(content);
    if (decoded is! List || decoded.isEmpty) {
      throw const FormatException(
        'El archivo JSON debe contener un arreglo no vacío de pruebas.',
      );
    }

    var packsCount = 0;
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException(
          'Cada elemento del arreglo JSON debe ser un objeto válido.',
        );
      }
      if (item['isPack'] == true) {
        packsCount++;
      }
    }

    return _ParsedJsonPreview(
      fileName: fileName,
      bytes: bytes,
      totalCount: decoded.length,
      atomicsCount: decoded.length - packsCount,
      packsCount: packsCount,
    );
  }

  void _confirmAndImport() {
    final preview = _preview;
    if (preview == null) return;
    final cubit = context.read<ImportsCubit>();

    showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.upload_file_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              const Expanded(child: Text('Confirmar Importación de Pruebas')),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Se importarán ${preview.totalCount} registros desde "${preview.fileName}" (${preview.atomicsCount} pruebas individuales y ${preview.packsCount} packs).',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withAlpha(80)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_outlined, color: Colors.green, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Modo seguro sin sobrescritura: las pruebas o packs que ya existan en la base de datos (por código o nombre) se omitirán intactos.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.cloud_upload_rounded, size: 18),
              label: const Text('Importar Pruebas'),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        cubit.importNewLabTestsFile(
          bytes: preview.bytes,
          fileName: preview.fileName,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _preview;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(140)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.playlist_add_check_rounded,
                    color: Colors.teal.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Importar Pruebas Nuevas (Archivo JSON)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sube un archivo .json con nuevos paneles o pruebas clínicas (por ejemplo, panel_atopica_30i_import.json). Solo se insertarán registros nuevos sin modificar los existentes.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_validationError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withAlpha(120),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.error.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (preview != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.teal.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.withAlpha(80)),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.description_outlined, color: Colors.teal.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          preview.fileName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Chip(
                      label: Text('${preview.totalCount} registros'),
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      label: Text('${preview.atomicsCount} pruebas'),
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      label: Text('${preview.packsCount} packs'),
                      visualDensity: VisualDensity.compact,
                    ),
                    TextButton.icon(
                      onPressed: widget.isLoading
                          ? null
                          : () => setState(() => _preview = null),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Quitar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.isLoading ? null : _pickAndParseJson,
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: Text(
                    preview == null ? 'Seleccionar archivo .json' : 'Cambiar archivo .json',
                  ),
                ),
                FilledButton.icon(
                  onPressed: (widget.isLoading || preview == null) ? null : _confirmAndImport,
                  icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: const Text('Importar Pruebas Nuevas'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
