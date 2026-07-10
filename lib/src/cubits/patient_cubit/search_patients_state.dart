part of 'search_patients_cubit.dart';

sealed class SearchPatientState {}

final class SearchPatientInitial extends SearchPatientState {}

final class SearchPatientLoading extends SearchPatientState {}

class SearchPatientSuccess extends SearchPatientState {
  final List<PatientInDb> items;

  SearchPatientSuccess(this.items);
}

final class SearchPatientError extends SearchPatientState {
  final String message;
  SearchPatientError(this.message);
}
