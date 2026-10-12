import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/controllers/advertisement_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:video_player/video_player.dart';

// On-video chrome sizing. Deliberate literals rather than Dimensions/theme values:
// these describe controls painted over arbitrary video frames, where the app's
// spacing and colour tokens don't apply. Mirrors _MuteToggleButton in
// lib/common/widgets/item_new_bottom_sheet.dart, which sets the same precedent.
const double _kControlButtonSize = 36;
const double _kControlIconSize = 20;
// Idle: a passive hairline. Revealed: the bar keeps its own height but gains
// vertical padding, and VideoScrubber hit-tests that whole padded box — so the
// padding is what makes it draggable with a finger rather than a stylus.
const double _kProgressBarHeight = 3;
const double _kScrubberTouchPadding = 10;
// Matches ChewieController.defaultHideControlsTimer, so the dwell time feels
// unchanged from the controls this replaced.
const Duration _kControlsHideDelay = Duration(seconds: 3);
const Duration _kControlsFadeDuration = Duration(milliseconds: 200);
const double _kUnmutedVolume = 1;

// Not const: withValues() isn't a const expression. Shared by both the idle
// hairline and the revealed scrubber so they read as the same control.
final VideoProgressColors _kProgressColors = VideoProgressColors(
  playedColor: Colors.white,
  bufferedColor: Colors.white.withValues(alpha: 0.35),
  backgroundColor: Colors.white.withValues(alpha: 0.18),
);

/// Autoplaying, muted advertisement video.
///
/// Renders a clean frame carrying nothing but a thin progress hairline along the
/// bottom. A tap reveals play/pause in the centre, mute in the top corner, and
/// turns the hairline into a draggable scrubber; all of it fades out again after
/// 3s. This replaces Chewie's default Material controls, which put a full control
/// bar, a centre play button, a seek cluster, an options sheet and a `black54`
/// scrim over the ad the moment it started playing.
///
/// Geometry matches what Chewie rendered: `Center` → `AspectRatio` → `VideoPlayer`
/// on black, i.e. the video letterboxes/pillarboxes rather than filling. Do not
/// switch this to `FittedBox(fit: BoxFit.cover)` — that crops to fill and changes
/// the look of every ad card.
///
/// When the clip finishes, this signals [AdvertisementController] to resume the
/// carousel's auto-advance (the carousel pauses itself while a video slide is up).
class AdVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final double aspectRatioMultiplier;

  const AdVideoPlayerWidget({super.key, required this.videoUrl, this.aspectRatioMultiplier = 1});

  @override
  State<AdVideoPlayerWidget> createState() => _AdVideoPlayerWidgetState();
}

