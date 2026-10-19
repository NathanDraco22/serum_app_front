import '../../data/imports_data_source.dart';
import '../models/import_catalog_result/import_catalog_result.dart';

class ImportsRepository {
  final ImportsDataSource importsDataSource;

  ImportsRepository(this.importsDataSource);

  ImportCatalogResult? _lastResult;

  ImportCatalogResult? get lastResult => _lastResult;

  Future<ImportCatalogResult> importDefaultCatalog() async {
    final result = await importsDataSource.importDefaultCatalog();
    final model = ImportCatalogResult.fromJson(result);
    _lastResult = model;
    return model;
  }

  Future<ImportCatalogResult> importLabTests() async {
    final result = await importsDataSource.importLabTests();
    final model = ImportCatalogResult.fromJson(result);
    _lastResult = model;
    return model;
  }
}
