import 'package:serum_business/src/domain/models/shared/order_test_result.dart';
import 'package:serum_business/src/domain/models/shared/user_info.dart';

class BaseOrder {
  final String patientId;
  final String? quotationId;
  final String examId;
  final String examName;
  final int salePriceApplied;
  final String status;
  final List<OrderTestResult> results;

  BaseOrder({
    required this.patientId,
    this.quotationId,
    required this.examId,
    required this.examName,
    required this.salePriceApplied,
    this.status = "pending",
    this.results = const [],
  });
}

class CreateOrder extends BaseOrder {
  CreateOrder({
    required super.patientId,
    super.quotationId,
    required super.examId,
    required super.examName,
    required super.salePriceApplied,
    super.status = "pending",
    super.results = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'quotationId': quotationId,
      'examId': examId,
      'examName': examName,
      'salePriceApplied': salePriceApplied,
      'status': status,
      'results': results.map((e) => e.toJson()).toList(),
    };
  }
}

class UpdateOrder {
  final String? patientId;
  final String? quotationId;
  final String? examId;
  final String? examName;
  final int? salePriceApplied;
  final String? status;
  final List<OrderTestResult>? results;

  UpdateOrder({
    this.patientId,
    this.quotationId,
    this.examId,
    this.examName,
    this.salePriceApplied,
    this.status,
    this.results,
  });

  Map<String, dynamic> toJson() {
    return {
      if (patientId != null) 'patientId': patientId,
      if (quotationId != null) 'quotationId': quotationId,
      if (examId != null) 'examId': examId,
      if (examName != null) 'examName': examName,
      if (salePriceApplied != null) 'salePriceApplied': salePriceApplied,
      if (status != null) 'status': status,
      if (results != null)
        'results': results!.map((e) => e.toJson()).toList(),
    };
  }
}

class OrderPayRequest {
  final int amount;
  final String registerId;
  final String paymentMethod;
  final UserInfo performedBy;

  OrderPayRequest({
    required this.amount,
    required this.registerId,
    required this.paymentMethod,
    required this.performedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'registerId': registerId,
      'paymentMethod': paymentMethod,
      'performedBy': performedBy.toJson(),
    };
  }
}

class OrderInDb extends BaseOrder {
  final String id;
  final int createdAt;
  final int? updatedAt;
  final bool isDeleted;

  OrderInDb({
    required this.id,
    required super.patientId,
    super.quotationId,
    required super.examId,
    required super.examName,
    required super.salePriceApplied,
    super.status = "pending",
    super.results = const [],
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory OrderInDb.fromJson(Map<String, dynamic> json) {
    return OrderInDb(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      quotationId: json['quotationId'] as String?,
      examId: json['examId'] as String,
      examName: json['examName'] as String,
      salePriceApplied: json['salePriceApplied'] as int,
      status: json['status'] as String? ?? "pending",
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => OrderTestResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
