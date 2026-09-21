import 'package:image_picker/image_picker.dart';

/// Submit payload for a single service review (one `service_id` per submission).
/// Mirrors the base `ReviewBodyModel`, but carries picked image files for the
/// `attachment[]` multipart upload rather than pre-uploaded string paths.
class ServiceReviewBodyModel {
  final int serviceId;
  final int bookingId;
  final int rating;
  final String? comment;
  final List<XFile> attachments;

  ServiceReviewBodyModel({required this.serviceId,
    required this.bookingId, required this.rating, this.comment, this.attachments = const [],
  });

  Map<String, String> toFields() => {
    'service_id': serviceId.toString(),
    'booking_id': bookingId.toString(),
    'rating': rating.toString(),
    'comment': comment ?? '',
  };
}
