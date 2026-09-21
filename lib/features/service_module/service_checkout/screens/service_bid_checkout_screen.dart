import 'package:flutter/material.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';

class ServiceBidCheckoutScreen extends StatefulWidget {
  final int providerId;
  final int bidId;
  final double offerPrice;
  final AddressModel? initialServiceAddress;
  final DateTime? initialScheduleAt;

  const ServiceBidCheckoutScreen({super.key, required this.providerId, required this.bidId, required this.offerPrice,
    this.initialServiceAddress, this.initialScheduleAt,
  });

  @override
  State<ServiceBidCheckoutScreen> createState() => _ServiceBidCheckoutScreenState();
}

class _ServiceBidCheckoutScreenState extends State<ServiceBidCheckoutScreen> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
