import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import '../widgets/clinical_classification_registry.dart';
import 'reference_values_validator.dart';

/// Controlador de estado local para la pantalla de formulario de estudios clínicos y perfiles/packs.
/// Sigue la arquitectura ViewController del estándar OKF v0.2.
class LabTestFormViewController extends ChangeNotifier {
  final LabTestInDb? initialLabTest;

  late final TextEditingController nameController;
  late final TextEditingController codeController;
  late final TextEditingController categoryController;
  late final TextEditingController customCategoryController;
  late final TextEditingController customSubclassController;
  late final TextEditingController unitController;
  late final TextEditingController priceController;
  late final TextEditingController price2Controller;
  late final TextEditingController qualitativeOptionsController;
  late final TextEditingController referenceTextController;

  late String _commercialCategory;
  late String _subclassification;
  late bool _isCustomCategory;
  late bool _isCustomSubclass;
  late bool _isProfileParameter;
  late double _salePrice;
  late double _salePrice2;
  late bool _isPack;
  late bool _useChildTestsPriceSum;
  late List<String> _childTestIds;
  late String _dataType;
  late String _unitOfMeasure;
  late List<ReferenceValue> _referenceValues;
  late List<String> _qualitativeOptions;
  late String _expectedQualitativeValue;

  static const List<Map<String, dynamic>> qualitativePresets = [
    {
      'label': 'Negativo / Positivo',
      'options': ['Negativo', 'Positivo'],
      'expected': 'Negativo',
    },
    {
      'label': 'Sedimento Urinario (No se observó, Escasas...)',
      'options': ['No se observó', 'Escasas', 'Moderadas', 'Abundantes'],
      'expected': 'No se observó',
    },
    {
      'label': 'Escala de Cruces (Negativo, Trazas, +, ++, +++)',
      'options': ['Negativo', 'Trazas', '+', '++', '+++'],
      'expected': 'Negativo',
    },
    {
      'label': 'Normal / Alterado',
      'options': ['Normal', 'Alterado'],
      'expected': 'Normal',
    },
  ];

  static const List<String> commonUnits = [
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

  static String normalizeGender(String raw) {
    final normalized = ReferenceValueResolver.normalizeGender(raw);
    if (normalized == 'male' || normalized == 'female') return normalized;
    return 'both';
  }

  LabTestFormViewController({this.initialLabTest}) {
    nameController = TextEditingController();
    codeController = TextEditingController();
    categoryController = TextEditingController();
    customCategoryController = TextEditingController();
    customSubclassController = TextEditingController();
    unitController = TextEditingController();
    priceController = TextEditingController();
    price2Controller = TextEditingController();
    qualitativeOptionsController = TextEditingController();
    referenceTextController = TextEditingController();

    _isCustomCategory = false;
    _isCustomSubclass = false;

    if (initialLabTest != null) {
      final t = initialLabTest!;
      nameController.text = t.name;
      codeController.text = t.code ?? '';
      _commercialCategory = t.commercialCategory;
      _subclassification = t.subclassification;
      _isProfileParameter = t.isProfileParameter;
      _salePrice = t.salePrice / 100.0;
      _salePrice2 = t.salePrice2 / 100.0;
      _isPack = t.isPack;
      _useChildTestsPriceSum = t.useChildTestsPriceSum;
      _childTestIds = List<String>.from(t.childTestIds);

      final rawType = t.dataType.trim().toLowerCase();
      if (rawType == 'boolean' || rawType == 'qualitative') {
        _dataType = 'qualitative';
      } else if (rawType == 'text') {
        _dataType = 'text';
      } else {
        _dataType = 'numeric';
      }

      _unitOfMeasure = t.unitOfMeasure;
      _referenceValues = t.referenceValues.map((ref) {
        return ReferenceValue(
          patientType: ref.patientType,
          gender: normalizeGender(ref.gender),
          minAgeDays: ref.minAgeDays,
          maxAgeDays: ref.maxAgeDays,
          minValue: ref.minValue,
          maxValue: ref.maxValue,
          ageUnit: ref.ageUnit,
          useAge: ref.useAge,
          useGender: ref.useGender,
        );
      }).toList();

      _qualitativeOptions = List<String>.from(t.qualitativeOptions);
      _expectedQualitativeValue = t.expectedQualitativeValue ?? '';
      referenceTextController.text = t.referenceText;
    } else {
      nameController.text = '';
      codeController.text = '';
      _commercialCategory = 'Hematología';
      _subclassification = 'General';
      _isProfileParameter = false;
      _salePrice = 0.0;
      _salePrice2 = 0.0;
      _isPack = false;
      _useChildTestsPriceSum = true;
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
          ageUnit: 'years',
        ),
      ];
      _qualitativeOptions = ['Negativo', 'Positivo'];
      _expectedQualitativeValue = 'Negativo';
      referenceTextController.text = '';
    }

