import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'search_lab_tests_state.dart';

class SearchLabTestCubit extends Cubit<SearchLabTestState> {
  final LabTestsRepository labTestsRepository;

  SearchLabTestCubit({required this.labTestsRepository})
      : super(SearchLabTestInitial());

  Future<void> search(String textQuery) async {
    emit(SearchLabTestLoading());
    try {
      final items = await labTestsRepository.searchLabTestsByText(textQuery);
      emit(SearchLabTestSuccess(items));
    } catch (e) {
      emit(SearchLabTestError(e.toString()));
    }
  }

  void clear() {
    emit(SearchLabTestInitial());
  }
}
