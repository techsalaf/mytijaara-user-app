import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';

class IosEdgeSwipeBackDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onBack;
  final bool enabled;

  const IosEdgeSwipeBackDetector({super.key, required this.child, required this.onBack, this.enabled = true});

  static const double edgeWidth = 20;
  static const double triggerDistance = 80;
  static const double flingVelocity = 700;

  @override
  State<IosEdgeSwipeBackDetector> createState() => _IosEdgeSwipeBackDetectorState();
}

class _IosEdgeSwipeBackDetectorState extends State<IosEdgeSwipeBackDetector> with SingleTickerProviderStateMixin {
  late final HorizontalDragGestureRecognizer _recognizer;
  late final AnimationController _progress;
  final ValueNotifier<double> _pointerY = ValueNotifier(0);
  double _dragExtent = 0;
  bool _pointerCancelled = false;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recognizer.gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
  }

  @override
  void dispose() {
    _recognizer.dispose();
    _progress.dispose();
    _pointerY.dispose();
    super.dispose();
  }

  bool get _isRtl => Directionality.of(context) == TextDirection.rtl;
  double _toLogical(double value) => _isRtl ? -value : value;

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.enabled) {
      _pointerCancelled = false;
      _recognizer.addPointer(event);
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) => _pointerCancelled = true;

  void _handleDragStart(DragStartDetails details) {
    _dragExtent = 0;
    _progress.stop();
    _updatePointerY(details.globalPosition);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragExtent = math.max(0, _dragExtent + _toLogical(details.primaryDelta ?? details.delta.dx));
    _updatePointerY(details.globalPosition);
    _progress.value = (_dragExtent / IosEdgeSwipeBackDetector.triggerDistance).clamp(0.0, 1.0);
  }

  void _handleDragEnd(DragEndDetails details) {
    final double velocity = _toLogical(details.primaryVelocity ?? details.velocity.pixelsPerSecond.dx);
    final bool shouldGoBack = velocity.abs() >= IosEdgeSwipeBackDetector.flingVelocity
        ? velocity > 0
        : _dragExtent >= IosEdgeSwipeBackDetector.triggerDistance;
    _resetDrag();
    if (shouldGoBack && widget.enabled && !_pointerCancelled) {
      widget.onBack();
    }
  }

  void _handleDragCancel() => _resetDrag();

  void _resetDrag() {
    _dragExtent = 0;
    _progress.reverse();
  }

  void _updatePointerY(Offset globalPosition) {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      _pointerY.value = renderObject.globalToLocal(globalPosition).dy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = MediaQuery.paddingOf(context);

    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,

        Positioned.fill(
          child: IgnorePointer(
            child: _SwipeBackIndicator(progress: _progress, pointerY: _pointerY, topInset: padding.top, bottomInset: padding.bottom),
          ),
        ),

        if (widget.enabled)
          PositionedDirectional(
            start: 0, top: 0, bottom: 0, width: IosEdgeSwipeBackDetector.edgeWidth,
            child: Listener(onPointerDown: _handlePointerDown, onPointerCancel: _handlePointerCancel, behavior: HitTestBehavior.translucent),
          ),
      ],
    );
  }
}

class _SwipeBackIndicator extends StatelessWidget {
  final Animation<double> progress;
  final ValueListenable<double> pointerY;
  final double topInset;
  final double bottomInset;

  const _SwipeBackIndicator({required this.progress, required this.pointerY, required this.topInset, required this.bottomInset});

  static const double _size = 40;
  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return AnimatedBuilder(
        animation: Listenable.merge([progress, pointerY]),
        builder: (context, _) {
          final double value = progress.value;
          if (value == 0) {
            return const SizedBox.shrink();
          }

          final bool isArmed = value >= 1;
          final double start = lerpDouble(-_size, Dimensions.paddingSizeSmall, Curves.easeOut.transform(value))!;
          final double maxTop = math.max(topInset, constraints.maxHeight - bottomInset - _size);
          final double top = (pointerY.value - _size / 2).clamp(topInset, maxTop);

          return Stack(
            children: [
              PositionedDirectional(
                start: start, top: top, width: _size, height: _size,
                child: Opacity(
                  opacity: value,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                        color: Theme.of(context).shadowColor.withValues(alpha: 0.15),
                        blurRadius: 8, offset: const Offset(0, 2),
                      )],
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded, size: _iconSize,
                      color: isArmed ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }
}