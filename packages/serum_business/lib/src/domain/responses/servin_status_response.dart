class ServinStatusResponse {
  final String nickname;
  final bool isActive;
  final bool isMultiBranch;
  final bool isUsingExpirationDate;

  ServinStatusResponse({
    required this.nickname,
    required this.isActive,
    required this.isMultiBranch,
    required this.isUsingExpirationDate,
  });

  factory ServinStatusResponse.fromJson(Map<String, dynamic> json) {
    return ServinStatusResponse(
      nickname: json['nickname'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      isMultiBranch: json['isMultiBranch'] as bool? ?? false,
      isUsingExpirationDate: json['isUsingExpirationDate'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'isActive': isActive,
      'isMultiBranch': isMultiBranch,
      'isUsingExpirationDate': isUsingExpirationDate,
    };
  }
}
