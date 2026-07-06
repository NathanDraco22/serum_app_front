import 'package:serum_business/src/services/http_service.dart';
import 'package:serum_business/src/tools/http_tool.dart';

class ExamsDataSource with HttpService {
  ExamsDataSource._();
  static final ExamsDataSource instance = ExamsDataSource._();
  factory ExamsDataSource() {
    return instance;
  }

  final _endpoint = "/exams";

  Future<Map<String, dynamic>> createExam(Map<String, dynamic> exam) async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await postQuery(uri, exam, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> getAllExams() async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> getExamById(String examId) async {
    final uri = HttpTools.generateUri("$_endpoint/$examId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> updateExamById(
    String examId,
    Map<String, dynamic> exam,
  ) async {
    final uri = HttpTools.generateUri("$_endpoint/$examId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await patchQuery(uri, body: exam, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> deleteExamById(String examId) async {
    final uri = HttpTools.generateUri("$_endpoint/$examId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await deleteQuery(uri, headers: headers);
    return res;
  }
}
