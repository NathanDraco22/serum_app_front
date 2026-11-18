import 'dart:convert';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/imports_cubit/imports_cubit.dart';
import 'package:serum_app_front/src/modules/imports/widgets/new_lab_tests_json_card.dart';
import 'package:serum_business/serum_business.dart';

class _FakeImportsDataSource implements ImportsDataSource {
  @override
  Future<Map<String, dynamic>> importBranchPrices({
    required String sourceBranchId,
    required String targetBranchId,
    bool mustOverridePrice = false,
  }) async =>
      {};

  @override
  Future<Map<String, dynamic>> importDefaultCatalog() async => {};

  @override
  Future<Map<String, dynamic>> importLabTests() async => {};

  @override
  Future<Map<String, dynamic>> importNewLabTestsFile({
    required Uint8List bytes,
    required String fileName,
  }) async =>
      {};

  @override
  Future<Map<String, dynamic>> updateCatalog({
    bool overridePrice = false,
    bool updateLabTest = true,
    bool preserveReferenceValues = true,
  }) async =>
      {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeImportsRepository extends ImportsRepository {
  String? uploadedFileName;
  Uint8List? uploadedBytes;

  _FakeImportsRepository() : super(_FakeImportsDataSource());

  @override
  Future<ImportCatalogResult> importNewLabTestsFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    uploadedFileName = fileName;
    uploadedBytes = bytes;
    return const ImportCatalogResult(
      success: true,
      message: 'Pruebas nuevas importadas exitosamente',
      atomicCreated: 2,
      packsCreated: 1,
      accountsCreated: 3,
      alreadyExisting: 0,
      totalProcessed: 3,
    );
  }
}

void main() {
  Widget buildTestWidget(
    ImportsCubit cubit, {
    JsonFilePicker? onPickFile,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: BlocProvider.value(
            value: cubit,
            child: NewLabTestsJsonCard(
              isLoading: false,
              onPickFile: onPickFile,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renderiza estado inicial con botón importar deshabilitado', (tester) async {
    final repo = _FakeImportsRepository();
    final cubit = ImportsCubit(importsRepository: repo);

    await tester.pumpWidget(buildTestWidget(cubit));

    expect(find.text('Importar Pruebas Nuevas (Archivo JSON)'), findsOneWidget);
    expect(find.text('Seleccionar archivo .json'), findsOneWidget);

    final importButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Importar Pruebas Nuevas'),
    );
    expect(importButton.onPressed, isNull);
    await cubit.close();
  });

  testWidgets('previsualiza archivo JSON válido y ejecuta importación al confirmar', (
    tester,
  ) async {
    final repo = _FakeImportsRepository();
    final cubit = ImportsCubit(importsRepository: repo);

    final jsonBytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode([
          {'name': 'Alergeno 1', 'code': 'ALG-1', 'isPack': false},
          {'name': 'Alergeno 2', 'code': 'ALG-2', 'isPack': false},
          {'name': 'Panel Alergia', 'code': 'PANEL-ALG', 'isPack': true},
        ]),
      ),
    );

    await tester.pumpWidget(
      buildTestWidget(
        cubit,
        onPickFile: () async => (name: 'panel_atopica_30i_import.json', bytes: jsonBytes),
      ),
    );

    await tester.tap(find.text('Seleccionar archivo .json'));
    await tester.pumpAndSettle();

    expect(find.text('panel_atopica_30i_import.json'), findsOneWidget);
    expect(find.text('3 registros'), findsOneWidget);
    expect(find.text('2 pruebas'), findsOneWidget);
    expect(find.text('1 packs'), findsOneWidget);

    await tester.tap(find.text('Importar Pruebas Nuevas'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar Importación de Pruebas'), findsOneWidget);
    await tester.tap(find.text('Importar Pruebas'));
    await tester.pumpAndSettle();

    expect(repo.uploadedFileName, 'panel_atopica_30i_import.json');
    expect(repo.uploadedBytes, jsonBytes);
    await cubit.close();
  });

  testWidgets('muestra error de validación si el JSON no es un arreglo', (tester) async {
    final repo = _FakeImportsRepository();
    final cubit = ImportsCubit(importsRepository: repo);

    final badBytes = Uint8List.fromList(utf8.encode('{"not": "a list"}'));

    await tester.pumpWidget(
      buildTestWidget(
        cubit,
        onPickFile: () async => (name: 'invalido.json', bytes: badBytes),
      ),
    );

    await tester.tap(find.text('Seleccionar archivo .json'));
    await tester.pumpAndSettle();

    expect(
      find.text('El archivo JSON debe contener un arreglo no vacío de pruebas.'),
      findsOneWidget,
    );

    final importButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Importar Pruebas Nuevas'),
    );
    expect(importButton.onPressed, isNull);
    await cubit.close();
  });
}
