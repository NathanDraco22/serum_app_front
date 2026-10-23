import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/lab_test_cubit/search_lab_tests_cubit.dart';
import 'package:serum_app_front/src/cubits/lab_test_cubit/write_lab_tests_cubit.dart';
import 'package:serum_app_front/src/modules/lab_test/widgets/lab_test_quick_price_dialog.dart';
import 'package:serum_app_front/src/modules/lab_test/widgets/lab_tests_list.dart';
import 'package:serum_business/serum_business.dart';

class _FakeLabTestsDataSource extends Fake implements LabTestsDataSource {
  final Map<String, dynamic> storedData = {};

  @override
  Future<Map<String, dynamic>?> updateLabTestById(
    String id,
    Map<String, dynamic> labTest,
  ) async {
    final existing = Map<String, dynamic>.from(storedData[id] ?? {});
    existing.addAll(labTest);
    existing['id'] = id;
    existing['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    storedData[id] = existing;
    return existing;
  }
}

void main() {
  late _FakeLabTestsDataSource fakeDataSource;
  late LabTestsRepository repository;

  final sampleTest = LabTestInDb(
    id: 'test-101',
    name: 'Glucosa en Ayunas',
    code: 'GLU-01',
    commercialCategory: 'Bioquímica Clínica',
    salePrice: 15000, // $150.00
    salePrice2: 12000, // $120.00
    costPrice: 5000,
    currency: 'USD',
    isPack: false,
    useChildTestsPriceSum: false,
    childTestIds: [],
    dataType: 'numeric',
    unitOfMeasure: 'mg/dL',
    createdAt: 1700000000000,
    isDeleted: false,
  );

  setUp(() {
    fakeDataSource = _FakeLabTestsDataSource();
    fakeDataSource.storedData['test-101'] = {
      'id': sampleTest.id,
      'name': sampleTest.name,
      'code': sampleTest.code,
      'commercialCategory': sampleTest.commercialCategory,
      'salePrice': sampleTest.salePrice,
      'salePrice2': sampleTest.salePrice2,
      'costPrice': sampleTest.costPrice,
      'currency': sampleTest.currency,
      'isPack': sampleTest.isPack,
      'useChildTestsPriceSum': sampleTest.useChildTestsPriceSum,
      'childTestIds': sampleTest.childTestIds,
      'dataType': sampleTest.dataType,
      'unitOfMeasure': sampleTest.unitOfMeasure,
      'createdAt': sampleTest.createdAt,
      'isDeleted': sampleTest.isDeleted,
    };
    repository = LabTestsRepository(fakeDataSource);
  });

  group('LabTestQuickPriceDialog', () {
    testWidgets('renders current prices and test info accurately',
        (tester) async {
      final writeCubit = WriteLabTestCubit(labTestsRepository: repository);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<WriteLabTestCubit>.value(
              value: writeCubit,
              child: LabTestQuickPriceDialog(
                labTest: sampleTest,
                branchId: 'branch-1',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Modificar Precio de Análisis'), findsOneWidget);
      expect(find.text('Glucosa en Ayunas'), findsOneWidget);
      expect(find.text('Cód: GLU-01'), findsOneWidget);
      expect(find.text('Bioquímica Clínica'), findsOneWidget);

      // Current prices in fields
      expect(find.text('150.00'), findsOneWidget);
      expect(find.text('120.00'), findsOneWidget);

      await writeCubit.close();
    });

    testWidgets('updates price and closes dialog on submit', (tester) async {
      final writeCubit = WriteLabTestCubit(labTestsRepository: repository);

      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<bool>(
                    context: ctx,
                    builder: (_) => BlocProvider<WriteLabTestCubit>.value(
                      value: writeCubit,
                      child: LabTestQuickPriceDialog(
                        labTest: sampleTest,
                        branchId: 'branch-1',
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Modify price
      final priceField =
          find.widgetWithText(TextFormField, 'Precio 1 / Regular (\$)');
      expect(priceField, findsOneWidget);

      await tester.enterText(priceField, '195.50');
      await tester.pump();

      // Submit
      await tester.tap(find.text('Guardar Precio'));
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue);
      expect(fakeDataSource.storedData['test-101']['salePrice'], 19550);

      await writeCubit.close();
    });

    testWidgets('renders pack options without assertion errors when isPack is true',
        (tester) async {
      final packTest = LabTestInDb(
        id: 'pack-201',
        name: 'Perfil Lipídico',
        code: 'PERF-LIP',
        commercialCategory: 'Perfiles Clínicos',
        salePrice: 40000,
        salePrice2: 35000,
        costPrice: 15000,
        currency: 'USD',
        isPack: true,
        useChildTestsPriceSum: true,
        childTestIds: ['test-col', 'test-tri'],
        dataType: 'numeric',
        unitOfMeasure: '',
        createdAt: 1700000000000,
        isDeleted: false,
      );

      final writeCubit = WriteLabTestCubit(labTestsRepository: repository);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<WriteLabTestCubit>.value(
              value: writeCubit,
              child: LabTestQuickPriceDialog(
                labTest: packTest,
                branchId: 'branch-1',
              ),
            ),
          ),
        ),
      );

      // Verify header and pack specific section
      expect(find.text('Modificar Precio de Análisis'), findsOneWidget);
      expect(find.text('Perfil Lipídico'), findsOneWidget);
      expect(find.text('Cód: PERF-LIP'), findsOneWidget);
      expect(find.text('Modalidad de Precio del Perfil / Pack'), findsOneWidget);
      expect(
        find.text('Calcular precio sumando los análisis incluidos'),
        findsOneWidget,
      );

      await writeCubit.close();
    });
  });

  group('LabTestsList Price Badge Interaction', () {
    testWidgets('tapping price triggers onEditPrice callback', (tester) async {
      LabTestInDb? clickedForPrice;
      LabTestInDb? clickedForDetail;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LabTestsList(
              labTests: [sampleTest],
              onEdit: (_) {},
              onDetail: (t) => clickedForDetail = t,
              onEditPrice: (t) => clickedForPrice = t,
            ),
          ),
        ),
      );

      expect(find.text('\$150.00'), findsOneWidget);
      expect(find.text('P2: \$120.00'), findsOneWidget);

      // Tap on the price badge
      await tester.tap(find.text('\$150.00'));
      await tester.pumpAndSettle();

      expect(clickedForPrice?.id, 'test-101');
      expect(clickedForDetail, isNull); // Ensures card tap did not take precedence
    });
  });

  group('SearchLabTestCubit Reactivity', () {
    test('updates result list when repository emits updated lab test', () async {
      final searchCubit = SearchLabTestCubit(labTestsRepository: repository);

      // Initial state
      searchCubit.emit(SearchLabTestSuccess([sampleTest]));

      final updatedTest = LabTestInDb(
        id: sampleTest.id,
        name: sampleTest.name,
        code: sampleTest.code,
        commercialCategory: sampleTest.commercialCategory,
        salePrice: 22000, // $220.00
        salePrice2: sampleTest.salePrice2,
        costPrice: sampleTest.costPrice,
        currency: sampleTest.currency,
        isPack: sampleTest.isPack,
        useChildTestsPriceSum: sampleTest.useChildTestsPriceSum,
        childTestIds: sampleTest.childTestIds,
        dataType: sampleTest.dataType,
        unitOfMeasure: sampleTest.unitOfMeasure,
        createdAt: sampleTest.createdAt,
        isDeleted: sampleTest.isDeleted,
      );

      // Notify repository update
      repository.notifyItemUpdated(updatedTest);

      // Allow event stream to process
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = searchCubit.state;
      expect(state, isA<SearchLabTestSuccess>());
      final items = (state as SearchLabTestSuccess).items;
      expect(items.first.salePrice, 22000);

      await searchCubit.close();
    });
  });
}
