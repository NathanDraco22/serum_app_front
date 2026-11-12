import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

class CreateOrderViewController extends ChangeNotifier {
  OrderInDb? editingOrder;
  PatientInDb? _selectedPatient;
  DoctorInDb? _selectedDoctor;
  final List<LabTestInDb> _selectedItems = [];
  final List<OrderService> _services = [];
  final List<OrderDiscount> _discounts = [];
  final Map<String, int> _itemPriceLevels = {};
  final Map<String, int> _customPrices = {};
  int _defaultPriceLevel = 1;
  bool _isSubmitting = false;
  bool _isPopulated = false;

  late final TextEditingController notesController;

  CreateOrderViewController({
    this.editingOrder,
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

  bool get isEditing => editingOrder != null;
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

  /// Indica si la orden de edición ya fue cargada desde el catálogo/snapshots.
  /// Mientras sea `false`, no se permite generar un `UpdateOrder` para evitar
  /// enviar `items`/`results` vacíos y borrar la orden original.
  bool get isPopulated => _isPopulated;

  /// Indica si la orden de edición ya tiene al menos un resultado capturado.
  bool get hasCapturedResults =>
      editingOrder?.results.any((r) => (r.resultValue ?? '').trim().isNotEmpty) ?? false;

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
    if (editingOrder != null && hasCapturedResults && patient?.id != _selectedPatient?.id) {
      return;
    }
    if (_selectedPatient?.id == patient?.id) return;
    _selectedPatient = patient;
    notifyListeners();
  }

  /// Refresca los datos demográficos del paciente ya seleccionado sin cambiar
  /// su identidad. Se usa cuando el usuario corrige la fecha/edad desde la
  /// pantalla de creación de la orden.
  void updateSelectedPatientData(PatientInDb patient) {
    if (_selectedPatient?.id != patient.id) {
      selectPatient(patient);
      return;
    }
    _selectedPatient = patient;
    notifyListeners();
  }

  void removePatient() {
    if (editingOrder != null && hasCapturedResults) return;
    if (_selectedPatient == null) return;
    _selectedPatient = null;
    notifyListeners();
  }

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
    editingOrder = null;
    _selectedPatient = null;
    _selectedDoctor = null;
    _defaultPriceLevel = 1;
    _isSubmitting = false;
    notesController.clear();
    notifyListeners();
  }

  /// Carga y sincroniza la información de una orden existente para modificación.
  void populateFromOrder(OrderInDb order, List<LabTestInDb> allLabTests) {
    editingOrder = order;

    _selectedPatient = PatientInDb(
      id: order.patientId,
      name: order.patientInfo?.name ?? '',
      dateOfBirth: order.patientInfo?.dateOfBirth ?? 0,
      gender: order.patientInfo?.gender ?? 'M',
      phone: order.patientInfo?.phone ?? '',
      address: order.patientInfo?.address,
      cardId: order.patientInfo?.cardId,
      email: order.patientInfo?.email,
      age: order.patientInfo?.explicitAge,
      originBranch: order.branchId,
      createdAt: 0,
    );

    if (order.doctorId != null && order.doctorId!.trim().isNotEmpty) {
      _selectedDoctor = DoctorInDb(
        id: order.doctorId!,
        name: order.doctorInfo?.name ?? '',
        specialty: order.doctorInfo?.specialty ?? 'Medicina General',
        phone: order.doctorInfo?.phone,
        cardId: order.doctorInfo?.cardId,
        email: order.doctorInfo?.email,
        originBranch: order.branchId,
        createdAt: 0,
      );
    } else {
      _selectedDoctor = null;
    }

    _selectedItems.clear();
    _itemPriceLevels.clear();
    _customPrices.clear();

    for (final item in order.items) {
      final catalogTest = allLabTests.cast<LabTestInDb?>().firstWhere(
        (t) => t?.id == item.labTestId,
        orElse: () => null,
      );
      final testObj =
          catalogTest ??
          LabTestInDb(
            id: item.labTestId,
            name: item.name,
            salePrice: item.originalPrice > 0 ? item.originalPrice : item.salePriceApplied,
            isPack: item.isPack,
            createdAt: 0,
          );
      _selectedItems.add(testObj);
      _itemPriceLevels[item.labTestId] = item.priceLevel;
      if (item.salePriceApplied != testObj.salePrice && item.salePriceApplied > 0) {
        _customPrices[item.labTestId] = item.salePriceApplied;
      }
    }

    _services.clear();
    _services.addAll(order.services);

    _discounts.clear();
    _discounts.addAll(order.discounts);

    notesController.text = order.notes ?? '';

    _isPopulated = true;
    notifyListeners();
  }

