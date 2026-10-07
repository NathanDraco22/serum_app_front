import 'package:serum_business/src/domain/models/shared/quoted_exam.dart';
import 'package:serum_business/src/domain/models/order_model/order_model.dart';

class BaseQuotation {
  final String clientName;
  final String branchId;
  final String? patientId;
  final PatientInfo? clientInfo;
  final String? doctorId;
  final DoctorInfo? doctorInfo;
  final List<QuotedExam> exams;
  final int totalAmount;
  final String status;
  final String? convertedToOrderId;

  BaseQuotation({
    required this.clientName,
    required this.branchId,
    this.patientId,
    this.clientInfo,
    this.doctorId,
    this.doctorInfo,
    this.exams = const [],
    required this.totalAmount,
    this.status = "pending",
    this.convertedToOrderId,
  });
}

class CreateQuotation extends BaseQuotation {
  CreateQuotation({
    required super.clientName,
    required super.branchId,
    super.patientId,
    super.clientInfo,
    super.doctorId,
    super.doctorInfo,
    super.exams = const [],
    required super.totalAmount,
    super.status = "pending",
    super.convertedToOrderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientName': clientName,
      if (patientId != null) 'patientId': patientId,
      if (clientInfo != null) 'clientInfo': clientInfo!.toJson(),
      if (doctorId != null) 'doctorId': doctorId,
      if (doctorInfo != null) 'doctorInfo': doctorInfo!.toJson(),
      'branchId': branchId,
      'items': exams.map((e) => e.toJson()).toList(),
      'exams': exams.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      if (convertedToOrderId != null) 'convertedToOrderId': convertedToOrderId,
    };
  }
}

class UpdateQuotation {
  final String? clientName;
  final String? patientId;
  final PatientInfo? clientInfo;
  final String? doctorId;
  final DoctorInfo? doctorInfo;
  final List<QuotedExam>? exams;
  final int? totalAmount;
  final String? status;
  final String? convertedToOrderId;
  final String? branchId;

  UpdateQuotation({
    this.clientName,
    this.patientId,
    this.clientInfo,
    this.doctorId,
    this.doctorInfo,
    this.exams,
    this.totalAmount,
    this.status,
    this.convertedToOrderId,
    this.branchId,
  });

  Map<String, dynamic> toJson() {
    return {
      if (clientName != null) 'clientName': clientName,
      if (patientId != null) 'patientId': patientId,
      if (clientInfo != null) 'clientInfo': clientInfo!.toJson(),
      if (doctorId != null) 'doctorId': doctorId,
      if (doctorInfo != null) 'doctorInfo': doctorInfo!.toJson(),
      if (exams != null) ...{
        'items': exams!.map((e) => e.toJson()).toList(),
        'exams': exams!.map((e) => e.toJson()).toList(),
      },
      if (totalAmount != null) 'totalAmount': totalAmount,
      if (status != null) 'status': status,
      if (convertedToOrderId != null) 'convertedToOrderId': convertedToOrderId,
      if (branchId != null) 'branchId': branchId,
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
    required super.branchId,
    super.patientId,
    super.clientInfo,
    super.doctorId,
    super.doctorInfo,
    super.exams = const [],
    required super.totalAmount,
    super.status = "pending",
    super.convertedToOrderId,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory QuotationInDb.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? json['exams'] as List<dynamic>?;
    return QuotationInDb(
      id: json['id'] as String,
      clientName: json['clientName'] as String? ?? 'Cliente General',
      branchId: json['branchId'] as String? ?? '',
      patientId: json['patientId'] as String?,
      clientInfo: json['clientInfo'] != null
          ? PatientInfo.fromJson(json['clientInfo'] as Map<String, dynamic>)
          : null,
      doctorId: json['doctorId'] as String?,
      doctorInfo: json['doctorInfo'] != null
          ? DoctorInfo.fromJson(json['doctorInfo'] as Map<String, dynamic>)
          : null,
      exams: rawItems
              ?.map((e) => QuotedExam.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? "pending",
      convertedToOrderId: json['convertedToOrderId'] as String?,
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updatedAt'] as num?)?.toInt(),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
