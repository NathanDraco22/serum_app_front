import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/quotation/controllers/create_quotation_view_controller.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  group('CreateQuotationViewController Unit Tests', () {
    late CreateQuotationViewController controller;

    final samplePatient = PatientInDb(
      id: 'pat_1',
      name: 'Carlos Ruiz',
      originBranch: 'branch_1',
      dateOfBirth: 946684800000,
      gender: 'M',
      phone: '87654321',
      address: 'Granada',
      cardId: '001-020290-0002B',
      email: 'carlos@example.com',
      age: 36,
      createdAt: 0,
    );

    final sampleDoctor = DoctorInDb(
      id: 'doc_1',
      name: 'Dra. Ana Miranda',
      originBranch: 'branch_1',
      specialty: 'Pediatría',
      phone: '88776655',
      createdAt: 0,
    );

    final test1 = LabTestInDb(
      id: 'test_1',
      name: 'Hemograma Completo',
      salePrice: 12000, // C$ 120.00
      salePrice2: 10000, // C$ 100.00
      commercialCategory: 'Hematología',
      createdAt: 0,
    );

    final test2 = LabTestInDb(
      id: 'test_2',
      name: 'Examen General de Orina',
      salePrice: 8000, // C$ 80.00
      salePrice2: 7000,
      commercialCategory: 'Uroanálisis',
      createdAt: 0,
    );

    setUp(() {
      controller = CreateQuotationViewController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Estado inicial en blanco e isEmpty == true', () {
      expect(controller.isEmpty, isTrue);
      expect(controller.selectedPatient, isNull);
      expect(controller.selectedDoctor, isNull);
      expect(controller.selectedItems, isEmpty);
      expect(controller.casualClientName, isEmpty);
      expect(controller.clientName, 'Cliente General');
      expect(controller.totalAmount, 0);
      expect(controller.defaultPriceLevel, 1);
      expect(controller.isSubmitting, isFalse);
    });

    test('Seleccionar paciente sincroniza casualClientNameController y notifica', () {
      int notifications = 0;
      controller.addListener(() => notifications++);

      controller.selectPatient(samplePatient);
      expect(controller.selectedPatient, equals(samplePatient));
      expect(controller.casualClientName, 'Carlos Ruiz');
      expect(controller.clientName, 'Carlos Ruiz');
      expect(notifications, 1);

      controller.removePatient();
      expect(controller.selectedPatient, isNull);
      expect(controller.casualClientName, isEmpty);
      expect(controller.clientName, 'Cliente General');
      expect(notifications, 2);
    });

    test('Cliente casual manual define clientName cuando no hay paciente formal', () {
      controller.casualClientNameController.text = 'Empresa XYZ';
      expect(controller.clientName, 'Empresa XYZ');
      expect(controller.isEmpty, isFalse);

      // Si luego se asocia un paciente, prevalece el paciente
      controller.selectPatient(samplePatient);
      expect(controller.clientName, 'Carlos Ruiz');
    });

    test('Selección y remoción de médico', () {
      controller.selectDoctor(sampleDoctor);
      expect(controller.selectedDoctor, equals(sampleDoctor));

      controller.removeDoctor();
      expect(controller.selectedDoctor, isNull);
    });

    test('Toggle, remoción y cálculo de tarifas de exámenes cotizados', () {
      controller.toggleItem(test1);
      expect(controller.selectedItems.length, 1);
      expect(controller.isItemSelected('test_1'), isTrue);
      expect(controller.totalAmount, 12000);

      // Toggle al mismo estudio lo remueve
      controller.toggleItem(test1);
      expect(controller.selectedItems, isEmpty);
      expect(controller.totalAmount, 0);

      // Agregar ambos estudios
      controller.toggleItem(test1);
      controller.toggleItem(test2);
      expect(controller.selectedItems.length, 2);
      expect(controller.totalAmount, 20000); // 12000 + 8000

      // Cambiar nivel de tarifa individual para test1 al Nivel 2
      controller.changeItemPriceLevel(test1.id, 2);
      expect(controller.getItemPriceLevel(test1.id), 2);
      expect(controller.getItemEffectivePrice(test1), 10000); // test1 salePrice2
      expect(controller.totalAmount, 18000); // 10000 + 8000

      // Cambiar nivel de tarifa global a 2
      controller.changeDefaultPriceLevel(2);
      expect(controller.defaultPriceLevel, 2);
      expect(controller.getItemEffectivePrice(test2), 7000); // test2 salePrice2
      expect(controller.totalAmount, 17000); // 10000 + 7000

      // Remover test1
      controller.removeItem(test1);
      expect(controller.selectedItems.length, 1);
      expect(controller.totalAmount, 7000);
    });

    test('generateCreateQuotation retorna null si no hay exámenes agregados', () {
      controller.selectPatient(samplePatient);
      expect(controller.generateCreateQuotation(branchId: 'branch_1'), isNull);
    });

    test('generateCreateQuotation genera el DTO con datos completos y snapshots', () {
      controller.selectPatient(samplePatient);
      controller.selectDoctor(sampleDoctor);
      controller.toggleItem(test1);
      controller.toggleItem(test2);

      final dto = controller.generateCreateQuotation(branchId: 'branch_central');
      expect(dto, isNotNull);
      expect(dto!.clientName, 'Carlos Ruiz');
      expect(dto.branchId, 'branch_central');
      expect(dto.patientId, 'pat_1');
      expect(dto.clientInfo?.name, 'Carlos Ruiz');
      expect(dto.clientInfo?.cardId, '001-020290-0002B');
      expect(dto.doctorId, 'doc_1');
      expect(dto.doctorInfo?.name, 'Dra. Ana Miranda');
      expect(dto.doctorInfo?.specialty, 'Pediatría');
      expect(dto.exams.length, 2);
      expect(dto.exams.first.labTestId, 'test_1');
      expect(dto.exams.first.quotedPrice, 12000);
      expect(dto.totalAmount, 20000);
      expect(dto.status, 'pending');
    });

    test('generateCreateQuotation funciona para cliente casual sin paciente registrado', () {
      controller.casualClientNameController.text = 'Juan Casual';
      controller.toggleItem(test1);

      final dto = controller.generateCreateQuotation(branchId: 'branch_central');
      expect(dto, isNotNull);
      expect(dto!.clientName, 'Juan Casual');
      expect(dto.patientId, isNull);
      expect(dto.clientInfo?.name, 'Juan Casual');
      expect(dto.totalAmount, 12000);
    });

    test('clearCart y clearAll limpian el estado correspondientemente', () {
      controller.selectPatient(samplePatient);
      controller.selectDoctor(sampleDoctor);
      controller.toggleItem(test1);

      controller.clearCart();
      expect(controller.selectedItems, isEmpty);
      expect(controller.totalAmount, 0);
      // Paciente y médico se conservan tras clearCart
      expect(controller.selectedPatient, equals(samplePatient));
      expect(controller.selectedDoctor, equals(sampleDoctor));

      controller.clearAll();
      expect(controller.isEmpty, isTrue);
      expect(controller.selectedPatient, isNull);
      expect(controller.selectedDoctor, isNull);
      expect(controller.casualClientName, isEmpty);
    });
  });
}
