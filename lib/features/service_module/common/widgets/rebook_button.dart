import 'package:flutter/material.dart';
import 'package:sixam_mart/features/service_module/booking_details/domain/models/booking_model.dart';

class RebookButton extends StatelessWidget {
  final BookingModel booking;
  final double height;
  final double width;

  const RebookButton({super.key, required this.booking, this.height = 32, this.width = 90});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
