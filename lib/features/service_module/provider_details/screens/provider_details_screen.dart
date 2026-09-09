import 'package:flutter/material.dart';
import 'package:sixam_mart/features/service_module/common/models/service_provider_model.dart';

class ProviderDetailsScreen extends StatefulWidget {
  final int providerId;
  final String? slug;
  final ServiceProvider? initialProvider;
  const ProviderDetailsScreen({super.key, required this.providerId, this.slug, this.initialProvider});

  static Future<void> loadData() async {}

  @override
  State<ProviderDetailsScreen> createState() => _ProviderDetailsScreenState();
}

class _ProviderDetailsScreenState extends State<ProviderDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
