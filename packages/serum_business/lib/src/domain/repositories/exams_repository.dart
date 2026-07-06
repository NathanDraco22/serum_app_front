import 'package:serum_business/src/domain/models/exam_model/exam_model.dart';
import 'package:serum_business/src/domain/responses/list_response.dart';
import 'package:serum_business/src/data/data_sources.dart';
import 'package:serum_business/src/tools/reactive_repo/reactive_repository.dart';

class ExamsRepository with ReactiveRepository<ExamInDb> {
  final ExamsDataSource examsDataSource;

  ExamsRepository(this.examsDataSource);

  List<ExamInDb> _exams = [];

  Future<ExamInDb> createExam(CreateExam createExam) async {
    final result = await examsDataSource.createExam(createExam.toJson());
    final newExam = ExamInDb.fromJson(result);
    _exams = [newExam, ..._exams];
    notifyItemCreated(newExam);
    return newExam;
  }

  Future<List<ExamInDb>> getAllExams() async {
    final results = await examsDataSource.getAllExams();
    final response = ListResponse<ExamInDb>.fromJson(
      results,
      ExamInDb.fromJson,
    );

    _exams = response.data;
    _exams.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return _exams;
  }

  Future<ExamInDb?> getExamById(String examId) async {
    final result = await examsDataSource.getExamById(examId);
    if (result == null) return null;
    return ExamInDb.fromJson(result);
  }

  Future<ExamInDb?> updateExamById(
    String examId,
    UpdateExam exam,
  ) async {
    final result = await examsDataSource.updateExamById(
      examId,
      exam.toJson(),
    );
    if (result == null) return null;

    final updatedExam = ExamInDb.fromJson(result);
    final index = _exams.indexWhere((u) => u.id == examId);
    if (index != -1) {
      _exams[index] = updatedExam;
      notifyItemUpdated(updatedExam);
    }
    return updatedExam;
  }

  Future<ExamInDb?> deleteExamById(String examId) async {
    final result = await examsDataSource.deleteExamById(examId);
    if (result == null) return null;

    final deletedExam = ExamInDb.fromJson(result);
    _exams.removeWhere((u) => u.id == examId);
    notifyItemDeleted(deletedExam);
    return deletedExam;
  }
}
