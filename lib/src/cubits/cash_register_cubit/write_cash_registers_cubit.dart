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
}
