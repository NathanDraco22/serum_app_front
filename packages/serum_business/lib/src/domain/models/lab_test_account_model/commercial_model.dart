class LabTestCommercial {
  final int salePrice;
  final int salePrice2;
  final int costPrice;
  final String currency;

  LabTestCommercial({
    this.salePrice = 0,
    this.salePrice2 = 0,
    this.costPrice = 0,
    this.currency = 'USD',
  });

  factory LabTestCommercial.fromJson(Map<String, dynamic> json) {
    return LabTestCommercial(
      salePrice: (json['salePrice'] as num?)?.toInt() ?? 0,
      salePrice2: (json['salePrice2'] as num?)?.toInt() ?? 0,
      costPrice: (json['costPrice'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'salePrice': salePrice,
      'salePrice2': salePrice2,
      'costPrice': costPrice,
      'currency': currency,
    };
  }
}
