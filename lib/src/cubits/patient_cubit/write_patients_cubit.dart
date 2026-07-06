import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'write_patients_state.dart';

class WritePatientCubit extends Cubit<WritePatientState> {
  final PatientsRepository patientsRepository;

  WritePatientCubit({required this.patientsRepository})
      : super(WritePatientInitial());

  Future<void> create(CreatePatient createPatient) async {
    emit(WritingPatient());
    try {
      final item = await patientsRepository.createPatient(createPatient);
      emit(PatientCreated(item));
    } catch (e) {
      emit(WritePatientError(e.toString()));
    }
  }

  Future<void> update(String patientId, UpdatePatient patient) async {
    emit(WritingPatient());
    try {
      final item = await patientsRepository.updatePatientById(patientId, patient);
      if (item != null) {
        emit(PatientUpdated(item));
      } else {
        emit(WritePatientError('Not found'));
      }
    } catch (e) {
      emit(WritePatientError(e.toString()));
    }
  }

  Future<void> delete(String patientId) async {
    emit(WritingPatient());
    try {
      final item = await patientsRepository.deletePatientById(patientId);
      if (item != null) {
        emit(PatientDeleted(item));
      } else {
        emit(WritePatientError('Not found'));
      }
    } catch (e) {
      emit(WritePatientError(e.toString()));
    }
  }
}
