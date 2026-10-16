import 'package:flutter_test/flutter_test.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  group('ReceiptModel Tests', () {
    test('Serialización y deserialización de ReceiptInDb con formato monetario y fechas', () {
      final json = {
        'id': '101',
        'receiptNumber': '101',
        'orderId': 'ORD-55',
        'orderNumber': '55',
        'branchId': 'BR1',
        'shiftId': 'SH-2',
        'registerId': 'REG-1',
        'amount': 25050, // $250.50
        'paymentMethod': 'card',
        'concept': 'Abono a orden #55',
        'performedBy': {
          'id': 'user-1',
          'name': 'Carlos Cajero',
        },
        'patientName': 'Ana Gómez',
        'createdAt': 1776268800000,
        'updatedAt': null,
        'isDeleted': false,
      };

      final receipt = ReceiptInDb.fromJson(json);

      expect(receipt.id, '101');
      expect(receipt.receiptNumber, '101');
      expect(receipt.orderId, 'ORD-55');
      expect(receipt.orderNumber, '55');
      expect(receipt.amount, 25050);
      expect(receipt.amountDouble, 250.50);
      expect(receipt.formattedAmount, '\$250.50');
      expect(receipt.paymentMethod, 'card');
      expect(receipt.paymentMethodLabel, 'Tarjeta');
      expect(receipt.patientName, 'Ana Gómez');
      expect(receipt.performedBy.name, 'Carlos Cajero');
      expect(receipt.formattedDate, isNotEmpty);
      expect(receipt.isDeleted, false);
    });

    test('CreateReceipt serializa correctamente', () {
      final create = CreateReceipt(
        orderId: 'ORD-10',
        branchId: 'BR1',
        amount: 15000,
        paymentMethod: 'cash',
        concept: 'Pago total',
        performedBy: UserInfo(id: 'u1', name: 'Laura'),
        patientName: 'Pedro',
      );

      final json = create.toJson();
      expect(json['orderId'], 'ORD-10');
      expect(json['branchId'], 'BR1');
      expect(json['amount'], 15000);
      expect(json['paymentMethod'], 'cash');
      expect(json['patientName'], 'Pedro');
    });

    test('ReceiptQueryParams genera parámetros URL esperados', () {
      final params = ReceiptQueryParams(
        orderId: 'ORD-99',
        shiftId: 'SH-1',
        paymentMethod: 'cash',
        offset: 0,
        limit: 25,
      );

      final queryMap = params.toQueryParameters();
      expect(queryMap['orderId'], 'ORD-99');
      expect(queryMap['shiftId'], 'SH-1');
      expect(queryMap['paymentMethod'], 'cash');
      expect(queryMap['limit'], '25');
      expect(queryMap['offset'], '0');
    });
  });
}
