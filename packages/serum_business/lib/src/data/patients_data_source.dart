import 'package:serum_business/src/services/http_service.dart';
import 'package:serum_business/src/tools/http_tool.dart';

class PatientsDataSource with HttpService {
  PatientsDataSource._();
  static final PatientsDataSource instance = PatientsDataSource._();
  factory PatientsDataSource() {
    return instance;
  }

  final _endpoint = "/patients";

  Future<Map<String, dynamic>> createPatient(Map<String, dynamic> patient) async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await postQuery(uri, patient, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> getAllPatients() async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> getPatientById(String patientId) async {
    final uri = HttpTools.generateUri("$_endpoint/$patientId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> updatePatientById(
    String patientId,
    Map<String, dynamic> patient,
  ) async {
    final uri = HttpTools.generateUri("$_endpoint/$patientId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await patchQuery(uri, body: patient, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> deletePatientById(String patientId) async {
    final uri = HttpTools.generateUri("$_endpoint/$patientId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await deleteQuery(uri, headers: headers);
    return res;
  }
}
