import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:serum_business/serum_business.dart';

import '../controllers/reference_values_validator.dart';

/// Editor reutilizable de rangos de referencia para pruebas de laboratorio.
///
/// Mantiene los flags `useAge` / `useGender` a nivel de prueba (aplicados a
/// todos los rangos) y expone un único selector de unidad de edad por rango.
/// La unidad es solo de presentación: los límites siempre se reportan en días.
class ReferenceValuesEditor extends StatelessWidget {
  final List<ReferenceValue> values;
  final ValueChanged<List<ReferenceValue>> onChanged;
  final String unitOfMeasure;
  final bool showTitle;

  const ReferenceValuesEditor({
    super.key,
    required this.values,
    required this.onChanged,
    required this.unitOfMeasure,
    this.showTitle = true,
  });

  bool get _usesAge => ReferenceValuesValidator.usesAge(values);
  bool get _usesGender => ReferenceValuesValidator.usesGender(values);

  void _setUseAge(bool value) {
    if (values.isEmpty) return;
    onChanged(
      values.map((ref) => ref.copyWith(useAge: value)).toList(growable: false),
    );
  }

  void _setUseGender(bool value) {
    if (values.isEmpty) return;
    onChanged(
      values.map((ref) => ref.copyWith(useGender: value)).toList(growable: false),
    );
  }

  void _addRange() {
    onChanged([
      ...values,
      ReferenceValue(
        patientType: 'general',
        gender: 'both',
        minAgeDays: 0,
        maxAgeDays: 36500,
        minValue: 0.0,
        maxValue: 100.0,
        ageUnit: 'years',
        useAge: _usesAge,
        useGender: _usesGender,
      ),
    ]);
  }

  void _updateRange(int index, ReferenceValue ref) {
    final updated = List<ReferenceValue>.of(values);
    updated[index] = ref;
    onChanged(updated);
  }

  void _removeRange(int index) {
    final updated = List<ReferenceValue>.of(values)..removeAt(index);
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validation = ReferenceValuesValidator.validate(values);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          Text(
            'Rangos de Referencia',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],
        _ReferenceEvaluationSwitches(
          valueAge: _usesAge,
          valueGender: _usesGender,
          enabled: values.isNotEmpty,
          onChangedAge: _setUseAge,
          onChangedGender: _setUseGender,
        ),
        const SizedBox(height: 16),
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
              key: const ValueKey('ref_add_range'),
              onPressed: _addRange,
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
        if (values.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Haga clic en "+ Agregar Rango" para definir los límites de normalidad.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          for (var i = 0; i < values.length; i++)
            _ReferenceRangeCard(
              key: ValueKey(i),
              index: i,
              ref: values[i],
              usesAge: _usesAge,
              usesGender: _usesGender,
              unitOfMeasure: unitOfMeasure,
              onChanged: (ref) => _updateRange(i, ref),
              onDelete: () => _removeRange(i),
            ),
        if (validation.error != null) ...[
          const SizedBox(height: 8),
          _ReferenceMessage(
            key: const ValueKey('reference_values_error'),
            icon: Icons.error_outline,
            color: theme.colorScheme.error,
            text: validation.error!,
          ),
        ],
        if (validation.warning != null) ...[
          const SizedBox(height: 8),
          _ReferenceMessage(
            key: const ValueKey('reference_values_warning'),
            icon: Icons.warning_amber_rounded,
            color: Colors.amber.shade900,
            text: validation.warning!,
          ),
        ],
      ],
    );
  }
}

class _ReferenceEvaluationSwitches extends StatelessWidget {
  final bool valueAge;
  final bool valueGender;
  final bool enabled;
  final ValueChanged<bool> onChangedAge;
  final ValueChanged<bool> onChangedGender;

