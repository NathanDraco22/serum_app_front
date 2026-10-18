class Servin {
  final String name;
  final String nickname;
  final String url;
  final bool isActive;
  final bool isMultiBranch;
  final bool isUsingExpirationDate;

  Servin({
    required this.name,
    required this.nickname,
    required this.url,
    required this.isActive,
    this.isMultiBranch = false,
    this.isUsingExpirationDate = true,
  });

  factory Servin.fromJson(Map<String, dynamic> json) {
    return Servin(
      name: json['name'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      url: json['url'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      isMultiBranch: json['isMultiBranch'] as bool? ?? false,
      isUsingExpirationDate: json['isUsingExpirationDate'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nickname': nickname,
      'url': url,
      'isActive': isActive,
      'isMultiBranch': isMultiBranch,
      'isUsingExpirationDate': isUsingExpirationDate,
    };
  }

  Servin copyWith({
    String? name,
    String? nickname,
    String? url,
    bool? isActive,
    bool? isMultiBranch,
    bool? isUsingExpirationDate,
  }) {
    return Servin(
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      url: url ?? this.url,
      isActive: isActive ?? this.isActive,
      isMultiBranch: isMultiBranch ?? this.isMultiBranch,
      isUsingExpirationDate:
          isUsingExpirationDate ?? this.isUsingExpirationDate,
    );
  }
}
