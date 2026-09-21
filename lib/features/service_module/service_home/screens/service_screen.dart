import 'package:flutter/material.dart';
import 'package:sixam_mart/features/dashboard/widgets/quick_filters_widget.dart';

class ServiceScreen extends StatefulWidget {
  final Key searchHeaderKey;
  final Key? exploreRestaurantKey;
  final ScrollController? scrollController;
  final bool isSearchPinned;

  const ServiceScreen({super.key,
    required this.searchHeaderKey, this.exploreRestaurantKey, this.scrollController, this.isSearchPinned = false,
  });

  static List<FoodModuleQuickFilterItem> get serviceQuickFilterItems => <FoodModuleQuickFilterItem>[];

  static void handleQuickFilterTap(FoodModuleQuickFilterItem item) {}

  static Future<void> loadData() async {}

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  // Rendered directly inside the dashboard's CustomScrollView (main_screen.dart),
  // so this must return a sliver — a plain box throws a RenderViewport type error.
  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(child: SizedBox());
  }
}
