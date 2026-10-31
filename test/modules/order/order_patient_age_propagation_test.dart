import 'package:flutter_test/flutter_test.dart';
import 'package:serum_business/serum_business.dart';

void main() {
  group('Order Patient Age Propagation Tests', () {
    test('PatientInfo conserva y serializa age correctamente', () {
      final info = PatientInfo(
        name: 'Guillermo Davila',
        dateOfBirth: DateTime(1995, 5, 20).millisecondsSinceEpoch,
        gender: 'M',
        phone: '8765-4321',
        age: 31,
      );

      expect(info.age, equals(31));
      final json = info.toJson();
      expect(json['age'], equals(31));

      final restored = PatientInfo.fromJson(json);
      expect(restored.age, equals(31));
      expect(restored.name, equals('Guillermo Davila'));
    });

    test('PatientInDb con age explícito propaga a PatientInfo de la orden', () {
      final patient = PatientInDb(
        id: 'pat-100',
        name: 'Doña Martha',
        dateOfBirth: DateTime(1980, 1, 1).millisecondsSinceEpoch,
        gender: 'F',
        phone: '8888-0000',
        originBranch: 'branch-1',
        createdAt: 1700000000000,
        age: 46,
      );

      final order = CreateOrder(
        patientId: patient.id,
        branchId: 'branch-1',
        patientInfo: PatientInfo(
          name: patient.name,
          dateOfBirth: patient.dateOfBirth,
          gender: patient.gender,
          phone: patient.phone,
          address: patient.address ?? '',
          cardId: patient.cardId,
          email: patient.email,
          age: patient.age,
        ),
        items: [],
      );

      expect(order.patientInfo?.age, equals(46));
      expect(order.patientInfo?.name, equals('Doña Martha'));

      final orderJson = order.toJson();
      expect((orderJson['patientInfo'] as Map<String, dynamic>)['age'], equals(46));
    });

    test('Fallback automático: si age no se pasa explícito se calcula de dateOfBirth', () {
      final now = DateTime.now();
      final birthDate = DateTime(now.year - 22, now.month, now.day);

      final legacyPatient = PatientInDb(
        id: 'pat-legacy',
        name: 'Carlos Ruiz',
        dateOfBirth: birthDate.millisecondsSinceEpoch,
        gender: 'M',
        phone: '8888-1111',
        originBranch: 'branch-1',
        createdAt: 1700000000000,
      );

      final patientInfo = PatientInfo(
        name: legacyPatient.name,
        dateOfBirth: legacyPatient.dateOfBirth,
        gender: legacyPatient.gender,
      );

      expect(legacyPatient.age, equals(22));
      expect(patientInfo.age, equals(22));
    });
  });
}
