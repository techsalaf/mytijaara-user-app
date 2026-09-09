import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class HomeNewModuleSectionWidget extends StatefulWidget {
  final bool isExpanded;
  final ValueChanged<bool>? onExpandedChanged;

  const HomeNewModuleSectionWidget({super.key, this.isExpanded = false, this.onExpandedChanged});

  @override
  State<HomeNewModuleSectionWidget> createState() => _HomeNewModuleSectionWidgetState();
}

class _HomeNewModuleSectionWidgetState extends State<HomeNewModuleSectionWidget> {
  static const int _collapsedCount = 5;

  bool get _isExpanded => widget.isExpanded;

  void _toggleExpanded() {
    widget.onExpandedChanged?.call(!_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(builder: (splashController) {
      final List<ModuleModel>? apiModules = splashController.moduleList;

      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Dimensions.radiusExtraLarge)),
          // boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
        child: apiModules == null
            ? const _ModuleSectionShimmer()
            : apiModules.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
                    child: Center(child: Text('no_module_found'.tr, style: robotoMedium)),
                  )
                : _buildGrid(context, _mapApiModules(apiModules)),
      );
    });
  }

  Widget _buildGrid(BuildContext context, List<_ModuleData> modules) {
    final bool canToggle = modules.length > _collapsedCount;
    final List<_ModuleData> visibleModules = (!canToggle || _isExpanded)
        ? modules
        : modules.sublist(0, _collapsedCount);

    return Column(
      children: [
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: StaggeredGrid.count(
              crossAxisCount: 12,
              mainAxisSpacing: Dimensions.paddingSizeSmall,
              crossAxisSpacing: Dimensions.paddingSizeSmall,
              children: visibleModules.asMap().entries.map((entry) {
                final int index = entry.key;
                final _ModuleData module = entry.value;
                final bool isExtra = index >= _collapsedCount;
                Widget card = _ModuleCard(
                  module: module,
                  onTap: () => Get.find<SplashController>().selectModuleByTabIndex(index + 1),
                );
                if (isExtra) {
                  card = TweenAnimationBuilder<double>(
                    key: ValueKey('module-extra-$index'),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 16),
                        child: child,
                      ),
                    ),
                    child: card,
                  );
                }
                return StaggeredGridTile.extent(
                  crossAxisCellCount: _crossAxisCountFor(module.layout, modules.length),
                  mainAxisExtent: _mainAxisExtentFor(module.layout),
                  child: card,
                );
              }).toList(),
            ),
          ),
        ),

        if (canToggle) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),

          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeExtraSmall,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isExpanded ? 'see_less'.tr : 'see_more'.tr,
                    style: robotoSemiBold.copyWith(
                      color: Colors.blueAccent,
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<_ModuleData> _mapApiModules(List<ModuleModel> apiModules) {
    return apiModules.asMap().entries.map((entry) {
      final int position = entry.key;
      final ModuleModel module = entry.value;
      final _ModuleStyle style = _resolveStyle(module, position);
      final _ModuleLayout layout = _layoutForPosition(position);
      final bool isLargeOrMedium = layout == _ModuleLayout.large || layout == _ModuleLayout.mediumHorizontal;

      return _ModuleData(
        title: (module.moduleName ?? '').trim(),
        subtitle: isLargeOrMedium ? _resolveSubtitle(module) : '',
        iconUrl: module.iconFullUrl,
        emojiFallback: style.emojiFallback,
        bgColor: style.bgColor,
        layout: layout,
        hasFlashSale: module.flashSale == 1,
        hasFreeDelivery: module.freeDelivery == 1,
        minDeliveryTime: (module.minDeliveryTime ?? '').trim(),
        topOffer: module.topOffer,
      );
    }).toList();
  }

  String _resolveSubtitle(ModuleModel module) {
    final String description = _stripHtml(module.shortDescription ?? '');
    if (description.isNotEmpty) {
      return description;
    }
    final int? count = module.storesCount;
    if (count != null && count > 0) {
      return '$count ${'stores_available'.tr}';
    }
    return '';
  }

  String _stripHtml(String input) {
    if (input.isEmpty) {
      return '';
    }
    final String withoutTags = input.replaceAll(RegExp(r'<[^>]*>'), ' ');
    final String decoded = withoutTags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
    return decoded.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  _ModuleLayout _layoutForPosition(int position) {
    if (position <= 1) {
      return _ModuleLayout.large;
    } else if (position == 2) {
      return _ModuleLayout.mediumHorizontal;
    } else if (position <= 4) {
      return _ModuleLayout.iconWithTitle;
    }
    return _ModuleLayout.wideIconWithTitle;
  }

  _ModuleStyle _resolveStyle(ModuleModel module, int position) {
    final String emoji = _knownStyles[module.moduleType ?? '']?.emojiFallback ?? '📦';

    if (position < _fixedBigCardColors.length) {
      return _ModuleStyle(bgColor: _fixedBigCardColors[position], emojiFallback: emoji);
    }

    return _ModuleStyle(bgColor: _greyCardColor, emojiFallback: emoji);
  }

  static const List<Color> _fixedBigCardColors = [
    Color(0xFFFFF1C2),
    Color(0xFFCFF7D3),
    Color(0xFFDBE9FF),
  ];

  static const Color _greyCardColor = Color(0xFFF2F2F2);

  static const Map<String, _ModuleStyle> _knownStyles = {
    AppConstants.food: _ModuleStyle(bgColor: Color(0xFFFFE7B3), emojiFallback: '🍔'),
    AppConstants.grocery: _ModuleStyle(bgColor: Color(0xFFB3DDB4), emojiFallback: '🛒'),
    AppConstants.pharmacy: _ModuleStyle(bgColor: Color(0xFFD6E4FF), emojiFallback: '💊'),
    AppConstants.ecommerce: _ModuleStyle(bgColor: Color(0xFFF2F2F2), emojiFallback: '🛍️'),
    AppConstants.taxi: _ModuleStyle(bgColor: Color(0xFFF2F2F2), emojiFallback: '🚗'),
    AppConstants.parcel: _ModuleStyle(bgColor: Color(0xFFF2F2F2), emojiFallback: '🛵'),
    AppConstants.ride: _ModuleStyle(bgColor: Color(0xFFF2F2F2), emojiFallback: '🚗'),
    AppConstants.service: _ModuleStyle(bgColor: Color(0xFFF2F2F2), emojiFallback: '🏠'),
  };

  int _crossAxisCountFor(_ModuleLayout layout, int totalCount) {
    if (totalCount == 1 && layout == _ModuleLayout.large) {
      return 12;
    }
    switch (layout) {
      case _ModuleLayout.large:
      case _ModuleLayout.mediumHorizontal:
        return 6;
      case _ModuleLayout.iconWithTitle:
        return 3;
      case _ModuleLayout.wideIconWithTitle:
        return 4;
    }
  }

  double _mainAxisExtentFor(_ModuleLayout layout) {
    switch (layout) {
      case _ModuleLayout.large:
        return 125;
      case _ModuleLayout.mediumHorizontal:
      case _ModuleLayout.iconWithTitle:
      case _ModuleLayout.wideIconWithTitle:
        return 85;
    }
  }
}

enum _ModuleLayout {
  large,
  mediumHorizontal,
  iconWithTitle,
  wideIconWithTitle,
}

class _ModuleStyle {
  final Color bgColor;
  final String emojiFallback;

  const _ModuleStyle({required this.bgColor, required this.emojiFallback});
}

class _ModuleData {
  final String title;
  final String subtitle;
  final String? iconUrl;
  final String emojiFallback;
  final Color bgColor;
  final _ModuleLayout layout;
  final bool hasFlashSale;
  final bool hasFreeDelivery;
  final String minDeliveryTime;
  final TopOffer? topOffer;

  const _ModuleData({required this.title,
    required this.subtitle, required this.iconUrl, required this.emojiFallback, required this.bgColor, required this.layout,
    required this.hasFlashSale, required this.hasFreeDelivery, required this.minDeliveryTime, this.topOffer,
  });
}

class _ModuleCard extends StatelessWidget {
  final _ModuleData module;
  final VoidCallback onTap;

  const _ModuleCard({required this.module, required this.onTap});

  // Module card background. The design colors are light pastels (fine in light
  // mode). In dark mode those would be too bright for the (now light) text, so we
  // keep each module's hue but lay it over a subtly-elevated dark surface.
  Color _resolveBackgroundColor(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) {
      return module.bgColor;
    }
    final Color base = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.06), // slight elevation above the section bg
      Theme.of(context).cardColor,
    );
    return Color.alphaBlend(module.bgColor.withValues(alpha: 0.14), base);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _resolveBackgroundColor(context),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      ),
      child: CustomInkWell(
        onTap: onTap,
        enableRippleEffect: true,
        radius: Dimensions.radiusLarge,
        padding: EdgeInsets.all(module.layout == _ModuleLayout.large ? 0 : Dimensions.paddingSizeSmall),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (module.layout) {
      case _ModuleLayout.large:
        return _buildLarge(context);
      case _ModuleLayout.mediumHorizontal:
        return _buildMediumHorizontal(context);
      case _ModuleLayout.iconWithTitle:
        return _buildIconWithTitle(context);
      case _ModuleLayout.wideIconWithTitle:
        return _buildIconWithTitle(context);
    }
  }

  Widget _buildLarge(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeExtraLarge,
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    Text(
                      module.subtitle,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5),
                        height: 120 * 0.01,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _ModuleVisual(iconUrl: module.iconUrl, emojiFallback: module.emojiFallback, size: 35),
            ],
          ),
        ),

        const Spacer(),

        Padding(
          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
          child: _ModulePillRow(module: module),
        ),
      ],
    );
  }

  Widget _buildMediumHorizontal(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    module.title,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    module.subtitle,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5),
                      height: 120 * 0.01,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
              child: _ModuleVisual(iconUrl: module.iconUrl, emojiFallback: module.emojiFallback, size: 32),
            ),
          ],
        ),

        if (module.hasFlashSale)
          const Positioned(
            top: -5,
            right: -5,
            child: _FlashBadge(size: 15,),
          ),
      ],
    );
  }

  Widget _buildIconWithTitle(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ModuleVisual(iconUrl: module.iconUrl, emojiFallback: module.emojiFallback, size: 32),
              if (module.title.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  module.title,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (module.hasFlashSale)
          const Positioned(
            top: -3,
            right: -3,
            child: _FlashBadge(size: 15,),
          ),
      ],
    );
  }
}

