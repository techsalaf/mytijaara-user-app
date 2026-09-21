import 'package:flutter/material.dart';
import 'package:sixam_mart/features/service_module/common/models/service_provider_model.dart';

class ServiceVerifiedProviderCard extends StatelessWidget {
  final ServiceProvider provider;
  final double? width;
  final double? imageHeight;

  const ServiceVerifiedProviderCard({super.key, required this.provider, this.width, this.imageHeight});

  static ({double cardWidth, double imageHeight, double cardHeight}) carouselMetrics(BuildContext context) =>
      (cardWidth: 0, imageHeight: 0, cardHeight: 0);

  @override
  Widget build(BuildContext context) => const SizedBox();
}
