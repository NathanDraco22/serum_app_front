class AppSettingModel {
  final String id;
  final bool useCost;
  final bool usePrice2;
  final bool allowEditPrice;
  final int createdAt;
  final int? updatedAt;

  const AppSettingModel({
    required this.id,
    this.useCost = false,
    this.usePrice2 = false,
    this.allowEditPrice = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory AppSettingModel.fromJson(Map<String, dynamic> json) {
    return AppSettingModel(
      id: json['id'] as String? ?? 'Default',
      useCost: json['useCost'] as bool? ?? false,
      usePrice2: json['usePrice2'] as bool? ?? false,
      allowEditPrice: json['allowEditPrice'] as bool? ?? false,
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'useCost': useCost,
      'usePrice2': usePrice2,
      'allowEditPrice': allowEditPrice,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  AppSettingModel copyWith({
    String? id,
    bool? useCost,
    bool? usePrice2,
    bool? allowEditPrice,
    int? createdAt,
    int? updatedAt,
  }) {
    return AppSettingModel(
      id: id ?? this.id,
      useCost: useCost ?? this.useCost,
      usePrice2: usePrice2 ?? this.usePrice2,
      allowEditPrice: allowEditPrice ?? this.allowEditPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UpdateAppSetting {
  final bool? useCost;
  final bool? usePrice2;
  final bool? allowEditPrice;

  const UpdateAppSetting({
    this.useCost,
    this.usePrice2,
    this.allowEditPrice,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (useCost != null) {
      data['useCost'] = useCost;
    }
    if (usePrice2 != null) {
      data['usePrice2'] = usePrice2;
    }
    if (allowEditPrice != null) {
      data['allowEditPrice'] = allowEditPrice;
    }
    return data;
  }
}
