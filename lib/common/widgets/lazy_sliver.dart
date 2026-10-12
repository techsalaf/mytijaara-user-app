import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Wraps a sliver so its data is fetched the first time the sliver is laid out —
/// that is, when it scrolls into (or near) the viewport — instead of up front.
///
/// The dashboard used to fetch every section's data on module entry, ~18 requests
/// in one burst, most of them for content the user never scrolled to. Wrapping a
/// section here moves its fetch to the moment it is actually needed.
///
/// ```dart
/// LazySliver(
///   onReveal: () => Get.find<BrandsController>().getBrandList(),
///   sliver: GetBuilder<BrandsController>(builder: (controller) { … }),
/// )
/// ```
///
/// **How the deferral works.** Being laid out is *not* the signal. A viewport calls
/// `layout()` on every one of its sliver children, all the way to the last —
/// `RenderViewport.layoutChildSequence` loops `while (child != null)` with no early
/// break. Children past the visible area are laid out with *zero* remaining extent
/// rather than skipped, so [SliverLayoutBuilder]'s callback runs for all of them.
/// Keying off the callback alone would fire every section's fetch on the first
/// frame — the exact burst this widget exists to prevent.
///
/// The real signal is in the constraints: the viewport hands each sliver in turn a
/// shrinking [SliverConstraints.remainingCacheExtent], and once the visible area
/// plus cache extent is used up every subsequent sliver gets `0`. So
/// `remainingCacheExtent > 0` means "I am on screen or within the cache extent" —
/// that is what triggers [onReveal]. Flutter's default 250px cache extent means a
/// section starts loading just before it scrolls into view, so its shimmer is
/// usually replaced before the user reaches it.
///
/// **Requirement:** an unloaded section must still occupy vertical space — a
/// shimmer placeholder, not `SizedBox.shrink()`. A zero-height section consumes no
/// cache extent, so it leaves the full budget to the sections after it and pulls
/// them into the same frame. Enough of those in a row and the burst comes back.
/// The module screens satisfy this because `_conditionalSection` keeps a section
/// visible while its controller data is `null`.
///
/// [onReveal] fires after the frame completes — controller fetches call
/// `update()`, and mutating state during layout throws. It fires once per reveal
/// per [LazyRefreshNotifier] epoch; see that class for how refresh works.
///
/// **Refresh.** `MainScreen` keeps its state alive (`AutomaticKeepAliveClientMixin`),
/// so a revealed section would never re-reveal and pull-to-refresh would silently
/// stop refreshing every lazy section. [LazyRefreshNotifier.bump] solves that — see
/// its documentation.
class LazySliver extends StatefulWidget {
  /// The sliver to render. Must be a sliver, not a box widget.
  final Widget sliver;

  /// Called once, the first time this sliver comes within the viewport's visible
  /// area or its cache extent — and again after each [LazyRefreshNotifier.bump]
  /// while it is still there.
  final VoidCallback onReveal;

  const LazySliver({super.key, required this.sliver, required this.onReveal});

  @override
  State<LazySliver> createState() => _LazySliverState();
}

class _LazySliverState extends State<LazySliver> {
  /// The epoch this sliver last fetched for, or null while never revealed.
  int? _revealedEpoch;

  @override
  void initState() {
    super.initState();
    LazyRefreshNotifier.epoch.addListener(_onRefreshRequested);
  }

  @override
  void dispose() {
    LazyRefreshNotifier.epoch.removeListener(_onRefreshRequested);
    super.dispose();
  }

  // Marks this sliver dirty so its builder runs again. Whether it actually
  // refetches is decided inside the builder — which only runs for slivers the
  // viewport still lays out, i.e. the ones on screen.
  void _onRefreshRequested() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (BuildContext context, SliverConstraints constraints) {
        // Every sliver gets laid out, including ones far below the fold — they just
        // receive no remaining extent. This, not the callback itself, is what says
        // the sliver has actually come into (or near) view.
        final bool isInView = constraints.remainingCacheExtent > 0;
        final int epoch = LazyRefreshNotifier.epoch.value;
        if (isInView && _revealedEpoch != epoch) {
          _revealedEpoch = epoch;
          // Deferred to after the frame: the builder runs during layout, and a
          // controller's update() inside layout throws.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onReveal();
            }
          });
        }
        return widget.sliver;
      },
    );
  }
}

/// Broadcasts "refetch what is on screen" to every [LazySliver].
///
/// A revealed [LazySliver] fetches once and then stays quiet — which is the point,
/// but it means the usual refresh paths (`RefreshIndicator`, placing an order,
/// changing address or language) would no longer reload any lazy section, because
/// `MainScreen` keeps its state alive across those events.
///
/// Calling [bump] marks every [LazySliver] dirty. Only the ones the viewport still
/// lays out — those on screen plus the cache extent — run their builder and refetch;
/// off-screen sections stay lazy and will fetch when scrolled to, as normal.
///
/// Pair it with the module's critical fetches, which are not lazy and must be
/// reloaded explicitly:
///
/// ```dart
/// HomeScreen.loadData(true, fromModule: true);
/// LazyRefreshNotifier.bump();
/// ```
class LazyRefreshNotifier {
  LazyRefreshNotifier._();

  /// Incremented on every refresh. Never disposed — it outlives every sliver.
  static final ValueNotifier<int> epoch = ValueNotifier<int>(0);

  static void bump() => epoch.value++;
}
