part of 'write_doctors_cubit.dart';

sealed class WriteDoctorState {}

final class WriteDoctorInitial extends WriteDoctorState {}

final class WritingDoctor extends WriteDoctorState {}

class WriteDoctorSuccess extends WriteDoctorState {
  final DoctorInDb item;
  WriteDoctorSuccess(this.item);
}

final class DoctorCreated extends WriteDoctorSuccess {
  DoctorCreated(super.item);
}

final class DoctorUpdated extends WriteDoctorSuccess {
  DoctorUpdated(super.item);
}

final class DoctorDeleted extends WriteDoctorSuccess {
  DoctorDeleted(super.item);
}

final class WriteDoctorError extends WriteDoctorState {
  final String message;
  WriteDoctorError(this.message);
}
