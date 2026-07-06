import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'write_doctors_state.dart';

class WriteDoctorCubit extends Cubit<WriteDoctorState> {
  final DoctorsRepository doctorsRepository;

  WriteDoctorCubit({required this.doctorsRepository})
      : super(WriteDoctorInitial());

  Future<void> create(CreateDoctor createDoctor) async {
    emit(WritingDoctor());
    try {
      final item = await doctorsRepository.createDoctor(createDoctor);
      emit(DoctorCreated(item));
    } catch (e) {
      emit(WriteDoctorError(e.toString()));
    }
  }

  Future<void> update(String doctorId, UpdateDoctor doctor) async {
    emit(WritingDoctor());
    try {
      final item = await doctorsRepository.updateDoctorById(doctorId, doctor);
      if (item != null) {
        emit(DoctorUpdated(item));
      } else {
        emit(WriteDoctorError('Not found'));
      }
    } catch (e) {
      emit(WriteDoctorError(e.toString()));
    }
  }

  Future<void> delete(String doctorId) async {
    emit(WritingDoctor());
    try {
      final item = await doctorsRepository.deleteDoctorById(doctorId);
      if (item != null) {
        emit(DoctorDeleted(item));
      } else {
        emit(WriteDoctorError('Not found'));
      }
    } catch (e) {
      emit(WriteDoctorError(e.toString()));
    }
  }
}
