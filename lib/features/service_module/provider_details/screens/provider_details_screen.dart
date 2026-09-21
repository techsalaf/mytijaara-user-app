import 'package:flutter/material.dart';
import 'package:sixam_mart/features/service_module/common/models/service_provider_model.dart';

class ProviderDetailsScreen extends StatefulWidget {
  final int providerId;
  final String? slug;
  final ServiceProvider? initialProvider;
  final bool fromGlobalCart;
  const ProviderDetailsScreen({super.key,
    required this.providerId, this.slug, this.initialProvider, this.fromGlobalCart = false,
  });

  @override
  State<ProviderDetailsScreen> createState() => _ProviderDetailsScreenState();
}

class _ProviderDetailsScreenState extends State<ProviderDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

class SliverDelegate extends SliverPersistentHeaderDelegate {
  const SliverDelegate();

  @override
  double get maxExtent => 0;

  @override
  double get minExtent => 0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => const SizedBox();

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;
}
