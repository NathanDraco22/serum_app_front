part of 'search_doctors_cubit.dart';

sealed class SearchDoctorState {}

final class SearchDoctorInitial extends SearchDoctorState {}

final class SearchDoctorLoading extends SearchDoctorState {}

class SearchDoctorSuccess extends SearchDoctorState {
  final List<DoctorInDb> items;

  SearchDoctorSuccess(this.items);
}

final class SearchDoctorError extends SearchDoctorState {
  final String message;
  SearchDoctorError(this.message);
}
