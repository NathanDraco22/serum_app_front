class ReferenceValue {
  final String patientType;
  final String gender;
  final int minAgeDays;
  final int maxAgeDays;
  final double minValue;
  final double maxValue;

  ReferenceValue({
    required this.patientType,
    required this.gender,
    required this.minAgeDays,
    required this.maxAgeDays,
    required this.minValue,
    required this.maxValue,
  });

  factory ReferenceValue.fromJson(Map<String, dynamic> json) {
    return ReferenceValue(
      patientType: json['patientType'] as String,
      gender: json['gender'] as String,
      minAgeDays: json['minAgeDays'] as int,
      maxAgeDays: json['maxAgeDays'] as int,
      minValue: (json['minValue'] as num).toDouble(),
      maxValue: (json['maxValue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientType': patientType,
      'gender': gender,
      'minAgeDays': minAgeDays,
      'maxAgeDays': maxAgeDays,
      'minValue': minValue,
      'maxValue': maxValue,
    };
  }
}
