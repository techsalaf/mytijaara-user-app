import 'package:flutter/material.dart';

class BookingDetailsScreen extends StatefulWidget {
  final int? bookingId;
  final bool fromNotification;
  final bool isSubBooking;
  final String? trackContactNumber;

  const BookingDetailsScreen({super.key,
    required this.bookingId, this.fromNotification = false, this.isSubBooking = false, this.trackContactNumber,
  });

  @override
  BookingDetailsScreenState createState() => BookingDetailsScreenState();
}

class BookingDetailsScreenState extends State<BookingDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