  void setSubmitting(bool value) {
    if (_isSubmitting == value) return;
    _isSubmitting = value;
    notifyListeners();
  }

  // --- Validación de Integridad de Packs y Mapeo al Dominio ---

  /// Verifica que todos los perfiles/packs (`isPack == true`) seleccionados en la orden
  /// existan en el catálogo y puedan expandir íntegramente sus parámetros hijos.
  ///
  /// Retorna `null` si todo es válido, o un mensaje descriptivo de error si algún pack
  /// no tiene parámetros o el catálogo aún no está disponible.
  String? validatePacksExpansion(List<LabTestInDb> allLabTests) {
    if (_selectedItems.isEmpty) return null;
    if (allLabTests.isEmpty) {
      return 'El catálogo de pruebas clínicas aún está cargando. Espera un momento e intenta guardar nuevamente.';
    }

    final catalogById = {for (final t in allLabTests) t.id: t};

    bool isValidPackTree(LabTestInDb pack, Set<String> visited) {
      if (pack.childTestIds.isEmpty) return false;
      if (!visited.add(pack.id)) return true;

      int atomicCount = 0;
      for (final childId in pack.childTestIds) {
        final child = catalogById[childId];
        if (child == null) return false;
        if (child.isPack) {
          if (!isValidPackTree(child, visited)) return false;
          atomicCount++;
        } else {
          atomicCount++;
        }
      }
      return atomicCount > 0;
    }

    for (final item in _selectedItems) {
      final resolved = catalogById[item.id] ?? item;
      if (resolved.isPack) {
        if (!isValidPackTree(resolved, <String>{})) {
          return 'El perfil "${resolved.name}" no pudo sincronizar todos sus parámetros del catálogo. Recarga e intenta de nuevo.';
        }
      }
    }

    return null;
  }

