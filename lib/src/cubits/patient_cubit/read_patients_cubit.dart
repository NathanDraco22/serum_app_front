import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'read_patients_state.dart';

class ReadPatientCubit extends Cubit<ReadPatientState> {
  final PatientsRepository patientsRepository;
  StreamSubscription<RepoEvent<PatientInDb>>? _subscription;

  ReadPatientCubit({required PatientsRepository patientsRepository})
      : patientsRepository = patientsRepository,
        super(ReadPatientInitial()) {
    _subscription = patientsRepository.eventStream.listen(_handleRepoEvent);
  }

  void _handleRepoEvent(RepoEvent<PatientInDb> event) {
    if (isClosed) return;
    if (event is RepoItemCreated<PatientInDb>) {
      markPatientCreated(event.item);
    } else if (event is RepoItemUpdated<PatientInDb>) {
      markPatientUpdated(event.item);
    } else if (event is RepoItemDeleted<PatientInDb>) {
      markPatientDeleted(event.item);
    }
  }

  Future<void> getAll() async {
    final currentState = state;
    if (currentState is ReadPatientSuccess) {
      emit(ReadPatientRefreshing.fromSuccess(currentState));
    } else {
      emit(ReadPatientLoading());
    }
    try {
      final items = await patientsRepository.getAllPatients();
      if (isClosed) return;
      emit(ReadPatientSuccess(items));
    } catch (e) {
      if (isClosed) return;
      emit(ReadPatientError(e.toString()));
    }
  }

  Future<void> getById(String patientId) async {
    emit(ReadPatientLoading());
    try {
      final item = await patientsRepository.getPatientById(patientId);
      if (isClosed) return;
      if (item != null) {
        emit(ReadPatientSuccess([item]));
      } else {
        emit(ReadPatientError('Not found'));
      }
    } catch (e) {
      if (isClosed) return;
      emit(ReadPatientError(e.toString()));
    }
  }

  void markPatientCreated(PatientInDb item) {
    if (isClosed) return;
    final currentState = state;
    if (currentState is ReadPatientSuccess) {
      final items = [item, ...currentState.items.where((u) => u.id != item.id)];
      final newItems = [...currentState.newItems, item];
      emit(ReadPatientSuccess(items, newItems: newItems));
    }
  }

  void markPatientUpdated(PatientInDb item) {
    if (isClosed) return;
    final currentState = state;
    if (currentState is ReadPatientSuccess) {
      final items = currentState.items.map((u) => u.id == item.id ? item : u).toList();
      final updatedItems = [...currentState.updatedItems, item];
      emit(ReadPatientSuccess(items, updatedItems: updatedItems));
    }
  }

  void markPatientDeleted(PatientInDb item) {
    if (isClosed) return;
    final currentState = state;
    if (currentState is ReadPatientSuccess) {
      final deletedItems = [...currentState.deletedItems, item];
      emit(ReadPatientSuccess(currentState.items, deletedItems: deletedItems));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
