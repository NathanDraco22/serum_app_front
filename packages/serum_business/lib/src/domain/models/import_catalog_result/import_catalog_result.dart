class ImportCatalogResult {
  final bool success;
  final String message;
  final int atomicCreated;
  final int packsCreated;
  final int accountsCreated;
  final int alreadyExisting;
  final int totalProcessed;

  const ImportCatalogResult({
    this.success = true,
    this.message = 'Catálogo por defecto importado exitosamente',
    this.atomicCreated = 0,
    this.packsCreated = 0,
    this.accountsCreated = 0,
    this.alreadyExisting = 0,
    this.totalProcessed = 0,
  });

  factory ImportCatalogResult.fromJson(Map<String, dynamic> json) {
    return ImportCatalogResult(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? '',
      atomicCreated: json['atomicCreated'] as int? ?? 0,
      packsCreated: json['packsCreated'] as int? ?? 0,
      accountsCreated: json['accountsCreated'] as int? ?? 0,
      alreadyExisting: json['alreadyExisting'] as int? ?? 0,
      totalProcessed: json['totalProcessed'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'atomicCreated': atomicCreated,
      'packsCreated': packsCreated,
      'accountsCreated': accountsCreated,
      'alreadyExisting': alreadyExisting,
      'totalProcessed': totalProcessed,
    };
  }

  @override
  String toString() {
    return 'ImportCatalogResult(success: $success, message: $message, atomicCreated: $atomicCreated, packsCreated: $packsCreated, accountsCreated: $accountsCreated, alreadyExisting: $alreadyExisting, totalProcessed: $totalProcessed)';
  }
}
