import '../../data/cash_shifts_data_source.dart';
import '../../domain/models/cash_shift_model/cash_shift_model.dart';
import '../../domain/responses/list_response.dart';
import '../../tools/reactive_repo/reactive_repository.dart';

class CashShiftsRepository with ReactiveRepository<CashShiftInDb> {
  final CashShiftsDataSource cashShiftsDataSource;

  CashShiftsRepository(this.cashShiftsDataSource);

  List<CashShiftInDb> _cashShifts = [];

  Future<CashShiftInDb> openShift(CreateCashShift createCashShift) async {
    final result =
        await cashShiftsDataSource.openCashShift(createCashShift.toJson());
    final newCashShift = CashShiftInDb.fromJson(result);
    _cashShifts = [newCashShift, ..._cashShifts];
    notifyItemCreated(newCashShift);
    return newCashShift;
  }

  Future<CashShiftInDb?> getCurrentShift(String userId) async {
    final result = await cashShiftsDataSource.getCurrentCashShift(userId);
    if (result == null) return null;
    return CashShiftInDb.fromJson(result);
  }

  Future<CashShiftInDb> closeShift(
    String shiftId,
    CloseCashShift closeShift, {
    String? userId,
  }) async {
    final result = await cashShiftsDataSource.closeCashShift(
      shiftId,
      closeShift.toJson(),
      userId: userId,
    );
    final closedShift = CashShiftInDb.fromJson(result);
    _cashShifts = _cashShifts.map((s) => s.id == shiftId ? closedShift : s).toList();
    notifyItemUpdated(closedShift);
    return closedShift;
  }

  Future<List<CashShiftInDb>> getAllCashShifts({
    String? branchId,
    String? userId,
    String? status,
  }) async {
    final results = await cashShiftsDataSource.getAllCashShifts(
      branchId: branchId,
      userId: userId,
      status: status,
    );
    final response = ListResponse<CashShiftInDb>.fromJson(
      results,
      CashShiftInDb.fromJson,
    );
    _cashShifts = response.data;
    return _cashShifts;
  }

  Future<CashShiftInDb?> getCashShiftById(String shiftId) async {
    final result = await cashShiftsDataSource.getCashShiftById(shiftId);
    if (result == null) return null;
    return CashShiftInDb.fromJson(result);
  }

  Future<CashShiftInDb?> updateCashShiftById(
    String shiftId,
    UpdateCashShift cashShift,
  ) async {
    final result = await cashShiftsDataSource.updateCashShiftById(
      shiftId,
      cashShift.toJson(),
    );
    if (result == null) return null;

    final updatedCashShift = CashShiftInDb.fromJson(result);
    notifyItemUpdated(updatedCashShift);
    return updatedCashShift;
  }

  Future<CashShiftInDb?> deleteCashShiftById(String shiftId) async {
    final result = await cashShiftsDataSource.deleteCashShiftById(shiftId);
    if (result == null) return null;

    final deletedCashShift = CashShiftInDb.fromJson(result);
    notifyItemDeleted(deletedCashShift);
    return deletedCashShift;
  }
}
