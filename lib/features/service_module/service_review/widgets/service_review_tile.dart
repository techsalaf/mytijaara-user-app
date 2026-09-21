import 'package:flutter/material.dart';
import 'package:sixam_mart/features/service_module/service_review/domain/models/service_review_model.dart';

class ServiceReviewTile extends StatelessWidget {
  final ServiceReview review;
  final bool showService;

  const ServiceReviewTile({super.key, required this.review, this.showService = false});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
