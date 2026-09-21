import 'package:flutter/material.dart';
import 'package:sixam_mart/features/service_module/booking_details/domain/models/booking_line_item_model.dart';

class ServiceRateReviewScreen extends StatefulWidget {
  final List<BookingLineItemModel> lineItems;
  final int bookingId;

  const ServiceRateReviewScreen({super.key, required this.lineItems, required this.bookingId});

  @override
  State<ServiceRateReviewScreen> createState() => _ServiceRateReviewScreenState();
}

class _ServiceRateReviewScreenState extends State<ServiceRateReviewScreen> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
