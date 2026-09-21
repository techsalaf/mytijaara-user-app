import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class PromoBannerItem {
  final String title;
  final String subtitle;
  final String image;
  final Color accent;

  const PromoBannerItem({required this.title, required this.subtitle, required this.image, required this.accent});
}

/// Small promo card shown just above the bottom navbar. It animates in and, when
/// given more than one item, auto-rotates between them with a slide + fade.
class NavbarPromoBanner extends StatefulWidget {
  final List<PromoBannerItem> items;
  final VoidCallback onClose;
  // Extra bottom padding so the card's content stays above the part that tucks
  // behind the navbar (only the empty rounded bottom should be hidden).
  final double bottomTuck;

  const NavbarPromoBanner({super.key, required this.items, required this.onClose, this.bottomTuck = 0});

  @override
  State<NavbarPromoBanner> createState() => _NavbarPromoBannerState();
}

class _NavbarPromoBannerState extends State<NavbarPromoBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  Timer? _rotateTimer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 320))..forward();
    _startRotation();
  }

  void _startRotation() {
    _rotateTimer?.cancel();
    if (widget.items.length > 1) {
      _rotateTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
        if (!mounted) return;
        setState(() => _index = (_index + 1) % widget.items.length);
      });
    }
  }

  @override
  void didUpdateWidget(covariant NavbarPromoBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      if (_index >= widget.items.length) {
        _index = 0;
      }
      _startRotation();
    }
  }

  @override
  void dispose() {
    _rotateTimer?.cancel();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }
    final PromoBannerItem item = widget.items[_index.clamp(0, widget.items.length - 1)];
    final Animation<double> curve = CurvedAnimation(parent: _entrance, curve: Curves.easeOutBack);

    // Light: warm cream. Dark: an amber-tinted elevated dark surface so the card
    // keeps its promo warmth and stays distinct from the (cardColor) navbar pill.
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark
        ? Color.alphaBlend(const Color(0xFFFFC107).withValues(alpha: 0.14), Theme.of(context).cardColor)
        : const Color(0xFFFFFBEB);

    return FadeTransition(
      opacity: _entrance,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(curve),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusLarge)),
            boxShadow: [BoxShadow(
              color: Theme.of(context).hintColor.withValues(alpha: 0.20),
              blurRadius: 8, spreadRadius: 1, offset: const Offset(0, 3),
            )],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall + widget.bottomTuck,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (Widget child, Animation<double> animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: _PromoContent(key: ValueKey<int>(_index), item: item),
              ),
            ),

            Positioned(
              top: -3, right: -3,
              child: InkWell(
                onTap: widget.onClose,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Icon(Icons.close, size: 18, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.7)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PromoContent extends StatelessWidget {
  final PromoBannerItem item;

  const _PromoContent({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoBold.copyWith(color: item.accent, fontSize: Dimensions.fontSizeLarge),
            ),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(color: const Color(0xFFE5A000), fontSize: Dimensions.fontSizeSmall),
            ),
          ],
        ),
      ),
      const SizedBox(width: Dimensions.paddingSizeSmall),
      Image.asset(item.image, height: 42, width: 54, fit: BoxFit.contain),
    ]);
  }
}
