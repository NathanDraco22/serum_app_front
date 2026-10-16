import 'package:flutter_test/flutter_test.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  group('CashMovementModel Tests', () {
    test('Serialización y deserialización de CashMovementInDb con formato monetario y tipos', () {
      final json = {
        'id': 'mov-100',
        'shiftId': 'SH-1',
        'branchId': 'BR-1',
        'movementType': 'income',
        'paymentMethod': 'cash',
        'amount': 20000, // $200.00
        'concept': 'Fondo adicional para cambio',
        'performedBy': {
          'id': 'user-1',
          'name': 'Carlos Cajero',
        },
        'resultingBalance': 70000,
        'registerId': null,
        'createdAt': 1776268800000,
        'updatedAt': null,
        'isDeleted': false,
      };

      final movement = CashMovementInDb.fromJson(json);

      expect(movement.id, 'mov-100');
      expect(movement.shiftId, 'SH-1');
      expect(movement.branchId, 'BR-1');
      expect(movement.movementType, 'income');
      expect(movement.isIncome, true);
      expect(movement.isWithdrawal, false);
      expect(movement.typeLabel, 'Ingreso');
      expect(movement.paymentMethod, 'cash');
      expect(movement.paymentMethodLabel, 'Efectivo');
      expect(movement.amount, 20000);
      expect(movement.amountDouble, 200.00);
      expect(movement.formattedAmount, '\$200.00');
      expect(movement.resultingBalance, 70000);
      expect(movement.performedBy.name, 'Carlos Cajero');
      expect(movement.formattedDate, isNotEmpty);
      expect(movement.isDeleted, false);
    });

    test('CreateCashMovement serializa correctamente', () {
      final create = CreateCashMovement(
        shiftId: 'SH-2',
        branchId: 'BR-1',
        movementType: 'withdrawal',
        paymentMethod: 'cash',
        amount: 15000,
        concept: 'Compra de garrafón de agua',
        performedBy: UserInfo(id: 'u1', name: 'Laura'),
      );

      final json = create.toJson();
      expect(json['shiftId'], 'SH-2');
      expect(json['branchId'], 'BR-1');
      expect(json['movementType'], 'withdrawal');
      expect(json['paymentMethod'], 'cash');
      expect(json['amount'], 15000);
      expect(json['concept'], 'Compra de garrafón de agua');
      expect(json['performedBy']['name'], 'Laura');
    });

    test('CashMovementQueryParams genera parámetros URL esperados', () {
      final params = CashMovementQueryParams(
        shiftId: 'SH-2',
        movementType: 'withdrawal',
        offset: 0,
        limit: 20,
      );

      final queryMap = params.toQueryParameters();
      expect(queryMap['shiftId'], 'SH-2');
      expect(queryMap['movementType'], 'withdrawal');
      expect(queryMap['offset'], '0');
      expect(queryMap['limit'], '20');
    });
  });
}
