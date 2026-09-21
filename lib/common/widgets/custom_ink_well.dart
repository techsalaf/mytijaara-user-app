import 'package:flutter/material.dart';

class CustomInkWell extends StatefulWidget {
  final double? radius;
  final Widget child;
  final Function? onTap;
  final Color? highlightColor;
  final EdgeInsetsGeometry? padding;
  final bool enableRippleEffect;
  final Color? splashColor;
  const CustomInkWell({super.key,
    this.radius, required this.child, required this.onTap, this.highlightColor, this.padding = const EdgeInsets.all(0),
    this.enableRippleEffect = false, this.splashColor,
  });

  @override
  State<CustomInkWell> createState() => _CustomInkWellState();
}

class _CustomInkWellState extends State<CustomInkWell> with SingleTickerProviderStateMixin {
  static const double _pressedScale = 0.93;
  static const Duration _pressDuration = Duration(milliseconds: 80);
  static const Duration _releaseDuration = Duration(milliseconds: 140);

  late final AnimationController _controller;
  late final Animation<double> _scale;

  // Runs the full press-down/release-back animation to completion before
  // invoking onTap, so a quick tap shows the same visible feedback as a
  // press-and-hold instead of getting cut short by an immediate reverse.
  Future<void> _animateThenInvoke() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onTap!();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _pressDuration,
      reverseDuration: _releaseDuration,
    );
    _scale = Tween<double>(begin: 1.0, end: _pressedScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null;

    if (widget.enableRippleEffect) {
      final BorderRadius? borderRadius = widget.radius != null ? BorderRadius.circular(widget.radius!) : null;

      return Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: enabled ? _animateThenInvoke : null,
          onHighlightChanged: enabled
              ? (pressed) => pressed ? _controller.forward() : null
              : null,
          borderRadius: borderRadius,
          highlightColor: widget.highlightColor,
          splashColor: widget.splashColor,
          child: ScaleTransition(
            scale: _scale,
            child: Padding(
              padding: widget.padding!,
              child: widget.child,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _controller.forward() : null,
      onTapCancel: enabled ? () => _controller.reverse() : null,
      onTap: enabled ? _animateThenInvoke : null,
      child: ScaleTransition(
        scale: _scale,
        child: Padding(
          padding: widget.padding!,
          child: widget.child,
        ),
      ),
    );
  }
}
