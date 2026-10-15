import 'package:serum_business/src/data/lab_test_accounts_data_source.dart';
import 'package:serum_business/src/domain/models/lab_test_account_model/lab_test_account_model.dart';
import 'package:serum_business/src/domain/responses/list_response.dart';

class LabTestAccountsRepository {
  final LabTestAccountsDataSource dataSource;

  LabTestAccountsRepository({LabTestAccountsDataSource? dataSource})
      : dataSource = dataSource ?? LabTestAccountsDataSource();

  Future<List<LabTestAccountInDb>> getAccountsByBranch(String branchId) async {
    final res = await dataSource.getAccountsByBranch(branchId);
    final listResponse = ListResponse<LabTestAccountInDb>.fromJson(
      res,
      (json) => LabTestAccountInDb.fromJson(json),
    );
    return listResponse.data;
  }

  Future<List<LabTestAccountInDb>> getAccountsByTest(String labTestId) async {
    final res = await dataSource.getAccountsByTest(labTestId);
    final listResponse = ListResponse<LabTestAccountInDb>.fromJson(
      res,
      (json) => LabTestAccountInDb.fromJson(json),
    );
    return listResponse.data;
  }

  Future<LabTestAccountInDb?> getByBranchAndTest(
    String branchId,
    String labTestId,
  ) async {
    final res = await dataSource.getByBranchAndTest(branchId, labTestId);
    if (res == null) return null;
    return LabTestAccountInDb.fromJson(res);
  }

  Future<LabTestAccountInDb?> updateCommercial(
    String accountId,
    UpdateLabTestCommercial commercial,
  ) async {
    final res =
        await dataSource.updateCommercial(accountId, commercial.toJson());
    if (res == null) return null;
    return LabTestAccountInDb.fromJson(res);
  }

  Future<LabTestAccountInDb?> updateCommercialByBranchAndTest(
    String branchId,
    String labTestId,
    UpdateLabTestCommercial commercial,
  ) async {
    final res = await dataSource.updateCommercialByBranchAndTest(
      branchId,
      labTestId,
      commercial.toJson(),
    );
    if (res == null) return null;
    return LabTestAccountInDb.fromJson(res);
  }
}
