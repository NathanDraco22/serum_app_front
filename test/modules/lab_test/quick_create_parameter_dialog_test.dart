import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/modules/lab_test/widgets/quick_create_parameter_dialog.dart';
import 'package:serum_business/serum_business.dart';

class _FakeLabTestsDataSource extends Fake implements LabTestsDataSource {
  Map<String, dynamic>? lastCreated;

  @override
  Future<Map<String, dynamic>> createLabTest(Map<String, dynamic> labTest) async {
    final copy = Map<String, dynamic>.from(labTest);
    copy['id'] = 'new-test-${DateTime.now().millisecondsSinceEpoch}';
    copy['createdAt'] = DateTime.now().millisecondsSinceEpoch;
    copy['isDeleted'] = false;
    lastCreated = copy;
    return copy;
  }
}

void main() {
  late _FakeLabTestsDataSource fakeDataSource;
  late LabTestsRepository repository;

  setUp(() {
    fakeDataSource = _FakeLabTestsDataSource();
    repository = LabTestsRepository(fakeDataSource);
  });

  testWidgets('QuickCreateParameterDialog crea un parámetro interno con clasificación y subclasificación', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    LabTestInDb? result;

    await tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider<LabTestsRepository>.value(
          value: repository,
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await QuickCreateParameterDialog.show(
                      context,
                      initialCategory: 'Uroanálisis',
                      initialSubclassification: 'Examen Físico-Químico',
                      branchId: 'br-123',
                    );
                  },
                  child: const Text('Abrir Diálogo'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Abrir el diálogo
    await tester.tap(find.text('Abrir Diálogo'));
    await tester.pumpAndSettle();

    expect(find.text('Crear Parámetro de Perfil'), findsOneWidget);
    expect(find.text('Uroanálisis'), findsOneWidget);
    expect(find.text('Examen Físico-Químico'), findsOneWidget);

    // Ingresar nombre
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del Parámetro *'),
      'Color',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Código / Abreviatura'),
      'COL',
    );

    // Cambiar a Cualitativo
    await tester.tap(find.text('Cualitativo / Lista'));
    await tester.pumpAndSettle();

    // Guardar
    await tester.tap(find.text('Crear y Agregar'));
    await tester.pumpAndSettle();

    // Verificar llamada al repositorio
    expect(fakeDataSource.lastCreated, isNotNull);
    expect(fakeDataSource.lastCreated!['name'], 'Color');
    expect(fakeDataSource.lastCreated!['code'], 'COL');
    expect(fakeDataSource.lastCreated!['commercialCategory'], 'Uroanálisis');
    expect(fakeDataSource.lastCreated!['subclassification'], 'Examen Físico-Químico');
    expect(fakeDataSource.lastCreated!['isProfileParameter'], true);
    expect(fakeDataSource.lastCreated!['dataType'], 'qualitative');

    // Verificar resultado devuelto por showDialog
    expect(result, isNotNull);
    expect(result!.name, 'Color');
    expect(result!.isProfileParameter, true);
    expect(result!.subclassification, 'Examen Físico-Químico');
  });
}
