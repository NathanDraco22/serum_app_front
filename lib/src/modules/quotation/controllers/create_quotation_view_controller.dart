import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

/// Controlador de vista para la pantalla de Creación de Cotizaciones de Análisis.
///
/// Siguiendo la estrategia ViewController del estándar OKF:
/// - Concentra el estado en memoria: paciente, médico, cliente casual, estudios cotizados y niveles de tarifa.
/// - Expone getters derivados para cálculos financieros (total cotizado, nombre de cliente resuelto).
/// - Provee mutaciones reactivas que llaman a [notifyListeners].
/// - Mapea el estado al dominio generando el DTO [CreateQuotation] listo para el Cubit.
/// - Es agnóstico a la UI (sin BuildContext de widgets ni diálogos).
class CreateQuotationViewController extends ChangeNotifier {
  PatientInDb? _selectedPatient;
  DoctorInDb? _selectedDoctor;
  final List<LabTestInDb> _selectedItems = [];
  final Map<String, int> _itemPriceLevels = {};
  int _defaultPriceLevel = 1;
  bool _isSubmitting = false;

  late final TextEditingController casualClientNameController;

  CreateQuotationViewController({
    PatientInDb? initialPatient,
    DoctorInDb? initialDoctor,
    String initialCasualClientName = '',
    List<LabTestInDb>? initialItems,
    Map<String, int>? initialItemPriceLevels,
    int initialDefaultPriceLevel = 1,
  }) {
    _selectedPatient = initialPatient;
    _selectedDoctor = initialDoctor;
    if (initialItems != null) _selectedItems.addAll(initialItems);
    if (initialItemPriceLevels != null) _itemPriceLevels.addAll(initialItemPriceLevels);
    _defaultPriceLevel = initialDefaultPriceLevel;
    casualClientNameController = TextEditingController(
      text: initialPatient?.name ?? initialCasualClientName,
    );
  }

  // --- Getters de Estado ---

  PatientInDb? get selectedPatient => _selectedPatient;
  DoctorInDb? get selectedDoctor => _selectedDoctor;
  List<LabTestInDb> get selectedItems => List.unmodifiable(_selectedItems);
  Map<String, int> get itemPriceLevels => Map.unmodifiable(_itemPriceLevels);
  int get defaultPriceLevel => _defaultPriceLevel;
  bool get isSubmitting => _isSubmitting;
  String get casualClientName => casualClientNameController.text.trim();

  /// Resuelve el nombre del cliente a imprimir o registrar:
  /// Paciente seleccionado > texto ingresado en cliente casual > 'Cliente General'.
  String get clientName {
    if (_selectedPatient != null && _selectedPatient!.name.isNotEmpty) {
      return _selectedPatient!.name;
    }
    if (casualClientName.isNotEmpty) {
      return casualClientName;
    }
    return 'Cliente General';
  }

  /// Indica si la pantalla está completamente vacía (sin datos ingresados).
  bool get isEmpty =>
      _selectedItems.isEmpty &&
      _selectedPatient == null &&
      _selectedDoctor == null &&
      casualClientName.isEmpty;

  bool isItemSelected(String testId) => _selectedItems.any((i) => i.id == testId);

  int getItemPriceLevel(String testId) => _itemPriceLevels[testId] ?? _defaultPriceLevel;

  /// Retorna el precio unitario en centavos aplicando el nivel de precio seleccionado.
  int getItemEffectivePrice(LabTestInDb test) {
    final level = getItemPriceLevel(test.id);
    if (level == 2 && test.salePrice2 > 0) {
      return test.salePrice2;
    }
    return test.salePrice;
  }

  /// Total general en centavos de todos los análisis presupuestados.
  int get totalAmount =>
      _selectedItems.fold<int>(0, (sum, test) => sum + getItemEffectivePrice(test));

  // --- Mutaciones de Estado ---

  void selectPatient(PatientInDb? patient) {
    if (_selectedPatient?.id == patient?.id) return;
    _selectedPatient = patient;
    if (patient != null) {
      casualClientNameController.text = patient.name;
    } else {
      casualClientNameController.clear();
    }
    notifyListeners();
  }

