import 'package:flutter/material.dart';

class ServiceExploreCategoryTabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Key filterKey;

  ServiceExploreCategoryTabHeaderDelegate({required this.filterKey});

  @override
  double get minExtent => ServiceExploreCategoryTabHeaderWidget.height;

  @override
  double get maxExtent => ServiceExploreCategoryTabHeaderWidget.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => const SizedBox();

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class ServiceExploreCategoryTabHeaderWidget extends StatelessWidget {
  static const double height = 55;
  final Key? filterKey;
  final bool showBottomDivider;

  const ServiceExploreCategoryTabHeaderWidget({super.key, this.filterKey, this.showBottomDivider = false});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class ServiceExploreSection extends StatelessWidget {
  final ScrollController scrollController;
  final Key? exploreKey;

  const ServiceExploreSection({super.key, required this.scrollController, this.exploreKey});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
