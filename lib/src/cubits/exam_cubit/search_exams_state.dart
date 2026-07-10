part of 'search_exams_cubit.dart';

sealed class SearchExamState {}

final class SearchExamInitial extends SearchExamState {}

final class SearchExamLoading extends SearchExamState {}

class SearchExamSuccess extends SearchExamState {
  final List<ExamInDb> items;

  SearchExamSuccess(this.items);
}

final class SearchExamError extends SearchExamState {
  final String message;
  SearchExamError(this.message);
}
