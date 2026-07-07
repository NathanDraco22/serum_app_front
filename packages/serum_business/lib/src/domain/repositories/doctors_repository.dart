import 'package:serum_business/src/domain/models/doctor_model/doctor_model.dart';
import 'package:serum_business/src/domain/responses/list_response.dart';
import 'package:serum_business/src/data/data_sources.dart';
import 'package:serum_business/src/tools/reactive_repo/reactive_repository.dart';

class DoctorsRepository with ReactiveRepository<DoctorInDb> {
  final DoctorsDataSource doctorsDataSource;

  DoctorsRepository(this.doctorsDataSource);

  List<DoctorInDb> _doctors = [];

  Future<DoctorInDb> createDoctor(CreateDoctor createDoctor) async {
    final result = await doctorsDataSource.createDoctor(createDoctor.toJson());
    final newDoctor = DoctorInDb.fromJson(result);
    _doctors = [newDoctor, ..._doctors];
    notifyItemCreated(newDoctor);
    return newDoctor;
  }

  Future<List<DoctorInDb>> getAllDoctors() async {
    final results = await doctorsDataSource.getAllDoctors();
    final response = ListResponse<DoctorInDb>.fromJson(
      results,
      DoctorInDb.fromJson,
    );

    _doctors = response.data;
    _doctors.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return _doctors;
  }

  Future<List<DoctorInDb>> searchDoctorsByText(String textQuery) async {
    final results = await doctorsDataSource.searchDoctorsByText(textQuery);
    final response = ListResponse<DoctorInDb>.fromJson(
      results,
      DoctorInDb.fromJson,
    );
    return response.data;
  }

  Future<DoctorInDb?> getDoctorById(String doctorId) async {
    final result = await doctorsDataSource.getDoctorById(doctorId);
    if (result == null) return null;
    return DoctorInDb.fromJson(result);
  }

  Future<DoctorInDb?> updateDoctorById(
    String doctorId,
    UpdateDoctor doctor,
  ) async {
    final result = await doctorsDataSource.updateDoctorById(
      doctorId,
      doctor.toJson(),
    );
    if (result == null) return null;

    final updatedDoctor = DoctorInDb.fromJson(result);
    final index = _doctors.indexWhere((u) => u.id == doctorId);
    if (index != -1) {
      _doctors[index] = updatedDoctor;
      notifyItemUpdated(updatedDoctor);
    }
    return updatedDoctor;
  }

  Future<DoctorInDb?> deleteDoctorById(String doctorId) async {
    final result = await doctorsDataSource.deleteDoctorById(doctorId);
    if (result == null) return null;

    final deletedDoctor = DoctorInDb.fromJson(result);
    _doctors.removeWhere((u) => u.id == doctorId);
    notifyItemDeleted(deletedDoctor);
    return deletedDoctor;
  }
}
