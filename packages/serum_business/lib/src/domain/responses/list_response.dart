class ListResponse<T> {
  final List<T> data;
  final int count;

  ListResponse({required this.data, required this.count});

  factory ListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final items = (json['data'] as List<dynamic>?)
            ?.map((item) => fromJsonT(item as Map<String, dynamic>))
            .toList() ??
        [];

    return ListResponse(
      data: items,
      count: json['count'] as int? ?? items.length,
    );
  }
}