    final allCats = ClinicalClassificationRegistry.classifications;
    if (_commercialCategory.isNotEmpty && !allCats.contains(_commercialCategory)) {
      _isCustomCategory = true;
      customCategoryController.text = _commercialCategory;
    }
    final allSubs = ClinicalClassificationRegistry.getSubclassificationsFor(
      _isCustomCategory ? customCategoryController.text : _commercialCategory,
    );
    if (_subclassification.isNotEmpty && !allSubs.contains(_subclassification)) {
      _isCustomSubclass = true;
      customSubclassController.text = _subclassification;
    }

    categoryController.text = _commercialCategory;
    unitController.text = _unitOfMeasure;
    priceController.text = _salePrice > 0 ? _salePrice.toStringAsFixed(2) : '';
    price2Controller.text = _salePrice2 > 0 ? _salePrice2.toStringAsFixed(2) : '';
    qualitativeOptionsController.text = _qualitativeOptions.join(', ');
  }

  // --- Getters de Estado ---

  bool get isEdit => initialLabTest != null;
  String get name => nameController.text.trim();
  String get code => codeController.text.trim();
  String get rawCommercialCategory => _commercialCategory;
  String get commercialCategory =>
      _isCustomCategory ? customCategoryController.text.trim() : _commercialCategory.trim();
  String get rawSubclassification => _subclassification;
  String get subclassification =>
      _isCustomSubclass ? customSubclassController.text.trim() : _subclassification.trim();
  bool get isCustomCategory => _isCustomCategory;
  bool get isCustomSubclass => _isCustomSubclass;
  bool get isProfileParameter => _isProfileParameter;
  double get salePrice => _salePrice;
  double get salePrice2 => _salePrice2;
  int get priceInCents => (_salePrice * 100).round();
  int get price2InCents => (_salePrice2 * 100).round();
  bool get isPack => _isPack;
  bool get useChildTestsPriceSum => _useChildTestsPriceSum;
  List<String> get childTestIds => List.unmodifiable(_childTestIds);
  String get dataType => _dataType;
  String get unitOfMeasure => _unitOfMeasure;
  List<ReferenceValue> get referenceValues => List.unmodifiable(_referenceValues);
  List<String> get qualitativeOptions => List.unmodifiable(_qualitativeOptions);
  String get expectedQualitativeValue => _expectedQualitativeValue;
  String get referenceText => referenceTextController.text.trim();

  /// Indica si la prueba evalúa la edad en sus rangos de referencia.
  bool get usesAge => _referenceValues.any((ref) => ref.useAge);

  /// Indica si la prueba evalúa el género en sus rangos de referencia.
  bool get usesGender => _referenceValues.any((ref) => ref.useGender);

  /// Error de configuración de los rangos de referencia.
  String? get referenceRangesError {
    if (_isPack || _dataType != 'numeric') return null;
    return ReferenceValuesValidator.errorFor(_referenceValues);
  }

  /// Advertencia de configuración ambigua de los rangos de referencia.
  String? get referenceRangesWarning {
    if (_isPack || _dataType != 'numeric') return null;
    return ReferenceValuesValidator.warningFor(_referenceValues);
  }

  // --- Cálculos Financieros y Dinámicos ---

  double calculateChildrenSum(List<LabTestInDb> allAvailableTests) {
    final selectedTests = allAvailableTests.where((t) => _childTestIds.contains(t.id)).toList();
    final totalCents = selectedTests.fold<int>(0, (sum, t) => sum + t.salePrice);
    return totalCents / 100.0;
  }

  void updateCalculatedPrice(List<LabTestInDb> allAvailableTests) {
    if (_isPack && _useChildTestsPriceSum) {
      _salePrice = calculateChildrenSum(allAvailableTests);
      priceController.text = _salePrice > 0 ? _salePrice.toStringAsFixed(2) : '0.00';
      notifyListeners();
    }
  }

  // --- Mutaciones de Estado ---

  void setIsPack(bool value, [List<LabTestInDb>? allAvailableTests]) {
    if (_isPack == value) return;
    _isPack = value;
    if (_isPack && _useChildTestsPriceSum && allAvailableTests != null) {
      _salePrice = calculateChildrenSum(allAvailableTests);
      priceController.text = _salePrice > 0 ? _salePrice.toStringAsFixed(2) : '0.00';
    }
    notifyListeners();
  }

  void setUseChildTestsPriceSum(bool value, [List<LabTestInDb>? allAvailableTests]) {
    if (_useChildTestsPriceSum == value) return;
    _useChildTestsPriceSum = value;
    if (value && allAvailableTests != null) {
      _salePrice = calculateChildrenSum(allAvailableTests);
      priceController.text = _salePrice > 0 ? _salePrice.toStringAsFixed(2) : '0.00';
    } else {
      if (_salePrice > 0) {
        priceController.text = _salePrice.toStringAsFixed(2);
      } else {
        priceController.text = '';
      }
    }
    notifyListeners();
  }

  void setCommercialCategory(String value) {
    if (value == '__custom__') {
      _isCustomCategory = true;
      _commercialCategory = '__custom__';
    } else {
      _isCustomCategory = false;
      _commercialCategory = value;
      categoryController.text = value;
      final subs = ClinicalClassificationRegistry.getSubclassificationsFor(value);
      _subclassification = subs.firstOrNull ?? 'General';
      _isCustomSubclass = false;
    }
    notifyListeners();
  }

  void setIsCustomCategory(bool value) {
    if (_isCustomCategory == value) return;
    _isCustomCategory = value;
    notifyListeners();
  }

  void setSubclassification(String value) {
    if (value == '__custom__') {
      _isCustomSubclass = true;
      _subclassification = '__custom__';
    } else {
      _isCustomSubclass = false;
      _subclassification = value;
    }
    notifyListeners();
  }

  void setIsCustomSubclass(bool value) {
    if (_isCustomSubclass == value) return;
    _isCustomSubclass = value;
    notifyListeners();
  }

  void setIsProfileParameter(bool value) {
    if (_isProfileParameter == value) return;
    _isProfileParameter = value;
    notifyListeners();
  }

  void setSalePrice(double value) {
    _salePrice = value;
    notifyListeners();
  }

  void setSalePrice2(double value) {
    _salePrice2 = value;
    notifyListeners();
  }

  void setDataType(String value) {
    if (_dataType == value) return;
    _dataType = value;
    notifyListeners();
  }

  /// Sincroniza la unidad mientras el usuario escribe en el campo de texto.
  ///
  /// No reescribe [unitController]: asignar `.text` reconstruye el
  /// [TextEditingValue] con una selección inválida y borra la composición del
  /// IME, lo que provoca que el texto se reemplace en cada pulsación.
  void updateUnitOfMeasureFromText(String value) {
    if (_unitOfMeasure == value) return;
    _unitOfMeasure = value;
    notifyListeners();
  }

  /// Aplica una unidad desde los chips de acceso rápido del formulario.
  void setUnitOfMeasure(String value) {
    _unitOfMeasure = value;
    if (unitController.text != value) {
      unitController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    notifyListeners();
  }

  void addReferenceValue([ReferenceValue? ref]) {
    final useAge = usesAge;
    final useGender = usesGender;
    _referenceValues.add(
      ref ??
          ReferenceValue(
            patientType: 'general',
            gender: 'both',
            minAgeDays: 0,
            maxAgeDays: 36500,
            minValue: 0.0,
            maxValue: 100.0,
            ageUnit: 'years',
            useAge: useAge,
            useGender: useGender,
          ),
    );
    notifyListeners();
  }

  /// Reemplaza la lista completa de rangos de referencia.
  ///
  /// Es el punto de entrada usado por el editor para mantener una única
  /// fuente de verdad en el controlador.
  void setReferenceValues(List<ReferenceValue> values) {
    _referenceValues = List<ReferenceValue>.of(values);
    notifyListeners();
  }

  /// Activa o desactiva la evaluación por edad en todos los rangos.
  void setUseAge(bool value) {
    if (_referenceValues.every((ref) => ref.useAge == value)) return;
    _referenceValues = _referenceValues.map((ref) => ref.copyWith(useAge: value)).toList();
    notifyListeners();
  }

  /// Activa o desactiva la evaluación por género en todos los rangos.
  void setUseGender(bool value) {
    if (_referenceValues.every((ref) => ref.useGender == value)) return;
    _referenceValues = _referenceValues.map((ref) => ref.copyWith(useGender: value)).toList();
    notifyListeners();
  }

  void updateReferenceValue(int index, ReferenceValue ref) {
    if (index >= 0 && index < _referenceValues.length) {
      _referenceValues[index] = ref;
      notifyListeners();
    }
  }

  void removeReferenceValueAt(int index) {
    if (index >= 0 && index < _referenceValues.length) {
      _referenceValues.removeAt(index);
      notifyListeners();
    }
  }

  void setQualitativePresets(List<String> options, String expected) {
    _qualitativeOptions = List<String>.from(options);
    _expectedQualitativeValue = expected;
    qualitativeOptionsController.text = options.join(', ');
    notifyListeners();
  }

  void updateQualitativeOptionsFromText(String rawText) {
    final parsed = rawText
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    _qualitativeOptions = parsed;
    if (!_qualitativeOptions.contains(_expectedQualitativeValue)) {
      _expectedQualitativeValue = _qualitativeOptions.isNotEmpty ? _qualitativeOptions.first : '';
    }
    notifyListeners();
  }

  void setExpectedQualitativeValue(String value) {
    _expectedQualitativeValue = value;
    notifyListeners();
  }

  void setChildTestIds(List<String> ids, [List<LabTestInDb>? allAvailableTests]) {
    _childTestIds = List<String>.from(ids);
    if (_isPack && _useChildTestsPriceSum && allAvailableTests != null) {
      _salePrice = calculateChildrenSum(allAvailableTests);
      priceController.text = _salePrice > 0 ? _salePrice.toStringAsFixed(2) : '0.00';
    }
    notifyListeners();
  }

  void addChildTestId(String id, [List<LabTestInDb>? allAvailableTests]) {
    if (!_childTestIds.contains(id)) {
      _childTestIds.add(id);
      if (_isPack && _useChildTestsPriceSum && allAvailableTests != null) {
        _salePrice = calculateChildrenSum(allAvailableTests);
        priceController.text = _salePrice > 0 ? _salePrice.toStringAsFixed(2) : '0.00';
      }
      notifyListeners();
    }
  }

  void removeChildTestId(String id, [List<LabTestInDb>? allAvailableTests]) {
    if (_childTestIds.remove(id)) {
      if (_isPack && _useChildTestsPriceSum && allAvailableTests != null) {
        _salePrice = calculateChildrenSum(allAvailableTests);
        priceController.text = _salePrice > 0 ? _salePrice.toStringAsFixed(2) : '0.00';
      }
      notifyListeners();
    }
  }

  void reorderChildTests(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _childTestIds.removeAt(oldIndex);
    _childTestIds.insert(newIndex, item);
    notifyListeners();
  }

  // --- Generación de DTOs ---

  CreateLabTest generateCreateDto({required String branchId}) {
    final finalCategory = commercialCategory;
    final finalSubclass = subclassification;
    final p1 = (double.tryParse(priceController.text) ?? _salePrice);
    final p2 = (double.tryParse(price2Controller.text) ?? _salePrice2);

    return CreateLabTest(
      branchId: branchId,
      name: name,
      code: code.isNotEmpty ? code : null,
      commercialCategory: finalCategory,
      subclassification: finalSubclass,
      salePrice: (p1 * 100).round(),
      salePrice2: (p2 * 100).round(),
      isPack: _isPack,
      useChildTestsPriceSum: _isPack ? _useChildTestsPriceSum : true,
      childTestIds: _isPack ? List<String>.from(_childTestIds) : const [],
      dataType: _isPack ? 'pack' : _dataType,
      unitOfMeasure: !_isPack && _dataType == 'numeric' ? unitController.text.trim() : '',
      referenceValues: !_isPack && _dataType == 'numeric' ? List.of(_referenceValues) : const [],
      qualitativeOptions: !_isPack && (_dataType == 'qualitative' || _dataType == 'boolean')
          ? List.of(_qualitativeOptions)
          : const [],
      expectedQualitativeValue:
          !_isPack &&
              (_dataType == 'qualitative' || _dataType == 'boolean') &&
              _expectedQualitativeValue.isNotEmpty
          ? _expectedQualitativeValue.trim()
          : null,
      referenceText: !_isPack ? referenceTextController.text.trim() : '',
      isProfileParameter: _isProfileParameter,
    );
  }

  UpdateLabTest generateUpdateDto({required String branchId}) {
    final finalCategory = commercialCategory;
    final finalSubclass = subclassification;
    final p1 = (double.tryParse(priceController.text) ?? _salePrice);
    final p2 = (double.tryParse(price2Controller.text) ?? _salePrice2);

    return UpdateLabTest(
      branchId: branchId,
      name: name,
      code: code.isNotEmpty ? code : null,
      commercialCategory: finalCategory,
      subclassification: finalSubclass,
      salePrice: (p1 * 100).round(),
      salePrice2: (p2 * 100).round(),
      isPack: _isPack,
      useChildTestsPriceSum: _isPack ? _useChildTestsPriceSum : true,
      childTestIds: _isPack ? List<String>.from(_childTestIds) : const [],
      dataType: _isPack ? 'pack' : _dataType,
      unitOfMeasure: !_isPack && _dataType == 'numeric' ? unitController.text.trim() : '',
      referenceValues: !_isPack && _dataType == 'numeric' ? List.of(_referenceValues) : const [],
      qualitativeOptions: !_isPack && (_dataType == 'qualitative' || _dataType == 'boolean')
          ? List.of(_qualitativeOptions)
          : const [],
      expectedQualitativeValue:
          !_isPack &&
              (_dataType == 'qualitative' || _dataType == 'boolean') &&
              _expectedQualitativeValue.isNotEmpty
          ? _expectedQualitativeValue.trim()
          : null,
      referenceText: !_isPack ? referenceTextController.text.trim() : '',
      isProfileParameter: _isProfileParameter,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    codeController.dispose();
    categoryController.dispose();
    customCategoryController.dispose();
    customSubclassController.dispose();
    unitController.dispose();
    priceController.dispose();
    price2Controller.dispose();
    qualitativeOptionsController.dispose();
    referenceTextController.dispose();
    super.dispose();
  }
}
