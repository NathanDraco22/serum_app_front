import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/order/widgets/order_results_dialogs/parameter_card.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  group('ParameterCard Visibility Toggle Tests', () {
    testWidgets('renders visible eye icon and toggles to hidden', (tester) async {
      bool? toggledVal;
      final result = OrderTestResult(
        labTestId: 'test-1',
        parameterName: 'Hemoglobina',
        dataType: 'numeric',
        unitOfMeasure: 'g/dL',
        showInPrint: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParameterCard(
              result: result,
              alert: null,
              isAlert: false,
              isReadOnly: false,
              controller: TextEditingController(text: '14.5'),
              qualitativeValue: null,
              showInPrint: true,
              onToggleVisibility: (val) {
                toggledVal = val;
              },
              onQualitativeChanged: (_) {},
              onNumericChanged: (_) {},
            ),
          ),
        ),
      );

      // Verify eye icon is present
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.text('NO SE IMPRIME'), findsNothing);

      // Tap the eye icon button
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(toggledVal, isFalse);
    });

    testWidgets('renders hidden eye icon and "NO SE IMPRIME" badge when showInPrint is false',
        (tester) async {
      bool? toggledVal;
      final result = OrderTestResult(
        labTestId: 'test-2',
        parameterName: 'Eosinófilos',
        dataType: 'numeric',
        unitOfMeasure: '%',
        showInPrint: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParameterCard(
              result: result,
              alert: null,
              isAlert: false,
              isReadOnly: false,
              controller: TextEditingController(text: ''),
              qualitativeValue: null,
              showInPrint: false,
              onToggleVisibility: (val) {
                toggledVal = val;
              },
              onQualitativeChanged: (_) {},
              onNumericChanged: (_) {},
            ),
          ),
        ),
      );

      // Verify visibility_off icon and badge
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.text('NO SE IMPRIME'), findsOneWidget);

      // Tap eye icon to make it visible
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      expect(toggledVal, isTrue);
    });
  });
}
