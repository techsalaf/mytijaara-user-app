import 'package:flutter/material.dart';
import 'package:sixam_mart/features/service_module/service_review/domain/models/service_review_model.dart';

class ServiceRatingSummaryView extends StatelessWidget {
  final ServiceRatingSummary? summary;
  final double? avgRating;
  final int? totalReviews;

  const ServiceRatingSummaryView({super.key, this.summary, this.avgRating, this.totalReviews});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
