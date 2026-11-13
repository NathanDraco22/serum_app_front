import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_business/serum_business.dart';
import 'package:serum_app_front/src/modules/lab_test/controllers/lab_test_form_view_controller.dart';

void main() {
  group('LabTestFormViewController Unit Tests', () {
    test('Estado inicial en modo creación contiene valores por defecto institucionales', () {
      final controller = LabTestFormViewController();

      expect(controller.isEdit, isFalse);
      expect(controller.name, isEmpty);
      expect(controller.code, isEmpty);
      expect(controller.commercialCategory, 'Hematología');
      expect(controller.subclassification, 'General');
      expect(controller.isPack, isFalse);
      expect(controller.useChildTestsPriceSum, isTrue);
      expect(controller.salePrice, 0.0);
      expect(controller.salePrice2, 0.0);
      expect(controller.priceInCents, 0);
      expect(controller.price2InCents, 0);
      expect(controller.dataType, 'numeric');
      expect(controller.unitOfMeasure, 'mg/dL');
      expect(controller.referenceValues.length, 1);
      expect(controller.referenceValues.first.minValue, 70.0);
      expect(controller.referenceValues.first.maxValue, 100.0);
      expect(controller.referenceValues.first.ageUnit, 'years');
      expect(controller.qualitativeOptions, ['Negativo', 'Positivo']);
      expect(controller.expectedQualitativeValue, 'Negativo');

      controller.dispose();
    });

    test('Estado inicial en modo edición precarga datos existentes correctamente', () {
      final existingTest = LabTestInDb(
        id: 'test-123',
        name: 'Glucosa en Sangre',
        code: 'GLU-01',
        commercialCategory: 'Bioquímica Clínica',
        subclassification: 'Carbohidratos / Glucosa',
        salePrice: 1500, // $15.00
        salePrice2: 1200, // $12.00
        costPrice: 500,
        currency: 'USD',
        isPack: false,
        useChildTestsPriceSum: false,
        childTestIds: [],
        dataType: 'numeric',
        unitOfMeasure: 'mg/dL',
        referenceValues: [
          ReferenceValue(
            patientType: 'general',
            gender: 'both',
            minAgeDays: 0,
            maxAgeDays: 36500,
            minValue: 74.0,
            maxValue: 106.0,
            ageUnit: 'months',
            useAge: true,
            useGender: true,
          ),
        ],
        qualitativeOptions: [],
        expectedQualitativeValue: null,
        referenceText: 'Valores en ayunas',
        isProfileParameter: false,
        createdAt: 1000,
        updatedAt: 1000,
      );

      final controller = LabTestFormViewController(initialLabTest: existingTest);

      expect(controller.isEdit, isTrue);
      expect(controller.name, 'Glucosa en Sangre');
      expect(controller.code, 'GLU-01');
      expect(controller.commercialCategory, 'Bioquímica Clínica');
      expect(controller.subclassification, 'Carbohidratos / Glucosa');
      expect(controller.salePrice, 15.0);
      expect(controller.salePrice2, 12.0);
      expect(controller.priceInCents, 1500);
      expect(controller.price2InCents, 1200);
      expect(controller.priceController.text, '15.00');
      expect(controller.price2Controller.text, '12.00');
      expect(controller.referenceText, 'Valores en ayunas');
      expect(controller.referenceValues.first.minValue, 74.0);
      expect(controller.referenceValues.first.maxValue, 106.0);
      expect(controller.usesAge, isTrue);
      expect(controller.usesGender, isTrue);
      expect(controller.referenceValues.first.useAge, isTrue);
      expect(controller.referenceValues.first.useGender, isTrue);
      expect(controller.referenceValues.first.ageUnit, 'months');

      controller.dispose();
    });

    test('Cambio a modo Pack y cálculo automático de pruebas hijas', () {
      final controller = LabTestFormViewController();
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      final availableTests = <LabTestInDb>[
        LabTestInDb(
          id: 'child-1',
          name: 'Colesterol Total',
          commercialCategory: 'Química Sanguínea',
          subclassification: 'General',
          salePrice: 1000, // $10.00
          salePrice2: 0,
          costPrice: 0,
          currency: 'USD',
          createdAt: 0,
          updatedAt: 0,
        ),
        LabTestInDb(
          id: 'child-2',
          name: 'Triglicéridos',
          commercialCategory: 'Química Sanguínea',
          subclassification: 'General',
          salePrice: 1500, // $15.00
          salePrice2: 0,
          costPrice: 0,
          currency: 'USD',
          createdAt: 0,
          updatedAt: 0,
        ),
      ];

      // Activar modo pack y asignar análisis hijos
      controller.setIsPack(true, availableTests);
      expect(controller.isPack, isTrue);

      controller.addChildTestId('child-1', availableTests);
      expect(controller.childTestIds, ['child-1']);
      expect(controller.salePrice, 10.0);
      expect(controller.priceController.text, '10.00');

      controller.addChildTestId('child-2', availableTests);
      expect(controller.childTestIds, ['child-1', 'child-2']);
      expect(controller.salePrice, 25.0); // $10 + $15
      expect(controller.priceController.text, '25.00');

      // Remover un hijo recalcula la sumatoria
      controller.removeChildTestId('child-1', availableTests);
      expect(controller.childTestIds, ['child-2']);
      expect(controller.salePrice, 15.0);
      expect(controller.priceController.text, '15.00');

      // Reordenar hijos
      controller.addChildTestId('child-1', availableTests);
      expect(controller.childTestIds, ['child-2', 'child-1']);
      controller.reorderChildTests(0, 2);
      expect(controller.childTestIds, ['child-1', 'child-2']);

      // Alternar switch de precio manual vs automático
      controller.setUseChildTestsPriceSum(false);
      expect(controller.useChildTestsPriceSum, isFalse);

      controller.priceController.text = '20.00';
      controller.setSalePrice(20.0);
      expect(controller.salePrice, 20.0);

      // Reactivar suma automática
      controller.setUseChildTestsPriceSum(true, availableTests);
      expect(controller.salePrice, 25.0);
      expect(controller.priceController.text, '25.00');

      expect(notifyCount, greaterThan(0));
      controller.dispose();
    });

    test('Manejo de categorías y subclasificaciones personalizadas', () {
      final controller = LabTestFormViewController();

      // Categoría existente estándar
      controller.setCommercialCategory('Uroanálisis');
      expect(controller.isCustomCategory, isFalse);
      expect(controller.commercialCategory, 'Uroanálisis');
      expect(controller.subclassification, 'Examen Físico-Químico');

      // Categoría personalizada
      controller.setCommercialCategory('__custom__');
      expect(controller.isCustomCategory, isTrue);
      controller.customCategoryController.text = 'Toxicología Especial';
      expect(controller.commercialCategory, 'Toxicología Especial');

      // Subclasificación personalizada
      controller.setSubclassification('__custom__');
      expect(controller.isCustomSubclass, isTrue);
      controller.customSubclassController.text = 'Metales Pesados';
      expect(controller.subclassification, 'Metales Pesados');

      controller.dispose();
    });

    test('Mutaciones de rangos de referencia', () {
      final controller = LabTestFormViewController();

      expect(controller.referenceValues.length, 1);

      controller.addReferenceValue(
        ReferenceValue(
          patientType: 'pediatric',
          gender: 'female',
          minAgeDays: 0,
          maxAgeDays: 365,
          minValue: 60.0,
          maxValue: 90.0,
        ),
      );
      expect(controller.referenceValues.length, 2);
      expect(controller.referenceValues[1].patientType, 'pediatric');

      controller.updateReferenceValue(
        1,
        ReferenceValue(
          patientType: 'pediatric',
          gender: 'female',
          minAgeDays: 0,
          maxAgeDays: 365,
          minValue: 65.0,
          maxValue: 95.0,
        ),
      );
      expect(controller.referenceValues[1].minValue, 65.0);

      controller.removeReferenceValueAt(0);
      expect(controller.referenceValues.length, 1);
      expect(controller.referenceValues[0].minValue, 65.0);

      controller.dispose();
    });

    test('Activa y desactiva la evaluación por edad y género en todos los rangos', () {
      final controller = LabTestFormViewController();
      controller.addReferenceValue();

      expect(controller.usesAge, isFalse);
      expect(controller.usesGender, isFalse);

      controller.setUseAge(true);
      controller.setUseGender(true);

      expect(controller.usesAge, isTrue);
      expect(controller.usesGender, isTrue);
      expect(
        controller.referenceValues.every((ref) => ref.useAge && ref.useGender),
        isTrue,
      );

      controller.setUseAge(false);
      expect(controller.usesAge, isFalse);

      controller.dispose();
    });

    test('setReferenceValues reemplaza la lista y addReferenceValue hereda flags', () {
      final controller = LabTestFormViewController();

      controller.setReferenceValues([
        ReferenceValue(
          patientType: 'general',
          gender: 'both',
          minAgeDays: 365,
          maxAgeDays: 3650,
          minValue: 10.0,
          maxValue: 20.0,
          ageUnit: 'years',
          useAge: true,
          useGender: true,
        ),
      ]);

      expect(controller.referenceValues.length, 1);
      expect(controller.referenceValues.first.minAgeDays, 365);
      expect(controller.referenceValues.first.ageUnit, 'years');
      expect(controller.usesAge, isTrue);
      expect(controller.usesGender, isTrue);

      controller.addReferenceValue();

      expect(controller.referenceValues.length, 2);
      expect(controller.referenceValues.last.ageUnit, 'years');
      expect(controller.referenceValues.last.useAge, isTrue);
      expect(controller.referenceValues.last.useGender, isTrue);
      expect(controller.referenceValues.last.minAgeDays, 0);
      expect(controller.referenceValues.last.maxAgeDays, 36500);

      controller.dispose();
    });

    test('Detecta errores y advertencias en la configuración de rangos', () {
      final controller = LabTestFormViewController();
      controller.addReferenceValue();

      controller.updateReferenceValue(
        0,
        controller.referenceValues[0].copyWith(
          useAge: true,
          minAgeDays: 365,
          maxAgeDays: 100,
        ),
      );
      expect(controller.referenceRangesError, isNotNull);

      controller.updateReferenceValue(
        0,
        controller.referenceValues[0].copyWith(
          useAge: false,
          minAgeDays: 0,
          maxAgeDays: 365,
        ),
      );
      controller.updateReferenceValue(
        1,
        controller.referenceValues[1].copyWith(
          useAge: false,
          minAgeDays: 365,
          maxAgeDays: 730,
        ),
      );
      expect(controller.referenceRangesError, isNull);
      expect(controller.referenceRangesWarning, isNotNull);

      controller.dispose();
    });

    test('Presets cualitativos y parseo de opciones de texto', () {
      final controller = LabTestFormViewController();
      controller.setDataType('qualitative');
      expect(controller.dataType, 'qualitative');

      // Aplicar preset
      controller.setQualitativePresets(
        ['No se observó', 'Escasas', 'Moderadas', 'Abundantes'],
        'No se observó',
      );
      expect(controller.qualitativeOptions.length, 4);
      expect(controller.expectedQualitativeValue, 'No se observó');
      expect(
        controller.qualitativeOptionsController.text,
        'No se observó, Escasas, Moderadas, Abundantes',
      );

      // Parsear desde texto separado por comas
      controller.updateQualitativeOptionsFromText('Reactivo, No Reactivo, Indeterminado');
      expect(controller.qualitativeOptions, ['Reactivo', 'No Reactivo', 'Indeterminado']);
      expect(controller.expectedQualitativeValue, 'Reactivo');

      controller.setExpectedQualitativeValue('No Reactivo');
      expect(controller.expectedQualitativeValue, 'No Reactivo');

      controller.dispose();
    });

    test('La escritura de la unidad conserva la selección del campo', () {
      final controller = LabTestFormViewController();
      controller.unitController.value = const TextEditingValue(
        text: 'mg',
        selection: TextSelection.collapsed(offset: 1),
      );

      controller.updateUnitOfMeasureFromText('mg');

      expect(controller.unitOfMeasure, 'mg');
      expect(controller.unitController.text, 'mg');
      expect(
        controller.unitController.selection,
        const TextSelection.collapsed(offset: 1),
      );

      controller.dispose();
    });

    test('Los chips de unidad actualizan el texto y colocan el cursor al final', () {
      final controller = LabTestFormViewController();

      controller.setUnitOfMeasure('g/dL');

      expect(controller.unitOfMeasure, 'g/dL');
      expect(controller.unitController.text, 'g/dL');
      expect(
        controller.unitController.selection,
        const TextSelection.collapsed(offset: 4),
      );

      controller.dispose();
    });

    test('Genera CreateLabTest DTO con saneamiento y mapeo adecuado', () {
      final controller = LabTestFormViewController();
      controller.nameController.text = ' Perfil Renal ';
      controller.codeController.text = ' REN-01 ';
      controller.setIsPack(true);
      controller.setChildTestIds(['urea-1', 'creatinina-1']);
      controller.priceController.text = '30.00';
      controller.price2Controller.text = '25.00';
      controller.referenceTextController.text = 'Requiere 8 horas de ayuno.';

      final dto = controller.generateCreateDto(branchId: 'branch-100');

      expect(dto.branchId, 'branch-100');
      expect(dto.name, 'Perfil Renal');
      expect(dto.code, 'REN-01');
      expect(dto.isPack, isTrue);
      expect(dto.dataType, 'pack');
      expect(dto.salePrice, 3000);
      expect(dto.salePrice2, 2500);
      expect(dto.childTestIds, ['urea-1', 'creatinina-1']);
      expect(dto.referenceText, ''); // Para packs se normaliza vacío
      expect(dto.referenceValues, isEmpty);

      controller.dispose();
    });

    test('Genera UpdateLabTest DTO para prueba individual numérica', () {
      final controller = LabTestFormViewController();
      controller.nameController.text = 'Hemoglobina Glicosilada';
      controller.codeController.text = 'HBA1C';
      controller.setCommercialCategory('Bioquímica Clínica');
      controller.setSubclassification('Carbohidratos / Glucosa');
      controller.setDataType('numeric');
      controller.setUnitOfMeasure('%');
      controller.priceController.text = '18.50';
      controller.referenceTextController.text = 'Escala ADA';

      final dto = controller.generateUpdateDto(branchId: 'branch-100');

      expect(dto.name, 'Hemoglobina Glicosilada');
      expect(dto.code, 'HBA1C');
      expect(dto.commercialCategory, 'Bioquímica Clínica');
      expect(dto.subclassification, 'Carbohidratos / Glucosa');
      expect(dto.salePrice, 1850);
      expect(dto.dataType, 'numeric');
      expect(dto.unitOfMeasure, '%');
      expect(dto.referenceText, 'Escala ADA');
      expect(dto.referenceValues?.isNotEmpty, isTrue);

      controller.dispose();
    });
  });
}
