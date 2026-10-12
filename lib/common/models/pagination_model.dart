/// Paging metadata, read from either API format.
///
/// The core API moved from flat `total_size` / `limit` / `offset` keys to a
/// nested `pagination` object:
///
/// ```json
/// {"data": [...], "pagination": {"current_page":1,"last_page":4,"per_page":25,"total":87}}
/// ```
///
/// The service module has **not** migrated and still returns the flat keys, so
/// both shapes are live at the same time and this reads whichever it is given.
///
/// The property names deliberately keep the app's existing vocabulary
/// ([totalSize], [limit], [offset]) rather than the new JSON names. The app
/// already treats `offset` as a 1-based page number — see
/// `my_order_screen.dart`, which does `currentPage: model?.offset` — so
/// `current_page` maps onto it directly and the ~74 files that read `totalSize`
/// need no change at all.
class PaginationModel {
  /// Total number of records across all pages (`total_size` / `pagination.total`).
  final int? totalSize;

  /// Records per page (`limit` / `pagination.per_page`).
  final int? limit;

  /// Current 1-based page (`offset` / `pagination.current_page`).
  final int? offset;

  /// Last available page. Only the new format reports this; null on the legacy one.
  final int? lastPage;

  const PaginationModel({this.totalSize, this.limit, this.offset, this.lastPage});

  /// Reads paging metadata from a response body of either format. Returns a
  /// model with all-null fields when the body carries no paging information.
  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    final dynamic pagination = json['pagination'];
    if (pagination is Map) {
      return PaginationModel(
        totalSize: _toInt(pagination['total']),
        limit: _toInt(pagination['per_page']),
        offset: _toInt(pagination['current_page']),
        lastPage: _toInt(pagination['last_page']),
      );
    }
    return PaginationModel(
      totalSize: _toInt(json['total_size']),
      limit: _toInt(json['limit']),
      offset: _toInt(json['offset']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'total_size': totalSize,
    'limit': limit,
    'offset': offset,
  };

  /// Both formats have been seen sending these as strings as well as numbers.
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