class _ModuleVisual extends StatelessWidget {
  final String? iconUrl;
  final String emojiFallback;
  final double size;

  const _ModuleVisual({required this.iconUrl, required this.emojiFallback, required this.size});

  @override
  Widget build(BuildContext context) {
    final bool hasUrl = iconUrl != null && iconUrl!.isNotEmpty;
    if (hasUrl) {
      return CustomImage(image: iconUrl!, height: size, width: size);
    }
    return Text(emojiFallback, style: TextStyle(fontSize: size - 5));
  }
}

class _ModulePillRow extends StatelessWidget {
  final _ModuleData module;

  const _ModulePillRow({required this.module});

  String? _offerText() {
    final TopOffer? offer = module.topOffer;
    if (!module.hasFlashSale || offer == null || offer.discount == null || offer.discount == 0) {
      return null;
    }
    final bool isPercent = offer.discountType == 'percent';
    final String symbol = isPercent
        ? '%'
        : (Get.find<SplashController>().configModel?.currencySymbol ?? '\$');
    return '${'up_to'.tr} ${offer.discount}$symbol ${'off'.tr}';
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pills = [];

    if (module.hasFlashSale) {
      pills.add(const _FlashBadge());
    }
    final String? offerText = _offerText();
    if (offerText != null) {
      pills.add(_Pill(text: offerText));
    } else if (module.hasFreeDelivery) {
      pills.add(_Pill(text: 'free_delivery'.tr));
    }

    if (module.minDeliveryTime.isNotEmpty) {
      pills.add(_Pill(
        leading: Icon(
          Icons.access_time_rounded,
          size: 12,
          color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.8),
        ),
        text: module.minDeliveryTime,
      ));
    }

