import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'write_lab_tests_state.dart';

class WriteLabTestCubit extends Cubit<WriteLabTestState> {
  final LabTestsRepository labTestsRepository;

  WriteLabTestCubit({required this.labTestsRepository})
      : super(WriteLabTestInitial());

  Future<void> create(CreateLabTest createLabTest) async {
    emit(WritingLabTest());
    try {
      final item = await labTestsRepository.createLabTest(createLabTest);
      emit(LabTestCreated(item));
    } catch (e) {
      emit(WriteLabTestError(e.toString()));
    }
  }

  Future<void> update(String labTestId, UpdateLabTest labTest) async {
    emit(WritingLabTest());
    try {
      final item = await labTestsRepository.updateLabTestById(labTestId, labTest);
      if (item != null) {
        emit(LabTestUpdated(item));
      } else {
        emit(WriteLabTestError('Not found'));
      }
    } catch (e) {
      emit(WriteLabTestError(e.toString()));
    }
  }

  Future<void> delete(String labTestId) async {
    emit(WritingLabTest());
    try {
      final item = await labTestsRepository.deleteLabTestById(labTestId);
      if (item != null) {
        emit(LabTestDeleted(item));
      } else {
        emit(WriteLabTestError('Not found'));
      }
    } catch (e) {
      emit(WriteLabTestError(e.toString()));
    }
  }
}
