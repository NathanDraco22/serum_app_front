import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'write_exams_state.dart';

class WriteExamCubit extends Cubit<WriteExamState> {
  final ExamsRepository examsRepository;

  WriteExamCubit({required this.examsRepository})
      : super(WriteExamInitial());

  Future<void> create(CreateExam createExam) async {
    emit(WritingExam());
    try {
      final item = await examsRepository.createExam(createExam);
      emit(ExamCreated(item));
    } catch (e) {
      emit(WriteExamError(e.toString()));
    }
  }

  Future<void> update(String examId, UpdateExam exam) async {
    emit(WritingExam());
    try {
      final item = await examsRepository.updateExamById(examId, exam);
      if (item != null) {
        emit(ExamUpdated(item));
      } else {
        emit(WriteExamError('Not found'));
      }
    } catch (e) {
      emit(WriteExamError(e.toString()));
    }
  }

  Future<void> delete(String examId) async {
    emit(WritingExam());
    try {
      final item = await examsRepository.deleteExamById(examId);
      if (item != null) {
        emit(ExamDeleted(item));
      } else {
        emit(WriteExamError('Not found'));
      }
    } catch (e) {
      emit(WriteExamError(e.toString()));
    }
  }
}
