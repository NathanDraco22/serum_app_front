part of 'write_lab_tests_cubit.dart';

sealed class WriteLabTestState {}

final class WriteLabTestInitial extends WriteLabTestState {}

final class WritingLabTest extends WriteLabTestState {}

class WriteLabTestSuccess extends WriteLabTestState {
  final LabTestInDb item;
  WriteLabTestSuccess(this.item);
}

final class LabTestCreated extends WriteLabTestSuccess {
  LabTestCreated(super.item);
}

final class LabTestUpdated extends WriteLabTestSuccess {
  LabTestUpdated(super.item);
}

final class LabTestDeleted extends WriteLabTestSuccess {
  LabTestDeleted(super.item);
}

final class WriteLabTestError extends WriteLabTestState {
  final String message;
  WriteLabTestError(this.message);
}
