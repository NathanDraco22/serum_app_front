import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/lab_test/widgets/reference_values_editor.dart';
import 'package:serum_business/serum_business.dart';

String? _fieldText(WidgetTester tester, String key) {
  return tester.widget<TextFormField>(find.byKey(ValueKey(key))).controller?.text;
}

void main() {
  testWidgets(
    'ReferenceValuesEditor muestra la unidad por rango y cambiar la unidad conserva los días',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var values = <ReferenceValue>[
        ReferenceValue(
          patientType: 'general',
          gender: 'both',
          minAgeDays: 365,
          maxAgeDays: 7300,
          minValue: 70.0,
          maxValue: 100.0,
          ageUnit: 'years',
          useAge: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Form(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return ReferenceValuesEditor(
                      values: values,
                      unitOfMeasure: 'mg/dL',
                      onChanged: (updated) {
                        setState(() => values = updated);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ReferenceValuesEditor), findsOneWidget);
      expect(find.text('Rango 1'), findsOneWidget);

      final ageUnitDropdown = find.descendant(
        of: find.byKey(const ValueKey('ref_age_unit_0')),
        matching: find.byType(DropdownButtonFormField<String>),
      );
      expect(ageUnitDropdown, findsOneWidget);

      await tester.tap(ageUnitDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Días').last);
      await tester.pumpAndSettle();

      expect(values.single.ageUnit, 'days');
      expect(values.single.minAgeDays, 365);
      expect(values.single.maxAgeDays, 7300);
      expect(_fieldText(tester, 'ref_min_age_0'), '365');
      expect(_fieldText(tester, 'ref_max_age_0'), '7300');
    },
  );

  testWidgets('ReferenceValuesEditor aplica los switches a todos los rangos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var values = <ReferenceValue>[
      ReferenceValue(
        patientType: 'general',
        gender: 'both',
        minAgeDays: 0,
        maxAgeDays: 36500,
        minValue: 70.0,
        maxValue: 100.0,
        ageUnit: 'years',
      ),
      ReferenceValue(
        patientType: 'general',
        gender: 'both',
        minAgeDays: 0,
        maxAgeDays: 36500,
        minValue: 4.0,
        maxValue: 10.0,
        ageUnit: 'years',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Form(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return ReferenceValuesEditor(
                    values: values,
                    unitOfMeasure: 'mg/dL',
                    onChanged: (updated) {
                      setState(() => values = updated);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final ageSwitch = find.descendant(
      of: find.byKey(const ValueKey('ref_use_age')),
      matching: find.byType(Switch),
    );
    expect(ageSwitch, findsOneWidget);

    await tester.tap(ageSwitch);
    await tester.pumpAndSettle();

    expect(values.every((ref) => ref.useAge), isTrue);
    expect(find.byKey(const ValueKey('ref_min_age_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('ref_min_age_1')), findsOneWidget);
  });

  testWidgets(
    'ReferenceValuesEditor renderiza todos los campos con altura uniforme y alineada',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final values = <ReferenceValue>[
        ReferenceValue(
          patientType: 'general',
          gender: 'both',
          minAgeDays: 0,
          maxAgeDays: 36500,
          minValue: 70.0,
          maxValue: 100.0,
          ageUnit: 'years',
          useAge: true,
          useGender: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Form(
                child: ReferenceValuesEditor(
                  values: values,
                  unitOfMeasure: 'mg/dL',
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final genderDropdown = find.descendant(
        of: find.byKey(const ValueKey('ref_gender_0')),
        matching: find.byType(DropdownButtonFormField<String>),
      );
      final ageUnitDropdown = find.descendant(
        of: find.byKey(const ValueKey('ref_age_unit_0')),
        matching: find.byType(DropdownButtonFormField<String>),
      );
      final minAgeField = find.byKey(const ValueKey('ref_min_age_0'));
      final maxAgeField = find.byKey(const ValueKey('ref_max_age_0'));
      final minValueField = find.byKey(const ValueKey('ref_min_value_0'));
      final maxValueField = find.byKey(const ValueKey('ref_max_value_0'));

      expect(genderDropdown, findsOneWidget);
      expect(ageUnitDropdown, findsOneWidget);
      expect(minAgeField, findsOneWidget);
      expect(maxAgeField, findsOneWidget);
      expect(minValueField, findsOneWidget);
      expect(maxValueField, findsOneWidget);

      final genderHeight = tester.getSize(genderDropdown).height;
      final ageUnitHeight = tester.getSize(ageUnitDropdown).height;
      final minAgeHeight = tester.getSize(minAgeField).height;
      final maxAgeHeight = tester.getSize(maxAgeField).height;
      final minValueHeight = tester.getSize(minValueField).height;
      final maxValueHeight = tester.getSize(maxValueField).height;

      // Todos los campos deben tener la misma altura exacta (44px)
      expect(genderHeight, equals(44.0));
      expect(ageUnitHeight, equals(44.0));
      expect(minAgeHeight, equals(44.0));
      expect(maxAgeHeight, equals(44.0));
      expect(minValueHeight, equals(44.0));
      expect(maxValueHeight, equals(44.0));
    },
  );
}
