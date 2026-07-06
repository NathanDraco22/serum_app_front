part of 'read_patients_cubit.dart';

sealed class ReadPatientState {}

final class ReadPatientInitial extends ReadPatientState {}

final class ReadPatientLoading extends ReadPatientState {}

class ReadPatientSuccess extends ReadPatientState {
  final List<PatientInDb> items;
  List<PatientInDb> newItems;
  List<PatientInDb> updatedItems;
  List<PatientInDb> deletedItems;

  ReadPatientSuccess(
    this.items, {
    this.newItems = const [],
    this.updatedItems = const [],
    this.deletedItems = const [],
  });
}

final class ReadPatientRefreshing extends ReadPatientSuccess {
  ReadPatientRefreshing(
    super.items, {
    super.newItems,
    super.updatedItems,
    super.deletedItems,
  });

  factory ReadPatientRefreshing.fromSuccess(
    ReadPatientSuccess success,
  ) =>
      ReadPatientRefreshing(
        success.items,
        newItems: success.newItems,
        updatedItems: success.updatedItems,
        deletedItems: success.deletedItems,
      );
}

final class ReadPatientError extends ReadPatientState {
  final String message;
  ReadPatientError(this.message);
}
