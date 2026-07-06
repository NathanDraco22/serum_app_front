import 'package:serum_business/src/services/http_service.dart';
import 'package:serum_business/src/tools/http_tool.dart';

class LabTestsDataSource with HttpService {
  LabTestsDataSource._();
  static final LabTestsDataSource instance = LabTestsDataSource._();
  factory LabTestsDataSource() {
    return instance;
  }

  final _endpoint = "/lab-tests";

  Future<Map<String, dynamic>> createLabTest(Map<String, dynamic> labTest) async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await postQuery(uri, labTest, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> getAllLabTests() async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> getLabTestById(String labTestId) async {
    final uri = HttpTools.generateUri("$_endpoint/$labTestId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> updateLabTestById(
    String labTestId,
    Map<String, dynamic> labTest,
  ) async {
    final uri = HttpTools.generateUri("$_endpoint/$labTestId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await patchQuery(uri, body: labTest, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> deleteLabTestById(String labTestId) async {
    final uri = HttpTools.generateUri("$_endpoint/$labTestId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await deleteQuery(uri, headers: headers);
    return res;
  }
}
