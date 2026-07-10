import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'search_exams_state.dart';

class SearchExamCubit extends Cubit<SearchExamState> {
  final ExamsRepository examsRepository;

  SearchExamCubit({required this.examsRepository})
      : super(SearchExamInitial());

  Future<void> search(String textQuery) async {
    emit(SearchExamLoading());
    try {
      final items = await examsRepository.searchExamsByText(textQuery);
      emit(SearchExamSuccess(items));
    } catch (e) {
      emit(SearchExamError(e.toString()));
    }
  }

  void clear() {
    emit(SearchExamInitial());
  }
}
