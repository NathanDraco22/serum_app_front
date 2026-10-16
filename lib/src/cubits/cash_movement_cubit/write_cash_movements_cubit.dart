import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'write_cash_movements_state.dart';

class WriteCashMovementCubit extends Cubit<WriteCashMovementState> {
  final CashMovementsRepository cashMovementsRepository;

  WriteCashMovementCubit({required this.cashMovementsRepository})
      : super(WriteCashMovementInitial());

  Future<CashMovementInDb?> create(CreateCashMovement createCashMovement) async {
    emit(WritingCashMovement());
    try {
      final item =
          await cashMovementsRepository.createCashMovement(createCashMovement);
      emit(CashMovementCreated(item));
      emit(WriteCashMovementInitial());
      return item;
    } catch (error) {
      emit(WriteCashMovementError(error.toString()));
      return null;
    }
  }

  Future<void> update(
      String cashMovementId, UpdateCashMovement cashMovement) async {
    emit(WritingCashMovement());
    try {
      final item = await cashMovementsRepository.updateCashMovementById(
          cashMovementId, cashMovement);
      if (item == null) {
        emit(const WriteCashMovementError("CashMovement not found"));
      } else {
        emit(CashMovementUpdated(item));
        emit(WriteCashMovementInitial());
      }
    } catch (error) {
      emit(WriteCashMovementError(error.toString()));
    }
  }

  Future<void> delete(String cashMovementId) async {
    emit(WritingCashMovement());
    try {
      final item = await cashMovementsRepository
          .deleteCashMovementById(cashMovementId);
      if (item == null) {
        emit(const WriteCashMovementError("CashMovement not found"));
      } else {
        emit(CashMovementDeleted(item));
        emit(WriteCashMovementInitial());
      }
    } catch (error) {
      emit(WriteCashMovementError(error.toString()));
    }
  }
}