  /// Mapea el estado actual en memoria hacia el DTO [CreateOrder] listo para persistir en el Cubit.
  ///
  /// Retorna `null` si faltan requisitos indispensables (paciente, items/servicios o integridad de packs).
  CreateOrder? generateCreateOrder({
    required String branchId,
    required UserInDb? currentUser,
    required List<LabTestInDb> allLabTests,
  }) {
    if (_selectedPatient == null) return null;
    if (_selectedItems.isEmpty && _services.isEmpty) return null;
    if (validatePacksExpansion(allLabTests) != null) return null;

    final catalogById = {for (final t in allLabTests) t.id: t};

    // 1. Construir lista de OrderItem congelando precios efectivos
    final orderItems = _selectedItems.map((test) {
      final resolved = catalogById[test.id] ?? test;
      final level = getItemPriceLevel(test.id);
      final price = getItemEffectivePrice(test);
      return OrderItem(
        labTestId: resolved.id,
        name: resolved.name,
        salePriceApplied: price,
        originalPrice: resolved.salePrice,
        isPack: resolved.isPack,
        priceLevel: level,
      );
    }).toList();

    // 2. Resolver parámetros individuales para resultados clínicos (expandiendo packs recursivamente)
    final Map<String, OrderTestResult> resultsMap = {};
    final Set<String> visitedPackIds = {};

    void expandTest(LabTestInDb test, String rootItemName) {
      final resolvedTest = catalogById[test.id] ?? test;

      if (resolvedTest.isPack) {
        if (!visitedPackIds.add(resolvedTest.id)) {
          return; // Prevenir posibles referencias circulares
        }
        for (final childId in resolvedTest.childTestIds) {
          final childTest = catalogById[childId];
          if (childTest != null) {
            expandTest(childTest, rootItemName);
          }
        }
        return; // Un pack JAMÁS se registra como parámetro clínico individual
      }

      if (!resultsMap.containsKey(resolvedTest.id)) {
        resultsMap[resolvedTest.id] = OrderTestResult(
          labTestId: resolvedTest.id,
          parameterName: resolvedTest.name,
          medicalClassification: resolvedTest.commercialCategory,
          subclassification: resolvedTest.subclassification,
          dataType: resolvedTest.dataType,
          unitOfMeasure: resolvedTest.unitOfMeasure,
          referenceValues: resolvedTest.referenceValues,
          qualitativeOptions: resolvedTest.qualitativeOptions,
          expectedQualitativeValue: resolvedTest.expectedQualitativeValue,
          referenceText: resolvedTest.referenceText,
          parentExamName: rootItemName,
        );
      }
    }

    for (final item in _selectedItems) {
      final resolved = catalogById[item.id] ?? item;
      expandTest(resolved, resolved.name);
    }

    if (_selectedItems.isNotEmpty && resultsMap.isEmpty) return null;
    if (orderItems.any((item) => item.isPack && resultsMap.containsKey(item.labTestId))) {
      return null;
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
        age: _selectedPatient!.explicitAge,
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

  /// Mapea el estado actual en memoria hacia el DTO [UpdateOrder] para actualizar la orden en el Cubit.
  ///
  /// Retorna `null` si faltan requisitos indispensables (paciente o items/servicios).
  /// Preserva los resultados clínicos previamente capturados (`resultValue`, `alertFlag`, `showInPrint`).
  UpdateOrder? generateUpdateOrder({
    required String branchId,
    required UserInDb? currentUser,
    required List<LabTestInDb> allLabTests,
  }) {
    // Guard de seguridad: si la orden existente no se ha cargado todavía, no
    // se debe generar un PATCH con items/results vacíos (borraría la orden).
    if (editingOrder != null && !_isPopulated) return null;
    if (_selectedPatient == null) return null;
    if (_selectedItems.isEmpty && _services.isEmpty) return null;
    if (validatePacksExpansion(allLabTests) != null) return null;

    final catalogById = {for (final t in allLabTests) t.id: t};

    final orderItems = _selectedItems.map((test) {
      final resolved = catalogById[test.id] ?? test;
      final level = getItemPriceLevel(test.id);
      final price = getItemEffectivePrice(test);
      return OrderItem(
        labTestId: resolved.id,
        name: resolved.name,
        salePriceApplied: price,
        originalPrice: resolved.salePrice,
        isPack: resolved.isPack,
        priceLevel: level,
      );
    }).toList();

    final Map<String, OrderTestResult> existingResultsMap = {
      if (editingOrder != null)
        for (final r in editingOrder!.results) r.labTestId: r,
    };

    final Map<String, OrderTestResult> resultsMap = {};
    final Set<String> visitedPackIds = {};

    void expandTest(LabTestInDb test, String rootItemName) {
      final resolvedTest = catalogById[test.id] ?? test;

      if (resolvedTest.isPack) {
        if (!visitedPackIds.add(resolvedTest.id)) return;
        for (final childId in resolvedTest.childTestIds) {
          final childTest = catalogById[childId];
          if (childTest != null) {
            expandTest(childTest, rootItemName);
          }
        }
        return; // Un pack JAMÁS se registra como parámetro clínico individual
      }

      if (!resultsMap.containsKey(resolvedTest.id)) {
        final existing = existingResultsMap[resolvedTest.id];
        resultsMap[resolvedTest.id] = OrderTestResult(
          labTestId: resolvedTest.id,
          parameterName: resolvedTest.name,
          medicalClassification: resolvedTest.commercialCategory,
          subclassification: resolvedTest.subclassification,
          dataType: resolvedTest.dataType,
          unitOfMeasure: resolvedTest.unitOfMeasure,
          referenceValues: resolvedTest.referenceValues,
          qualitativeOptions: resolvedTest.qualitativeOptions,
          expectedQualitativeValue: resolvedTest.expectedQualitativeValue,
          referenceText: resolvedTest.referenceText,
          parentExamName: rootItemName,
          resultValue: existing?.resultValue,
          alertFlag: existing?.alertFlag,
          showInPrint: existing?.showInPrint ?? true,
        );
      }
    }

    for (final item in _selectedItems) {
      final resolved = catalogById[item.id] ?? item;
      expandTest(resolved, resolved.name);
    }

    if (_selectedItems.isNotEmpty && resultsMap.isEmpty) return null;
    if (orderItems.any((item) => item.isPack && resultsMap.containsKey(item.labTestId))) {
      return null;
    }

    final hasSupervisorLevel = (currentUser?.accessLevel ?? 0) > 3;
    bool isBlocked = false;
    OrderApproval? approval = editingOrder?.approval;

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
        final wasApproved = editingOrder?.approval?.isApproved == true;
        if (!wasApproved) {
          isBlocked = true;
          approval = OrderApproval(
            requiresApproval: true,
            isApproved: false,
            reason: defaultReason,
          );
        }
      }
    } else {
      isBlocked = false;
    }

    return UpdateOrder(
      patientId: _selectedPatient!.id,
      doctorId: _selectedDoctor?.id,
      clearDoctor: _selectedDoctor == null,
      patientInfo: PatientInfo(
        name: _selectedPatient!.name,
        dateOfBirth: _selectedPatient!.dateOfBirth,
        gender: _selectedPatient!.gender,
        phone: _selectedPatient!.phone,
        address: _selectedPatient!.address ?? '',
        cardId: _selectedPatient!.cardId,
        email: _selectedPatient!.email,
        age: _selectedPatient!.explicitAge,
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
