class ApiKeyModel {
  final String id;
  final String name;
  final String key;
  final String maskedKey;
  final String serviceType;
  final List<String> scopes;
  final String? branchId;
  final bool isActive;
  final int createdAt;
  final int? updatedAt;
  final int? lastUsedAt;
  final String? createdBy;
  final String? rawKey;

  ApiKeyModel({
    required this.id,
    required this.name,
    required this.key,
    required this.maskedKey,
    required this.serviceType,
    required this.scopes,
    this.branchId,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.lastUsedAt,
    this.createdBy,
    this.rawKey,
  });

  factory ApiKeyModel.fromJson(Map<String, dynamic> json) {
    return ApiKeyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      key: json['key'] ?? '',
      maskedKey: json['maskedKey'] ?? json['key'] ?? '',
      serviceType: json['serviceType'] ?? 'power_bi',
      scopes: (json['scopes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['bi:read'],
      branchId: json['branchId'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] ?? 0,
      updatedAt: json['updatedAt'],
      lastUsedAt: json['lastUsedAt'],
      createdBy: json['createdBy'],
      rawKey: json['rawKey'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'key': key,
      'maskedKey': maskedKey,
      'serviceType': serviceType,
      'scopes': scopes,
      'branchId': branchId,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastUsedAt': lastUsedAt,
      'createdBy': createdBy,
      if (rawKey != null) 'rawKey': rawKey,
    };
  }
}
