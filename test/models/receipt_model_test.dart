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
      expect(receipt.referenceNumber, isNull);
      expect(receipt.bank, isNull);
    });

    test('ReceiptInDb y OrderPayRequest con transferencia bancaria y selección de banco', () {
      final json = {
        'id': '102',
        'receiptNumber': '102',
        'orderId': 'ORD-60',
        'orderNumber': '60',
        'branchId': 'BR1',
        'shiftId': 'SH-2',
        'amount': 30000,
        'paymentMethod': 'transfer',
        'concept': 'Liquidación de orden #ORD-60',
        'performedBy': {
          'id': 'user-1',
          'name': 'Carlos Cajero',
        },
        'patientName': 'María Torres',
        'referenceNumber': '987654321',
        'bank': 'BAC',
        'createdAt': 1776268800000,
      };

      final receipt = ReceiptInDb.fromJson(json);

      expect(receipt.paymentMethod, 'transfer');
      expect(receipt.paymentMethodLabel, 'Transferencia');
      expect(receipt.bank, 'BAC');
      expect(receipt.referenceNumber, '987654321');
      expect(receipt.paymentDetailsLabel, 'Transferencia (BAC • Ref: 987654321)');

      final payRequest = OrderPayRequest(
        amount: 30000,
        shiftId: 'SH-2',
        paymentMethod: 'transfer',
        performedBy: UserInfo(id: 'u1', name: 'Carlos'),
        referenceNumber: '987654321',
        bank: 'BAC',
      );

      final reqJson = payRequest.toJson();
      expect(reqJson['paymentMethod'], 'transfer');
      expect(reqJson['referenceNumber'], '987654321');
      expect(reqJson['bank'], 'BAC');
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