class _AdVideoPlayerWidgetState extends State<AdVideoPlayerWidget> {
  VideoPlayerController? _controller;
  Timer? _hideControlsTimer;
  bool _initialized = false;
  bool _hasError = false;
  bool _muted = true;
  bool _controlsVisible = false;
  bool _completionReported = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final VideoPlayerController controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    // Assigned before the first await so dispose() can always find and release it,
    // even if the carousel advances mid-initialize.
    _controller = controller;
    controller.addListener(_onVideoTick);
    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(0); // ads start muted
      await controller.play();
      _initialized = true;
    } catch (_) {
      // A dead video URL used to throw an unhandled async error, spin the loader
      // forever and strand the carousel on this slide. Fail visibly and hand the
      // carousel back instead.
      _hasError = true;
      _completionReported = true;
      _resumeCarouselAutoPlay();
    }
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant AdVideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The carousel builds its children positionally, so a refreshed advertisement
    // list reuses this State with a new URL. Without this the previous ad's video
    // keeps playing.
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposePlayer();
      _hideControlsTimer?.cancel();
      _initialized = false;
      _hasError = false;
      _muted = true;
      _controlsVisible = false;
      _completionReported = false;
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _disposePlayer();
    super.dispose();
  }

  void _disposePlayer() {
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    _controller = null;
  }

  void _onVideoTick() {
    final VideoPlayerController? controller = _controller;
    if (controller == null || _completionReported) return;

    final VideoPlayerValue value = controller.value;
    final bool reachedEnd = value.isCompleted
        || (value.duration > Duration.zero && value.position >= value.duration);
    if (!reachedEnd) return;

    // Fire-once: this listener runs on every value change, so without the guard it
    // re-signalled on each tick while parked at the end, rebuilding the whole
    // carousel every time.
    _completionReported = true;
    _resumeCarouselAutoPlay();
  }

  void _resumeCarouselAutoPlay() {
    if (GetPlatform.isWeb) {
      // Deliberately not cancelled on dispose: if this card is torn down inside the
      // delay, the resume still has to land or the carousel stalls for good. It only
      // touches controller state, so firing after dispose is harmless.
      Future.delayed(const Duration(seconds: 4), () {
        Get.find<AdvertisementController>().updateAutoPlayStatus(status: true, shouldUpdate: true);
      });
    } else {
      Get.find<AdvertisementController>().updateAutoPlayStatus(status: true, shouldUpdate: true);
    }
  }

  void _handleTap() {
    if (_controlsVisible) {
      _hideControlsTimer?.cancel();
      setState(() => _controlsVisible = false);
    } else {
      setState(() => _controlsVisible = true);
      _restartHideTimer();
    }
  }

  void _restartHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(_kControlsHideDelay, () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _togglePlayPause() {
    final VideoPlayerController? controller = _controller;
    if (controller == null) return;
    controller.value.isPlaying ? controller.pause() : controller.play();
    // Pressing a button keeps the chrome up rather than dismissing it, so pause and
    // unmute can be tapped back to back.
    _restartHideTimer();
  }

  void _toggleMute() {
    final VideoPlayerController? controller = _controller;
    if (controller == null) return;
    setState(() => _muted = !_muted);
    controller.setVolume(_muted ? 0 : _kUnmutedVolume);
    _restartHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? controller = _controller;

    if (_hasError) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 28)),
      );
    }
    if (controller == null || !_initialized) {
      return const ColoredBox(color: Colors.black, child: Center(child: CircularProgressIndicator()));
    }

    return GestureDetector(
      // Opaque, not the deferToChild default: the pillarbox bars are bare colour, and
      // letting taps there fall through would open the store from the black margins
      // while the video itself reveals controls.
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Stack(fit: StackFit.expand, children: [

        const ColoredBox(color: Colors.black),

        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio * widget.aspectRatioMultiplier,
            child: VideoPlayer(controller),
          ),
        ),

        // Scoped to the player's own value, so per-frame position updates don't
        // rebuild the surrounding ad card.
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (BuildContext context, VideoPlayerValue value, Widget? child) {
            return Stack(fit: StackFit.expand, children: [

              if (value.isBuffering) const Center(
                child: SizedBox(
                  height: _kControlIconSize, width: _kControlIconSize,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),

              IgnorePointer(
                ignoring: !_controlsVisible,
                child: AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: _kControlsFadeDuration,
                  child: Stack(fit: StackFit.expand, children: [

                    Center(
                      child: _AdVideoControlButton(
                        icon: value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        onTap: _togglePlayPause,
                      ),
                    ),

                    // Directional so it lands top-left under RTL locales.
                    PositionedDirectional(
                      top: Dimensions.paddingSizeSmall, end: Dimensions.paddingSizeSmall,
                      child: _AdVideoControlButton(
                        icon: _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        onTap: _toggleMute,
                      ),
                    ),

                  ]),
                ),
              ),

            ]);
          },
        ),

        // Idle it's a passive hairline: allowScrubbing: false renders a bare Padding
        // with no gesture wrapper, so it can't steal the tap and the carousel stays
        // swipeable across the full frame. Once revealed it becomes a real scrubber,
        // whose horizontal-drag recognizer deliberately outranks the carousel's for
        // pointers that start on the bar.
        PositionedDirectional(
          start: 0, end: 0, bottom: 0,
          // Grow/shrink over the same duration the buttons fade, so the bar doesn't
          // snap between its two heights while everything else animates.
          child: AnimatedSize(
            duration: _kControlsFadeDuration,
            alignment: Alignment.bottomCenter,
            child: _controlsVisible
              ? Listener(
                  // Listener sits outside the gesture arena, so this can hold the
                  // controls open for the length of a drag without competing with
                  // the scrubber's own recognizers.
                  onPointerDown: (_) => _hideControlsTimer?.cancel(),
                  onPointerUp: (_) => _restartHideTimer(),
                  onPointerCancel: (_) => _restartHideTimer(),
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(vertical: _kScrubberTouchPadding),
                    colors: _kProgressColors,
                  ),
                )
              : IgnorePointer(
                  child: SizedBox(
                    height: _kProgressBarHeight,
                    child: VideoProgressIndicator(
                      controller,
                      allowScrubbing: false,
                      padding: EdgeInsets.zero,
                      colors: _kProgressColors,
                    ),
                  ),
                ),
          ),
        ),

      ]),
    );
  }
}

/// Circular control button painted over the video. Same visual language as
/// `_MuteToggleButton` in lib/common/widgets/item_new_bottom_sheet.dart.
class _AdVideoControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AdVideoControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: _kControlButtonSize, width: _kControlButtonSize,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Icon(icon, color: Colors.white, size: _kControlIconSize),
        ),
      ),
    );
  }
}
