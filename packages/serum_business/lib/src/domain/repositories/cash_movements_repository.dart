import '../../data/cash_movements_data_source.dart';
import '../../domain/models/cash_movement_model/cash_movement_model.dart';
import '../../domain/query_params/cash_movement_query_params.dart';
import '../../domain/responses/list_response.dart';
import '../../tools/reactive_repo/reactive_repository.dart';

class CashMovementsRepository with ReactiveRepository<CashMovementInDb> {
  final CashMovementsDataSource cashMovementsDataSource;

  CashMovementsRepository(this.cashMovementsDataSource);

  List<CashMovementInDb> _cashMovements = [];

  Future<CashMovementInDb> createCashMovement(
      CreateCashMovement createCashMovement) async {
    final result = await cashMovementsDataSource
        .createCashMovement(createCashMovement.toJson());
    final newMovement = CashMovementInDb.fromJson(result);
    _cashMovements = [newMovement, ..._cashMovements];
    notifyItemCreated(newMovement);
    return newMovement;
  }

  Future<List<CashMovementInDb>> getAllCashMovements(
      {CashMovementQueryParams? queryParams}) async {
    final results = await cashMovementsDataSource.getAllCashMovements(
        queryParams: queryParams);
    final response = ListResponse<CashMovementInDb>.fromJson(
      results,
      CashMovementInDb.fromJson,
    );

    _cashMovements = response.data;
    return _cashMovements;
  }

  Future<CashMovementInDb?> getCashMovementById(String cashMovementId) async {
    final result =
        await cashMovementsDataSource.getCashMovementById(cashMovementId);
    if (result == null) return null;
    return CashMovementInDb.fromJson(result);
  }

  Future<CashMovementInDb?> updateCashMovementById(
    String cashMovementId,
    UpdateCashMovement cashMovement,
  ) async {
    final result = await cashMovementsDataSource.updateCashMovementById(
      cashMovementId,
      cashMovement.toJson(),
    );
    if (result == null) return null;

    final updatedMovement = CashMovementInDb.fromJson(result);
    final index = _cashMovements.indexWhere((m) => m.id == cashMovementId);
    if (index != -1) {
      _cashMovements[index] = updatedMovement;
    }
    notifyItemUpdated(updatedMovement);
    return updatedMovement;
  }

  Future<CashMovementInDb?> deleteCashMovementById(
      String cashMovementId) async {
    final result =
        await cashMovementsDataSource.deleteCashMovementById(cashMovementId);
    if (result == null) return null;

    final deletedMovement = CashMovementInDb.fromJson(result);
    _cashMovements.removeWhere((m) => m.id == cashMovementId);
    notifyItemDeleted(deletedMovement);
    return deletedMovement;
  }
}
