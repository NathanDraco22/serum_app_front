import 'package:flutter_test/flutter_test.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  group('LabTestAccount & Commercial Models Tests', () {
    test('LabTestCommercial serializes and deserializes correctly', () {
      final commercial = LabTestCommercial(
        salePrice: 15000,
        salePrice2: 12000,
        costPrice: 5000,
        currency: 'USD',
      );

      final json = commercial.toJson();
      expect(json['salePrice'], equals(15000));
      expect(json['salePrice2'], equals(12000));
      expect(json['costPrice'], equals(5000));
      expect(json['currency'], equals('USD'));

      final fromJson = LabTestCommercial.fromJson(json);
      expect(fromJson.salePrice, equals(15000));
      expect(fromJson.salePrice2, equals(12000));
      expect(fromJson.costPrice, equals(5000));
      expect(fromJson.currency, equals('USD'));
    });

    test('CreateLabTestAccount serializes correctly', () {
      final account = CreateLabTestAccount(
        branchId: 'branch_1',
        labTestId: 'test_1',
        commercial: LabTestCommercial(
          salePrice: 20000,
          salePrice2: 18000,
          costPrice: 7000,
        ),
      );

      final json = account.toJson();
      expect(json['branchId'], equals('branch_1'));
      expect(json['labTestId'], equals('test_1'));
      expect(json['commercial']['salePrice'], equals(20000));
      expect(json['commercial']['costPrice'], equals(7000));
    });

    test('LabTestAccountInDb parses from JSON', () {
      final json = {
        'id': 'acc_123',
        'branchId': 'branch_1',
        'labTestId': 'test_1',
        'commercial': {
          'salePrice': 25000,
          'salePrice2': 22000,
          'costPrice': 9000,
          'currency': 'USD',
        },
        'createdAt': 1728864000000,
        'updatedAt': null,
        'isDeleted': false,
      };

      final account = LabTestAccountInDb.fromJson(json);
      expect(account.id, equals('acc_123'));
      expect(account.branchId, equals('branch_1'));
      expect(account.commercial.salePrice, equals(25000));
      expect(account.commercial.costPrice, equals(9000));
      expect(account.isDeleted, isFalse);
    });

    test('CreateLabTest includes branchId and costPrice in toJson', () {
      final create = CreateLabTest(
        branchId: 'branch_norte',
        name: 'Biometría Hemática',
        salePrice: 18000,
        salePrice2: 15000,
        costPrice: 6000,
      );

      final json = create.toJson();
      expect(json['branchId'], equals('branch_norte'));
      expect(json['costPrice'], equals(6000));
      expect(json['salePrice'], equals(18000));
    });

    test('LabTestInDb parses enriched commercial data correctly', () {
      final json = {
        'id': 'test_bio',
        'name': 'Biometría Hemática',
        'commercialCategory': 'Hematología',
        'salePrice': 18000,
        'salePrice2': 15000,
        'costPrice': 6000,
        'currency': 'USD',
        'commercial': {
          'salePrice': 18000,
          'salePrice2': 15000,
          'costPrice': 6000,
          'currency': 'USD',
        },
        'createdAt': 1728864000000,
      };

      final testInDb = LabTestInDb.fromJson(json);
      expect(testInDb.id, equals('test_bio'));
      expect(testInDb.salePrice, equals(18000));
      expect(testInDb.salePrice2, equals(15000));
      expect(testInDb.costPrice, equals(6000));
      expect(testInDb.commercial, isNotNull);
      expect(testInDb.commercial!.costPrice, equals(6000));
    });
  });
}
