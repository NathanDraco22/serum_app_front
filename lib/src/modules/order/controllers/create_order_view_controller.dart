import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

class CreateOrderViewController extends ChangeNotifier {
  PatientInDb? _selectedPatient;
  DoctorInDb? _selectedDoctor;
  final List<LabTestInDb> _selectedItems = [];
  final List<OrderService> _services = [];
  final List<OrderDiscount> _discounts = [];
  final Map<String, int> _itemPriceLevels = {};
  final Map<String, int> _customPrices = {};
  int _defaultPriceLevel = 1;
  bool _isSubmitting = false;

  late final TextEditingController notesController;

  CreateOrderViewController({
    PatientInDb? initialPatient,
    DoctorInDb? initialDoctor,
    List<LabTestInDb>? initialItems,
    List<OrderService>? initialServices,
    List<OrderDiscount>? initialDiscounts,
    Map<String, int>? initialItemPriceLevels,
    Map<String, int>? initialCustomPrices,
    int initialDefaultPriceLevel = 1,
    String initialNotes = '',
  }) {
    _selectedPatient = initialPatient;
    _selectedDoctor = initialDoctor;
    if (initialItems != null) _selectedItems.addAll(initialItems);
    if (initialServices != null) _services.addAll(initialServices);
    if (initialDiscounts != null) _discounts.addAll(initialDiscounts);
    if (initialItemPriceLevels != null) _itemPriceLevels.addAll(initialItemPriceLevels);
    if (initialCustomPrices != null) _customPrices.addAll(initialCustomPrices);
    _defaultPriceLevel = initialDefaultPriceLevel;
    notesController = TextEditingController(text: initialNotes);
  }

  // --- Getters de Estado ---

  PatientInDb? get selectedPatient => _selectedPatient;
  DoctorInDb? get selectedDoctor => _selectedDoctor;
  List<LabTestInDb> get selectedItems => List.unmodifiable(_selectedItems);
  List<OrderService> get services => List.unmodifiable(_services);
  List<OrderDiscount> get discounts => List.unmodifiable(_discounts);
  Map<String, int> get itemPriceLevels => Map.unmodifiable(_itemPriceLevels);
  Map<String, int> get customPrices => Map.unmodifiable(_customPrices);
  int get defaultPriceLevel => _defaultPriceLevel;
  bool get isSubmitting => _isSubmitting;
  String get notes => notesController.text.trim();

  /// Indica si la pantalla está completamente vacía (sin selecciones ni datos cargados).
  bool get isEmpty =>
      _selectedItems.isEmpty &&
      _services.isEmpty &&
      _discounts.isEmpty &&
      _selectedPatient == null &&
      _selectedDoctor == null &&
      notes.isEmpty;

  bool isItemSelected(String testId) => _selectedItems.any((i) => i.id == testId);

  int getItemPriceLevel(String testId) => _itemPriceLevels[testId] ?? _defaultPriceLevel;

  int? getItemCustomPrice(String testId) => _customPrices[testId];

  /// Calcula el precio unitario efectivo en centavos de un análisis específico
  /// considerando precio personalizado o nivel de precio aplicado.
  int getItemEffectivePrice(LabTestInDb test) {
    final customPrice = _customPrices[test.id];
    if (customPrice != null) return customPrice;

    final level = getItemPriceLevel(test.id);
    if (level == 2 && test.salePrice2 > 0) {
      return test.salePrice2;
    }
    return test.salePrice;
  }

  // --- Getters Derivados y Cálculos Financieros ---

  /// Total bruto de análisis seleccionados (en centavos).
  int get testsTotalInCents =>
      _selectedItems.fold<int>(0, (sum, test) => sum + getItemEffectivePrice(test));

  /// Total de servicios adicionales (en centavos).
  int get servicesTotalInCents => _services.fold<int>(0, (sum, s) => sum + s.price);

  /// Subtotal bruto combinado (análisis + servicios) en centavos.
  int get grossSubtotalInCents => testsTotalInCents + servicesTotalInCents;

  /// Total de deducciones aplicadas por descuentos en centavos.
  int get discountsTotalInCents => _discounts.fold<int>(0, (sum, d) => sum + d.appliedAmount);

