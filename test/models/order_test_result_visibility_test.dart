import 'package:flutter_test/flutter_test.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  group('OrderTestResult showInPrint tests', () {
    test('default showInPrint should be true', () {
      final result = OrderTestResult(
        labTestId: 'test-1',
        parameterName: 'Hemoglobina',
        dataType: 'numeric',
      );

      expect(result.showInPrint, isTrue);
    });

    test('fromJson defaults showInPrint to true if absent', () {
      final json = {
        'labTestId': 'test-2',
        'parameterName': 'Hematocrito',
        'dataType': 'numeric',
        'resultValue': '42.5',
      };

      final result = OrderTestResult.fromJson(json);
      expect(result.showInPrint, isTrue);
      expect(result.resultValue, '42.5');
    });

    test('fromJson parses showInPrint correctly when false', () {
      final json = {
        'labTestId': 'test-3',
        'parameterName': 'Eosinófilos',
        'dataType': 'numeric',
        'showInPrint': false,
      };

      final result = OrderTestResult.fromJson(json);
      expect(result.showInPrint, isFalse);
    });

    test('toJson serializes showInPrint correctly', () {
      final result = OrderTestResult(
        labTestId: 'test-4',
        parameterName: 'Leucocitos',
        dataType: 'numeric',
        showInPrint: false,
      );

      final json = result.toJson();
      expect(json['showInPrint'], isFalse);
    });

    test('copyWith updates showInPrint correctly', () {
      final result = OrderTestResult(
        labTestId: 'test-5',
        parameterName: 'Plaquetas',
        dataType: 'numeric',
        showInPrint: true,
      );

      final updated = result.copyWith(showInPrint: false);
      expect(updated.showInPrint, isFalse);
      expect(updated.parameterName, 'Plaquetas');
    });
  });
}
