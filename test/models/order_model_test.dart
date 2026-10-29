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

  group('OrderModel Discounts Tests', () {
    test('CreateOrder serializa correctamente descuentos y calcula salePriceApplied', () {
      final order = CreateOrder(
        patientId: 'patient_1',
        branchId: 'branch_1',
        items: [
          OrderItem(
            labTestId: 'test_1',
            name: 'Glucosa',
            salePriceApplied: 50000,
            originalPrice: 50000,
          ),
        ],
        discounts: [
          OrderDiscount(
            description: 'Tercera Edad',
            type: 'percentage',
            value: 10.0,
            appliedAmount: 5000,
          ),
        ],
      );

      expect(order.grossTotal, 50000);
      expect(order.totalDiscounts, 5000);
      expect(order.salePriceApplied, 45000);

      final json = order.toJson();
      expect(json['discounts'], isA<List>());
      expect((json['discounts'] as List).length, 1);
      expect((json['discounts'] as List).first['description'], 'Tercera Edad');
      expect((json['discounts'] as List).first['type'], 'percentage');
      expect((json['discounts'] as List).first['value'], 10.0);
      expect((json['discounts'] as List).first['appliedAmount'], 5000);
    });

    test('OrderInDb parsea correctamente órdenes con descuentos', () {
      final json = {
        'id': 'ord_disc_1',
        'patientId': 'p_1',
        'branchId': 'b_1',
        'createdAt': 1700000000000,
        'items': [
          {
            'labTestId': 't_1',
            'name': 'Perfil Lipídico',
            'salePriceApplied': 40000,
          }
        ],
        'discounts': [
          {
            'description': 'Cupón Descuento',
            'type': 'amount',
            'value': 10000,
            'appliedAmount': 10000,
          }
        ],
        'totalPrice': 30000,
      };

      final order = OrderInDb.fromJson(json);
      expect(order.discounts.length, 1);
      expect(order.discounts.first.description, 'Cupón Descuento');
      expect(order.discounts.first.isAmount, true);
      expect(order.discounts.first.appliedAmount, 10000);
      expect(order.totalPrice, 30000);
      expect(order.grossTotal, 40000);
      expect(order.totalDiscounts, 10000);
    });

    test('OrderInDb retrocompatibilidad: órdenes sin descuentos parsean lista vacía', () {
      final legacyJson = {
        'id': 'ord_legacy',
        'patientId': 'p_1',
        'branchId': 'b_1',
        'createdAt': 1700000000000,
        'items': [
          {
            'labTestId': 't_legacy',
            'name': 'Hemograma',
            'salePriceApplied': 30000,
          }
        ],
        'totalPrice': 30000,
      };

      final order = OrderInDb.fromJson(legacyJson);
      expect(order.discounts, isEmpty);
      expect(order.totalDiscounts, 0);
      expect(order.totalPrice, 30000);
    });
  });
}
