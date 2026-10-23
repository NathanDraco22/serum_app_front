import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'search_patients_state.dart';

class SearchPatientCubit extends Cubit<SearchPatientState> {
  final PatientsRepository patientsRepository;
  StreamSubscription<RepoEvent<PatientInDb>>? _subscription;
  final Map<String, List<PatientInDb>> _queryCache = {};

  SearchPatientCubit({required this.patientsRepository})
      : super(SearchPatientInitial()) {
    _subscription = patientsRepository.eventStream.listen(_handleRepoEvent);
  }

  void _handleRepoEvent(RepoEvent<PatientInDb> event) {
    if (isClosed) return;
    final currentState = state;
    if (currentState is SearchPatientSuccess) {
      if (event is RepoItemUpdated<PatientInDb>) {
        final updatedItems = currentState.items.map((item) {
          return item.id == event.item.id ? event.item : item;
        }).toList();
        emit(SearchPatientSuccess(updatedItems));
      } else if (event is RepoItemDeleted<PatientInDb>) {
        final filteredItems = currentState.items
            .where((item) => item.id != event.item.id)
            .toList();
        emit(SearchPatientSuccess(filteredItems));
      }
    }

    // Actualizar también entradas cacheadas para coherencia de datos
    if (event is RepoItemUpdated<PatientInDb>) {
      _queryCache.forEach((key, list) {
        final idx = list.indexWhere((p) => p.id == event.item.id);
        if (idx != -1) {
          list[idx] = event.item;
        }
      });
    } else if (event is RepoItemDeleted<PatientInDb>) {
      _queryCache.forEach((key, list) {
        list.removeWhere((p) => p.id == event.item.id);
      });
    }
  }

  Future<void> search(String textQuery, {String? originBranch}) async {
    final query = textQuery.trim();
    if (query.isEmpty) {
      clear();
      return;
    }

    final cacheKey = '${originBranch ?? "all"}:${query.toLowerCase()}';
    if (_queryCache.containsKey(cacheKey)) {
      emit(SearchPatientSuccess(_queryCache[cacheKey]!));
      return;
    }

    emit(SearchPatientLoading());
    try {
      final items = await patientsRepository.searchPatientsByText(
        query,
        originBranch: originBranch,
      );
      if (isClosed) return;
      _queryCache[cacheKey] = items;
      emit(SearchPatientSuccess(items));
    } catch (e) {
      if (isClosed) return;
      emit(SearchPatientError(e.toString()));
    }
  }

  void clear() {
    emit(SearchPatientInitial());
  }

  void clearCache() {
    _queryCache.clear();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

