class QuotedExam {
  final String labTestId;
  final String name;
  final int quotedPrice;
  final bool isPack;
  final int priceLevel;

  String get examId => labTestId;
  String get examName => name;

  QuotedExam({
    required this.labTestId,
    required this.name,
    required this.quotedPrice,
    this.isPack = false,
    this.priceLevel = 1,
  });

  factory QuotedExam.fromJson(Map<String, dynamic> json) {
    return QuotedExam(
      labTestId: json['labTestId'] as String? ?? json['examId'] as String? ?? '',
      name: json['name'] as String? ?? json['examName'] as String? ?? '',
      quotedPrice: (json['quotedPrice'] as num?)?.toInt() ?? 0,
      isPack: json['isPack'] as bool? ?? false,
      priceLevel: (json['priceLevel'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'labTestId': labTestId,
      'name': name,
      'quotedPrice': quotedPrice,
      'isPack': isPack,
      'priceLevel': priceLevel,
    };
  }
}
