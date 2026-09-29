import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/widgets/common/search_field_debounced.dart';

void main() {
  testWidgets('SearchFieldDebounced emits query after debounce duration and clears correctly',
      (WidgetTester tester) async {
    String lastQuery = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchFieldDebounced(
            duration: const Duration(milliseconds: 200),
            onSearch: (query) {
              lastQuery = query;
            },
          ),
        ),
      ),
    );

    // Initial state: empty
    expect(find.byType(TextField), findsOneWidget);
    expect(lastQuery, isEmpty);

    // Enter text
    await tester.enterText(find.byType(TextField), 'Glucosa');
    await tester.pump(const Duration(milliseconds: 50));
    // Still not called because debounce is 200ms
    expect(lastQuery, isEmpty);

    // Advance beyond debounce duration
    await tester.pump(const Duration(milliseconds: 200));
    expect(lastQuery, 'Glucosa');

    // Suffix clear button should now be visible
    expect(find.byIcon(Icons.clear), findsOneWidget);

    // Tap clear button
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    // Query should be empty and text field cleared
    expect(lastQuery, '');
    expect(find.text('Glucosa'), findsNothing);
  });
}
