import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serum_app_front/src/cubits/app_session_cubit/app_session_cubit.dart';
import 'package:serum_app_front/src/cubits/patient_cubit/read_patients_cubit.dart';
import 'package:serum_app_front/src/cubits/patient_cubit/search_patients_cubit.dart';
import 'package:serum_app_front/src/cubits/patient_cubit/write_patients_cubit.dart';
import 'package:serum_app_front/src/modules/patient/view/patient_screen.dart';
import 'package:serum_business/serum_business.dart';

class _FakePatientsDataSource extends Fake implements PatientsDataSource {
  int searchCallsCount = 0;
  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, dynamic>> allPatients = [];

  @override
  Future<Map<String, dynamic>> searchPatientsByText(
    String textQuery, {
    String? originBranch,
  }) async {
    searchCallsCount++;
    return {
      'count': searchResults.length,
      'data': searchResults,
    };
  }

  @override
  Future<Map<String, dynamic>> getAllPatients({String? originBranch}) async {
    return {
      'count': allPatients.length,
      'data': allPatients,
    };
  }
}

class _MockAppSessionCubit extends Cubit<AppSessionState> implements AppSessionCubit {
  _MockAppSessionCubit() : super(const AppSessionState());

  @override
  String get currentBranchId => 'branch-1';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakePatientsDataSource fakeDataSource;
  late PatientsRepository repository;

  final patient1 = PatientInDb(
    id: 'pat-1',
    name: 'Carlos Mendoza',
    dateOfBirth: 631152000000,
    originBranch: 'branch-1',
    cardId: '001-123456-0001A',
    phone: '8888-1111',
    gender: 'M',
    email: 'carlos@test.com',
    createdAt: 1700000000000,
    isDeleted: false,
  );

  final patient2 = PatientInDb(
    id: 'pat-2',
    name: 'Maria Lopez',
    dateOfBirth: 757382400000,
    originBranch: 'branch-1',
    cardId: '001-987654-0002B',
    phone: '8888-2222',
    gender: 'F',
    email: 'maria@test.com',
    createdAt: 1700000000000,
    isDeleted: false,
  );

  setUp(() {
    fakeDataSource = _FakePatientsDataSource();
    fakeDataSource.allPatients = [patient1.toJson(), patient2.toJson()];
    fakeDataSource.searchResults = [patient1.toJson()];
    repository = PatientsRepository(fakeDataSource);
  });

  group('SearchPatientCubit Tests', () {
    test('search(query) emite SearchPatientSuccess y utiliza cache para query repetida', () async {
      final cubit = SearchPatientCubit(patientsRepository: repository);

      expect(cubit.state, isA<SearchPatientInitial>());

      await cubit.search('Carlos');
      expect(cubit.state, isA<SearchPatientSuccess>());
      final success = cubit.state as SearchPatientSuccess;
      expect(success.items.length, 1);
      expect(success.items.first.name, 'Carlos Mendoza');
      expect(fakeDataSource.searchCallsCount, 1);

      // Segunda búsqueda idéntica debe resolverse desde caché sin golpear el datasource
      await cubit.search('Carlos');
      expect(fakeDataSource.searchCallsCount, 1);
      expect(cubit.state, isA<SearchPatientSuccess>());

      cubit.close();
    });

    test('search con query vacía o clear() emite SearchPatientInitial', () async {
      final cubit = SearchPatientCubit(patientsRepository: repository);

      await cubit.search('Carlos');
      expect(cubit.state, isA<SearchPatientSuccess>());

      await cubit.search('   ');
      expect(cubit.state, isA<SearchPatientInitial>());

      await cubit.search('Carlos');
      expect(cubit.state, isA<SearchPatientSuccess>());

      cubit.clear();
      expect(cubit.state, isA<SearchPatientInitial>());

      cubit.close();
    });

    test('reacciona a eventos reactivos de PatientsRepository (update y delete)', () async {
      final cubit = SearchPatientCubit(patientsRepository: repository);

      await cubit.search('Carlos');
      expect(cubit.state, isA<SearchPatientSuccess>());

      // Emitir evento de actualización
      final updatedPatient = PatientInDb(
        id: 'pat-1',
        name: 'Carlos Mendoza Modificado',
        dateOfBirth: 631152000000,
        originBranch: 'branch-1',
        cardId: '001-123456-0001A',
        phone: '8888-9999',
        gender: 'M',
        email: 'carlos@test.com',
        createdAt: 1700000000000,
        isDeleted: false,
      );

      repository.notifyItemUpdated(updatedPatient);
      await pumpEventQueue();

      final stateUpdated = cubit.state as SearchPatientSuccess;
      expect(stateUpdated.items.first.name, 'Carlos Mendoza Modificado');

      // Emitir evento de eliminación
      repository.notifyItemDeleted(updatedPatient);
      await pumpEventQueue();

      final stateDeleted = cubit.state as SearchPatientSuccess;
      expect(stateDeleted.items, isEmpty);

      cubit.close();
    });
  });

  group('PatientsScreen Widget Tests', () {
    testWidgets('Muestra lista inicial y recupera lista inicial al limpiar búsqueda con icono X', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final readCubit = ReadPatientCubit(patientsRepository: repository);
      final searchCubit = SearchPatientCubit(patientsRepository: repository);
      final writeCubit = WritePatientCubit(patientsRepository: repository);
      final mockAppSessionCubit = _MockAppSessionCubit();

      await readCubit.getAll();

      await tester.pumpWidget(
        MaterialApp(
          home: RepositoryProvider<PatientsRepository>.value(
            value: repository,
            child: MultiBlocProvider(
              providers: [
                BlocProvider<AppSessionCubit>.value(value: mockAppSessionCubit),
                BlocProvider<ReadPatientCubit>.value(value: readCubit),
                BlocProvider<SearchPatientCubit>.value(value: searchCubit),
                BlocProvider<WritePatientCubit>.value(value: writeCubit),
              ],
              child: const PatientsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe mostrar inicialmente ambos pacientes
      expect(find.text('Carlos Mendoza'), findsOneWidget);
      expect(find.text('Maria Lopez'), findsOneWidget);

      // Escribir en el campo de búsqueda
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Carlos');
      await tester.pump(); // actualiza setState para suffixIcon

      // El icono de limpiar debe ser visible
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Esperar que termine el debounce de 300ms
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // En resultados de búsqueda solo está Carlos
      expect(find.text('Carlos Mendoza'), findsOneWidget);
      expect(find.text('Maria Lopez'), findsNothing);

      // Tocar el botón de limpiar 'X'
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Inmediatamente debe recuperar la lista original sin parpadeos
      expect(find.text('Carlos Mendoza'), findsOneWidget);
      expect(find.text('Maria Lopez'), findsOneWidget);

      readCubit.close();
      searchCubit.close();
      writeCubit.close();
      mockAppSessionCubit.close();
    });
  });
}
