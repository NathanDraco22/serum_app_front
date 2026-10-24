import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import 'imports_state.dart';

class ImportsCubit extends Cubit<ImportsState> {
  final ImportsRepository importsRepository;

  ImportsCubit({required this.importsRepository})
      : super(const ImportsInitial());

  ImportCatalogResult? get lastResult => importsRepository.lastResult;
  ImportBranchPricesResult? get lastPricesResult =>
      importsRepository.lastPricesResult;

  Future<ImportCatalogResult?> importDefaultCatalog() async {
    emit(const ImportsLoading(
        message: 'Importando catálogo clínico maestro por defecto...'));
    try {
      final result = await importsRepository.importDefaultCatalog();
      if (isClosed) return result;
      emit(ImportsSuccess(result));
      return result;
    } catch (e) {
      if (isClosed) return null;
      emit(ImportsFailure(e.toString()));
      return null;
    }
  }

  Future<ImportCatalogResult?> importLabTests() async {
    emit(const ImportsLoading(
        message: 'Importando pruebas de laboratorio por defecto...'));
    try {
      final result = await importsRepository.importLabTests();
      if (isClosed) return result;
      emit(ImportsSuccess(result));
      return result;
    } catch (e) {
      if (isClosed) return null;
      emit(ImportsFailure(e.toString()));
      return null;
    }
  }

  Future<ImportBranchPricesResult?> importBranchPrices({
    required String sourceBranchId,
    required String targetBranchId,
    bool mustOverridePrice = false,
  }) async {
    emit(const ImportsLoading(
        message: 'Importando precios entre sucursales...'));
    try {
      final result = await importsRepository.importBranchPrices(
        sourceBranchId: sourceBranchId,
        targetBranchId: targetBranchId,
        mustOverridePrice: mustOverridePrice,
      );
      if (isClosed) return result;
      emit(ImportsPricesSuccess(result));
      return result;
    } catch (e) {
      if (isClosed) return null;
      emit(ImportsFailure(e.toString()));
      return null;
    }
  }

  void reset() {
    emit(const ImportsInitial());
  }
}
