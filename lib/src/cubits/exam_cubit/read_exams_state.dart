part of 'read_exams_cubit.dart';

sealed class ReadExamState {}

final class ReadExamInitial extends ReadExamState {}

final class ReadExamLoading extends ReadExamState {}

class ReadExamSuccess extends ReadExamState {
  final List<ExamInDb> items;
  List<ExamInDb> newItems;
  List<ExamInDb> updatedItems;
  List<ExamInDb> deletedItems;

  ReadExamSuccess(
    this.items, {
    this.newItems = const [],
    this.updatedItems = const [],
    this.deletedItems = const [],
  });
}

final class ReadExamRefreshing extends ReadExamSuccess {
  ReadExamRefreshing(
    super.items, {
    super.newItems,
    super.updatedItems,
    super.deletedItems,
  });

  factory ReadExamRefreshing.fromSuccess(
    ReadExamSuccess success,
  ) =>
      ReadExamRefreshing(
        success.items,
        newItems: success.newItems,
        updatedItems: success.updatedItems,
        deletedItems: success.deletedItems,
      );
}

final class ReadExamError extends ReadExamState {
  final String message;
  ReadExamError(this.message);
}
