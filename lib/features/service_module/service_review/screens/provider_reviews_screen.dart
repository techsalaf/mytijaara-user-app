import 'package:flutter/material.dart';

class ProviderReviewsScreen extends StatefulWidget {
  final int providerId;
  final String? providerName;
  final double? avgRating;
  final int? ratingCount;

  const ProviderReviewsScreen({super.key,
    required this.providerId, this.providerName, this.avgRating, this.ratingCount,
  });

  @override
  State<ProviderReviewsScreen> createState() => _ProviderReviewsScreenState();
}

class _ProviderReviewsScreenState extends State<ProviderReviewsScreen> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
