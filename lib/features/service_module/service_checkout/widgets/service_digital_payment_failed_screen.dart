import 'package:flutter/material.dart';

class ServiceDigitalPaymentFailedScreen extends StatefulWidget {
  final String bookingId;
  final double totalPrice;
  final bool isPayAfterServiceActive;
  final bool isDigitalPaymentActive;
  final bool isOfflinePaymentActive;
  final bool? fromDialog;
  final bool? createAccount;

  const ServiceDigitalPaymentFailedScreen({super.key,
    required this.bookingId, required this.totalPrice, required this.isPayAfterServiceActive,
    required this.isDigitalPaymentActive, required this.isOfflinePaymentActive,
    this.fromDialog = false, this.createAccount = false,
  });

  @override
  State<ServiceDigitalPaymentFailedScreen> createState() => _ServiceDigitalPaymentFailedScreenState();
}

class _ServiceDigitalPaymentFailedScreenState extends State<ServiceDigitalPaymentFailedScreen> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
