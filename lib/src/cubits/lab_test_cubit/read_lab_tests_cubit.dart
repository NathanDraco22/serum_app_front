import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'read_lab_tests_state.dart';

class ReadLabTestCubit extends Cubit<ReadLabTestState> {
  final LabTestsRepository labTestsRepository;
  ReadLabTestCubit({required LabTestsRepository labTestsRepository})
      : labTestsRepository = labTestsRepository,
        super(ReadLabTestInitial()) {
    labTestsRepository.eventStream.listen(_handleRepoEvent);
  }

  void _handleRepoEvent(RepoEvent<LabTestInDb> event) {
    if (event is RepoItemCreated<LabTestInDb>) {
      markLabTestCreated(event.item);
    } else if (event is RepoItemUpdated<LabTestInDb>) {
      markLabTestUpdated(event.item);
    } else if (event is RepoItemDeleted<LabTestInDb>) {
      markLabTestDeleted(event.item);
    }
  }

  Future<void> getAll() async {
    final currentState = state;
    if (currentState is ReadLabTestSuccess) {
      emit(ReadLabTestRefreshing.fromSuccess(currentState));
    } else {
      emit(ReadLabTestLoading());
    }
    try {
      final items = await labTestsRepository.getAllLabTests();
      emit(ReadLabTestSuccess(items));
    } catch (e) {
      emit(ReadLabTestError(e.toString()));
    }
  }

  Future<void> getById(String labTestId) async {
    emit(ReadLabTestLoading());
    try {
      final item = await labTestsRepository.getLabTestById(labTestId);
      if (item != null) {
        emit(ReadLabTestSuccess([item]));
      } else {
        emit(ReadLabTestError('Not found'));
      }
    } catch (e) {
      emit(ReadLabTestError(e.toString()));
    }
  }

  void markLabTestCreated(LabTestInDb item) {
    final currentState = state;
    if (currentState is ReadLabTestSuccess) {
      final items = [item, ...currentState.items.where((u) => u.id != item.id)];
      final newItems = [...currentState.newItems, item];
      emit(ReadLabTestSuccess(items, newItems: newItems));
    }
  }

  void markLabTestUpdated(LabTestInDb item) {
    final currentState = state;
    if (currentState is ReadLabTestSuccess) {
      final items = currentState.items.map((u) => u.id == item.id ? item : u).toList();
      final updatedItems = [...currentState.updatedItems, item];
      emit(ReadLabTestSuccess(items, updatedItems: updatedItems));
    }
  }

  void markLabTestDeleted(LabTestInDb item) {
    final currentState = state;
    if (currentState is ReadLabTestSuccess) {
      final deletedItems = [...currentState.deletedItems, item];
      emit(ReadLabTestSuccess(currentState.items, deletedItems: deletedItems));
    }
  }
}
