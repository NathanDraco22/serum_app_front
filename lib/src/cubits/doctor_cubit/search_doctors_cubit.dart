import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'search_doctors_state.dart';

class SearchDoctorCubit extends Cubit<SearchDoctorState> {
  final DoctorsRepository doctorsRepository;

  SearchDoctorCubit({required this.doctorsRepository})
      : super(SearchDoctorInitial());

  Future<void> search(String textQuery) async {
    emit(SearchDoctorLoading());
    try {
      final items = await doctorsRepository.searchDoctorsByText(textQuery);
      emit(SearchDoctorSuccess(items));
    } catch (e) {
      emit(SearchDoctorError(e.toString()));
    }
  }

  void clear() {
    emit(SearchDoctorInitial());
  }
}
