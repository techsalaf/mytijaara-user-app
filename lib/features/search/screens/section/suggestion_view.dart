part of '../search_screen.dart';

class _SuggestionsView extends StatelessWidget {
  final List<RecentSearchEntry> suggestions;
  final String searchQuery;
  final bool isLoading;
  final bool isGlobal;
  final void Function(RecentSearchEntry) onSuggestionTap;
  final VoidCallback onNearMeTap;
  final VoidCallback onSearchForTap;

  const _SuggestionsView({
    required this.suggestions, required this.searchQuery, required this.isLoading, required this.isGlobal,
    required this.onSuggestionTap, required this.onNearMeTap, required this.onSearchForTap,
  });

  // In global search each suggestion shows its module image in the leading
  // position; resolve it from the entry (or the loaded module list as fallback).
  String? _moduleImage(RecentSearchEntry entry) {
    if (entry.moduleImage?.isNotEmpty == true) return entry.moduleImage;
    final List<ModuleModel>? modules = Get.find<SplashController>().moduleList;
    if (modules == null) return null;
    if (entry.moduleId != null) {
      for (final ModuleModel m in modules) {
        if (m.id == entry.moduleId) return m.iconFullUrl ?? m.thumbnailFullUrl;
      }
    }
    if (entry.moduleType != null) {
      for (final ModuleModel m in modules) {
        if (m.moduleType == entry.moduleType) return m.iconFullUrl ?? m.thumbnailFullUrl;
      }
    }
    return null;
  }

  // In global search, show "is a {Module} Item" / "is a Restaurant" under each row.
  Widget? _subtitle(BuildContext context, RecentSearchEntry entry) {
    if (!isGlobal || entry.kind == RecentSearchKind.keyword) return null;
    final String text;
    if (entry.kind == RecentSearchKind.store) {
      final bool isFood = entry.moduleType == AppConstants.food;
      text = '${'is_a'.tr} ${isFood ? 'restaurant'.tr : 'store'.tr}';
    } else {
      final String moduleName = entry.moduleName ?? _typeLabel(entry.moduleType);
      text = '${'is_a'.tr} $moduleName ${'item'.tr}';
    }
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
    );
  }

  String _typeLabel(String? type) {
    switch (type) {
      case AppConstants.food:
        return 'Food';
      case AppConstants.grocery:
        return 'Grocery';
      case AppConstants.ecommerce:
        return 'Shop';
      case AppConstants.pharmacy:
        return 'Pharmacy';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [

      Expanded(
        child: isLoading
            ? const _SuggestionListShimmer()
            : suggestions.isNotEmpty
            ? ListView.builder(
                itemCount: suggestions.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final RecentSearchEntry entry = suggestions[index];
                  final String item = entry.name;
                  final lowerItem = item.toLowerCase();
                  final lowerQuery = searchQuery.toLowerCase();

                  if (searchQuery.isNotEmpty && lowerItem.contains(lowerQuery)) {
                    final startIndex = lowerItem.indexOf(lowerQuery);
                    final prefix = item.substring(0, startIndex);
                    final match = item.substring(startIndex, startIndex + searchQuery.length);
                    final suffix = item.substring(startIndex + searchQuery.length);
                    return ListTile(
                      leading: _SuggestionIcon(kind: entry.kind, moduleImage: isGlobal ? _moduleImage(entry) : null),
                      title: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            if (prefix.isNotEmpty) TextSpan(text: prefix, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5))),
                            TextSpan(text: match, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                            if (suffix.isNotEmpty) TextSpan(text: suffix, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5))),
                          ],
                        ),
                      ),
                      subtitle: _subtitle(context, entry),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => onSuggestionTap(entry),
                    );
                  }

                  return ListTile(
                    leading: _SuggestionIcon(kind: entry.kind, moduleImage: isGlobal ? _moduleImage(entry) : null),
                    title: Text(item, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5))),
                    subtitle: _subtitle(context, entry),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => onSuggestionTap(entry),
                  );
                },
              )
            : Padding(
                padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.2),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const CustomAssetImageWidget(Images.emptyBox, height: 100, width: 100),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  Text('no_suggestions_found'.tr, style: robotoMedium.copyWith(color: Theme.of(context).hintColor)),
                ]),
              ),
      ),

      if (searchQuery.isNotEmpty) ...[
        Divider(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), height: 1),

        InkWell(
          onTap: onNearMeTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
            child: Row(children: [
              const _SuggestionIcon(showBackground: false),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(text: searchQuery, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                    TextSpan(text: ' ${'near_me'.tr}', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor)),
                  ],
                ),
              )),
              // Icon(Icons.arrow_forward_ios, color: Theme.of(context).disabledColor, size: 16),
            ]),
          ),
        ),

        Divider(color: Theme.of(context).disabledColor.withValues(alpha: 0.1), height: 1),

        InkWell(
          onTap: onSearchForTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
            child: Row(children: [
              const _SuggestionIcon(showBackground: false),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(text: '${'search_for'.tr} "', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor)),
                    TextSpan(text: searchQuery, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                    TextSpan(text: '"', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor)),
                  ],
                ),
              )),
              // Icon(Icons.arrow_forward_ios, color: Theme.of(context).disabledColor, size: 16),
            ]),
          ),
        ),
      ],

    ]);
  }
}

class _SuggestionListShimmer extends StatelessWidget {
  const _SuggestionListShimmer();

  @override
  Widget build(BuildContext context) {
    final Color shimmerColor = Theme.of(context).disabledColor.withValues(alpha: 0.12);
    const List<double> widths = [160, 120, 180, 100, 140, 110];
    return ListView.builder(
      itemCount: widths.length,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
        child: Row(children: [
          Shimmer(
            duration: const Duration(seconds: 2),
            child: Container(
              height: 36, width: 36,
              decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Shimmer(
            duration: const Duration(seconds: 2),
            child: Container(
              height: 14, width: widths[index],
              decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SuggestionIcon extends StatelessWidget {
  final RecentSearchKind? kind;
  final String? moduleImage;
  final bool showBackground;
  const _SuggestionIcon({this.kind, this.moduleImage, this.showBackground = true});

  IconData _icon() {
    switch (kind) {
      case RecentSearchKind.item:
        return CupertinoIcons.cube_box;
      case RecentSearchKind.store:
        return Icons.storefront_outlined;
      case RecentSearchKind.keyword:
      case null:
        return CupertinoIcons.search;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (moduleImage?.isNotEmpty ?? false) {
      return Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: showBackground ? Theme.of(context).disabledColor.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
        child: CustomImage(image: moduleImage??'', fit: BoxFit.cover),
      );
    }
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
      decoration: BoxDecoration(
        color: showBackground ? Theme.of(context).disabledColor.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Icon(_icon(), color: Theme.of(context).disabledColor, size: 20),
    );
  }
}
