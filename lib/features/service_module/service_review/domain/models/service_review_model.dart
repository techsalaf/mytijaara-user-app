import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// Service Module — reviews list envelope for `GET /service/reviews/{service_id}`.
/// Mirrors the core `ItemReviewModel` shape, Service-prefixed so it doesn't clash
/// with the item-review `RatingSummary` / `RatingBreakdown` / `ReviewCustomer`.
/// The same `reviews[]` (as `ServiceReview`) is also embedded, last-3, in the
/// `service/details/{id}` response — see the `Service` model.
class ServiceReviewModel {
  int? totalSize;
  String? limit;
  String? offset;
  ServiceRatingSummary? ratingSummary;
  List<ServiceReview>? reviews;

  ServiceReviewModel({this.totalSize, this.limit, this.offset, this.ratingSummary, this.reviews});

  factory ServiceReviewModel.fromJson(Map<String, dynamic> json) => ServiceReviewModel(
    totalSize: int.tryParse(json['total_size']?.toString() ?? ''),
    limit: json['limit']?.toString(),
    offset: json['offset']?.toString(),
    ratingSummary: json['rating_summary'] != null
        ? ServiceRatingSummary.fromJson(json['rating_summary'] as Map<String, dynamic>)
        : null,
    reviews: (json['reviews'] as List<dynamic>?)
        ?.map((e) => ServiceReview.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'total_size': totalSize,
    'limit': limit,
    'offset': offset,
    'rating_summary': ratingSummary?.toJson(),
    'reviews': reviews?.map((e) => e.toJson()).toList(),
  };
}

class ServiceRatingSummary {
  double? avgRating;
  int? totalReviews;
  List<ServiceRatingBreakdown>? breakdown;

  ServiceRatingSummary({this.avgRating, this.totalReviews, this.breakdown});

  /// Builds the summary client-side. The provider (store) reviews endpoint
  /// returns a bare review array with no `rating_summary`, so the avg + 5→1
  /// breakdown are derived from the list itself.
  factory ServiceRatingSummary.fromReviews(List<ServiceReview> reviews) {
    final List<int> ratings = reviews.map((e) => e.rating ?? 0).where((r) => r > 0).toList();
    return ServiceRatingSummary(
      avgRating: ratings.isEmpty ? 0 : ratings.reduce((a, b) => a + b) / ratings.length,
      totalReviews: reviews.length,
      breakdown: List.generate(5, (i) {
        final int star = 5 - i;
        return ServiceRatingBreakdown(star: star, count: ratings.where((r) => r == star).length);
      }),
    );
  }

  factory ServiceRatingSummary.fromJson(Map<String, dynamic> json) => ServiceRatingSummary(
    avgRating: double.tryParse(json['avg_rating']?.toString() ?? ''),
    totalReviews: int.tryParse(json['total_reviews']?.toString() ?? ''),
    breakdown: (json['breakdown'] as List<dynamic>?)
        ?.map((e) => ServiceRatingBreakdown.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'avg_rating': avgRating,
    'total_reviews': totalReviews,
    'breakdown': breakdown?.map((e) => e.toJson()).toList(),
  };
}

class ServiceRatingBreakdown {
  String? label;
  int? star;
  int? count;

  ServiceRatingBreakdown({this.label, this.star, this.count});

  factory ServiceRatingBreakdown.fromJson(Map<String, dynamic> json) => ServiceRatingBreakdown(
    label: json['label']?.toString(),
    star: int.tryParse(json['star']?.toString() ?? ''),
    count: int.tryParse(json['count']?.toString() ?? ''),
  );

  Map<String, dynamic> toJson() => {'label': label, 'star': star, 'count': count};
}

class ServiceReview {
  int? id;
  String? reviewId;
  int? serviceId;
  int? bookingId;
  int? rating;
  String? comment;
  List<String>? attachment;
  String? reply;
  String? repliedAt;
  String? serviceName;
  String? serviceImageUrl; // only set by [ServiceReview.fromStoreJson]
  ServiceReviewCustomer? customer;
  String? reviewDate; // pre-formatted by the API, e.g. "12 July 2026"
  String? reviewTime; // pre-formatted by the API, e.g. "10:31 AM"
  String? createdAt;
  String? updatedAt;

