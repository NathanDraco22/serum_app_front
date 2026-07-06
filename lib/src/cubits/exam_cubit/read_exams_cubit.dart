import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'read_exams_state.dart';

class ReadExamCubit extends Cubit<ReadExamState> {
  final ExamsRepository examsRepository;
  ReadExamCubit({required ExamsRepository examsRepository})
      : examsRepository = examsRepository,
        super(ReadExamInitial()) {
    examsRepository.eventStream.listen(_handleRepoEvent);
  }

  void _handleRepoEvent(RepoEvent<ExamInDb> event) {
    if (event is RepoItemCreated<ExamInDb>) {
      markExamCreated(event.item);
    } else if (event is RepoItemUpdated<ExamInDb>) {
      markExamUpdated(event.item);
    } else if (event is RepoItemDeleted<ExamInDb>) {
      markExamDeleted(event.item);
    }
  }

  Future<void> getAll() async {
    final currentState = state;
    if (currentState is ReadExamSuccess) {
      emit(ReadExamRefreshing.fromSuccess(currentState));
    } else {
      emit(ReadExamLoading());
    }
    try {
      final items = await examsRepository.getAllExams();
      emit(ReadExamSuccess(items));
    } catch (e) {
      emit(ReadExamError(e.toString()));
    }
  }

  Future<void> getById(String examId) async {
    emit(ReadExamLoading());
    try {
      final item = await examsRepository.getExamById(examId);
      if (item != null) {
        emit(ReadExamSuccess([item]));
      } else {
        emit(ReadExamError('Not found'));
      }
    } catch (e) {
      emit(ReadExamError(e.toString()));
    }
  }

  void markExamCreated(ExamInDb item) {
    final currentState = state;
    if (currentState is ReadExamSuccess) {
      final items = [item, ...currentState.items.where((u) => u.id != item.id)];
      final newItems = [...currentState.newItems, item];
      emit(ReadExamSuccess(items, newItems: newItems));
    }
  }

  void markExamUpdated(ExamInDb item) {
    final currentState = state;
    if (currentState is ReadExamSuccess) {
      final items = currentState.items.map((u) => u.id == item.id ? item : u).toList();
      final updatedItems = [...currentState.updatedItems, item];
      emit(ReadExamSuccess(items, updatedItems: updatedItems));
    }
  }

  void markExamDeleted(ExamInDb item) {
    final currentState = state;
    if (currentState is ReadExamSuccess) {
      final deletedItems = [...currentState.deletedItems, item];
      emit(ReadExamSuccess(currentState.items, deletedItems: deletedItems));
    }
  }
}
