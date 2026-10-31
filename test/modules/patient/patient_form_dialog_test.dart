import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/cubits/patient_cubit/write_patients_cubit.dart';
import 'package:serum_app_front/src/modules/patient/widgets/patient_form_dialog.dart';
import 'package:serum_business/serum_business.dart';

class MockWritePatientCubit extends Cubit<WritePatientState>
    implements WritePatientCubit {
  MockWritePatientCubit() : super(WritePatientInitial());

  CreatePatient? lastCreatedPatient;
  UpdatePatient? lastUpdatedPatient;
  String? lastUpdatedId;

  @override
  Future<void> create(CreatePatient patient) async {
    lastCreatedPatient = patient;
    final inDb = PatientInDb(
      id: 'pat-new-1',
      name: patient.name,
      dateOfBirth: patient.dateOfBirth,
      gender: patient.gender,
      phone: patient.phone,
      address: patient.address,
      email: patient.email,
      cardId: patient.cardId,
      originBranch: patient.originBranch,
      createdAt: 1700000000000,
      age: patient.age,
    );
    emit(PatientCreated(inDb));
  }

  @override
  Future<void> update(String id, UpdatePatient patient) async {
    lastUpdatedId = id;
    lastUpdatedPatient = patient;
    final inDb = PatientInDb(
      id: id,
      name: patient.name ?? 'Updated',
      dateOfBirth: patient.dateOfBirth ?? 0,
      gender: patient.gender ?? 'M',
      phone: patient.phone ?? '8888',
      address: patient.address,
      email: patient.email,
      cardId: patient.cardId,
      originBranch: patient.originBranch ?? 'branch-1',
      createdAt: 1700000000000,
      age: patient.age,
    );
    emit(PatientUpdated(inDb));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAppSessionCubit extends Cubit<AppSessionState>
    implements AppSessionCubit {
  MockAppSessionCubit()
      : super(
          AppSessionState(
            currentBranch: BranchInDb(
              id: 'branch-central',
              name: 'Central',
              address: 'Central',
              phone: '8888',
              createdAt: 100,
            ),
            currentUser: UserInDb(
              id: 'user-1',
              username: 'admin',
              name: 'Admin User',
              role: 'Admin',
              createdAt: 100,
            ),
          ),
        );

  @override
  String get currentBranchId => 'branch-central';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PatientFormDialog Age and Birthdate Tests', () {
    late MockWritePatientCubit mockWritePatientCubit;
    late MockAppSessionCubit mockAppSessionCubit;

    setUp(() {
      mockWritePatientCubit = MockWritePatientCubit();
      mockAppSessionCubit = MockAppSessionCubit();
    });

    Widget createWidgetUnderTest({PatientInDb? patient}) {
      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<WritePatientCubit>.value(value: mockWritePatientCubit),
            BlocProvider<AppSessionCubit>.value(value: mockAppSessionCubit),
          ],
          child: Scaffold(
            body: PatientFormDialog(patient: patient),
          ),
        ),
      );
    }

    testWidgets('Muestra campo de Edad (años) * y Fecha de Nacimiento', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Paciente'), findsOneWidget);
      expect(find.text('Edad (años) *'), findsOneWidget);
      expect(find.text('Fecha de Nacimiento'), findsOneWidget);
      expect(find.byIcon(Icons.cake_outlined), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    });

    testWidgets('Formateador solo permite números enteros (bloquea letras y símbolos)', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final ageFinder = find.widgetWithText(TextFormField, 'Edad (años) *');
      expect(ageFinder, findsOneWidget);

      // Ingresar texto no numérico
      await tester.enterText(ageFinder, '35abc.5');
      await tester.pumpAndSettle();

      // Debe haber filtrado a solo dígitos enteros: "355"
      final ageField = tester.widget<TextFormField>(ageFinder);
      expect(ageField.controller?.text, equals('355'));
    });

    testWidgets('Al ingresar edad se calcula dateOfBirth y se guarda CreatePatient con age', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Llenar Nombre
      final nameFinder = find.widgetWithText(TextFormField, 'Nombre Completo *');
      await tester.enterText(nameFinder, 'Guillermo Davila');

      // Llenar Teléfono
      final phoneFinder = find.widgetWithText(TextFormField, 'Teléfono *');
      await tester.enterText(phoneFinder, '8765-4321');

      // Llenar Edad
      final ageFinder = find.widgetWithText(TextFormField, 'Edad (años) *');
      await tester.enterText(ageFinder, '28');
      await tester.pumpAndSettle();

      // Verificar que la Fecha de Nacimiento en pantalla refleje el año estimado (año actual - 28)
      final expectedYear = DateTime.now().year - 28;
      expect(find.textContaining('$expectedYear'), findsOneWidget);

      // Guardar formulario
      final submitButton = find.widgetWithText(ElevatedButton, 'Registrar');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(mockWritePatientCubit.lastCreatedPatient, isNotNull);
      final created = mockWritePatientCubit.lastCreatedPatient!;
      expect(created.name, equals('Guillermo Davila'));
      expect(created.phone, equals('8765-4321'));
      expect(created.age, equals(28));
      final calculatedBirth = DateTime.fromMillisecondsSinceEpoch(created.dateOfBirth);
      expect(calculatedBirth.year, equals(expectedYear));
    });

    testWidgets('Modo edición pre-llena la edad calculada a partir del paciente existente', (tester) async {
      final now = DateTime.now();
      final birthDate = DateTime(now.year - 42, now.month, now.day);

      final existingPatient = PatientInDb(
        id: 'pat-42',
        name: 'Doña Martha',
        dateOfBirth: birthDate.millisecondsSinceEpoch,
        gender: 'F',
        phone: '8888-0042',
        originBranch: 'branch-central',
        createdAt: 1700000000000,
      );

      await tester.pumpWidget(createWidgetUnderTest(patient: existingPatient));
      await tester.pumpAndSettle();

      expect(find.text('Editar Paciente'), findsOneWidget);
      expect(find.text('#pat-42'), findsOneWidget);

      final ageFinder = find.widgetWithText(TextFormField, 'Edad (años) *');
      final ageField = tester.widget<TextFormField>(ageFinder);
      expect(ageField.controller?.text, equals('42'));
    });
  });
}
