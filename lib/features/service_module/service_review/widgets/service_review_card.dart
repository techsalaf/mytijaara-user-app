import 'package:flutter/material.dart';
import 'package:sixam_mart/features/service_module/booking_details/domain/models/booking_line_item_model.dart';
import 'package:sixam_mart/features/service_module/service_review/controllers/service_review_controller.dart';

class ServiceReviewCard extends StatelessWidget {
  final ServiceReviewController controller;
  final BookingLineItemModel lineItem;
  final int index;
  final int bookingId;

  const ServiceReviewCard({super.key,
    required this.controller, required this.lineItem, required this.index, required this.bookingId,
  });

  @override
  Widget build(BuildContext context) => const SizedBox();
}
