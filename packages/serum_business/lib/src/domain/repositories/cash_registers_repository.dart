import 'package:serum_business/src/domain/models/cash_register_model/cash_register_model.dart';
import 'package:serum_business/src/domain/models/cash_transaction_model/cash_transaction_model.dart';
import 'package:serum_business/src/domain/responses/list_response.dart';
import 'package:serum_business/src/data/data_sources.dart';
import 'package:serum_business/src/tools/reactive_repo/reactive_repository.dart';

class CashRegistersRepository with ReactiveRepository<CashRegisterInDb> {
  final CashRegistersDataSource cashRegistersDataSource;

  CashRegistersRepository(this.cashRegistersDataSource);

  List<CashRegisterInDb> _cashRegisters = [];

  Future<CashRegisterInDb> createCashRegister(CreateCashRegister createCashRegister) async {
    final result = await cashRegistersDataSource.createCashRegister(createCashRegister.toJson());
    final newCashRegister = CashRegisterInDb.fromJson(result);
    _cashRegisters = [newCashRegister, ..._cashRegisters];
    notifyItemCreated(newCashRegister);
    return newCashRegister;
  }

  Future<List<CashRegisterInDb>> getAllCashRegisters() async {
    final results = await cashRegistersDataSource.getAllCashRegisters();
    final response = ListResponse<CashRegisterInDb>.fromJson(
      results,
      CashRegisterInDb.fromJson,
    );

    _cashRegisters = response.data;
    _cashRegisters.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return _cashRegisters;
  }

  Future<CashRegisterInDb?> getCashRegisterById(String cashRegisterId) async {
    final result = await cashRegistersDataSource.getCashRegisterById(cashRegisterId);
    if (result == null) return null;
    return CashRegisterInDb.fromJson(result);
  }

  Future<CashRegisterInDb?> updateCashRegisterById(
    String cashRegisterId,
    UpdateCashRegister cashRegister,
  ) async {
    final result = await cashRegistersDataSource.updateCashRegisterById(
      cashRegisterId,
      cashRegister.toJson(),
    );
    if (result == null) return null;

    final updatedCashRegister = CashRegisterInDb.fromJson(result);
    final index = _cashRegisters.indexWhere((u) => u.id == cashRegisterId);
    if (index != -1) {
      _cashRegisters[index] = updatedCashRegister;
      notifyItemUpdated(updatedCashRegister);
    }
    return updatedCashRegister;
  }

  Future<CashRegisterInDb?> deleteCashRegisterById(String cashRegisterId) async {
    final result = await cashRegistersDataSource.deleteCashRegisterById(cashRegisterId);
    if (result == null) return null;

    final deletedCashRegister = CashRegisterInDb.fromJson(result);
    _cashRegisters.removeWhere((u) => u.id == cashRegisterId);
    notifyItemDeleted(deletedCashRegister);
    return deletedCashRegister;
  }

  Future<CashRegisterInDb> openCashRegister(
    String cashRegisterId,
    OpenCashRegisterRequest request,
  ) async {
    final result = await cashRegistersDataSource.openCashRegister(
      cashRegisterId,
      request.toJson(),
    );
    final opened = CashRegisterInDb.fromJson(result);
    final index = _cashRegisters.indexWhere((c) => c.id == cashRegisterId);
    if (index != -1) {
      _cashRegisters[index] = opened;
      notifyItemUpdated(opened);
    }
    return opened;
  }

  Future<CashRegisterInDb> closeCashRegister(
    String cashRegisterId,
    CloseCashRegisterRequest request,
  ) async {
    final result = await cashRegistersDataSource.closeCashRegister(
      cashRegisterId,
      request.toJson(),
    );
    final closed = CashRegisterInDb.fromJson(result);
    final index = _cashRegisters.indexWhere((c) => c.id == cashRegisterId);
    if (index != -1) {
      _cashRegisters[index] = closed;
      notifyItemUpdated(closed);
    }
    return closed;
  }

  Future<CashTransactionInDb> registerIncome(
    String cashRegisterId,
    IncomeRegisterRequest request,
  ) async {
    final result = await cashRegistersDataSource.registerIncome(
      cashRegisterId,
      request.toJson(),
    );
    return CashTransactionInDb.fromJson(result);
  }

  Future<CashTransactionInDb> registerWithdrawal(
    String cashRegisterId,
    WithdrawalRegisterRequest request,
  ) async {
    final result = await cashRegistersDataSource.registerWithdrawal(
      cashRegisterId,
      request.toJson(),
    );
    return CashTransactionInDb.fromJson(result);
  }

  Future<CashTransactionInDb> registerPayment(
    String cashRegisterId,
    PaymentRegisterRequest request,
  ) async {
    final result = await cashRegistersDataSource.registerPayment(
      cashRegisterId,
      request.toJson(),
    );
    return CashTransactionInDb.fromJson(result);
  }
}
