part of 'read_lab_tests_cubit.dart';

sealed class ReadLabTestState {}

final class ReadLabTestInitial extends ReadLabTestState {}

final class ReadLabTestLoading extends ReadLabTestState {}

class ReadLabTestSuccess extends ReadLabTestState {
  final List<LabTestInDb> items;
  List<LabTestInDb> newItems;
  List<LabTestInDb> updatedItems;
  List<LabTestInDb> deletedItems;

  ReadLabTestSuccess(
    this.items, {
    this.newItems = const [],
    this.updatedItems = const [],
    this.deletedItems = const [],
  });
}

final class ReadLabTestRefreshing extends ReadLabTestSuccess {
  ReadLabTestRefreshing(
    super.items, {
    super.newItems,
    super.updatedItems,
    super.deletedItems,
  });

  factory ReadLabTestRefreshing.fromSuccess(
    ReadLabTestSuccess success,
  ) =>
      ReadLabTestRefreshing(
        success.items,
        newItems: success.newItems,
        updatedItems: success.updatedItems,
        deletedItems: success.deletedItems,
      );
}

final class ReadLabTestError extends ReadLabTestState {
  final String message;
  ReadLabTestError(this.message);
}
