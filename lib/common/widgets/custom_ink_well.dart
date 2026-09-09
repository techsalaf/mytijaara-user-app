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
  static const Duration _pressDuration = Duration(milliseconds: 200);
  static const Duration _releaseDuration = Duration(milliseconds: 320);
  static const Duration _tapDelay = Duration(milliseconds: 120);

  late final AnimationController _controller;
  late final Animation<double> _scale;

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
          onTap: enabled ? () => Future.delayed(_tapDelay, () => widget.onTap!()) : null,
          onHighlightChanged: enabled
              ? (pressed) => pressed ? _controller.forward() : _controller.reverse()
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
      onTapUp: enabled ? (_) => _controller.reverse() : null,
      onTapCancel: enabled ? () => _controller.reverse() : null,
      onTap: enabled ? () => Future.delayed(_tapDelay, () => widget.onTap!()) : null,
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
