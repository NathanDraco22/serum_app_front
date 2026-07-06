class QuotedExam {
  final String examId;
  final String examName;
  final int quotedPrice;

  QuotedExam({
    required this.examId,
    required this.examName,
    required this.quotedPrice,
  });

  factory QuotedExam.fromJson(Map<String, dynamic> json) {
    return QuotedExam(
      examId: json['examId'] as String,
      examName: json['examName'] as String,
      quotedPrice: json['quotedPrice'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'examId': examId,
      'examName': examName,
      'quotedPrice': quotedPrice,
    };
  }
}
