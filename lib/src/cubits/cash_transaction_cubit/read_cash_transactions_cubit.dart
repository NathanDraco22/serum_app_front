import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'read_cash_transactions_state.dart';

class ReadCashTransactionCubit extends Cubit<ReadCashTransactionState> {
  final CashTransactionsRepository cashTransactionsRepository;

  ReadCashTransactionCubit({required this.cashTransactionsRepository})
      : super(ReadCashTransactionInitial());

  Future<void> getAll() async {
    final currentState = state;
    if (currentState is ReadCashTransactionSuccess) {
      emit(ReadCashTransactionRefreshing.fromSuccess(currentState));
    } else {
      emit(ReadCashTransactionLoading());
    }
    try {
      final items = await cashTransactionsRepository.getAllCashTransactions();
      emit(ReadCashTransactionSuccess(items));
    } catch (e) {
      emit(ReadCashTransactionError(e.toString()));
    }
  }
}