  const _ReferenceEvaluationSwitches({
    required this.valueAge,
    required this.valueGender,
    required this.enabled,
    required this.onChangedAge,
    required this.onChangedGender,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evaluación de referencia',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Activa solo las dimensiones que esta prueba necesita evaluar. '
            'Si ambas están desactivadas, el rango aplica a cualquier paciente.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 18,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ReferenceSwitch(
                key: const ValueKey('ref_use_age'),
                label: 'Rangos por edad',
                value: valueAge,
                enabled: enabled,
                onChanged: onChangedAge,
              ),
              _ReferenceSwitch(
                key: const ValueKey('ref_use_gender'),
                label: 'Rangos por género',
                value: valueGender,
                enabled: enabled,
                onChanged: onChangedGender,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReferenceSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ReferenceSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch.adaptive(
          value: value,
          onChanged: enabled ? onChanged : null,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: enabled ? null : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

InputDecoration _referenceFieldDecoration({
  required String labelText,
  String? suffixText,
  bool enabled = true,
  InputBorder? disabledBorder,
}) {
  return InputDecoration(
    labelText: labelText,
    suffixText: suffixText,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 8,
    ),
    border: const OutlineInputBorder(),
    enabled: enabled,
    disabledBorder: disabledBorder,
    constraints: const BoxConstraints(
      minHeight: 44,
      maxHeight: 44,
    ),
  );
}

class _ReferenceRangeCard extends StatefulWidget {
  final int index;
  final ReferenceValue ref;
  final bool usesAge;
  final bool usesGender;
  final String unitOfMeasure;
  final ValueChanged<ReferenceValue> onChanged;
  final VoidCallback onDelete;

  const _ReferenceRangeCard({
    super.key,
    required this.index,
    required this.ref,
    required this.usesAge,
    required this.usesGender,
    required this.unitOfMeasure,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_ReferenceRangeCard> createState() => _ReferenceRangeCardState();
}

class _ReferenceRangeCardState extends State<_ReferenceRangeCard> {
  static const String _unitDays = 'days';
  static const String _unitMonths = 'months';
  static const String _unitYears = 'years';

  late final TextEditingController _minAgeController;
  late final TextEditingController _maxAgeController;
  late final TextEditingController _minValueController;
  late final TextEditingController _maxValueController;
  late final FocusNode _minAgeFocus;
  late final FocusNode _maxAgeFocus;
  late final FocusNode _minValueFocus;
  late final FocusNode _maxValueFocus;

  late ReferenceValue _lastRef;

  @override
  void initState() {
    super.initState();
    _lastRef = widget.ref;
    _minAgeController = TextEditingController(
      text: _formatAge(widget.ref.minAgeDays, _ageUnit),
    );
    _maxAgeController = TextEditingController(
      text: _formatAge(widget.ref.maxAgeDays, _ageUnit),
    );
    _minValueController = TextEditingController(
      text: _formatNumber(widget.ref.minValue),
    );
    _maxValueController = TextEditingController(
      text: _formatNumber(widget.ref.maxValue),
    );
    _minAgeFocus = FocusNode();
    _maxAgeFocus = FocusNode();
    _minValueFocus = FocusNode();
    _maxValueFocus = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _ReferenceRangeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.ref;
    if (_sameReference(next, _lastRef)) return;

    _lastRef = next;
    _syncIfUnfocused(
      _minAgeController,
      _minAgeFocus,
      _formatAge(next.minAgeDays, _ageUnit),
    );
    _syncIfUnfocused(
      _maxAgeController,
      _maxAgeFocus,
      _formatAge(next.maxAgeDays, _ageUnit),
    );
    _syncIfUnfocused(
      _minValueController,
      _minValueFocus,
      _formatNumber(next.minValue),
    );
    _syncIfUnfocused(
      _maxValueController,
      _maxValueFocus,
      _formatNumber(next.maxValue),
    );
  }

  @override
  void dispose() {
    _minAgeController.dispose();
    _maxAgeController.dispose();
    _minValueController.dispose();
    _maxValueController.dispose();
    _minAgeFocus.dispose();
    _maxAgeFocus.dispose();
    _minValueFocus.dispose();
    _maxValueFocus.dispose();
    super.dispose();
  }

  String get _ageUnit {
    switch (_lastRef.ageUnit) {
      case _unitDays:
      case _unitMonths:
      case _unitYears:
        return _lastRef.ageUnit;
      default:
        return _unitYears;
    }
  }

  double get _ageFactor {
    switch (_ageUnit) {
      case _unitDays:
        return 1;
      case _unitMonths:
        return 30;
      default:
        return 365;
    }
  }

  void _emit(ReferenceValue updated) {
    _lastRef = updated;
    widget.onChanged(updated);
  }

  void _onAgeUnitChanged(String? newUnit) {
    if (newUnit == null || newUnit == _lastRef.ageUnit) return;

    final updated = _lastRef.copyWith(ageUnit: newUnit);
    setState(() {
      _lastRef = updated;
      _minAgeController.text = _formatAge(updated.minAgeDays, newUnit);
      _maxAgeController.text = _formatAge(updated.maxAgeDays, newUnit);
    });
    widget.onChanged(updated);
  }

  void _onMinAgeChanged(String text) {
    final parsed = double.tryParse(text.trim());
    if (parsed == null || parsed < 0) return;
    _emit(_lastRef.copyWith(minAgeDays: (parsed * _ageFactor).round()));
  }

  void _onMaxAgeChanged(String text) {
    final parsed = double.tryParse(text.trim());
    if (parsed == null || parsed < 0) return;
    _emit(_lastRef.copyWith(maxAgeDays: (parsed * _ageFactor).round()));
  }

  void _onMinValueChanged(String text) {
    final parsed = double.tryParse(text.trim());
    if (parsed == null) return;
    _emit(_lastRef.copyWith(minValue: parsed));
  }

  void _onMaxValueChanged(String text) {
    final parsed = double.tryParse(text.trim());
    if (parsed == null) return;
    _emit(_lastRef.copyWith(maxValue: parsed));
  }

  void _onGenderChanged(String? gender) {
    _emit(_lastRef.copyWith(gender: gender ?? 'both'));
  }

  void _syncIfUnfocused(
    TextEditingController controller,
    FocusNode focusNode,
    String text,
  ) {
    if (!focusNode.hasFocus && controller.text != text) {
      controller.text = text;
    }
  }

  bool _sameReference(ReferenceValue a, ReferenceValue b) {
    return a.patientType == b.patientType &&
        a.gender == b.gender &&
        a.minAgeDays == b.minAgeDays &&
        a.maxAgeDays == b.maxAgeDays &&
        a.minValue == b.minValue &&
        a.maxValue == b.maxValue &&
        a.ageUnit == b.ageUnit &&
        a.useAge == b.useAge &&
        a.useGender == b.useGender;
  }

  String _formatAge(int days, String unit) {
    final factor = switch (unit) {
      _unitDays => 1,
      _unitMonths => 30,
      _ => 365,
    };
    return _formatNumber(days / factor);
  }

  String _formatNumber(num value) {
    final doubleValue = value.toDouble();
    if (doubleValue == doubleValue.roundToDouble()) {
      return doubleValue.toInt().toString();
    }
    return doubleValue
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Rango ${widget.index + 1}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                key: ValueKey('ref_delete_${widget.index}'),
                icon: const Icon(Icons.delete_outline),
                onPressed: widget.onDelete,
                color: theme.colorScheme.error,
                tooltip: 'Eliminar rango',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              SizedBox(
                key: ValueKey('ref_gender_${widget.index}'),
                width: 160,
                child: widget.usesGender
                    ? DropdownButtonFormField<String>(
                        key: ValueKey(
                          'ref_gender_field_${widget.index}_${_lastRef.gender}',
                        ),
                        initialValue: _normalizeGenderForDisplay(_lastRef.gender),
                        isDense: true,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        style: theme.textTheme.bodyMedium,
                        decoration: _referenceFieldDecoration(
                          labelText: 'Género',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'both',
                            child: Text('Ambos'),
                          ),
                          DropdownMenuItem(
                            value: 'male',
                            child: Text('Masculino'),
                          ),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('Femenino'),
                          ),
                        ],
                        onChanged: _onGenderChanged,
                      )
                    : const _DisabledReferenceField(
                        label: 'Género',
                        value: 'Ambos',
                      ),
              ),
              if (widget.usesAge) ...[
                SizedBox(
                  key: ValueKey('ref_age_unit_${widget.index}'),
                  width: 130,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(
                      'ref_age_unit_field_${widget.index}_$_ageUnit',
                    ),
                    initialValue: _ageUnit,
                    isDense: true,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    style: theme.textTheme.bodyMedium,
                    decoration: _referenceFieldDecoration(
                      labelText: 'Unidad de Edad',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: _unitDays,
                        child: Text('Días'),
                      ),
                      DropdownMenuItem(
                        value: _unitMonths,
                        child: Text('Meses'),
                      ),
                      DropdownMenuItem(
                        value: _unitYears,
                        child: Text('Años'),
                      ),
                    ],
                    onChanged: _onAgeUnitChanged,
                  ),
                ),
                SizedBox(
                  width: 145,
                  child: TextFormField(
                    key: ValueKey('ref_min_age_${widget.index}'),
                    controller: _minAgeController,
                    focusNode: _minAgeFocus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: _referenceFieldDecoration(
                      labelText: 'Edad mínima',
                    ),
                    validator: _validateMinAge,
                    onChanged: _onMinAgeChanged,
                  ),
                ),
                SizedBox(
                  width: 145,
                  child: TextFormField(
                    key: ValueKey('ref_max_age_${widget.index}'),
                    controller: _maxAgeController,
                    focusNode: _maxAgeFocus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: _referenceFieldDecoration(
                      labelText: 'Edad máxima',
                    ),
                    validator: _validateMaxAge,
                    onChanged: _onMaxAgeChanged,
                  ),
                ),
              ] else
                const SizedBox(
                  width: 440,
                  child: _DisabledReferenceField(
                    label: 'Edad',
                    value: 'Todas las edades',
                  ),
                ),
              SizedBox(
                width: 130,
                child: TextFormField(
                  key: ValueKey('ref_min_value_${widget.index}'),
                  controller: _minValueController,
                  focusNode: _minValueFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _referenceFieldDecoration(
                    labelText: 'Mínimo',
                    suffixText: widget.unitOfMeasure.trim().isEmpty
                        ? null
                        : widget.unitOfMeasure.trim(),
                  ),
                  validator: _validateRequiredNumber,
                  onChanged: _onMinValueChanged,
                ),
              ),
              SizedBox(
                width: 130,
                child: TextFormField(
                  key: ValueKey('ref_max_value_${widget.index}'),
                  controller: _maxValueController,
                  focusNode: _maxValueFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _referenceFieldDecoration(
                    labelText: 'Máximo',
                    suffixText: widget.unitOfMeasure.trim().isEmpty
                        ? null
                        : widget.unitOfMeasure.trim(),
                  ),
                  validator: _validateRequiredNumber,
                  onChanged: _onMaxValueChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _validateRequiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Requerido';
    if (double.tryParse(value.trim()) == null) return 'Valor inválido';
    return null;
  }

  String? _validateMinAge(String? value) {
    if (!widget.usesAge) return null;
    final parsed = _parseAge(value);
    if (parsed == null) return 'Requerido';
    if (parsed < 0) return 'No puede ser negativa';
    final max = double.tryParse(_maxAgeController.text.trim());
    if (max != null && parsed > max) return 'Debe ser ≤ máxima';
    return null;
  }

  String? _validateMaxAge(String? value) {
    if (!widget.usesAge) return null;
    final parsed = _parseAge(value);
    if (parsed == null) return 'Requerido';
    if (parsed < 0) return 'No puede ser negativa';
    final min = double.tryParse(_minAgeController.text.trim());
    if (min != null && parsed < min) return 'Debe ser ≥ mínima';
    return null;
  }

  double? _parseAge(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }
}

class _DisabledReferenceField extends StatelessWidget {
  final String label;
  final String value;

  const _DisabledReferenceField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InputDecorator(
      decoration: _referenceFieldDecoration(
        labelText: label,
        enabled: false,
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ReferenceMessage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _ReferenceMessage({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

String _normalizeGenderForDisplay(String raw) {
  final normalized = ReferenceValueResolver.normalizeGender(raw);
  if (normalized == 'male' || normalized == 'female') return normalized;
  return 'both';
}
