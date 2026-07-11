import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'write_cash_registers_state.dart';

class WriteCashRegisterCubit extends Cubit<WriteCashRegisterState> {
  final CashRegistersRepository cashRegistersRepository;

  WriteCashRegisterCubit({required this.cashRegistersRepository})
      : super(WriteCashRegisterInitial());

  Future<void> create(CreateCashRegister createCashRegister) async {
    emit(WritingCashRegister());
    try {
      final item = await cashRegistersRepository.createCashRegister(createCashRegister);
      emit(CashRegisterCreated(item));
    } catch (e) {
      emit(WriteCashRegisterError(e.toString()));
    }
  }

  Future<void> update(String cashRegisterId, UpdateCashRegister cashRegister) async {
    emit(WritingCashRegister());
    try {
      final item = await cashRegistersRepository.updateCashRegisterById(cashRegisterId, cashRegister);
      if (item != null) {
        emit(CashRegisterUpdated(item));
      } else {
        emit(WriteCashRegisterError('Not found'));
      }
    } catch (e) {
      emit(WriteCashRegisterError(e.toString()));
    }
  }

  Future<void> delete(String cashRegisterId) async {
    emit(WritingCashRegister());
    try {
      final item = await cashRegistersRepository.deleteCashRegisterById(cashRegisterId);
      if (item != null) {
        emit(CashRegisterDeleted(item));
      } else {
        emit(WriteCashRegisterError('Not found'));
      }
    } catch (e) {
      emit(WriteCashRegisterError(e.toString()));
    }
  }

  Future<void> openCashRegister(String cashRegisterId, OpenCashRegisterRequest request) async {
    emit(WritingCashRegister());
    try {
      final item = await cashRegistersRepository.openCashRegister(cashRegisterId, request);
      emit(CashRegisterOpened(item));
    } catch (e) {
      emit(WriteCashRegisterError(e.toString()));
    }
  }

  Future<void> closeCashRegister(String cashRegisterId, CloseCashRegisterRequest request) async {
    emit(WritingCashRegister());
    try {
      final item = await cashRegistersRepository.closeCashRegister(cashRegisterId, request);
      emit(CashRegisterClosed(item));
    } catch (e) {
      emit(WriteCashRegisterError(e.toString()));
    }
  }

  Future<void> registerIncome(String cashRegisterId, IncomeRegisterRequest request) async {
    emit(WritingCashRegister());
    try {
      final transaction = await cashRegistersRepository.registerIncome(cashRegisterId, request);
      emit(CashRegisterIncomeRegistered(transaction));
    } catch (e) {
      emit(WriteCashRegisterError(e.toString()));
    }
  }

  Future<void> registerWithdrawal(String cashRegisterId, WithdrawalRegisterRequest request) async {
    emit(WritingCashRegister());
    try {
      final transaction = await cashRegistersRepository.registerWithdrawal(cashRegisterId, request);
      emit(CashRegisterWithdrawalRegistered(transaction));
    } catch (e) {
      emit(WriteCashRegisterError(e.toString()));
    }
  }

  Future<void> registerPayment(String cashRegisterId, PaymentRegisterRequest request) async {
    emit(WritingCashRegister());
    try {
      final transaction = await cashRegistersRepository.registerPayment(cashRegisterId, request);
      emit(CashRegisterPaymentRegistered(transaction));
    } catch (e) {
      emit(WriteCashRegisterError(e.toString()));
    }
  }
}
