part of '../search_screen.dart';

class _BrandShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Color shimmerColor = Theme.of(context).disabledColor.withValues(alpha: 0.12);
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeDefault),
      itemBuilder: (_, int index) => Padding(
        padding: EdgeInsets.only(
          left: index == 0 ? Dimensions.paddingSizeDefault : 0,
          right: index == 5 ? Dimensions.paddingSizeDefault : 0,
        ),
        child: Container(
          height: 72, width: 72,
          decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
        ),
      ),
    );
  }
}

// Result-list shimmer shown while a global keyword submit resolves its module
// from suggestions before the result view opens. Mirrors the result section's
// own loading rows so the transition is seamless.
class _SearchResultLoadingShimmer extends StatelessWidget {
  const _SearchResultLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    final Color base = Theme.of(context).disabledColor.withValues(alpha: 0.12);

    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
    );

    return ListView.separated(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: Dimensions.paddingSizeDefault),
      itemBuilder: (BuildContext context, int index) => Shimmer(
        duration: const Duration(seconds: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Container(
            height: 64, width: 64,
            decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            bar(double.infinity, 14),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            bar(180, 12),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            bar(110, 12),
          ])),
        ]),
      ),
    );
  }
}

class _TrendingSearchShimmer extends StatelessWidget {
  const _TrendingSearchShimmer();

  @override
  Widget build(BuildContext context) {
    final Color shimmerColor = Theme.of(context).disabledColor.withValues(alpha: 0.12);
    const List<double> pillWidths = [80, 110, 70, 95, 120, 75, 100, 85];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Shimmer(
          duration: const Duration(seconds: 2),
          child: Container(
            height: 16, width: 140,
            decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Wrap(
          spacing: Dimensions.paddingSizeSmall,
          runSpacing: Dimensions.paddingSizeSmall,
          children: pillWidths.map((w) => Shimmer(
            duration: const Duration(seconds: 2),
            child: Container(
              height: 30, width: w,
              decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(50)),
            ),
          )).toList(),
        ),
      ]),
    );
  }
}