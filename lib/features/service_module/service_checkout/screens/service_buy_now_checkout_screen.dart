import 'package:flutter/material.dart';
import 'package:sixam_mart/features/service_module/service_checkout/domain/models/service_buy_now_variant.dart';

class ServiceBuyNowCheckoutScreen extends StatefulWidget {
  final int providerId;
  final int campaignId;
  final bool isCampaign;
  final double unitPrice;
  final int quantity;
  final String? variation;
  final List<ServiceBuyNowVariant>? variants;

  const ServiceBuyNowCheckoutScreen({super.key,
    required this.providerId, required this.campaignId, this.isCampaign = true, required this.unitPrice, this.quantity = 1,
    this.variation, this.variants,
  });

  @override
  State<ServiceBuyNowCheckoutScreen> createState() => _ServiceBuyNowCheckoutScreenState();
}

class _ServiceBuyNowCheckoutScreenState extends State<ServiceBuyNowCheckoutScreen> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
