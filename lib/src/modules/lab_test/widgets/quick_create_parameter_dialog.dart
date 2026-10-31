import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import 'clinical_classification_registry.dart';

class QuickCreateParameterDialog extends StatefulWidget {
  final String initialCategory;
  final String? initialSubclassification;
  final String branchId;
  final LabTestsRepository? repository;

  const QuickCreateParameterDialog({
    super.key,
    required this.initialCategory,
    this.initialSubclassification,
    required this.branchId,
    this.repository,
  });

  static Future<LabTestInDb?> show(
    BuildContext context, {
    required String initialCategory,
    String? initialSubclassification,
    required String branchId,
    LabTestsRepository? repository,
  }) {
    final repo = repository ?? RepositoryProvider.of<LabTestsRepository>(context);
    return showDialog<LabTestInDb>(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuickCreateParameterDialog(
        initialCategory: initialCategory,
        initialSubclassification: initialSubclassification,
        branchId: branchId,
        repository: repo,
      ),
    );
  }

  @override
  State<QuickCreateParameterDialog> createState() => _QuickCreateParameterDialogState();
}

class _QuickCreateParameterDialogState extends State<QuickCreateParameterDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _unitController;
  late TextEditingController _minValueController;
  late TextEditingController _maxValueController;
  late TextEditingController _qualitativeOptionsController;
  late TextEditingController _expectedQualitativeController;
  late TextEditingController _referenceTextController;
  late TextEditingController _customSubclassController;

  late String _category;
  late String _subclassification;
  bool _isCustomSubclass = false;
  String _dataType = 'numeric'; // 'numeric', 'qualitative', 'text'
  bool _isSubmitting = false;

  static const List<Map<String, dynamic>> _qualitativePresets = [
    {
      'label': 'Negativo / Positivo',
      'options': 'Negativo, Positivo',
      'expected': 'Negativo',
    },
    {
      'label': 'Sedimento Urinario (No se observó, Escasas...)',
      'options': 'No se observó, Escasas, Moderadas, Abundantes',
      'expected': 'No se observó',
    },
    {
      'label': 'Escala de Cruces (Negativo, Trazas, +, ++, +++)',
      'options': 'Negativo, Trazas, +, ++, +++',
      'expected': 'Negativo',
    },
    {
      'label': 'Normal / Alterado',
      'options': 'Normal, Alterado',
      'expected': 'Normal',
    },
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory.trim().isNotEmpty
        ? widget.initialCategory.trim()
        : (ClinicalClassificationRegistry.classifications.firstOrNull ?? 'Hematología');

    final availableSubs = ClinicalClassificationRegistry.getSubclassificationsFor(_category);
    if (widget.initialSubclassification != null &&
        widget.initialSubclassification!.trim().isNotEmpty) {
      final initialSub = widget.initialSubclassification!.trim();
      if (availableSubs.contains(initialSub)) {
        _subclassification = initialSub;
      } else {
        _subclassification = '__custom__';
        _isCustomSubclass = true;
      }
    } else {
      _subclassification = availableSubs.firstOrNull ?? 'General';
    }

    _nameController = TextEditingController();
    _codeController = TextEditingController();
    _unitController = TextEditingController(text: 'mg/dL');
    _minValueController = TextEditingController(text: '0');
    _maxValueController = TextEditingController(text: '100');
    _qualitativeOptionsController = TextEditingController(text: 'Negativo, Positivo');
    _expectedQualitativeController = TextEditingController(text: 'Negativo');
    _referenceTextController = TextEditingController();
    _customSubclassController = TextEditingController(
      text: _isCustomSubclass ? widget.initialSubclassification ?? '' : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _unitController.dispose();
    _minValueController.dispose();
    _maxValueController.dispose();
    _qualitativeOptionsController.dispose();
    _expectedQualitativeController.dispose();
    _referenceTextController.dispose();
    _customSubclassController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String? newCategory) {
    if (newCategory == null) return;
    setState(() {
      _category = newCategory;
      final subs = ClinicalClassificationRegistry.getSubclassificationsFor(_category);
      _subclassification = subs.firstOrNull ?? 'General';
      _isCustomSubclass = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final finalSubclassification = _isCustomSubclass
          ? _customSubclassController.text.trim()
          : _subclassification.trim();

      List<ReferenceValue> refs = [];
      if (_dataType == 'numeric') {
        final minVal = double.tryParse(_minValueController.text.trim()) ?? 0.0;
        final maxVal = double.tryParse(_maxValueController.text.trim()) ?? 0.0;
        refs = [
          ReferenceValue(
            patientType: 'general',
            gender: 'both',
            minAgeDays: 0,
            maxAgeDays: 36500,
            minValue: minVal,
            maxValue: maxVal,
          ),
        ];
      }

      List<String> qualOptions = [];
      String? expectedQual;
      if (_dataType == 'qualitative') {
        qualOptions = _qualitativeOptionsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        expectedQual = _expectedQualitativeController.text.trim().isNotEmpty
            ? _expectedQualitativeController.text.trim()
            : null;
      }

      final newLabTest = CreateLabTest(
        branchId: widget.branchId,
        name: _nameController.text.trim(),
        code: _codeController.text.trim().isNotEmpty ? _codeController.text.trim() : null,
        commercialCategory: _category,
        subclassification: finalSubclassification,
        salePrice: 0,
        salePrice2: 0,
        costPrice: 0,
        currency: 'USD',
        isPack: false,
        useChildTestsPriceSum: false,
        childTestIds: const [],
        dataType: _dataType,
        unitOfMeasure: _dataType == 'numeric' ? _unitController.text.trim() : '',
        referenceValues: refs,
        qualitativeOptions: qualOptions,
        expectedQualitativeValue: expectedQual,
        referenceText: _referenceTextController.text.trim(),
        isProfileParameter: true, // Parámetro interno de perfil
      );

      final repo = widget.repository ?? RepositoryProvider.of<LabTestsRepository>(context);
      final created = await repo.createLabTest(newLabTest);

      if (mounted) {
        Navigator.of(context).pop(created);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear parámetro: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableCategories = ClinicalClassificationRegistry.classifications;
    if (!availableCategories.contains(_category)) {
      availableCategories.add(_category);
      availableCategories.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }

    final availableSubs = ClinicalClassificationRegistry.getSubclassificationsFor(_category);

    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: const Icon(Icons.add_chart_rounded, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crear Parámetro de Perfil',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Se asociará automáticamente a este perfil sin saturar el catálogo general',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre y Código
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _nameController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Parámetro *',
                          hintText: 'Ej. Aspecto, Color, Glucosa, Leucocitos...',
                          isDense: true,
                          prefixIcon: Icon(Icons.science_outlined, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Código / Abreviatura',
                          hintText: 'Ej. COL',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Clasificación y Subclasificación
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('dialog_cat_$_category'),
                        initialValue: _category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Clasificación *',
                          prefixIcon: Icon(Icons.category_outlined, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: availableCategories.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: _onCategoryChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('dialog_sub_${_category}_$_subclassification'),
                        initialValue: _isCustomSubclass ? '__custom__' : _subclassification,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Subclasificación',
                          prefixIcon: Icon(Icons.account_tree_outlined, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          ...availableSubs.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))),
                          const DropdownMenuItem(
                            value: '__custom__',
                            child: Text('+ Otra subclasificación...'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            if (val == '__custom__') {
                              _isCustomSubclass = true;
                              _subclassification = '__custom__';
                            } else {
                              _isCustomSubclass = false;
                              _subclassification = val;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (_isCustomSubclass) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _customSubclassController,
                    decoration: const InputDecoration(
                      labelText: 'Especifica la Subclasificación personalizada',
                      hintText: 'Ej. Serie Plaquetaria, Examen Físico...',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (_isCustomSubclass && (v == null || v.trim().isEmpty)) {
                        return 'Ingresa el nombre de la subclasificación';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),

                // Selector de Tipo de Dato
                Text(
                  'Tipo de Resultado:',
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'numeric',
                      label: Text('Numérico'),
                      icon: Icon(Icons.numbers, size: 18),
                    ),
                    ButtonSegment(
                      value: 'qualitative',
                      label: Text('Cualitativo / Lista'),
                      icon: Icon(Icons.checklist, size: 18),
                    ),
                    ButtonSegment(
                      value: 'text',
                      label: Text('Texto Libre'),
                      icon: Icon(Icons.text_fields, size: 18),
                    ),
                  ],
                  selected: {_dataType},
                  onSelectionChanged: (val) {
                    setState(() => _dataType = val.first);
                  },
                ),
                const SizedBox(height: 16),

                // Opciones según Tipo de Dato
                if (_dataType == 'numeric') ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _unitController,
                          decoration: const InputDecoration(
                            labelText: 'Unidad de Medida',
                            hintText: 'mg/dL, %, /campo...',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _minValueController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Mínimo de Referencia',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _maxValueController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Máximo de Referencia',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (_dataType == 'qualitative') ...[
                  // Presets rápidos
                  Text(
                    'Plantillas rápidas:',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _qualitativePresets.map((preset) {
                      return ActionChip(
                        label: Text(preset['label'] as String, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() {
                            _qualitativeOptionsController.text = preset['options'] as String;
                            _expectedQualitativeController.text = preset['expected'] as String;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _qualitativeOptionsController,
                    decoration: const InputDecoration(
                      labelText: 'Opciones posibles (separadas por coma) *',
                      hintText: 'Ej. Negativo, Trazas, Positivo (+), etc.',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (_dataType == 'qualitative' && (v == null || v.trim().isEmpty)) {
                        return 'Ingresa al menos una opción';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _expectedQualitativeController,
                    decoration: const InputDecoration(
                      labelText: 'Valor Normal / Esperado',
                      hintText: 'Ej. Negativo, No se observó...',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _referenceTextController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Texto / Criterio de Referencia (opcional)',
                      hintText: 'Indicaciones o rangos descriptivos...',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check, size: 18),
          label: Text(_isSubmitting ? 'Guardando...' : 'Crear y Agregar'),
        ),
      ],
    );
  }
}
