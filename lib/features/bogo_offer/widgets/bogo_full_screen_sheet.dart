import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class BogoFullScreenSheet extends StatefulWidget {
  final String? title;
  final List<Widget> slivers;
  final Widget? footer;
  final Widget? header;

  const BogoFullScreenSheet({super.key, this.title, required this.slivers, this.footer, this.header});

  static const double _dismissExtent = 0.6;

  static Future<void> show(BuildContext context, {required Widget child}) {
    return Get.bottomSheet(
      child,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      ignoreSafeArea: false,
      enableDrag: false,
    );
  }

  @override
  State<BogoFullScreenSheet> createState() => _BogoFullScreenSheetState();
}

class _BogoFullScreenSheetState extends State<BogoFullScreenSheet> {
  final GlobalKey _viewportKey = GlobalKey();
  final GlobalKey _titleKey = GlobalKey();
  final ValueNotifier<double> _barTitleOpacity = ValueNotifier<double>(0);
  static const double _titleFadeDistance = 24;

  bool get _showsOwnTitle => widget.header == null && widget.title != null;

  @override
  void dispose() {
    _barTitleOpacity.dispose();
    super.dispose();
  }

  void _syncBarTitle() {
    final RenderObject? title = _titleKey.currentContext?.findRenderObject();
    final RenderObject? viewport = _viewportKey.currentContext?.findRenderObject();
    if(title is! RenderBox || viewport is! RenderBox || !title.hasSize || !viewport.hasSize) {
      return;
    }

    final double titleBottom = title.localToGlobal(Offset.zero, ancestor: viewport).dy + title.size.height;
    final double opacity = (-titleBottom / _titleFadeDistance).clamp(0.0, 1.0);
    if((_barTitleOpacity.value - opacity).abs() > 0.01) {
      _barTitleOpacity.value = opacity;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (DraggableScrollableNotification notification) {
        if(notification.extent <= BogoFullScreenSheet._dismissExtent && Get.isBottomSheetOpen == true) {
          Get.back();
        }
        return false;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 1,
        minChildSize: BogoFullScreenSheet._dismissExtent,
        maxChildSize: 1,
        expand: false,
        snap: true,
        builder: (BuildContext context, ScrollController scrollController) => _body(context, scrollController),
      ),
    );
  }

  Widget _body(BuildContext context, ScrollController scrollController) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(bottom: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: Dimensions.paddingSizeSmall),

        ?widget.header,

        if(_showsOwnTitle) Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeLarge, 0, Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall,
          ),
          child: Row(children: [
            Expanded(child: ValueListenableBuilder<double>(
              valueListenable: _barTitleOpacity,
              builder: (BuildContext context, double opacity, Widget? child) => Opacity(opacity: opacity, child: child),
              child: Text(
                widget.title!, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
            )),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            const BogoSheetCloseButton(),
          ]),
        ),

        Expanded(child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            _syncBarTitle();
            return false;
          },
          child: CustomScrollView(key: _viewportKey, controller: scrollController, slivers: [
            if(_showsOwnTitle) SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeLarge, 0, Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall,
              ),
              child: Text(
                widget.title!, key: _titleKey, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
              ),
            )),

            ...widget.slivers,
          ]),
        )),

        ?widget.footer,
      ])),
    );
  }
}

class BogoSheetCloseButton extends StatelessWidget {
  const BogoSheetCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.back(),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 32, height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.surface),
        child: Icon(Icons.close, size: 18, color: Theme.of(context).textTheme.bodyLarge!.color),
      ),
    );
  }
}

// SUMMARY
// The shell every BOGO sheet is built in: a full-height draggable sheet that dismisses
// itself when pulled down far enough, with the close mark pinned at the top, the caller's
// slivers scrolling beneath it and an optional footer pinned below. Given a title it
// writes it twice — as the heading that scrolls away, and beside the close mark, which
// takes over the moment the heading passes out of view.
