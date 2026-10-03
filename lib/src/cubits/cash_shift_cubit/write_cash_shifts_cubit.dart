import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'write_cash_shifts_state.dart';

class WriteCashShiftCubit extends Cubit<WriteCashShiftState> {
  WriteCashShiftCubit({required CashShiftsRepository cashShiftsRepository})
      : _repository = cashShiftsRepository,
        super(WriteCashShiftInitial());

  final CashShiftsRepository _repository;

  Future<CashShiftInDb?> openShift(CreateCashShift createCashShift) async {
    emit(WritingCashShift());
    try {
      final item = await _repository.openShift(createCashShift);
      emit(CashShiftCreated(item));
      emit(WriteCashShiftInitial());
      return item;
    } catch (error) {
      emit(WriteCashShiftError(error.toString()));
      return null;
    }
  }

  Future<CashShiftInDb?> closeShift(
    String shiftId,
    CloseCashShift closeShift, {
    String? userId,
  }) async {
    emit(WritingCashShift());
    try {
      final item = await _repository.closeShift(
        shiftId,
        closeShift,
        userId: userId,
      );
      emit(CashShiftClosed(item));
      emit(WriteCashShiftInitial());
      return item;
    } catch (error) {
      emit(WriteCashShiftError(error.toString()));
      return null;
    }
  }

  Future<void> update(String shiftId, UpdateCashShift cashShift) async {
    emit(WritingCashShift());
    try {
      final item = await _repository.updateCashShiftById(shiftId, cashShift);
      if (item == null) {
        emit(WriteCashShiftError("CashShift not found"));
      } else {
        emit(CashShiftUpdated(item));
        emit(WriteCashShiftInitial());
      }
    } catch (error) {
      emit(WriteCashShiftError(error.toString()));
    }
  }

  Future<void> delete(String shiftId) async {
    emit(WritingCashShift());
    try {
      final item = await _repository.deleteCashShiftById(shiftId);
      if (item == null) {
        emit(WriteCashShiftError("CashShift not found"));
      } else {
        emit(CashShiftDeleted(item));
        emit(WriteCashShiftInitial());
      }
    } catch (error) {
      emit(WriteCashShiftError(error.toString()));
    }
  }
}
