import 'package:serum_business/src/services/http_service.dart';
import 'package:serum_business/src/tools/http_tool.dart';

class DoctorsDataSource with HttpService {
  DoctorsDataSource._();
  static final DoctorsDataSource instance = DoctorsDataSource._();
  factory DoctorsDataSource() {
    return instance;
  }

  final _endpoint = "/doctors";

  Future<Map<String, dynamic>> createDoctor(Map<String, dynamic> doctor) async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await postQuery(uri, doctor, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> getAllDoctors() async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> getDoctorById(String doctorId) async {
    final uri = HttpTools.generateUri("$_endpoint/$doctorId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> updateDoctorById(
    String doctorId,
    Map<String, dynamic> doctor,
  ) async {
    final uri = HttpTools.generateUri("$_endpoint/$doctorId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await patchQuery(uri, body: doctor, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> deleteDoctorById(String doctorId) async {
    final uri = HttpTools.generateUri("$_endpoint/$doctorId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await deleteQuery(uri, headers: headers);
    return res;
  }
}
