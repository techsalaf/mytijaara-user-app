import 'package:flutter/material.dart';

/// Converts logical (layout) sizes into the physical-pixel decode targets that
/// `CustomImage.cacheWidth` / `cacheHeight` expect, and that ultimately reach
/// `ResizeImage`.
///
/// The two units are easy to mix up and both mistakes are visible:
/// * passing a logical value decodes a bitmap 2-4x smaller than the box it paints
///   into, and the upscale looks blurry;
/// * passing no target at all keeps the source at full resolution in memory, which
///   the framework reports as an oversized image.
///
/// Choosing axes: with `BoxFit.cover`/`contain` pass a single axis so the decoder
/// derives the other and keeps the source aspect ratio. With `BoxFit.fill` — or
/// when the box may be proportionally wider or taller than the photo — pass both;
/// `ResizeImage` then scales to exactly those numbers ([ResizeImagePolicy.exact]),
/// matching what is painted at the cost of the source ratio.
class ImageCacheHelper {
  ImageCacheHelper._();

  /// Logical pixels -> physical. Returns null when [logical] cannot be used — null,
  /// `double.infinity` from an expanding parent, or <= 0 — so the caller simply
  /// omits the hint rather than crashing on `.round()`.
  static int? pixels(BuildContext context, double? logical) {
    if (logical == null || !logical.isFinite || logical <= 0) {
      return null;
    }
    return (logical * MediaQuery.devicePixelRatioOf(context)).round();
  }

  /// Like [pixels], but falls back to the screen width when [logical] is unusable.
  ///
  /// For widths declared as `double.infinity`: the widget fills its parent, and a
  /// parent can never be wider than the screen, so that is a safe upper bound.
  static int widthPixels(BuildContext context, double? logical) {
    return pixels(context, logical) ?? (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round();
  }
}