  void removePatient() => selectPatient(null);

  void selectDoctor(DoctorInDb? doctor) {
    if (_selectedDoctor?.id == doctor?.id) return;
    _selectedDoctor = doctor;
    notifyListeners();
  }

  void removeDoctor() => selectDoctor(null);

  void toggleItem(LabTestInDb test) {
    final index = _selectedItems.indexWhere((i) => i.id == test.id);
    if (index >= 0) {
      _selectedItems.removeAt(index);
      _itemPriceLevels.remove(test.id);
    } else {
      _selectedItems.add(test);
      _itemPriceLevels[test.id] = _defaultPriceLevel;
    }
    notifyListeners();
  }

  void removeItem(LabTestInDb test) {
    _selectedItems.removeWhere((i) => i.id == test.id);
    _itemPriceLevels.remove(test.id);
    notifyListeners();
  }

  void changeItemPriceLevel(String testId, int level) {
    if (_itemPriceLevels[testId] == level) return;
    _itemPriceLevels[testId] = level;
    notifyListeners();
  }

  void changeDefaultPriceLevel(int level) {
    _defaultPriceLevel = level;
    for (final item in _selectedItems) {
      _itemPriceLevels[item.id] = level;
    }
    notifyListeners();
  }

  /// Limpia los análisis agregados conservando los datos del cliente y médico.
  void clearCart() {
    _selectedItems.clear();
    _itemPriceLevels.clear();
    notifyListeners();
  }

  /// Restablece por completo la cotización a su estado original.
  void clearAll() {
    clearCart();
    _selectedPatient = null;
    _selectedDoctor = null;
    _defaultPriceLevel = 1;
    _isSubmitting = false;
    casualClientNameController.clear();
    notifyListeners();
  }

  void setSubmitting(bool value) {
    if (_isSubmitting == value) return;
    _isSubmitting = value;
    notifyListeners();
  }

  // --- Mapeo al Dominio (Generación de DTOs) ---

  /// Mapea el estado en memoria hacia el DTO [CreateQuotation] listo para el Cubit.
  ///
  /// Retorna `null` si no hay al menos un estudio seleccionado.
  CreateQuotation? generateCreateQuotation({required String branchId}) {
    if (_selectedItems.isEmpty) return null;

    final resolvedClientName = clientName;
    final casualText = casualClientName;

    // 1. Resolver snapshots de información
    final PatientInfo? clientInfo = _selectedPatient != null
        ? PatientInfo(
            name: _selectedPatient!.name,
            dateOfBirth: _selectedPatient!.dateOfBirth,
            gender: _selectedPatient!.gender,
            phone: _selectedPatient!.phone,
            address: _selectedPatient!.address ?? '',
            cardId: _selectedPatient!.cardId,
            email: _selectedPatient!.email,
            age: _selectedPatient!.age,
          )
        : (casualText.isNotEmpty ? PatientInfo(name: casualText) : null);

    final DoctorInfo? doctorInfo = _selectedDoctor != null
        ? DoctorInfo(
            name: _selectedDoctor!.name,
            specialty: _selectedDoctor!.specialty,
            phone: _selectedDoctor!.phone ?? '',
            cardId: _selectedDoctor!.cardId,
            email: _selectedDoctor!.email,
          )
        : null;

    // 2. Construir lista de QuotedExam congelando tarifas
    final quotedExams = _selectedItems.map((test) {
      final level = getItemPriceLevel(test.id);
      final price = getItemEffectivePrice(test);
      return QuotedExam(
        labTestId: test.id,
        name: test.name,
        quotedPrice: price,
        isPack: test.isPack,
        priceLevel: level,
      );
    }).toList();

    return CreateQuotation(
      clientName: resolvedClientName,
      branchId: branchId,
      patientId: _selectedPatient?.id,
      clientInfo: clientInfo,
      doctorId: _selectedDoctor?.id,
      doctorInfo: doctorInfo,
      exams: quotedExams,
      totalAmount: totalAmount,
      status: 'pending',
    );
  }

  @override
  void dispose() {
    casualClientNameController.dispose();
    super.dispose();
  }
}
