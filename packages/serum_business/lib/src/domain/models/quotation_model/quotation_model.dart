import 'package:serum_business/src/domain/models/shared/quoted_exam.dart';

class BaseQuotation {
  final String clientName;
  final String? patientId;
  final List<QuotedExam> exams;
  final int totalAmount;
  final String status;
  final String? convertedToOrderId;

  BaseQuotation({
    required this.clientName,
    this.patientId,
    this.exams = const [],
    required this.totalAmount,
    this.status = "pending",
    this.convertedToOrderId,
  });
}

class CreateQuotation extends BaseQuotation {
  CreateQuotation({
    required super.clientName,
    super.patientId,
    super.exams = const [],
    required super.totalAmount,
    super.status = "pending",
    super.convertedToOrderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientName': clientName,
      'patientId': patientId,
      'exams': exams.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'convertedToOrderId': convertedToOrderId,
    };
  }
}

class UpdateQuotation {
  final String? clientName;
  final String? patientId;
  final List<QuotedExam>? exams;
  final int? totalAmount;
  final String? status;
  final String? convertedToOrderId;

  UpdateQuotation({
    this.clientName,
    this.patientId,
    this.exams,
    this.totalAmount,
    this.status,
    this.convertedToOrderId,
  });

  Map<String, dynamic> toJson() {
    return {
      if (clientName != null) 'clientName': clientName,
      if (patientId != null) 'patientId': patientId,
      if (exams != null)
        'exams': exams!.map((e) => e.toJson()).toList(),
      if (totalAmount != null) 'totalAmount': totalAmount,
      if (status != null) 'status': status,
      if (convertedToOrderId != null) 'convertedToOrderId': convertedToOrderId,
    };
  }
}

class QuotationInDb extends BaseQuotation {
  final String id;
  final int createdAt;
  final int? updatedAt;
  final bool isDeleted;

  QuotationInDb({
    required this.id,
    required super.clientName,
    super.patientId,
    super.exams = const [],
    required super.totalAmount,
    super.status = "pending",
    super.convertedToOrderId,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory QuotationInDb.fromJson(Map<String, dynamic> json) {
    return QuotationInDb(
      id: json['id'] as String,
      clientName: json['clientName'] as String,
      patientId: json['patientId'] as String?,
      exams: (json['exams'] as List<dynamic>?)
              ?.map((e) => QuotedExam.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: json['totalAmount'] as int,
      status: json['status'] as String? ?? "pending",
      convertedToOrderId: json['convertedToOrderId'] as String?,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
