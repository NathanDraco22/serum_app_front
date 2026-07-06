import 'package:serum_business/src/domain/models/branch_model/branch_model.dart';
import 'package:serum_business/src/domain/responses/list_response.dart';
import 'package:serum_business/src/data/data_sources.dart';
import 'package:serum_business/src/tools/reactive_repo/reactive_repository.dart';

class BranchesRepository with ReactiveRepository<BranchInDb> {
  final BranchesDataSource branchesDataSource;

  BranchesRepository(this.branchesDataSource);

  List<BranchInDb> _branches = [];

  Future<BranchInDb> createBranch(CreateBranch createBranch) async {
    final result = await branchesDataSource.createBranch(createBranch.toJson());
    final newBranch = BranchInDb.fromJson(result);
    _branches = [newBranch, ..._branches];
    notifyItemCreated(newBranch);
    return newBranch;
  }

  Future<List<BranchInDb>> getAllBranches() async {
    final results = await branchesDataSource.getAllBranches();
    final response = ListResponse<BranchInDb>.fromJson(
      results,
      BranchInDb.fromJson,
    );

    _branches = response.data;
    _branches.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return _branches;
  }

  Future<BranchInDb?> getBranchById(String branchId) async {
    final result = await branchesDataSource.getBranchById(branchId);
    if (result == null) return null;
    return BranchInDb.fromJson(result);
  }

  Future<BranchInDb?> updateBranchById(
    String branchId,
    UpdateBranch branch,
  ) async {
    final result = await branchesDataSource.updateBranchById(
      branchId,
      branch.toJson(),
    );
    if (result == null) return null;

    final updatedBranch = BranchInDb.fromJson(result);
    final index = _branches.indexWhere((u) => u.id == branchId);
    if (index != -1) {
      _branches[index] = updatedBranch;
      notifyItemUpdated(updatedBranch);
    }
    return updatedBranch;
  }

  Future<BranchInDb?> deleteBranchById(String branchId) async {
    final result = await branchesDataSource.deleteBranchById(branchId);
    if (result == null) return null;

    final deletedBranch = BranchInDb.fromJson(result);
    _branches.removeWhere((u) => u.id == branchId);
    notifyItemDeleted(deletedBranch);
    return deletedBranch;
  }
}