  ServiceReview({this.id, this.reviewId, this.serviceId, this.bookingId, this.rating,
    this.comment, this.attachment, this.reply, this.repliedAt, this.serviceName, this.serviceImageUrl,
    this.customer, this.reviewDate, this.reviewTime, this.createdAt, this.updatedAt,
  });

  /// Maps the provider-scoped `GET /stores/reviews?store_id={id}` shape, which
  /// differs from `service/reviews/{id}`: a flat `customer_name` instead of a
  /// customer object, `item_name`/`item_image_full_url` for the reviewed
  /// service, raw `created_at` instead of a pre-formatted date, and attachments
  /// as `{img, storage}` pairs with no full URL (built here off the same
  /// `service/review` storage path the service endpoint returns).
  factory ServiceReview.fromStoreJson(Map<String, dynamic> json) => ServiceReview(
    id: int.tryParse(json['id']?.toString() ?? ''),
    reviewId: json['review_id']?.toString(),
    serviceId: int.tryParse(json['service_id']?.toString() ?? ''),
    bookingId: int.tryParse(json['booking_id']?.toString() ?? ''),
    rating: int.tryParse(json['rating']?.toString() ?? ''),
    comment: json['comment']?.toString(),
    attachment: (json['attachment'] as List<dynamic>?)
        ?.map((e) => e is Map ? e['img']?.toString() ?? '' : e.toString())
        .where((img) => img.isNotEmpty)
        .map((img) => '${AppConstants.baseUrl}/storage/app/public/service/review/$img')
        .toList(),
    reply: json['reply']?.toString(),
    repliedAt: json['replied_at']?.toString(),
    serviceName: json['item_name']?.toString(),
    serviceImageUrl: json['item_image_full_url']?.toString(),
    customer: ServiceReviewCustomer(fName: json['customer_name']?.toString().trim()),
    // `service/reviews/{id}` hands back a local-converted `review_date`; this
    // endpoint only has the raw UTC timestamp, so convert the same way.
    reviewDate: json['created_at'] != null ? DateConverter.isoUtcStringToLocalDateOnly(json['created_at'].toString()) : null,
    createdAt: json['created_at']?.toString(),
    updatedAt: json['updated_at']?.toString(),
  );

  factory ServiceReview.fromJson(Map<String, dynamic> json) => ServiceReview(
    id: int.tryParse(json['id']?.toString() ?? ''),
    reviewId: json['review_id']?.toString(),
    serviceId: int.tryParse(json['service_id']?.toString() ?? ''),
    bookingId: int.tryParse(json['booking_id']?.toString() ?? ''),
    rating: int.tryParse(json['rating']?.toString() ?? ''),
    comment: json['comment']?.toString(),
    attachment: (json['attachment'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    reply: json['reply']?.toString(),
    repliedAt: json['replied_at']?.toString(),
    serviceName: json['service_name']?.toString(),
    serviceImageUrl: json['service_image_full_url']?.toString(),
    customer: json['customer'] != null
        ? ServiceReviewCustomer.fromJson(json['customer'] as Map<String, dynamic>)
        : null,
    reviewDate: json['review_date']?.toString(),
    reviewTime: json['review_time']?.toString(),
    createdAt: json['created_at']?.toString(),
    updatedAt: json['updated_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'review_id': reviewId,
    'service_id': serviceId,
    'booking_id': bookingId,
    'rating': rating,
    'comment': comment,
    'attachment': attachment,
    'reply': reply,
    'replied_at': repliedAt,
    'service_name': serviceName,
    'service_image_full_url': serviceImageUrl,
    'customer': customer?.toJson(),
    'review_date': reviewDate,
    'review_time': reviewTime,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class ServiceReviewCustomer {
  int? id;
  String? fName;
  String? lName;
  String? imageFullUrl;

  ServiceReviewCustomer({this.id, this.fName, this.lName, this.imageFullUrl});

  factory ServiceReviewCustomer.fromJson(Map<String, dynamic> json) => ServiceReviewCustomer(
    id: int.tryParse(json['id']?.toString() ?? ''),
    fName: json['f_name']?.toString(),
    lName: json['l_name']?.toString(),
    imageFullUrl: json['image_full_url']?.toString(),
  );

  String get fullName => '${fName ?? ''} ${lName ?? ''}'.trim();

  Map<String, dynamic> toJson() => {
    'id': id, 'f_name': fName, 'l_name': lName, 'image_full_url': imageFullUrl,
  };
}
