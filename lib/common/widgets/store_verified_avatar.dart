import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/util/images.dart';

/// Small store/provider avatar that periodically flips to a verified badge.
///
/// This lives inside card widgets that are built by `itemBuilder` in long lists,
/// so it can be on screen a dozen times at once and it animates for the lifetime
/// of the card. Three things keep that affordable:
///
/// * A [RepaintBoundary] confines the flip to this widget's own layer. Without it
///   the animation dirties the enclosing list item's repaint boundary every frame,
///   so the whole card — image, text, price, badges — repaints continuously even
///   while the user is doing nothing.
/// * A single [AnimationController] drives the flip, read inside an
///   [AnimatedBuilder]. Nothing calls `setState` per frame or per flip, so the
///   faces (and the [CustomImage] inside the avatar) are built once per parent
///   rebuild rather than every couple of seconds.
/// * The rotation alone hides the swap — the face is edge-on at the halfway point,
///   so no `Opacity` is needed. `Opacity` between 0 and 1 forces a `saveLayer()`,
///   which is the single most expensive thing this widget used to do per frame.
///
/// The controller is vsync-driven, so `TickerMode` mutes it automatically when the
/// route is covered by another screen.
class StoreVerifiedAvatar extends StatefulWidget {
  final String? imageUrl;
  final bool isVerified;
  final double size;
  final Duration interval;

  const StoreVerifiedAvatar({super.key,
    this.imageUrl, this.isVerified = false, this.size = 18, this.interval = const Duration(seconds: 2),
  });

  @override
  State<StoreVerifiedAvatar> createState() => _StoreVerifiedAvatarState();
}

class _StoreVerifiedAvatarState extends State<StoreVerifiedAvatar> with SingleTickerProviderStateMixin {
  static const Duration _flipDuration = Duration(milliseconds: 500);

  final math.Random _random = math.Random();
  late final AnimationController _controller = AnimationController(vsync: this, duration: _flipDuration);
  Timer? _timer;
  bool _badgeAtRest = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_onFlipComplete);
    _startIfNeeded();
  }

  @override
  void didUpdateWidget(covariant StoreVerifiedAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVerified != widget.isVerified || oldWidget.interval != widget.interval) {
      _timer?.cancel();
      _controller.reset();
      _badgeAtRest = false;
      _startIfNeeded();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.removeStatusListener(_onFlipComplete);
    _controller.dispose();
    super.dispose();
  }

  void _startIfNeeded() {
    if (!widget.isVerified) return;
    _scheduleNext();
  }

  void _onFlipComplete(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _badgeAtRest = !_badgeAtRest;
    _controller.reset();
    _scheduleNext();
  }

  void _scheduleNext() {
    final int baseMs = widget.interval.inMilliseconds;
    final Duration delay = Duration(milliseconds: (baseMs * 0.5).round() + _random.nextInt(baseMs));
    _timer = Timer(delay, () {
      if (!mounted) return;
      _controller.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;
    final Widget avatar = _AvatarFace(imageUrl: widget.imageUrl, size: s);

    if (!widget.isVerified) {
      return SizedBox(height: s, width: s, child: avatar);
    }

    final Widget badge = _BadgeFace(size: s);

    return RepaintBoundary(
      child: SizedBox(
        height: s, width: s,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final double t = _controller.value;
            final bool pastHalfway = t >= 0.5;
            final bool showBadge = pastHalfway ? !_badgeAtRest : _badgeAtRest;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(t * math.pi),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(pastHalfway ? math.pi : 0),
                child: showBadge ? badge : avatar,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AvatarFace extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const _AvatarFace({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final int? decodeSize = ImageCacheHelper.pixels(context, size);
    return ClipOval(
      child: hasImage
          ? CustomImage(image: imageUrl!, height: size, width: size, fit: BoxFit.cover, cacheWidth: decodeSize, cacheHeight: decodeSize)
          : Image.asset(Images.placeholder, height: size, width: size, fit: BoxFit.cover, cacheWidth: decodeSize, cacheHeight: decodeSize),
    );
  }
}

class _BadgeFace extends StatelessWidget {
  final double size;

  const _BadgeFace({required this.size});

  @override
  Widget build(BuildContext context) {
    final double badgeSize = size - 3;
    final int? decodeSize = ImageCacheHelper.pixels(context, badgeSize);
    return Image.asset(Images.verifiedBadge2, height: badgeSize, width: badgeSize, cacheWidth: decodeSize, cacheHeight: decodeSize);
  }
}
