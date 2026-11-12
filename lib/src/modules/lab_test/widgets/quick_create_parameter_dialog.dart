import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../controllers/reference_values_validator.dart';
import 'clinical_classification_registry.dart';
import 'reference_values_editor.dart';

class QuickCreateParameterDialog extends StatefulWidget {
  final String initialCategory;
  final String? initialSubclassification;
  final String branchId;
  final LabTestsRepository? repository;
  final LabTestInDb? parameterToEdit;

  const QuickCreateParameterDialog({
    super.key,
    required this.initialCategory,
    this.initialSubclassification,
    required this.branchId,
    this.repository,
    this.parameterToEdit,
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

  static Future<LabTestInDb?> showEdit(
    BuildContext context, {
    required LabTestInDb parameter,
    required String branchId,
    LabTestsRepository? repository,
  }) {
    final repo = repository ?? RepositoryProvider.of<LabTestsRepository>(context);
    return showDialog<LabTestInDb>(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuickCreateParameterDialog(
        initialCategory: parameter.commercialCategory,
        initialSubclassification: parameter.subclassification,
        branchId: branchId,
        repository: repo,
        parameterToEdit: parameter,
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
  late TextEditingController _qualitativeOptionsController;
  late TextEditingController _referenceTextController;
  late TextEditingController _customSubclassController;

  late List<ReferenceValue> _referenceValues;
  bool _referenceRangesExpanded = false;

  late List<String> _qualitativeOptions;
  late String _expectedQualitativeValue;

  late String _category;
  late String _subclassification;
  bool _isCustomSubclass = false;
  String _dataType = 'numeric'; // 'numeric', 'qualitative', 'text'
  bool _isSubmitting = false;

  bool get _isEditing => widget.parameterToEdit != null;

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
    final p = widget.parameterToEdit;

    if (p != null) {
      _category = p.commercialCategory.trim().isNotEmpty
          ? p.commercialCategory.trim()
          : (ClinicalClassificationRegistry.classifications.firstOrNull ?? 'Hematología');

      final availableSubs = ClinicalClassificationRegistry.getSubclassificationsFor(_category);
      final rawSub = p.subclassification.trim();
      if (rawSub.isNotEmpty) {
        if (availableSubs.contains(rawSub)) {
          _subclassification = rawSub;
        } else {
          _subclassification = '__custom__';
          _isCustomSubclass = true;
        }
      } else {
        _subclassification = availableSubs.firstOrNull ?? 'General';
      }

      _dataType = p.dataType.trim().isNotEmpty ? p.dataType.trim() : 'numeric';
      _nameController = TextEditingController(text: p.name);
      _codeController = TextEditingController(text: p.code ?? '');
      _unitController = TextEditingController(text: p.unitOfMeasure);

      if (_dataType == 'numeric') {
        _referenceValues = p.referenceValues.isNotEmpty
            ? List<ReferenceValue>.of(p.referenceValues)
            : [_defaultReferenceValue()];
        // En edición, los rangos existentes se muestran colapsados para
        // priorizar los datos generales del parámetro.
        _referenceRangesExpanded = p.referenceValues.isEmpty;
      } else {
        _referenceValues = <ReferenceValue>[];
        _referenceRangesExpanded = false;
      }

      _qualitativeOptions = p.qualitativeOptions.isNotEmpty
          ? List.from(p.qualitativeOptions)
          : ['Negativo', 'Positivo'];
      _expectedQualitativeValue =
          (p.expectedQualitativeValue != null && p.expectedQualitativeValue!.trim().isNotEmpty)
          ? p.expectedQualitativeValue!.trim()
          : (_qualitativeOptions.isNotEmpty ? _qualitativeOptions.first : 'Negativo');
      _qualitativeOptionsController = TextEditingController(
        text: p.qualitativeOptions.isNotEmpty
            ? p.qualitativeOptions.join(', ')
            : 'Negativo, Positivo',
      );
      _referenceTextController = TextEditingController(text: p.referenceText);
      _customSubclassController = TextEditingController(
        text: _isCustomSubclass ? rawSub : '',
      );
    } else {
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
      _referenceValues = [_defaultReferenceValue()];
      _referenceRangesExpanded = true;
      _qualitativeOptions = ['Negativo', 'Positivo'];
      _expectedQualitativeValue = 'Negativo';
      _qualitativeOptionsController = TextEditingController(text: 'Negativo, Positivo');
      _referenceTextController = TextEditingController();
      _customSubclassController = TextEditingController(
        text: _isCustomSubclass ? widget.initialSubclassification ?? '' : '',
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _unitController.dispose();
    _qualitativeOptionsController.dispose();
    _referenceTextController.dispose();
    _customSubclassController.dispose();
    super.dispose();
  }

  ReferenceValue _defaultReferenceValue() {
    return ReferenceValue(
      patientType: 'general',
      gender: 'both',
      minAgeDays: 0,
      maxAgeDays: 36500,
      minValue: 0,
      maxValue: 100,
      useAge: false,
      useGender: false,
      ageUnit: 'years',
    );
  }

  String get _referenceRangesSubtitle {
    final count = _referenceValues.length;
    if (count == 0) return 'Sin rangos';
    if (count == 1) return '1 rango configurado';
    return '$count rangos configurados';
  }

  void _onDataTypeChanged(String value) {
    if (value == _dataType) return;
    setState(() {
      _dataType = value;
      if (value == 'numeric') {
        if (_referenceValues.isEmpty) {
          _referenceValues = [_defaultReferenceValue()];
        }
        _referenceRangesExpanded = true;
      }
    });
  }

  void _updateQualitativeOptionsFromText(String text) {
    final parsed = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    _qualitativeOptions = parsed;
    if (!_qualitativeOptions.contains(_expectedQualitativeValue)) {
      _expectedQualitativeValue = _qualitativeOptions.isNotEmpty ? _qualitativeOptions.first : '';
    }
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

    if (_dataType == 'numeric') {
      final referenceError = ReferenceValuesValidator.errorFor(_referenceValues);
      if (referenceError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(referenceError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final finalSubclassification = _isCustomSubclass
          ? _customSubclassController.text.trim()
          : _subclassification.trim();

      final refs = _dataType == 'numeric'
          ? List<ReferenceValue>.of(_referenceValues)
          : <ReferenceValue>[];

      List<String> qualOptions = [];
      String? expectedQual;
      if (_dataType == 'qualitative') {
        _updateQualitativeOptionsFromText(_qualitativeOptionsController.text);
        qualOptions = _qualitativeOptions;
        expectedQual = _expectedQualitativeValue.trim().isNotEmpty
            ? _expectedQualitativeValue.trim()
            : (qualOptions.isNotEmpty ? qualOptions.first : null);
      }

      final repo = widget.repository ?? RepositoryProvider.of<LabTestsRepository>(context);

      if (_isEditing) {
        final updateData = UpdateLabTest(
          name: _nameController.text.trim(),
          code: _codeController.text.trim().isNotEmpty ? _codeController.text.trim() : null,
          commercialCategory: _category,
          subclassification: finalSubclassification,
          dataType: _dataType,
          unitOfMeasure: _dataType == 'numeric' ? _unitController.text.trim() : '',
          referenceValues: refs,
          qualitativeOptions: qualOptions,
          expectedQualitativeValue: expectedQual,
          referenceText: _referenceTextController.text.trim(),
        );

        final updated = await repo.updateLabTestById(widget.parameterToEdit!.id, updateData);

        if (mounted) {
          Navigator.of(context).pop(updated);
        }
      } else {
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

        final created = await repo.createLabTest(newLabTest);

        if (mounted) {
          Navigator.of(context).pop(created);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Error al actualizar parámetro: $e' : 'Error al crear parámetro: $e',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth > 1120 ? 1000.0 : screenWidth * 0.9;
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
            child: Icon(_isEditing ? Icons.edit_note_rounded : Icons.add_chart_rounded, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? 'Editar Parámetro: ${widget.parameterToEdit!.name}'
                      : 'Crear Parámetro de Perfil',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  _isEditing
                      ? 'Modifique los valores de referencia o configuración técnica de este parámetro'
                      : 'Se asociará automáticamente a este perfil sin saturar el catálogo general',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
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
                          return DropdownMenuItem(
                            value: c,
                            child: Text(c, overflow: TextOverflow.ellipsis),
                          );
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
                          ...availableSubs.map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s, overflow: TextOverflow.ellipsis),
                            ),
                          ),
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
                    _onDataTypeChanged(val.first);
                  },
                ),
                const SizedBox(height: 16),

                // Opciones según Tipo de Dato
                if (_dataType == 'numeric') ...[
                  TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unidad de Medida',
                      hintText: 'mg/dL, %, /campo...',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  ExpansionTile(
                    key: const ValueKey('dialog_reference_ranges_tile'),
                    initiallyExpanded: _referenceRangesExpanded,
                    onExpansionChanged: (expanded) {
                      _referenceRangesExpanded = expanded;
                    },
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    leading: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Rangos de referencia',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      _referenceRangesSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    backgroundColor: theme.colorScheme.surfaceContainerLowest,
                    collapsedBackgroundColor: theme.colorScheme.surfaceContainerLowest,
                    children: [
                      ReferenceValuesEditor(
                        values: _referenceValues,
                        onChanged: (updated) {
                          setState(() => _referenceValues = updated);
                        },
                        unitOfMeasure: _unitController.text.trim(),
                        showTitle: false,
                      ),
                    ],
                  ),
                ] else if (_dataType == 'qualitative') ...[
                  // Presets rápidos
                  Text(
                    'Plantillas rápidas:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _qualitativePresets.map((preset) {
                      return ActionChip(
                        avatar: const Icon(Icons.flash_on, size: 14),
                        label: Text(
                          preset['label'] as String,
                          style: const TextStyle(fontSize: 11),
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() {
                            final optsStr = preset['options'] as String;
                            final expStr = preset['expected'] as String;
                            _qualitativeOptionsController.text = optsStr;
                            _updateQualitativeOptionsFromText(optsStr);
                            _expectedQualitativeValue = expStr;
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
                      prefixIcon: Icon(Icons.list_alt, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (_dataType == 'qualitative') {
                        final parsed = (v ?? '')
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty);
                        if (parsed.isEmpty) {
                          return 'Ingresa al menos una opción';
                        }
                      }
                      return null;
                    },
                    onChanged: (val) {
                      setState(() {
                        _updateQualitativeOptionsFromText(val);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_qualitativeOptions.isNotEmpty)
                    DropdownButtonFormField<String>(
                      key: ValueKey('dialog_expected_$_expectedQualitativeValue'),
                      initialValue: _qualitativeOptions.contains(_expectedQualitativeValue)
                          ? _expectedQualitativeValue
                          : _qualitativeOptions.first,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Valor Normal / Esperado *',
                        helperText: 'Cualquier resultado distinto marcará alerta médica (ANORMAL)',
                        prefixIcon: Icon(Icons.check_circle_outline, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: _qualitativeOptions.toSet().map((opt) {
                        return DropdownMenuItem<String>(
                          value: opt,
                          child: Text(opt, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _expectedQualitativeValue = val ?? '';
                        });
                      },
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ingrese al menos una opción en el campo superior para seleccionar el valor esperado.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notes_rounded, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Para resultados descriptivos o patológicos, especifique abajo las notas de referencia o criterios.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Notas / Escala de Referencia Explicativa Universal (Opcional)
                TextFormField(
                  controller: _referenceTextController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notas de Referencia / Escala Explicativa (Opcional)',
                    hintText:
                        'Ej. - Menor de 5.6%: Nivel no diabético\n- 5.7 - 6.4%: Nivel prediabético...',
                    helperText:
                        'Opcional. Permite mostrar escalas clínicas complejas o notas multilínea en órdenes e impresiones.',
                    isDense: true,
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
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
          label: Text(
            _isSubmitting ? 'Guardando...' : (_isEditing ? 'Guardar Cambios' : 'Crear y Agregar'),
          ),
        ),
      ],
    );
  }
}
