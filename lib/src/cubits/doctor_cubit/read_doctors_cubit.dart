import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'read_doctors_state.dart';

class ReadDoctorCubit extends Cubit<ReadDoctorState> {
  final DoctorsRepository doctorsRepository;
  StreamSubscription<RepoEvent<DoctorInDb>>? _subscription;

  ReadDoctorCubit({required DoctorsRepository doctorsRepository})
      : doctorsRepository = doctorsRepository,
        super(ReadDoctorInitial()) {
    _subscription = doctorsRepository.eventStream.listen(_handleRepoEvent);
  }

  void _handleRepoEvent(RepoEvent<DoctorInDb> event) {
    if (isClosed) return;
    if (event is RepoItemCreated<DoctorInDb>) {
      markDoctorCreated(event.item);
    } else if (event is RepoItemUpdated<DoctorInDb>) {
      markDoctorUpdated(event.item);
    } else if (event is RepoItemDeleted<DoctorInDb>) {
      markDoctorDeleted(event.item);
    }
  }

  Future<void> getAll() async {
    final currentState = state;
    if (currentState is ReadDoctorSuccess) {
      emit(ReadDoctorRefreshing.fromSuccess(currentState));
    } else {
      emit(ReadDoctorLoading());
    }
    try {
      final items = await doctorsRepository.getAllDoctors();
      if (isClosed) return;
      emit(ReadDoctorSuccess(items));
    } catch (e) {
      if (isClosed) return;
      emit(ReadDoctorError(e.toString()));
    }
  }

  Future<void> getById(String doctorId) async {
    emit(ReadDoctorLoading());
    try {
      final item = await doctorsRepository.getDoctorById(doctorId);
      if (isClosed) return;
      if (item != null) {
        emit(ReadDoctorSuccess([item]));
      } else {
        emit(ReadDoctorError('Not found'));
      }
    } catch (e) {
      if (isClosed) return;
      emit(ReadDoctorError(e.toString()));
    }
  }

  void markDoctorCreated(DoctorInDb item) {
    if (isClosed) return;
    final currentState = state;
    if (currentState is ReadDoctorSuccess) {
      final items = [item, ...currentState.items.where((u) => u.id != item.id)];
      final newItems = [...currentState.newItems, item];
      emit(ReadDoctorSuccess(items, newItems: newItems));
    }
  }

  void markDoctorUpdated(DoctorInDb item) {
    if (isClosed) return;
    final currentState = state;
    if (currentState is ReadDoctorSuccess) {
      final items = currentState.items.map((u) => u.id == item.id ? item : u).toList();
      final updatedItems = [...currentState.updatedItems, item];
      emit(ReadDoctorSuccess(items, updatedItems: updatedItems));
    }
  }

  void markDoctorDeleted(DoctorInDb item) {
    if (isClosed) return;
    final currentState = state;
    if (currentState is ReadDoctorSuccess) {
      final deletedItems = [...currentState.deletedItems, item];
      emit(ReadDoctorSuccess(currentState.items, deletedItems: deletedItems));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
