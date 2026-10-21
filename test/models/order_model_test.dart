import 'package:flutter_test/flutter_test.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  group('OrderModel Notes & Description Tests', () {
    test('CreateOrder serializa correctamente el campo notes', () {
      final order = CreateOrder(
        patientId: 'patient_1',
        branchId: 'branch_1',
        notes: 'Muestra ligeramente hemolizada',
      );

      final json = order.toJson();
      expect(json['notes'], 'Muestra ligeramente hemolizada');
    });

    test('OrderInDb parsea correctamente tanto notes como description', () {
      final jsonWithNotes = {
        'id': 'ord_1',
        'patientId': 'p_1',
        'branchId': 'b_1',
        'createdAt': 1700000000000,
        'notes': 'Paciente en ayunas de 12 horas',
      };

      final orderNotes = OrderInDb.fromJson(jsonWithNotes);
      expect(orderNotes.notes, 'Paciente en ayunas de 12 horas');
      expect(orderNotes.description, 'Paciente en ayunas de 12 horas');

      final jsonWithDesc = {
        'id': 'ord_2',
        'patientId': 'p_2',
        'branchId': 'b_2',
        'createdAt': 1700000000000,
        'description': 'Control mensual de glucosa',
      };

      final orderDesc = OrderInDb.fromJson(jsonWithDesc);
      expect(orderDesc.notes, 'Control mensual de glucosa');
      expect(orderDesc.description, 'Control mensual de glucosa');
    });

    test('UpdateOrder serializa correctamente el campo notes', () {
      final update = UpdateOrder(
        notes: 'Se repite prueba para confirmación',
      );

      final json = update.toJson();
      expect(json['notes'], 'Se repite prueba para confirmación');
    });
  });
}
