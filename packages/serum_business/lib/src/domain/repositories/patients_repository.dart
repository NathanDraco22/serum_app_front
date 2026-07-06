import 'package:serum_business/src/domain/models/patient_model/patient_model.dart';
import 'package:serum_business/src/domain/responses/list_response.dart';
import 'package:serum_business/src/data/data_sources.dart';
import 'package:serum_business/src/tools/reactive_repo/reactive_repository.dart';

class PatientsRepository with ReactiveRepository<PatientInDb> {
  final PatientsDataSource patientsDataSource;

  PatientsRepository(this.patientsDataSource);

  List<PatientInDb> _patients = [];

  Future<PatientInDb> createPatient(CreatePatient createPatient) async {
    final result = await patientsDataSource.createPatient(createPatient.toJson());
    final newPatient = PatientInDb.fromJson(result);
    _patients = [newPatient, ..._patients];
    notifyItemCreated(newPatient);
    return newPatient;
  }

  Future<List<PatientInDb>> getAllPatients() async {
    final results = await patientsDataSource.getAllPatients();
    final response = ListResponse<PatientInDb>.fromJson(
      results,
      PatientInDb.fromJson,
    );

    _patients = response.data;
    _patients.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return _patients;
  }

  Future<PatientInDb?> getPatientById(String patientId) async {
    final result = await patientsDataSource.getPatientById(patientId);
    if (result == null) return null;
    return PatientInDb.fromJson(result);
  }

  Future<PatientInDb?> updatePatientById(
    String patientId,
    UpdatePatient patient,
  ) async {
    final result = await patientsDataSource.updatePatientById(
      patientId,
      patient.toJson(),
    );
    if (result == null) return null;

    final updatedPatient = PatientInDb.fromJson(result);
    final index = _patients.indexWhere((u) => u.id == patientId);
    if (index != -1) {
      _patients[index] = updatedPatient;
      notifyItemUpdated(updatedPatient);
    }
    return updatedPatient;
  }

  Future<PatientInDb?> deletePatientById(String patientId) async {
    final result = await patientsDataSource.deletePatientById(patientId);
    if (result == null) return null;

    final deletedPatient = PatientInDb.fromJson(result);
    _patients.removeWhere((u) => u.id == patientId);
    notifyItemDeleted(deletedPatient);
    return deletedPatient;
  }
}
