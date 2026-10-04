import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import '../../../cubits/lab_test_cubit/write_lab_tests_cubit.dart';
import 'pack_test_selector.dart';

class LabTestFormDialog extends StatefulWidget {
  final LabTestInDb? labTest;

  const LabTestFormDialog({super.key, this.labTest});

  @override
  State<LabTestFormDialog> createState() => _LabTestFormDialogState();
}

class _LabTestFormDialogState extends State<LabTestFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _code;
  late String _commercialCategory;
  late double _salePrice;
  late double _salePrice2;
  late bool _isPack;
  late List<String> _childTestIds;
  late String _dataType;
  late String _unitOfMeasure;
  late List<ReferenceValue> _referenceValues;
  late List<String> _qualitativeOptions;
  late String _expectedQualitativeValue;

  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _price2Controller = TextEditingController();

  static const List<String> _commonCategories = [
    'Bioquímica Clínica',
    'Hematología',
    'Inmunología',
    'Urianálisis',
    'Coprología',
    'Microbiología',
    'Endocrinología / Hormonas',
    'Perfiles Especiales',
  ];

  static const List<String> _commonUnits = [
    'mg/dL',
    'g/dL',
    'µL',
    'mm/h',
    '%',
    'UI/L',
    'ng/mL',
    'mmol/L',
    'x10^3/µL',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.labTest != null) {
      _name = widget.labTest!.name;
      _code = widget.labTest!.code ?? '';
      _commercialCategory = widget.labTest!.commercialCategory;
      _salePrice = widget.labTest!.salePrice / 100.0;
      _salePrice2 = widget.labTest!.salePrice2 / 100.0;
      _isPack = widget.labTest!.isPack;
      _childTestIds = List.from(widget.labTest!.childTestIds);
      _dataType = widget.labTest!.dataType;
      _unitOfMeasure = widget.labTest!.unitOfMeasure;
      _referenceValues = List.from(widget.labTest!.referenceValues);
      _qualitativeOptions = List.from(widget.labTest!.qualitativeOptions);
      _expectedQualitativeValue = widget.labTest!.expectedQualitativeValue ?? '';
    } else {
      _name = '';
      _code = '';
      _commercialCategory = 'Bioquímica Clínica';
      _salePrice = 0.0;
      _salePrice2 = 0.0;
      _isPack = false;
      _childTestIds = [];
      _dataType = 'numeric';
      _unitOfMeasure = 'mg/dL';
      _referenceValues = [
        ReferenceValue(
          patientType: 'general',
          gender: 'both',
          minAgeDays: 0,
          maxAgeDays: 36500,
          minValue: 70.0,
          maxValue: 100.0,
        ),
      ];
      _qualitativeOptions = ['Negativo', 'Positivo'];
      _expectedQualitativeValue = 'Negativo';
    }

    _categoryController.text = _commercialCategory;
    _unitController.text = _unitOfMeasure;
    _priceController.text = _salePrice > 0 ? _salePrice.toStringAsFixed(2) : '';
    _price2Controller.text = _salePrice2 > 0 ? _salePrice2.toStringAsFixed(2) : '';
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _price2Controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final cubit = context.read<WriteLabTestCubit>();
      final priceInCents = (_salePrice * 100).round();
      final price2InCents = (_salePrice2 * 100).round();

      if (widget.labTest == null) {
        final newTest = CreateLabTest(
          name: _name.trim(),
          code: _code.trim().isNotEmpty ? _code.trim() : null,
          commercialCategory: _commercialCategory.trim(),
          salePrice: priceInCents,
          salePrice2: price2InCents,
          isPack: _isPack,
          childTestIds: _isPack ? _childTestIds : [],
          dataType: _isPack ? 'pack' : _dataType,
          unitOfMeasure: !_isPack && _dataType == 'numeric' ? _unitOfMeasure.trim() : '',
          referenceValues: !_isPack && _dataType == 'numeric' ? _referenceValues : [],
          qualitativeOptions: !_isPack && _dataType == 'boolean' ? _qualitativeOptions : [],
          expectedQualitativeValue:
              !_isPack && _dataType == 'boolean' && _expectedQualitativeValue.isNotEmpty
              ? _expectedQualitativeValue.trim()
              : null,
        );
        cubit.create(newTest).then((_) {
          if (!mounted) return;
          Navigator.pop(context, true);
        });
      } else {
        final updateTest = UpdateLabTest(
          name: _name.trim(),
          code: _code.trim().isNotEmpty ? _code.trim() : null,
          commercialCategory: _commercialCategory.trim(),
          salePrice: priceInCents,
          salePrice2: price2InCents,
          isPack: _isPack,
          childTestIds: _isPack ? _childTestIds : [],
          dataType: _isPack ? 'pack' : _dataType,
          unitOfMeasure: !_isPack && _dataType == 'numeric' ? _unitOfMeasure.trim() : '',
          referenceValues: !_isPack && _dataType == 'numeric' ? _referenceValues : [],
          qualitativeOptions: !_isPack && _dataType == 'boolean' ? _qualitativeOptions : [],
          expectedQualitativeValue:
              !_isPack && _dataType == 'boolean' && _expectedQualitativeValue.isNotEmpty
              ? _expectedQualitativeValue.trim()
              : null,
        );
        cubit.update(widget.labTest!.id, updateTest).then((_) {
          if (!mounted) return;
          Navigator.pop(context, true);
        });
      }
    }
  }

  void _addReferenceValue() {
    setState(() {
      _referenceValues.add(
        ReferenceValue(
          patientType: 'general',
          gender: 'both',
          minAgeDays: 0,
          maxAgeDays: 36500,
          minValue: 0.0,
          maxValue: 100.0,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.labTest != null;
    final theme = Theme.of(context);
    final readState = context.watch<ReadLabTestCubit>().state;
    final allAvailableTests = (readState is ReadLabTestSuccess)
        ? readState.items.where((t) => !t.isPack && t.id != widget.labTest?.id).toList()
        : <LabTestInDb>[];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPack ? Icons.inventory_2_outlined : Icons.science_outlined,
                    color: theme.colorScheme.primary,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Editar Prueba / Pack' : 'Registrar Nueva Prueba / Pack',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        _isPack
                            ? 'Configure un paquete comercial con múltiples análisis individuales'
                            : 'Configure un parámetro clínico individual con sus rangos de referencia',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Modal Body with Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selector de Tipo: Individual vs Pack
                      Center(
                        child: SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text('Análisis Individual'),
                              icon: Icon(Icons.science),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text('Pack / Perfil Compuesto'),
                              icon: Icon(Icons.inventory_2),
                            ),
                          ],
                          selected: {_isPack},
                          onSelectionChanged: (set) {
                            setState(() => _isPack = set.first);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // SECCIÓN 1: DATOS GENERALES
                      Text(
                        '1. Información General del Análisis',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: _name,
                              decoration: InputDecoration(
                                labelText: _isPack
                                    ? 'Nombre del Pack / Perfil *'
                                    : 'Nombre del Análisis *',
                                hintText: _isPack
                                    ? 'ej. Perfil Lipídico Completo'
                                    : 'ej. Glucosa Sérica',
                                prefixIcon: const Icon(Icons.drive_file_rename_outline, size: 20),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Requerido' : null,
                              onSaved: (val) => _name = val ?? '',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: _code,
                              decoration: const InputDecoration(
                                labelText: 'Código / Clave',
                                hintText: 'ej. GLU-01',
                                prefixIcon: Icon(Icons.tag, size: 20),
                              ),
                              onSaved: (val) => _code = val ?? '',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _categoryController,
                                  decoration: const InputDecoration(
                                    labelText: 'Categoría Comercial / Especialidad *',
                                    hintText: 'ej. Bioquímica Clínica',
                                    prefixIcon: Icon(Icons.category_outlined, size: 20),
                                  ),
                                  validator: (val) =>
                                      val == null || val.trim().isEmpty ? 'Requerido' : null,
                                  onSaved: (val) => _commercialCategory = val ?? '',
                                ),
                                const SizedBox(height: 6),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: _commonCategories.map((cat) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: ActionChip(
                                          label: Text(cat, style: const TextStyle(fontSize: 10)),
                                          onPressed: () {
                                            setState(() {
                                              _categoryController.text = cat;
                                              _commercialCategory = cat;
                                            });
                                          },
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Precio 1 (\$ USD) *',
                                hintText: 'Tarifa regular',
                                prefixIcon: Icon(Icons.attach_money, size: 20),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Requerido';
                                final parsed = double.tryParse(val);
                                if (parsed == null || parsed < 0) return 'Precio inválido';
                                return null;
                              },
                              onChanged: (val) {
                                final parsed = double.tryParse(val);
                                if (parsed != null) {
                                  setState(() => _salePrice = parsed);
                                }
                              },
                              onSaved: (val) => _salePrice = double.tryParse(val ?? '0') ?? 0.0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _price2Controller,
                              decoration: const InputDecoration(
                                labelText: 'Precio 2 (\$ USD)',
                                hintText: 'Tarifa especial',
                                prefixIcon: Icon(Icons.attach_money, size: 20),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (val) {
                                if (val != null && val.trim().isNotEmpty) {
                                  final parsed = double.tryParse(val);
                                  if (parsed == null || parsed < 0) return 'Precio inválido';
                                }
                                return null;
                              },
                              onChanged: (val) {
                                final parsed = double.tryParse(val);
                                if (parsed != null) {
                                  setState(() => _salePrice2 = parsed);
                                }
                              },
                              onSaved: (val) => _salePrice2 = double.tryParse(val ?? '0') ?? 0.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // SECCIÓN 2: DEPENDIENTE DEL MODO (PACK VS INDIVIDUAL)
                      if (_isPack) ...[
                        Text(
                          '2. Selección de Análisis para este Pack',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Filtre y elija los análisis clínicos que formarán parte de este perfil comercial.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        PackTestSelector(
                          availableTests: allAvailableTests,
                          selectedTestIds: _childTestIds,
                          packSalePrice: _salePrice,
                          onSelectionChanged: (updated) {
                            setState(() => _childTestIds = updated);
                          },
                        ),
                      ] else ...[
                        Text(
                          '2. Configuración Analítica y Rangos de Referencia',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _dataType,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de Resultado',
                                  prefixIcon: Icon(Icons.biotech, size: 20),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'numeric',
                                    child: Text('Numérico (Unidad y Rangos Mín/Máx)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'boolean',
                                    child: Text(
                                      'Cualitativo / Booleano (Sí/No, Positivo/Negativo)',
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'text',
                                    child: Text('Texto Libre / Observaciones'),
                                  ),
                                ],
                                onChanged: (val) => setState(() => _dataType = val ?? 'numeric'),
                              ),
                            ),
                            if (_dataType == 'numeric') ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      controller: _unitController,
                                      decoration: const InputDecoration(
                                        labelText: 'Unidad de Medida *',
                                        hintText: 'ej. mg/dL',
                                        prefixIcon: Icon(Icons.straighten, size: 20),
                                      ),
                                      validator: (val) =>
                                          _dataType == 'numeric' &&
                                              (val == null || val.trim().isEmpty)
                                          ? 'Requerido'
                                          : null,
                                      onSaved: (val) => _unitOfMeasure = val ?? '',
                                    ),
                                    const SizedBox(height: 6),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: _commonUnits.map((u) {
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 6),
                                            child: ActionChip(
                                              label: Text(u, style: const TextStyle(fontSize: 10)),
                                              onPressed: () {
                                                setState(() {
                                                  _unitController.text = u;
                                                  _unitOfMeasure = u;
                                                });
                                              },
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Editor de Rangos Numéricos
                        if (_dataType == 'numeric') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tabla de Rangos de Referencia:',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _addReferenceValue,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Agregar Rango'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_referenceValues.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'Haga clic en "+ Agregar Rango" para definir los límites de normalidad.',
                                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _referenceValues.length,
                              itemBuilder: (context, index) {
                                final ref = _referenceValues[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: theme.colorScheme.outlineVariant),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: DropdownButtonFormField<String>(
                                          initialValue: ref.gender,
                                          isDense: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Género',
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: 'both', child: Text('Ambos')),
                                            DropdownMenuItem(
                                              value: 'male',
                                              child: Text('Masculino'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'female',
                                              child: Text('Femenino'),
                                            ),
                                          ],
                                          onChanged: (val) {
                                            setState(() {
                                              _referenceValues[index] = ReferenceValue(
                                                patientType: ref.patientType,
                                                gender: val ?? 'both',
                                                minAgeDays: ref.minAgeDays,
                                                maxAgeDays: ref.maxAgeDays,
                                                minValue: ref.minValue,
                                                maxValue: ref.maxValue,
                                              );
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          initialValue: ref.minValue.toString(),
                                          decoration: const InputDecoration(
                                            labelText: 'Mínimo',
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (val) {
                                            final parsed = double.tryParse(val) ?? 0.0;
                                            _referenceValues[index] = ReferenceValue(
                                              patientType: ref.patientType,
                                              gender: ref.gender,
                                              minAgeDays: ref.minAgeDays,
                                              maxAgeDays: ref.maxAgeDays,
                                              minValue: parsed,
                                              maxValue: ref.maxValue,
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          initialValue: ref.maxValue.toString(),
                                          decoration: const InputDecoration(
                                            labelText: 'Máximo',
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (val) {
                                            final parsed = double.tryParse(val) ?? 0.0;
                                            _referenceValues[index] = ReferenceValue(
                                              patientType: ref.patientType,
                                              gender: ref.gender,
                                              minAgeDays: ref.minAgeDays,
                                              maxAgeDays: ref.maxAgeDays,
                                              minValue: ref.minValue,
                                              maxValue: parsed,
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () =>
                                            setState(() => _referenceValues.removeAt(index)),
                                        color: theme.colorScheme.error,
                                        tooltip: 'Eliminar rango',
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],

                        // Editor Cualitativo
                        if (_dataType == 'boolean') ...[
                          TextFormField(
                            initialValue: _qualitativeOptions.join(', '),
                            decoration: const InputDecoration(
                              labelText: 'Opciones de Resultado (separadas por coma)',
                              hintText: 'ej. Negativo, Positivo',
                              prefixIcon: Icon(Icons.list_alt, size: 20),
                            ),
                            onChanged: (val) {
                              _qualitativeOptions = val
                                  .split(',')
                                  .map((e) => e.trim())
                                  .where((e) => e.isNotEmpty)
                                  .toList();
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: _expectedQualitativeValue,
                            decoration: const InputDecoration(
                              labelText: 'Valor Normal / Esperado',
                              hintText: 'ej. Negativo',
                              prefixIcon: Icon(Icons.check_circle_outline, size: 20),
                            ),
                            onSaved: (val) => _expectedQualitativeValue = val ?? '',
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Modal Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const Spacer(),
                  BlocBuilder<WriteLabTestCubit, WriteLabTestState>(
                    builder: (context, state) {
                      if (state is WritingLabTest) {
                        return const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      return ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.save, size: 18),
                        label: Text(isEdit ? 'Guardar Cambios' : 'Registrar Prueba'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
