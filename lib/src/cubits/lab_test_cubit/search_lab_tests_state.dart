part of 'search_lab_tests_cubit.dart';

sealed class SearchLabTestState {}

final class SearchLabTestInitial extends SearchLabTestState {}

final class SearchLabTestLoading extends SearchLabTestState {}

class SearchLabTestSuccess extends SearchLabTestState {
  final List<LabTestInDb> items;

  SearchLabTestSuccess(this.items);
}

final class SearchLabTestError extends SearchLabTestState {
  final String message;
  SearchLabTestError(this.message);
}
