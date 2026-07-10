import 'package:serum_business/src/domain/models/lab_test_model/lab_test_model.dart';
import 'package:serum_business/src/domain/responses/list_response.dart';
import 'package:serum_business/src/data/data_sources.dart';
import 'package:serum_business/src/tools/reactive_repo/reactive_repository.dart';

class LabTestsRepository with ReactiveRepository<LabTestInDb> {
  final LabTestsDataSource labTestsDataSource;

  LabTestsRepository(this.labTestsDataSource);

  List<LabTestInDb> _labTests = [];

  Future<LabTestInDb> createLabTest(CreateLabTest createLabTest) async {
    final result = await labTestsDataSource.createLabTest(createLabTest.toJson());
    final newLabTest = LabTestInDb.fromJson(result);
    _labTests = [newLabTest, ..._labTests];
    notifyItemCreated(newLabTest);
    return newLabTest;
  }

  Future<List<LabTestInDb>> getAllLabTests() async {
    final results = await labTestsDataSource.getAllLabTests();
    final response = ListResponse<LabTestInDb>.fromJson(
      results,
      LabTestInDb.fromJson,
    );

    _labTests = response.data;
    return _labTests;
  }

  Future<List<LabTestInDb>> searchLabTestsByText(String textQuery) async {
    if (textQuery.trim().isEmpty) return [];
    final results = await labTestsDataSource.searchLabTestsByText(textQuery);
    final response = ListResponse<LabTestInDb>.fromJson(
      results,
      LabTestInDb.fromJson,
    );
    return response.data;
  }

  Future<LabTestInDb?> getLabTestById(String labTestId) async {
    final result = await labTestsDataSource.getLabTestById(labTestId);
    if (result == null) return null;
    return LabTestInDb.fromJson(result);
  }

  Future<LabTestInDb?> updateLabTestById(
    String labTestId,
    UpdateLabTest labTest,
  ) async {
    final result = await labTestsDataSource.updateLabTestById(
      labTestId,
      labTest.toJson(),
    );
    if (result == null) return null;

    final updatedLabTest = LabTestInDb.fromJson(result);
    final index = _labTests.indexWhere((u) => u.id == labTestId);
    if (index != -1) {
      _labTests[index] = updatedLabTest;
      notifyItemUpdated(updatedLabTest);
    }
    return updatedLabTest;
  }

  Future<LabTestInDb?> deleteLabTestById(String labTestId) async {
    final result = await labTestsDataSource.deleteLabTestById(labTestId);
    if (result == null) return null;

    final deletedLabTest = LabTestInDb.fromJson(result);
    _labTests.removeWhere((u) => u.id == labTestId);
    notifyItemDeleted(deletedLabTest);
    return deletedLabTest;
  }
}
