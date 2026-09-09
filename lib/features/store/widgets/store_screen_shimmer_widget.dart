import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/features/store/widgets/store_details_screen_shimmer_widget.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// Loading placeholder for [StoreScreen] that mirrors the redesigned mobile
/// layout: cover header → store overview card (logo + stats) → pro banner →
/// category tabs → "Most Popular" horizontal rail → compact item rows.
///
/// The desktop layout still uses the legacy web design, so it keeps delegating
/// to [StoreDetailsScreenShimmerWidget].
class StoreScreenShimmerWidget extends StatelessWidget {
  const StoreScreenShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return const StoreDetailsScreenShimmerWidget();
    }

    final double topPadding = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Shimmer(
        duration: const Duration(seconds: 2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          /// Cover header with circular action buttons.
          SizedBox(height: 246,
            child: Stack(children: [
              const Positioned.fill(child: _Box(height: 246, radius: 0)),
              Positioned(top: topPadding + 12, left: Dimensions.paddingSizeDefault, child: const _Circle(size: 40)),
              Positioned(top: topPadding + 12, right: Dimensions.paddingSizeDefault,
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  _Circle(size: 40), SizedBox(width: Dimensions.paddingSizeSmall),
                  _Circle(size: 40), SizedBox(width: Dimensions.paddingSizeSmall),
                  _Circle(size: 40),
                ]),
              ),
              const Positioned(left: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeDefault,
                child: _Box(height: 26, width: 86, radius: Dimensions.radiusExtraLarge),
              ),
            ]),
          ),

          /// Store overview: logo + name/address, then the stats card.
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeDefault, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                _Box(height: 54, width: 54, radius: 14),
                SizedBox(width: Dimensions.paddingSizeDefault),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _Bar(width: 160, height: 16),
                    SizedBox(height: 10),
                    _Bar(width: 220, height: 12),
                  ]),
                ),
              ]),
              const SizedBox(height: 20),
              Container(height: 78,
                decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
                child: const Row(children: [
                  Expanded(child: _StatPlaceholder()),
                  _StatDivider(),
                  Expanded(child: _StatPlaceholder()),
                  _StatDivider(),
                  Expanded(child: _StatPlaceholder()),
                ]),
              ),
              const SizedBox(height: 20),
              SizedBox(height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: 2,
                  separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeDefault),
                  itemBuilder: (_, _) => const _Box(height: 92, width: 198, radius: 12),
                ),
              ),
            ]),
          ),

          /// Pro plan banner.
          const Padding(
            padding: EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, 0),
            child: _Box(height: 64, radius: Dimensions.radiusDefault),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          /// Category tabs row.
          Container(height: 52,
            color: Theme.of(context).cardColor,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(width: 24),
              itemBuilder: (_, _) => const Center(child: _Bar(width: 70, height: 12)),
            ),
          ),

          /// "Most Popular" horizontal rail.
          Container(width: double.infinity, color: Theme.of(context).cardColor,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 26),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: _Bar(width: 140, height: 18),
              ),
              const SizedBox(height: 14),
              SizedBox(height: 310,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  itemCount: 4,
                  separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeSmall),
                  itemBuilder: (_, _) => const _PopularCardPlaceholder(),
                ),
              ),
              const SizedBox(height: 26),
            ]),
          ),
          const SizedBox(height: 6),

          /// Category section: title + compact item rows.
          Container(color: Theme.of(context).cardColor,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 28, Dimensions.paddingSizeDefault, 6),
                child: _Bar(width: 160, height: 18),
              ),
              ...List.generate(4, (_) => const _CompactItemPlaceholder()),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _PopularCardPlaceholder extends StatelessWidget {
  const _PopularCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 158,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Box(height: 158, width: 158, radius: Dimensions.radiusExtraLarge),
        SizedBox(height: Dimensions.paddingSizeDefault),
        _Bar(width: 140, height: 12),
        SizedBox(height: 8),
        _Bar(width: 90, height: 12),
        SizedBox(height: 8),
        _Bar(width: 60, height: 12),
      ]),
    );
  }
}

class _CompactItemPlaceholder extends StatelessWidget {
  const _CompactItemPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Bar(width: double.infinity, height: 14),
            SizedBox(height: 12),
            _Bar(width: 120, height: 12),
            SizedBox(height: 12),
            _Bar(width: 80, height: 12),
            SizedBox(height: 14),
            _Bar(width: 64, height: 20),
          ]),
        ),
        SizedBox(width: Dimensions.paddingSizeDefault),
        _Box(height: 132, width: 132, radius: 12),
      ]),
    );
  }
}

class _StatPlaceholder extends StatelessWidget {
  const _StatPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      _Bar(width: 46, height: 16),
      SizedBox(height: 8),
      _Bar(width: 60, height: 10),
    ]);
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 42, color: _shimmerColor(context));
  }
}

/// Rounded grey block placeholder.
class _Box extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;

  const _Box({required this.height, this.width, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(height: height, width: width,
      decoration: BoxDecoration(color: _shimmerColor(context), borderRadius: BorderRadius.circular(radius)),
    );
  }
}

/// Pill-shaped placeholder for a single line of text.
class _Bar extends StatelessWidget {
  final double width;
  final double height;

  const _Bar({required this.width, this.height = 12});

  @override
  Widget build(BuildContext context) {
    return Container(height: height, width: width,
      decoration: BoxDecoration(color: _shimmerColor(context), borderRadius: BorderRadius.circular(99)),
    );
  }
}

/// Circular placeholder used for the cover header action buttons.
class _Circle extends StatelessWidget {
  final double size;

  const _Circle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(height: size, width: size,
      decoration: BoxDecoration(color: _shimmerColor(context), shape: BoxShape.circle),
    );
  }
}

Color _shimmerColor(BuildContext context) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFE9E9E9);
}
