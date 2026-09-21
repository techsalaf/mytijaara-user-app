import 'package:flutter/material.dart';

class ServiceBookingSuccessScreen extends StatefulWidget {
  final String bookingId;
  final bool createAccount;
  const ServiceBookingSuccessScreen({super.key, required this.bookingId, this.createAccount = false});

  @override
  State<ServiceBookingSuccessScreen> createState() => _ServiceBookingSuccessScreenState();
}

class _ServiceBookingSuccessScreenState extends State<ServiceBookingSuccessScreen> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
