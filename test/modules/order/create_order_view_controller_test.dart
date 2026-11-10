import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/order/controllers/create_order_view_controller.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  group('CreateOrderViewController Unit Tests', () {
    late CreateOrderViewController controller;

    final samplePatient = PatientInDb(
      id: 'p_100',
      name: 'Maria Lopez',
      originBranch: 'b_1',
      dateOfBirth: 946684800000,
      gender: 'F',
      phone: '88889999',
      address: 'Managua',
      cardId: '001-010100-0001A',
      email: 'maria@example.com',
      age: 26,
      createdAt: 0,
    );

    final sampleDoctor = DoctorInDb(
      id: 'doc_200',
      name: 'Dr. Roberto Gomez',
      originBranch: 'b_1',
      specialty: 'Cardiologia',
      phone: '87654321',
      email: 'roberto@example.com',
      createdAt: 0,
    );

    final test1 = LabTestInDb(
      id: 'test_1',
      name: 'Glucosa',
      salePrice: 15000, // C$ 150.00
      salePrice2: 12000, // C$ 120.00
      commercialCategory: 'Bioquimica',
      dataType: 'numeric',
      unitOfMeasure: 'mg/dL',
      createdAt: 0,
    );

    final test2 = LabTestInDb(
      id: 'test_2',
      name: 'Colesterol Total',
      salePrice: 20000, // C$ 200.00
      salePrice2: 18000,
      commercialCategory: 'Bioquimica',
      dataType: 'numeric',
      unitOfMeasure: 'mg/dL',
      createdAt: 0,
    );

    final packTest = LabTestInDb(
      id: 'pack_1',
      name: 'Perfil Lipidico',
      isPack: true,
      salePrice: 30000, // C$ 300.00
      childTestIds: ['test_1', 'test_2'],
      createdAt: 0,
    );

    setUp(() {
      controller = CreateOrderViewController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Estado inicial en blanco e isEmpty == true', () {
      expect(controller.isEmpty, isTrue);
      expect(controller.selectedPatient, isNull);
      expect(controller.selectedDoctor, isNull);
      expect(controller.selectedItems, isEmpty);
      expect(controller.services, isEmpty);
      expect(controller.discounts, isEmpty);
      expect(controller.testsTotalInCents, 0);
      expect(controller.servicesTotalInCents, 0);
      expect(controller.grossSubtotalInCents, 0);
      expect(controller.discountsTotalInCents, 0);
      expect(controller.totalInCents, 0);
      expect(controller.hasModifiedPrice, isFalse);
      expect(controller.hasDiscounts, isFalse);
      expect(controller.requiresSupervisorApproval, isFalse);
    });

    test('Selección y remoción de Paciente y Doctor notifica a los listeners', () {
      int notifications = 0;
      controller.addListener(() => notifications++);

      controller.selectPatient(samplePatient);
      expect(controller.selectedPatient, equals(samplePatient));
      expect(notifications, 1);
      expect(controller.isEmpty, isFalse);

      controller.selectDoctor(sampleDoctor);
      expect(controller.selectedDoctor, equals(sampleDoctor));
      expect(notifications, 2);

      controller.removeDoctor();
      expect(controller.selectedDoctor, isNull);
      expect(notifications, 3);

      controller.removePatient();
      expect(controller.selectedPatient, isNull);
      expect(notifications, 4);
    });

    test('Manejo de ítems: toggle, remoción y cálculos de subtotales', () {
      controller.toggleItem(test1);
      expect(controller.selectedItems.length, 1);
      expect(controller.isItemSelected('test_1'), isTrue);
      expect(controller.testsTotalInCents, 15000);
      expect(controller.grossSubtotalInCents, 15000);
      expect(controller.totalInCents, 15000);

      // Alternar el mismo ítem lo remueve
      controller.toggleItem(test1);
      expect(controller.selectedItems, isEmpty);
      expect(controller.testsTotalInCents, 0);

      // Agregar ambos
      controller.toggleItem(test1);
      controller.toggleItem(test2);
      expect(controller.selectedItems.length, 2);
      expect(controller.testsTotalInCents, 35000); // 15000 + 20000

      // Remover explícitamente test1
      controller.removeItem(test1);
      expect(controller.selectedItems.length, 1);
      expect(controller.testsTotalInCents, 20000);
    });

    test('Niveles de precio y precios personalizados alteran el total y activan aprobación', () {
      controller.toggleItem(test1); // salePrice = 15000, salePrice2 = 12000
      expect(controller.getItemEffectivePrice(test1), 15000);
      expect(controller.hasModifiedPrice, isFalse);
      expect(controller.requiresSupervisorApproval, isFalse);

      // Cambiar a nivel de precio 2 (C$ 120.00)
      controller.changeItemPriceLevel(test1.id, 2);
      expect(controller.getItemPriceLevel(test1.id), 2);
      expect(controller.getItemEffectivePrice(test1), 12000);
      expect(controller.testsTotalInCents, 12000);
      expect(controller.hasModifiedPrice, isTrue);
      expect(controller.requiresSupervisorApproval, isTrue);

      // Asignar precio personalizado especial (C$ 100.00 = 10000 centavos)
      controller.editItemPrice(test1.id, 10000, test1.salePrice);
      expect(controller.getItemCustomPrice(test1.id), 10000);
      expect(controller.getItemEffectivePrice(test1), 10000);
      expect(controller.testsTotalInCents, 10000);

      // Revertir precio al precio de catálogo elimina el precio personalizado
      controller.editItemPrice(test1.id, test1.salePrice, test1.salePrice);
      expect(controller.getItemCustomPrice(test1.id), isNull);
    });

    test('Servicios y Descuentos calculan totales correctamente y clamp a 0', () {
      controller.toggleItem(test1); // 15000 centavos (C$ 150.00)

      final service = OrderService(
        id: 'serv_1',
        name: 'Toma a domicilio',
        price: 5000, // C$ 50.00
      );
      controller.addService(service);
      expect(controller.services.length, 1);
      expect(controller.servicesTotalInCents, 5000);
      expect(controller.grossSubtotalInCents, 20000); // 15000 + 5000
      expect(controller.totalInCents, 20000);

      // Agregar descuento de C$ 30.00 (3000 centavos)
      final discount = OrderDiscount(
        id: 'disc_1',
        description: 'Tercera Edad',
        type: 'amount',
        value: 30.0,
        appliedAmount: 3000,
      );
      controller.addDiscount(discount);
      expect(controller.discounts.length, 1);
      expect(controller.discountsTotalInCents, 3000);
      expect(controller.totalInCents, 17000); // 20000 - 3000
      expect(controller.hasDiscounts, isTrue);
      expect(controller.requiresSupervisorApproval, isTrue);

      // Descuento mayor al subtotal no produce saldo negativo
      final hugeDiscount = OrderDiscount(
        id: 'disc_2',
        description: 'Cortesía total',
        type: 'amount',
        value: 500.0,
        appliedAmount: 50000, // 50000 > 20000
      );
      controller.addDiscount(hugeDiscount);
      expect(controller.totalInCents, 0); // clamp a 0
    });

    test('generateCreateOrder retorna null si falta paciente o ítems', () {
      final user = UserInDb(
        id: 'u_1',
        name: 'Operador 1',
        username: 'op1',
        role: 'operator',
        accessLevel: 1,
        branches: ['b_1'],
        isActive: true,
        isDeleted: false,
        createdAt: 0,
      );

      // Sin paciente
      controller.toggleItem(test1);
      expect(
        controller.generateCreateOrder(
          branchId: 'b_1',
          currentUser: user,
          allLabTests: [test1],
        ),
        isNull,
      );

      // Con paciente pero sin ítems ni servicios
      controller.selectPatient(samplePatient);
      controller.toggleItem(test1); // deselecciona test1
      expect(
        controller.generateCreateOrder(
          branchId: 'b_1',
          currentUser: user,
          allLabTests: [test1],
        ),
        isNull,
      );
    });

    test('generateCreateOrder expande packs y bloquea orden si operador aplica descuento', () {
      final operatorUser = UserInDb(
        id: 'u_op',
        name: 'Operador Cajero',
        username: 'cajero',
        role: 'operator',
        accessLevel: 1,
        branches: ['b_1'],
        isActive: true,
        isDeleted: false,
        createdAt: 0,
      );

      controller.selectPatient(samplePatient);
      controller.selectDoctor(sampleDoctor);
      controller.toggleItem(packTest); // Pack con test_1 y test_2

      // Aplicar descuento
      controller.addDiscount(
        OrderDiscount(
          id: 'disc_1',
          description: 'Descuento Familiar',
          type: 'amount',
          value: 20.0,
          appliedAmount: 2000,
        ),
      );

      final allTests = [packTest, test1, test2];
      final order = controller.generateCreateOrder(
        branchId: 'b_1',
        currentUser: operatorUser,
        allLabTests: allTests,
      );

      expect(order, isNotNull);
      expect(order!.patientId, 'p_100');
      expect(order.doctorId, 'doc_200');
      expect(order.patientInfo?.name, 'Maria Lopez');
      expect(order.doctorInfo?.name, 'Dr. Roberto Gomez');
      expect(order.items.length, 1);
      expect(order.items.first.labTestId, 'pack_1');
      expect(order.items.first.isPack, isTrue);

      // Debe expandir los parámetros hijos del pack en results con trazabilidad a su examen padre
      expect(order.results.length, 2);
      expect(order.results.map((r) => r.labTestId).toList(), containsAll(['test_1', 'test_2']));
      expect(order.results.every((r) => r.parentExamName == 'Perfil Lipidico'), isTrue);

      // Al ser operador y haber descuento -> nace bloqueada
      expect(order.isBlocked, isTrue);
      expect(order.approval, isNotNull);
      expect(order.approval!.requiresApproval, isTrue);
      expect(order.approval!.isApproved, isFalse);
    });

    test('generateCreateOrder expande recursivamente packs anidados', () {
      final operatorUser = UserInDb(
        id: 'u_op',
        name: 'Operador Cajero',
        username: 'cajero',
        role: 'operator',
        accessLevel: 1,
        branches: ['b_1'],
        isActive: true,
        isDeleted: false,
        createdAt: 0,
      );

      // Parámetros atómicos de nivel hoja
      final paramCual = LabTestInDb(
        id: 'pcr_cual',
        name: 'Proteína C Reactiva',
        code: 'PCR-CUAL',
        dataType: 'qualitative',
        qualitativeOptions: ['Negativo', 'Positivo'],
        expectedQualitativeValue: 'Negativo',
        isProfileParameter: true,
        salePrice: 0,
        createdAt: 0,
      );
      final paramTit = LabTestInDb(
        id: 'pcr_tit',
        name: 'Título',
        code: 'PCR-TIT',
        dataType: 'text',
        isProfileParameter: true,
        salePrice: 0,
        createdAt: 0,
      );
      final paramConc = LabTestInDb(
        id: 'pcr_conc',
        name: 'Concentración',
        code: 'PCR-CONC',
        dataType: 'text',
        unitOfMeasure: 'mg/L',
        isProfileParameter: true,
        salePrice: 0,
        createdAt: 0,
      );

      // Pack de PCR
      final pcrPack = LabTestInDb(
        id: 'pcr_pack',
        name: 'Proteína C Reactiva (PCR)',
        code: 'PCR',
        isPack: true,
        childTestIds: ['pcr_cual', 'pcr_tit', 'pcr_conc'],
        salePrice: 28000,
        createdAt: 0,
      );

      // Prueba atómica adicional
      final testVsg = LabTestInDb(
        id: 'vsg_test',
        name: 'Eritrosedimentación (VSG)',
        code: 'VSG',
        dataType: 'numeric',
        unitOfMeasure: 'mm/h',
        salePrice: 5000,
        createdAt: 0,
      );

      // Pack superior (Perfil Reumático) que contiene a pcr_pack y vsg_test
      final macroPack = LabTestInDb(
        id: 'perf_reum',
        name: 'Perfil Reumático',
        code: 'PERF-REUM',
        isPack: true,
        childTestIds: ['pcr_pack', 'vsg_test'],
        salePrice: 110000,
        createdAt: 0,
      );

      controller.selectPatient(samplePatient);
      controller.toggleItem(macroPack);

      final allTests = [macroPack, pcrPack, paramCual, paramTit, paramConc, testVsg];
      final order = controller.generateCreateOrder(
        branchId: 'b_1',
        currentUser: operatorUser,
        allLabTests: allTests,
      );

      expect(order, isNotNull);
      expect(order!.items.length, 1);
      expect(order.items.first.labTestId, 'perf_reum');

      // Debe haber expandido recursivamente pcr_pack en sus 3 parámetros + vsg_test = 4 resultados
      expect(order.results.length, 4);
      final resultIds = order.results.map((r) => r.labTestId).toList();
      expect(resultIds, containsAll(['pcr_cual', 'pcr_tit', 'pcr_conc', 'vsg_test']));
      // No debe contener el ID del pack intermedio como resultado
      expect(resultIds.contains('pcr_pack'), isFalse);
    });

    test(
      'generateCreateOrder auto-aprueba si el usuario es supervisor/admin (accessLevel > 3)',
      () {
        final supervisorUser = UserInDb(
          id: 'u_sup',
          name: 'Dra. Claudia Supervisor',
          username: 'supervisor',
          role: 'supervisor',
          accessLevel: 4,
          branches: ['b_1'],
          isActive: true,
          isDeleted: false,
          createdAt: 0,
        );

        controller.selectPatient(samplePatient);
        controller.toggleItem(test1);
        controller.editItemPrice(test1.id, 9900, test1.salePrice); // precio modificado

        final order = controller.generateCreateOrder(
          branchId: 'b_1',
          currentUser: supervisorUser,
          allLabTests: [test1],
        );

        expect(order, isNotNull);
        expect(order!.isBlocked, isFalse);
        expect(order.approval, isNotNull);
        expect(order.approval!.requiresApproval, isTrue);
        expect(order.approval!.isApproved, isTrue);
        expect(order.approval!.approvedBy?.id, 'u_sup');
        expect(order.approval!.reason, contains('Autorizado por supervisor'));
      },
    );

    test('clearCart y clearAll limpian los datos adecuadamente', () {
      controller.selectPatient(samplePatient);
      controller.selectDoctor(sampleDoctor);
      controller.toggleItem(test1);
      controller.notesController.text = 'Prueba urgente';

      controller.clearCart();
      expect(controller.selectedItems, isEmpty);
      // Paciente, doctor y notas se conservan tras clearCart
      expect(controller.selectedPatient, equals(samplePatient));
      expect(controller.notes, 'Prueba urgente');

      // clearAll restablece absolutamente todo
      controller.clearAll();
      expect(controller.isEmpty, isTrue);
      expect(controller.selectedPatient, isNull);
      expect(controller.notes, isEmpty);
    });

    test('populateFromOrder inicializa estado correctamente desde una orden existente', () {
      final existingOrder = OrderInDb(
        id: 'ord_500',
        createdAt: 1700000000000,
        patientId: 'p_100',
        patientInfo: PatientInfo(
          name: 'Maria Lopez',
          dateOfBirth: 946684800000,
          gender: 'F',
          phone: '88889999',
        ),
        doctorId: 'doc_200',
        doctorInfo: DoctorInfo(
          name: 'Dr. Roberto Gomez',
          specialty: 'Cardiologia',
        ),
        branchId: 'b_1',
        items: [
          OrderItem(
            labTestId: 'test_1',
            name: 'Glucosa',
            salePriceApplied: 14000, // precio con descuento manual
            originalPrice: 15000,
            priceLevel: 1,
          ),
          OrderItem(
            labTestId: 'test_2',
            name: 'Colesterol Total',
            salePriceApplied: 18000,
            originalPrice: 20000,
            priceLevel: 2,
          ),
        ],
        services: [
          OrderService(id: 'srv_1', name: 'Toma a Domicilio', price: 5000),
        ],
        discounts: [
          OrderDiscount(
            id: 'dsc_1',
            description: 'Convenio',
            type: 'amount',
            value: 2000,
            appliedAmount: 2000,
          ),
        ],
        notes: 'Paciente en ayuno',
        results: [
          OrderTestResult(
            labTestId: 'test_1',
            parameterName: 'Glucosa',
            dataType: 'numeric',
            resultValue: '95',
            alertFlag: 'NORMAL',
          ),
        ],
      );

      controller.populateFromOrder(existingOrder, [test1, test2]);

      expect(controller.isEditing, isTrue);
      expect(controller.editingOrder?.id, 'ord_500');
      expect(controller.selectedPatient?.id, 'p_100');
      expect(controller.selectedPatient?.name, 'Maria Lopez');
      expect(controller.selectedDoctor?.id, 'doc_200');
      expect(controller.selectedDoctor?.name, 'Dr. Roberto Gomez');
      expect(controller.selectedItems.length, 2);
      expect(controller.isItemSelected('test_1'), isTrue);
      expect(controller.isItemSelected('test_2'), isTrue);
      expect(controller.getItemCustomPrice('test_1'), 14000);
      expect(controller.getItemPriceLevel('test_2'), 2);
      expect(controller.services.length, 1);
      expect(controller.services.first.name, 'Toma a Domicilio');
      expect(controller.discounts.length, 1);
      expect(controller.notes, 'Paciente en ayuno');
    });

    test('generateUpdateOrder preserva resultados clínicos previos y añade nuevos en blanco', () {
      final existingOrder = OrderInDb(
        id: 'ord_500',
        createdAt: 1700000000000,
        patientId: 'p_100',
        branchId: 'b_1',
        items: [
          OrderItem(
            labTestId: 'test_1',
            name: 'Glucosa',
            salePriceApplied: 15000,
            originalPrice: 15000,
          ),
        ],
        results: [
          OrderTestResult(
            labTestId: 'test_1',
            parameterName: 'Glucosa',
            dataType: 'numeric',
            resultValue: '105',
            alertFlag: 'HIGH',
            showInPrint: true,
          ),
        ],
      );

      // Cargar orden previa
      controller.populateFromOrder(existingOrder, [test1, test2]);

      // Agregar un nuevo examen (Colesterol Total)
      controller.toggleItem(test2);
      expect(controller.selectedItems.length, 2);

      final updateOrder = controller.generateUpdateOrder(
        branchId: 'b_1',
        currentUser: null,
        allLabTests: [test1, test2],
      );

      expect(updateOrder, isNotNull);
      expect(updateOrder!.items?.length, 2);
      expect(updateOrder.results?.length, 2);

      // El resultado de Glucosa debe preservar su valor previo
      final glucosaResult = updateOrder.results!.firstWhere((r) => r.labTestId == 'test_1');
      expect(glucosaResult.resultValue, '105');
      expect(glucosaResult.alertFlag, 'HIGH');

      // El nuevo examen (Colesterol Total) debe tener resultado en blanco
      final colesterolResult = updateOrder.results!.firstWhere((r) => r.labTestId == 'test_2');
      expect(colesterolResult.resultValue, isNull);
      expect(colesterolResult.alertFlag, isNull);
    });

    test('generateUpdateOrder remueve resultados de exámenes deseleccionados', () {
      final existingOrder = OrderInDb(
        id: 'ord_500',
        createdAt: 1700000000000,
        patientId: 'p_100',
        branchId: 'b_1',
        items: [
          OrderItem(
            labTestId: 'test_1',
            name: 'Glucosa',
            salePriceApplied: 15000,
            originalPrice: 15000,
          ),
          OrderItem(
            labTestId: 'test_2',
            name: 'Colesterol Total',
            salePriceApplied: 20000,
            originalPrice: 20000,
          ),
        ],
        results: [
          OrderTestResult(
            labTestId: 'test_1',
            parameterName: 'Glucosa',
            dataType: 'numeric',
            resultValue: '90',
          ),
          OrderTestResult(
            labTestId: 'test_2',
            parameterName: 'Colesterol Total',
            dataType: 'numeric',
            resultValue: '180',
          ),
        ],
      );

      controller.populateFromOrder(existingOrder, [test1, test2]);

      // Quitar Colesterol Total
      controller.removeItem(test2);
      expect(controller.selectedItems.length, 1);

      final updateOrder = controller.generateUpdateOrder(
        branchId: 'b_1',
        currentUser: null,
        allLabTests: [test1, test2],
      );

      expect(updateOrder, isNotNull);
      expect(updateOrder!.items?.length, 1);
      expect(updateOrder.items!.first.labTestId, 'test_1');
      expect(updateOrder.results?.length, 1);
      expect(updateOrder.results!.first.labTestId, 'test_1');
      expect(updateOrder.results!.first.resultValue, '90');
      // Colesterol ya no debe existir en results
      expect(updateOrder.results!.any((r) => r.labTestId == 'test_2'), isFalse);
    });

    test(
      'Blindaje estricto de packs: impide crear o actualizar orden si el pack no hace match con sus parámetros en catálogo',
      () {
        final existingOrderWithBhc = OrderInDb(
          id: 'ord_44',
          createdAt: 1700000000000,
          patientId: 'p_100',
          branchId: 'b_1',
          items: [
            OrderItem(
              labTestId: 'pack_1',
              name: 'Perfil Lipidico',
              salePriceApplied: 30000,
              originalPrice: 30000,
              isPack: true,
            ),
          ],
          results: [],
        );

        // 1. Si populateFromOrder se llamó cuando el catálogo aún estaba vacío ([]),
        // el ítem en memoria queda como stub (isPack: true, childTestIds: []).
        controller.populateFromOrder(existingOrderWithBhc, []);

        // 2. Intentar actualizar con catálogo vacío DEBE ser bloqueado (retorna null),
        // jamás convirtiendo el pack en un único parámetro.
        expect(controller.validatePacksExpansion([]), isNotNull);
        expect(
          controller.generateUpdateOrder(
            branchId: 'b_1',
            currentUser: null,
            allLabTests: [],
          ),
          isNull,
        );

        // 3. Intentar actualizar si al catálogo le faltan los parámetros hijos del pack
        // también DEBE ser bloqueado.
        expect(controller.validatePacksExpansion([packTest]), isNotNull);
        expect(
          controller.generateUpdateOrder(
            branchId: 'b_1',
            currentUser: null,
            allLabTests: [packTest], // Faltan test1 y test2
          ),
          isNull,
        );

        // 4. Cuando el catálogo completo está presente ([packTest, test1, test2]),
        // valida exitosamente y expande los 2 parámetros hijos sin incluir pack_1 en results.
        expect(controller.validatePacksExpansion([packTest, test1, test2]), isNull);
        final validUpdate = controller.generateUpdateOrder(
          branchId: 'b_1',
          currentUser: null,
          allLabTests: [packTest, test1, test2],
        );
        expect(validUpdate, isNotNull);
        expect(validUpdate!.results, isNotNull);
        expect(validUpdate.results!.length, 2);
        expect(validUpdate.results!.any((r) => r.labTestId == 'pack_1'), isFalse);
        expect(
          validUpdate.results!.map((r) => r.labTestId),
          containsAll(['test_1', 'test_2']),
        );
      },
    );

    test('UpdateOrder.toJson incluye patientInfo', () {
      final update = UpdateOrder(
        patientId: 'p_nuevo',
        patientInfo: PatientInfo(
          name: 'Paciente Nuevo',
          gender: 'F',
          age: 40,
        ),
      );

      final json = update.toJson();
      expect(json['patientInfo'], isNotNull);
      expect(json['patientInfo']['name'], 'Paciente Nuevo');
      expect(json['patientInfo']['age'], 40);
    });

    test('generateUpdateOrder retorna null si la orden de edición no fue poblada', () {
      final order = OrderInDb(
        id: 'ord_sin_poblar',
        createdAt: 1700000000000,
        patientId: 'p_100',
        branchId: 'b_1',
        items: [
          OrderItem(
            labTestId: 'test_1',
            name: 'Glucosa',
            salePriceApplied: 15000,
            originalPrice: 15000,
          ),
        ],
      );

      final editingController = CreateOrderViewController(editingOrder: order);
      editingController.selectPatient(samplePatient);
      editingController.addService(
        OrderService(id: 'serv_1', name: 'Servicio', price: 1000),
      );

      expect(editingController.isPopulated, isFalse);
      expect(
        editingController.generateUpdateOrder(
          branchId: 'b_1',
          currentUser: null,
          allLabTests: [test1],
        ),
        isNull,
      );

      editingController.dispose();
    });

    test('selectPatient no cambia el paciente si la orden tiene resultados capturados', () {
      final order = OrderInDb(
        id: 'ord_con_resultados',
        createdAt: 1700000000000,
        patientId: 'p_100',
        branchId: 'b_1',
        items: [
          OrderItem(
            labTestId: 'test_1',
            name: 'Glucosa',
            salePriceApplied: 15000,
            originalPrice: 15000,
          ),
        ],
        results: [
          OrderTestResult(
            labTestId: 'test_1',
            parameterName: 'Glucosa',
            dataType: 'numeric',
            resultValue: '95',
          ),
        ],
      );

      final editingController = CreateOrderViewController(editingOrder: order);
      editingController.populateFromOrder(order, [test1]);

      expect(editingController.hasCapturedResults, isTrue);
      expect(editingController.selectedPatient?.id, 'p_100');

      editingController.selectPatient(
        PatientInDb(
          id: 'p_200',
          name: 'Otro Paciente',
          dateOfBirth: 0,
          gender: 'F',
          phone: '',
          originBranch: 'b_1',
          createdAt: 0,
        ),
      );
      expect(editingController.selectedPatient?.id, 'p_100');

      editingController.removePatient();
      expect(editingController.selectedPatient?.id, 'p_100');

      editingController.dispose();
    });
  });
}