    if (pills.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
      child: Row(
        children: [
          for (int i = 0; i < pills.length; i++) ...[
            pills[i],
            if (i < pills.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final Widget? leading;
  final String text;

  const _Pill({this.leading, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: leading == null ? 8 : 4,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: robotoSemiBold.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.7),
              height: 120 * 0.01,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashBadge extends StatelessWidget {
  const _FlashBadge({this.size = 18});
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFE53935),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.electric_bolt, size: 10, color: Colors.white),
    );
  }
}

class _ModuleSectionShimmer extends StatelessWidget {
  const _ModuleSectionShimmer();

  @override
  Widget build(BuildContext context) {
    final Color baseColor = Theme.of(context).disabledColor.withValues(alpha: 0.15);
    return Shimmer(
      duration: const Duration(seconds: 2),
      child: StaggeredGrid.count(
        crossAxisCount: 12,
        mainAxisSpacing: Dimensions.paddingSizeSmall,
        crossAxisSpacing: Dimensions.paddingSizeSmall,
        children: [
          StaggeredGridTile.extent(crossAxisCellCount: 6, mainAxisExtent: 160, child: _shimmerTile(baseColor)),
          StaggeredGridTile.extent(crossAxisCellCount: 6, mainAxisExtent: 160, child: _shimmerTile(baseColor)),
          StaggeredGridTile.extent(crossAxisCellCount: 6, mainAxisExtent: 110, child: _shimmerTile(baseColor)),
          StaggeredGridTile.extent(crossAxisCellCount: 3, mainAxisExtent: 110, child: _shimmerTile(baseColor)),
          StaggeredGridTile.extent(crossAxisCellCount: 3, mainAxisExtent: 110, child: _shimmerTile(baseColor)),
        ],
      ),
    );
  }

  Widget _shimmerTile(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      ),
    );
  }
}
