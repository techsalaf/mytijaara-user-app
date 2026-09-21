import 'package:flutter/material.dart';
import 'package:sixam_mart/features/item/domain/models/basic_campaign_model.dart';
import 'package:sixam_mart/features/service_module/service_home/domain/models/service_banner_model.dart';

class ServiceBannerWidget extends StatefulWidget {
  final List<ServiceBannerModel> banners;
  final List<BasicCampaignModel> campaigns;
  const ServiceBannerWidget({super.key, required this.banners, this.campaigns = const []});

  @override
  State<ServiceBannerWidget> createState() => _ServiceBannerWidgetState();
}

class _ServiceBannerWidgetState extends State<ServiceBannerWidget> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
