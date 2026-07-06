part of 'read_doctors_cubit.dart';

sealed class ReadDoctorState {}

final class ReadDoctorInitial extends ReadDoctorState {}

final class ReadDoctorLoading extends ReadDoctorState {}

class ReadDoctorSuccess extends ReadDoctorState {
  final List<DoctorInDb> items;
  List<DoctorInDb> newItems;
  List<DoctorInDb> updatedItems;
  List<DoctorInDb> deletedItems;

  ReadDoctorSuccess(
    this.items, {
    this.newItems = const [],
    this.updatedItems = const [],
    this.deletedItems = const [],
  });
}

final class ReadDoctorRefreshing extends ReadDoctorSuccess {
  ReadDoctorRefreshing(
    super.items, {
    super.newItems,
    super.updatedItems,
    super.deletedItems,
  });

  factory ReadDoctorRefreshing.fromSuccess(
    ReadDoctorSuccess success,
  ) =>
      ReadDoctorRefreshing(
        success.items,
        newItems: success.newItems,
        updatedItems: success.updatedItems,
        deletedItems: success.deletedItems,
      );
}

final class ReadDoctorError extends ReadDoctorState {
  final String message;
  ReadDoctorError(this.message);
}
