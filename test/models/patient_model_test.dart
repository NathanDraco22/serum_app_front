import 'package:flutter_test/flutter_test.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  group('Patient Model Tests', () {
    test('Calcula age correctamente a partir de dateOfBirth', () {
      final now = DateTime.now();
      final birth30YearsAgo = DateTime(now.year - 30, now.month, now.day);

      final patient = PatientInDb(
        id: 'pat-1',
        name: 'Ana Silva',
        dateOfBirth: birth30YearsAgo.millisecondsSinceEpoch,
        gender: 'F',
        phone: '8888-9999',
        originBranch: 'branch-1',
        createdAt: 1700000000000,
      );

      expect(patient.age, equals(30));
    });

    test('Usa explicitAge cuando está presente', () {
      final patient = PatientInDb(
        id: 'pat-2',
        name: 'Roberto Gómez',
        dateOfBirth: DateTime(2000, 1, 1).millisecondsSinceEpoch,
        gender: 'M',
        phone: '8888-1234',
        originBranch: 'branch-1',
        createdAt: 1700000000000,
        age: 45,
      );

      expect(patient.age, equals(45));
      expect(patient.toJson()['age'], equals(45));
    });

    test('Serialización y deserialización bidireccional en PatientInDb', () {
      final json = {
        'id': 'pat-3',
        'name': 'Carlos Mendoza',
        'dateOfBirth': 631152000000,
        'gender': 'M',
        'phone': '8888-5555',
        'address': 'Managua, Nicaragua',
        'email': 'carlos@test.com',
        'cardId': '001-123456-0001A',
        'originBranch': 'branch-1',
        'createdAt': 1700000000000,
        'updatedAt': 1700005000000,
        'isDeleted': false,
        'age': 34,
      };

      final patient = PatientInDb.fromJson(json);

      expect(patient.id, equals('pat-3'));
      expect(patient.name, equals('Carlos Mendoza'));
      expect(patient.age, equals(34));
      expect(patient.dateOfBirth, equals(631152000000));
      expect(patient.cardId, equals('001-123456-0001A'));

      final outJson = patient.toJson();
      expect(outJson['age'], equals(34));
      expect(outJson['cardId'], equals('001-123456-0001A'));
    });

    test('Retrocompatibilidad: funciona sin campo age en json', () {
      final legacyJson = {
        'id': 'pat-legacy',
        'name': 'Legacy Patient',
        'dateOfBirth': DateTime(DateTime.now().year - 20, 1, 1).millisecondsSinceEpoch,
        'gender': 'F',
        'phone': '8888-0000',
        'originBranch': 'branch-1',
        'createdAt': 1700000000000,
      };

      final patient = PatientInDb.fromJson(legacyJson);
      expect(patient.age, equals(20));
      expect(patient.explicitAge, isNull);
    });

    test('CreatePatient y UpdatePatient serializan age correctamente', () {
      final createPatient = CreatePatient(
        name: 'Nuevo Paciente',
        dateOfBirth: DateTime(DateTime.now().year - 25, 5, 10).millisecondsSinceEpoch,
        gender: 'M',
        phone: '8888-7777',
        originBranch: 'branch-1',
        age: 25,
      );

      expect(createPatient.toJson()['age'], equals(25));
      expect(createPatient.age, equals(25));

      final updatePatient = UpdatePatient(
        name: 'Paciente Actualizado',
        age: 26,
      );

      expect(updatePatient.toJson()['age'], equals(26));
    });

    test('PatientInfo en order_model calcula y serializa age correctamente', () {
      final now = DateTime.now();
      final birth18YearsAgo = DateTime(now.year - 18, now.month, now.day);

      final patientInfo = PatientInfo(
        name: 'Joven Mayor de Edad',
        dateOfBirth: birth18YearsAgo.millisecondsSinceEpoch,
        gender: 'M',
        age: 18,
      );

      expect(patientInfo.age, equals(18));
      expect(patientInfo.toJson()['age'], equals(18));

      final json = {
        'name': 'Paciente Deserializado',
        'dateOfBirth': birth18YearsAgo.millisecondsSinceEpoch,
        'gender': 'F',
        'phone': '8888-3333',
        'address': 'Dirección',
        'age': 18,
      };

      final deserialized = PatientInfo.fromJson(json);
      expect(deserialized.age, equals(18));
      expect(deserialized.name, equals('Paciente Deserializado'));
    });
  });
}
