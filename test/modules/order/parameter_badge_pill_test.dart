import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/order/widgets/order_results_dialogs/parameter_badge_pill.dart';
import 'package:serum_app_front/src/modules/order/widgets/order_results_dialogs/parameter_card.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  group('ParameterBadgePill Tests', () {
    testWidgets('renders simple text without icon when icon is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ParameterBadgePill(
              label: 'NORMAL',
              bgColor: Colors.green,
              textColor: Colors.white,
              borderColor: Colors.greenAccent,
            ),
          ),
        ),
      );

      expect(find.text('NORMAL'), findsOneWidget);
      expect(find.byType(Row), findsNothing);
    });

    testWidgets('renders icon and text in a Row when icon is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ParameterBadgePill(
              label: 'PENDIENTE',
              icon: Icon(Icons.warning_amber_rounded, size: 11, color: Colors.amber),
              bgColor: Colors.grey,
              textColor: Colors.black,
              borderColor: Colors.black12,
            ),
          ),
        ),
      );

      expect(find.text('PENDIENTE'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });
  });

  group('ParameterCard Pending Status Badge Tests', () {
    testWidgets('renders warning triangle icon on PENDIENTE badge when result is empty',
        (tester) async {
      final result = OrderTestResult(
        labTestId: 'test-pending',
        parameterName: 'Glucosa',
        dataType: 'numeric',
        unitOfMeasure: 'mg/dL',
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
              controller: TextEditingController(text: ''),
              qualitativeValue: null,
              showInPrint: true,
              onToggleVisibility: (_) {},
              onQualitativeChanged: (_) {},
              onNumericChanged: (_) {},
            ),
          ),
        ),
      );

      // Verify that the PENDIENTE badge and the warning amber triangle icon are rendered
      expect(find.text('PENDIENTE'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('does not render warning triangle icon when result has a normal value',
        (tester) async {
      final result = OrderTestResult(
        labTestId: 'test-filled',
        parameterName: 'Glucosa',
        dataType: 'numeric',
        unitOfMeasure: 'mg/dL',
        showInPrint: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParameterCard(
              result: result,
              alert: 'NORMAL',
              isAlert: false,
              isReadOnly: false,
              controller: TextEditingController(text: '85'),
              qualitativeValue: null,
              showInPrint: true,
              onToggleVisibility: (_) {},
              onQualitativeChanged: (_) {},
              onNumericChanged: (_) {},
            ),
          ),
        ),
      );

      // Verify NORMAL badge is shown and warning icon is NOT rendered
      expect(find.text('NORMAL'), findsOneWidget);
      expect(find.text('PENDIENTE'), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });
  });
}