  /// Total neto general a pagar (en centavos), nunca inferior a cero.
  int get totalInCents =>
      (grossSubtotalInCents - discountsTotalInCents).clamp(0, grossSubtotalInCents);

  /// Determina si algún análisis tiene un precio diferente a su precio base de catálogo.
  bool get hasModifiedPrice =>
      _selectedItems.any((test) => getItemEffectivePrice(test) != test.salePrice);

  /// Determina si la orden cuenta con descuentos registrados.
  bool get hasDiscounts => _discounts.isNotEmpty;

  /// Regla institucional: requiere aprobación de supervisor si hay descuentos o precios modificados.
  bool get requiresSupervisorApproval => hasModifiedPrice || hasDiscounts;

  // --- Mutaciones de Estado ---

  void selectPatient(PatientInDb? patient) {
    if (_selectedPatient?.id == patient?.id) return;
    _selectedPatient = patient;
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
      _customPrices.remove(test.id);
    } else {
      _selectedItems.add(test);
      _itemPriceLevels[test.id] = _defaultPriceLevel;
    }
    notifyListeners();
  }

  void removeItem(LabTestInDb test) {
    _selectedItems.removeWhere((i) => i.id == test.id);
    _itemPriceLevels.remove(test.id);
    _customPrices.remove(test.id);
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

  void editItemPrice(String testId, int newPrice, int catalogPrice) {
    if (newPrice == catalogPrice) {
      _customPrices.remove(testId);
    } else {
      _customPrices[testId] = newPrice;
    }
    notifyListeners();
  }

  void addService(OrderService service) {
    _services.add(service);
    notifyListeners();
  }

  void editService(OrderService service) {
    final index = _services.indexWhere((s) => s.id == service.id);
    if (index >= 0) {
      _services[index] = service;
      notifyListeners();
    }
  }

  void removeService(OrderService service) {
    _services.removeWhere((s) => (s.id != null && s.id == service.id) || s == service);
    notifyListeners();
  }

  void removeServiceById(String serviceId) {
    _services.removeWhere((s) => s.id == serviceId);
    notifyListeners();
  }

  void addDiscount(OrderDiscount discount) {
    _discounts.add(discount);
    notifyListeners();
  }

  void editDiscount(OrderDiscount discount) {
    final index = _discounts.indexWhere((d) => d.id == discount.id);
    if (index >= 0) {
      _discounts[index] = discount;
      notifyListeners();
    }
  }

  void removeDiscount(OrderDiscount discount) {
    _discounts.removeWhere((d) => (d.id != null && d.id == discount.id) || d == discount);
    notifyListeners();
  }

  void removeDiscountById(String discountId) {
    _discounts.removeWhere((d) => d.id == discountId);
    notifyListeners();
  }

  /// Limpia los análisis, servicios y descuentos seleccionados.
  void clearCart() {
    _selectedItems.clear();
    _services.clear();
    _discounts.clear();
    _itemPriceLevels.clear();
    _customPrices.clear();
    notifyListeners();
  }

  /// Limpia toda la pantalla regresándola a su estado inicial en blanco.
  void clearAll() {
    clearCart();
    _selectedPatient = null;
    _selectedDoctor = null;
    _defaultPriceLevel = 1;
    _isSubmitting = false;
    notesController.clear();
    notifyListeners();
  }

  void setSubmitting(bool value) {
    if (_isSubmitting == value) return;
    _isSubmitting = value;
    notifyListeners();
  }

  // --- Mapeo al Dominio (Generación de DTOs) ---

  /// Mapea el estado actual en memoria hacia el DTO [CreateOrder] listo para persistir en el Cubit.
  ///
  /// Retorna `null` si faltan requisitos indispensables (paciente o items/servicios).
  CreateOrder? generateCreateOrder({
    required String branchId,
    required UserInDb? currentUser,
    required List<LabTestInDb> allLabTests,
  }) {
    if (_selectedPatient == null) return null;
    if (_selectedItems.isEmpty && _services.isEmpty) return null;

    // 1. Construir lista de OrderItem congelando precios efectivos
    final orderItems = _selectedItems.map((test) {
      final level = getItemPriceLevel(test.id);
      final price = getItemEffectivePrice(test);
      return OrderItem(
        labTestId: test.id,
        name: test.name,
        salePriceApplied: price,
        originalPrice: test.salePrice,
        isPack: test.isPack,
        priceLevel: level,
      );
    }).toList();

    // 2. Resolver parámetros individuales para resultados clínicos (expandiendo packs)
    final Map<String, OrderTestResult> resultsMap = {};

    for (final item in _selectedItems) {
      if (item.isPack) {
        for (final childId in item.childTestIds) {
          final childTest = allLabTests.firstWhere(
            (t) => t.id == childId,
            orElse: () => LabTestInDb(
              id: childId,
              name: 'Análisis ($childId)',
              createdAt: 0,
            ),
          );
          if (!resultsMap.containsKey(childTest.id)) {
            resultsMap[childTest.id] = OrderTestResult(
              labTestId: childTest.id,
              parameterName: childTest.name,
              medicalClassification: childTest.commercialCategory,
              subclassification: childTest.subclassification,
              dataType: childTest.dataType,
              unitOfMeasure: childTest.unitOfMeasure,
              referenceValues: childTest.referenceValues,
              qualitativeOptions: childTest.qualitativeOptions,
              expectedQualitativeValue: childTest.expectedQualitativeValue,
              referenceText: childTest.referenceText,
            );
          }
        }
      } else {
        if (!resultsMap.containsKey(item.id)) {
          resultsMap[item.id] = OrderTestResult(
            labTestId: item.id,
            parameterName: item.name,
            medicalClassification: item.commercialCategory,
            subclassification: item.subclassification,
            dataType: item.dataType,
            unitOfMeasure: item.unitOfMeasure,
            referenceValues: item.referenceValues,
            qualitativeOptions: item.qualitativeOptions,
            expectedQualitativeValue: item.expectedQualitativeValue,
            referenceText: item.referenceText,
          );
        }
      }
    }

    // 3. Evaluar reglas de autorización por supervisor
    final hasSupervisorLevel = (currentUser?.accessLevel ?? 0) > 3;
    bool isBlocked = false;
    OrderApproval? approval;

    if (requiresSupervisorApproval) {
      final defaultReason = hasDiscounts && hasModifiedPrice
          ? 'Precio modificado y descuento aplicado en ventanilla'
          : (hasDiscounts
                ? 'Descuento aplicado a la orden'
                : 'Precio modificado respecto al catálogo');

      if (hasSupervisorLevel && currentUser != null) {
        isBlocked = false;
        approval = OrderApproval(
          requiresApproval: true,
          isApproved: true,
          approvedBy: UserInfo(id: currentUser.id, name: currentUser.name),
          approvedAt: DateTime.now().millisecondsSinceEpoch,
          reason: '$defaultReason (Autorizado por supervisor: ${currentUser.name})',
        );
      } else {
        isBlocked = true;
        approval = OrderApproval(
          requiresApproval: true,
          isApproved: false,
          reason: defaultReason,
        );
      }
    }

    return CreateOrder(
      patientId: _selectedPatient!.id,
      doctorId: _selectedDoctor?.id,
      patientInfo: PatientInfo(
        name: _selectedPatient!.name,
        dateOfBirth: _selectedPatient!.dateOfBirth,
        gender: _selectedPatient!.gender,
        phone: _selectedPatient!.phone,
        address: _selectedPatient!.address ?? '',
        cardId: _selectedPatient!.cardId,
        email: _selectedPatient!.email,
        age: _selectedPatient!.age,
      ),
      doctorInfo: _selectedDoctor != null
          ? DoctorInfo(
              name: _selectedDoctor!.name,
              specialty: _selectedDoctor!.specialty,
              phone: _selectedDoctor!.phone ?? '',
              cardId: _selectedDoctor!.cardId,
              email: _selectedDoctor!.email,
            )
          : null,
      branchId: branchId,
      items: orderItems,
      services: List.of(_services),
      discounts: List.of(_discounts),
      totalPrice: totalInCents,
      status: 'pending',
      results: resultsMap.values.toList(),
      isBlocked: isBlocked,
      approval: approval,
      notes: notes.isNotEmpty ? notes : null,
    );
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }
}
