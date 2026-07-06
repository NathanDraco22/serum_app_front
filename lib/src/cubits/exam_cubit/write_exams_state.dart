part of 'write_exams_cubit.dart';

sealed class WriteExamState {}

final class WriteExamInitial extends WriteExamState {}

final class WritingExam extends WriteExamState {}

class WriteExamSuccess extends WriteExamState {
  final ExamInDb item;
  WriteExamSuccess(this.item);
}

final class ExamCreated extends WriteExamSuccess {
  ExamCreated(super.item);
}

final class ExamUpdated extends WriteExamSuccess {
  ExamUpdated(super.item);
}

final class ExamDeleted extends WriteExamSuccess {
  ExamDeleted(super.item);
}

final class WriteExamError extends WriteExamState {
  final String message;
  WriteExamError(this.message);
}
