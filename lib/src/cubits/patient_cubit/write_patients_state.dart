part of 'write_patients_cubit.dart';

sealed class WritePatientState {}

final class WritePatientInitial extends WritePatientState {}

final class WritingPatient extends WritePatientState {}

class WritePatientSuccess extends WritePatientState {
  final PatientInDb item;
  WritePatientSuccess(this.item);
}

final class PatientCreated extends WritePatientSuccess {
  PatientCreated(super.item);
}

final class PatientUpdated extends WritePatientSuccess {
  PatientUpdated(super.item);
}

final class PatientDeleted extends WritePatientSuccess {
  PatientDeleted(super.item);
}

final class WritePatientError extends WritePatientState {
  final String message;
  WritePatientError(this.message);
}
