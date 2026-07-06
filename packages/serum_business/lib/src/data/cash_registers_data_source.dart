import 'package:serum_business/src/services/http_service.dart';
import 'package:serum_business/src/tools/http_tool.dart';

class CashRegistersDataSource with HttpService {
  CashRegistersDataSource._();
  static final CashRegistersDataSource instance = CashRegistersDataSource._();
  factory CashRegistersDataSource() {
    return instance;
  }

  final _endpoint = "/cash-registers";

  Future<Map<String, dynamic>> createCashRegister(Map<String, dynamic> cashRegister) async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await postQuery(uri, cashRegister, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> getAllCashRegisters() async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> getCashRegisterById(String cashRegisterId) async {
    final uri = HttpTools.generateUri("$_endpoint/$cashRegisterId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> updateCashRegisterById(
    String cashRegisterId,
    Map<String, dynamic> cashRegister,
  ) async {
    final uri = HttpTools.generateUri("$_endpoint/$cashRegisterId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await patchQuery(uri, body: cashRegister, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> deleteCashRegisterById(String cashRegisterId) async {
    final uri = HttpTools.generateUri("$_endpoint/$cashRegisterId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await deleteQuery(uri, headers: headers);
    return res;
  }
}
