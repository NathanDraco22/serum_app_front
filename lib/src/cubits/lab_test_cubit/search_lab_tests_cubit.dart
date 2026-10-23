import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'search_lab_tests_state.dart';

class SearchLabTestCubit extends Cubit<SearchLabTestState> {
  final LabTestsRepository labTestsRepository;
  StreamSubscription<RepoEvent<LabTestInDb>>? _subscription;

  SearchLabTestCubit({required LabTestsRepository labTestsRepository})
      : labTestsRepository = labTestsRepository,
        super(SearchLabTestInitial()) {
    _subscription = labTestsRepository.eventStream.listen(_handleRepoEvent);
  }

  void _handleRepoEvent(RepoEvent<LabTestInDb> event) {
    if (isClosed) return;
    final currentState = state;
    if (currentState is SearchLabTestSuccess) {
      if (event is RepoItemUpdated<LabTestInDb>) {
        final updatedItems = currentState.items.map((item) {
          return item.id == event.item.id ? event.item : item;
        }).toList();
        emit(SearchLabTestSuccess(updatedItems));
      } else if (event is RepoItemDeleted<LabTestInDb>) {
        final filteredItems = currentState.items
            .where((item) => item.id != event.item.id)
            .toList();
        emit(SearchLabTestSuccess(filteredItems));
      }
    }
  }

  Future<void> search(String textQuery, {String? branchId}) async {
    emit(SearchLabTestLoading());
    try {
      final items = await labTestsRepository.searchLabTestsByText(
        textQuery,
        branchId: branchId,
      );
      if (isClosed) return;
      emit(SearchLabTestSuccess(items));
    } catch (e) {
      if (isClosed) return;
      emit(SearchLabTestError(e.toString()));
    }
  }

  void clear() {
    emit(SearchLabTestInitial());
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
