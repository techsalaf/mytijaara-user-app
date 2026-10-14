import 'package:flutter/material.dart';

class RentalModuleScreen extends StatefulWidget {
  /// Height of the search bar this screen pins itself, inside the scroll view.
  ///
  /// Unlike the store modules, rental does not hand [searchHeaderKey] to a
  /// [SearchAndQuickFilterWidget], so `MainScreen`'s shared pinned-search overlay
  /// never activates here and has no height to measure. `MainScreen` reads this
  /// constant instead, to keep the back-to-top button clear of the bar.
  static const double pinnedHeaderHeight = 70.0;

  final Key searchHeaderKey;
  final Key exploreRestaurantKey;
  const RentalModuleScreen({super.key, required this.searchHeaderKey, required this.exploreRestaurantKey});

  @override
  State<RentalModuleScreen> createState() => _RentalModuleScreenState();
}

class _RentalModuleScreenState extends State<RentalModuleScreen> {

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
