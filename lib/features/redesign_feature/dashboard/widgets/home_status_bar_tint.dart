import 'package:flutter/material.dart';

/// Shared UI signal that lets the root [GetMaterialApp] builder paint the home
/// dashboard's status-bar tint ABOVE the navigator (and therefore above modal
/// barriers from bottom sheets / dialogs).
///
/// Android enforces edge-to-edge from targetSdk 35+, so `SystemUiOverlayStyle.
/// statusBarColor` is ignored and the status bar is coloured only by an in-body
/// strip. A modal's full-screen scrim, drawn by the navigator, then paints over
/// that strip and darkens the status bar. Re-drawing the same tint outside the
/// navigator keeps the status bar colour stable while a modal is open.
///
/// It is only [active] while the home tab of the dashboard is the visible,
/// uncovered top page, so every other screen/tab is left untouched.
class HomeStatusBarTint {
  HomeStatusBarTint._();

  /// Current tint colour of the home dashboard status-bar strip.
  static final ValueNotifier<Color?> color = ValueNotifier<Color?>(null);

  /// Whether the home dashboard tab is the visible, uncovered top page.
  static final ValueNotifier<bool> active = ValueNotifier<bool>(false);
}

/// Paints the home status-bar tint at the very top, above all routes/modals.
/// Lives in the root builder [Stack]; renders nothing unless the home tab is
/// active and a tint colour has been published.
class HomeStatusBarTintOverlay extends StatelessWidget {
  const HomeStatusBarTintOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: HomeStatusBarTint.active,
      builder: (context, active, _) {
        if (!active) {
          return const SizedBox.shrink();
        }
        return ValueListenableBuilder<Color?>(
          valueListenable: HomeStatusBarTint.color,
          builder: (context, color, _) {
            final double topInset = MediaQuery.paddingOf(context).top;
            if (color == null || topInset <= 0) {
              return const SizedBox.shrink();
            }
            return Positioned(
              top: 0, left: 0, right: 0,
              child: IgnorePointer(
                child: SizedBox(height: topInset, child: ColoredBox(color: color)),
              ),
            );
          },
        );
      },
    );
  }
}
