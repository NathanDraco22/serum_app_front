import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'search_patients_state.dart';

class SearchPatientCubit extends Cubit<SearchPatientState> {
  final PatientsRepository patientsRepository;

  SearchPatientCubit({required this.patientsRepository})
      : super(SearchPatientInitial());

  Future<void> search(String textQuery) async {
    emit(SearchPatientLoading());
    try {
      final items = await patientsRepository.searchPatientsByText(textQuery);
      emit(SearchPatientSuccess(items));
    } catch (e) {
      emit(SearchPatientError(e.toString()));
    }
  }

  void clear() {
    emit(SearchPatientInitial());
  }
}
