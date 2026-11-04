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
      controller.addDiscount(OrderDiscount(
        id: 'disc_1',
        description: 'Descuento Familiar',
        type: 'amount',
        value: 20.0,
        appliedAmount: 2000,
      ));

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

      // Debe expandir los parámetros hijos del pack en results
      expect(order.results.length, 2);
      expect(order.results.map((r) => r.labTestId).toList(), containsAll(['test_1', 'test_2']));

      // Al ser operador y haber descuento -> nace bloqueada
      expect(order.isBlocked, isTrue);
      expect(order.approval, isNotNull);
      expect(order.approval!.requiresApproval, isTrue);
      expect(order.approval!.isApproved, isFalse);
    });

    test('generateCreateOrder auto-aprueba si el usuario es supervisor/admin (accessLevel > 3)', () {
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
    });

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
  });
}
