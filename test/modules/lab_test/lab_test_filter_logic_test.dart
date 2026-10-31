import 'package:flutter_test/flutter_test.dart';
import 'package:serum_business/serum_business.dart';
import 'package:serum_app_front/src/modules/lab_test/widgets/clinical_classification_registry.dart';

void main() {
  group('LabTestScreen Filter Logic Tests', () {
    final testHematologyRed = LabTestInDb(
      id: 'test-1',
      name: 'Hemoglobina',
      code: 'HGB',
      commercialCategory: 'Hematología',
      subclassification: 'Serie Roja',
      salePrice: 1000,
      currency: 'USD',
      isPack: false,
      useChildTestsPriceSum: false,
      childTestIds: [],
      createdAt: 1700000000000,
      isDeleted: false,
    );

    final testHematologyWhite = LabTestInDb(
      id: 'test-2',
      name: 'Leucocitos',
      code: 'LEU',
      commercialCategory: 'Hematología',
      subclassification: 'Serie Blanca',
      salePrice: 1000,
      currency: 'USD',
      isPack: false,
      useChildTestsPriceSum: false,
      childTestIds: [],
      createdAt: 1700000000000,
      isDeleted: false,
    );

    final testUroanalysis = LabTestInDb(
      id: 'test-3',
      name: 'Examen General de Orina',
      code: 'EGO',
      commercialCategory: 'Uroanálisis',
      subclassification: 'Examen Físico-Químico',
      salePrice: 2000,
      currency: 'USD',
      isPack: true,
      useChildTestsPriceSum: false,
      childTestIds: [],
      createdAt: 1700000000000,
      isDeleted: false,
    );

    final testParameter = LabTestInDb(
      id: 'test-4',
      name: 'pH Urinario',
      code: 'PH-URI',
      commercialCategory: 'Uroanálisis',
      subclassification: 'Examen Físico-Químico',
      isProfileParameter: true,
      salePrice: 0,
      currency: 'USD',
      isPack: false,
      useChildTestsPriceSum: false,
      childTestIds: [],
      createdAt: 1700000000000,
      isDeleted: false,
    );

    final allTests = [
      testHematologyRed,
      testHematologyWhite,
      testUroanalysis,
      testParameter,
    ];

    List<LabTestInDb> applyFilters({
      required List<LabTestInDb> baseList,
      String filterType = 'all',
      String selectedCategory = 'Todas',
      String selectedSubclassification = 'Todas',
      bool hideProfileParameters = true,
    }) {
      final filtered = baseList.where((t) {
        if (filterType == 'individual' && (t.isPack || t.isProfileParameter)) return false;
        if (filterType == 'pack' && !t.isPack) return false;
        if (filterType == 'parameter' && !t.isProfileParameter) return false;
        if (hideProfileParameters && t.isProfileParameter && filterType == 'all') {
          return false;
        }
        if (selectedCategory != 'Todas' &&
            t.commercialCategory.trim().toLowerCase() != selectedCategory.toLowerCase()) {
          return false;
        }
        if (selectedSubclassification != 'Todas' &&
            t.subclassification.trim().toLowerCase() != selectedSubclassification.toLowerCase()) {
          return false;
        }
        return true;
      }).toList();

      filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return filtered;
    }

    test('Filters by category correctly', () {
      final hematologyOnly = applyFilters(
        baseList: allTests,
        selectedCategory: 'Hematología',
      );
      expect(hematologyOnly.length, equals(2));
      expect(hematologyOnly.map((t) => t.id), containsAll(['test-1', 'test-2']));

      final uroOnly = applyFilters(
        baseList: allTests,
        selectedCategory: 'Uroanálisis',
        hideProfileParameters: true,
      );
      // test-4 is a parameter and hidden by default
      expect(uroOnly.length, equals(1));
      expect(uroOnly.first.id, equals('test-3'));
    });

    test('Filters by category AND subclassification correctly', () {
      final redSeries = applyFilters(
        baseList: allTests,
        selectedCategory: 'Hematología',
        selectedSubclassification: 'Serie Roja',
      );
      expect(redSeries.length, equals(1));
      expect(redSeries.first.id, equals('test-1'));

      final whiteSeries = applyFilters(
        baseList: allTests,
        selectedCategory: 'Hematología',
        selectedSubclassification: 'Serie Blanca',
      );
      expect(whiteSeries.length, equals(1));
      expect(whiteSeries.first.id, equals('test-2'));
    });

    test('Subclassification extracts correctly for category and global', () {
      // For Hematology:
      final subsHematology = <String>{'Todas'};
      for (final t in allTests) {
        if (t.commercialCategory.toLowerCase() == 'hematología'.toLowerCase() &&
            t.subclassification.isNotEmpty) {
          subsHematology.add(t.subclassification);
        }
      }
      for (final s in ClinicalClassificationRegistry.getSubclassificationsFor('Hematología')) {
        subsHematology.add(s);
      }
      expect(subsHematology, containsAll(['Todas', 'Serie Roja', 'Serie Blanca']));
    });
  });
}
