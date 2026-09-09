import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/route_helper.dart';

class AiChatBotFloatingButtonWidget extends StatefulWidget {
  final String? heroTag;
  const AiChatBotFloatingButtonWidget({super.key, this.heroTag});

  @override
  State<AiChatBotFloatingButtonWidget> createState() => _AiChatBotFloatingButtonWidgetState();
}

class _AiChatBotFloatingButtonWidgetState extends State<AiChatBotFloatingButtonWidget>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pressController;
  late final AnimationController _sparkleController;

  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceFade;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _entranceScale = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pressController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    Get.toNamed(RouteHelper.getAiChatBotScreen());
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    const Color accent = Color(0xFF8E5BFF);

    return Tooltip(
      message: 'ai_chat_bot'.tr,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _pressController.forward(),
        onTapCancel: () => _pressController.reverse(),
        onTapUp: (_) {
          _pressController.reverse();
          _handleTap();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_entranceController, _pressController]),
          builder: (context, child) {
            return Opacity(
              opacity: _entranceFade.value,
              child: Transform.scale(
                scale: _entranceScale.value * _pressScale.value,
                child: child,
              ),
            );
          },
          child: Hero(
            tag: widget.heroTag ?? 'ai_chat_bot_fab',
            child: SizedBox(
              height: 66, width: 66,
              child: Center(
                child: _CoreButton(
                  primary: primary,
                  accent: accent,
                  child: _AnimatedSparkles(animation: _sparkleController, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoreButton extends StatelessWidget {
  final Color primary;
  final Color accent;
  final Widget child;
  const _CoreButton({required this.primary, required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46, width: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, accent],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

// CustomPaint sparkles that mirror the `auto_awesome` look: a main 4-point star
// plus two smaller ones, each twinkling (scale), rotating, and pulsing its glow.
class _AnimatedSparkles extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  const _AnimatedSparkles({required this.animation, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28, width: 28,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => CustomPaint(painter: _SparklePainter(t: animation.value, color: color)),
      ),
    );
  }
}

class _Sparkle {
  final Offset pos; // relative center (0..1)
  final double radius; // fraction of the paint width
  final double phase; // animation offset so stars twinkle out of sync
  const _Sparkle(this.pos, this.radius, this.phase);
}

class _SparklePainter extends CustomPainter {
  final double t;
  final Color color;
  _SparklePainter({required this.t, required this.color});

  static const List<_Sparkle> _sparkles = [
    _Sparkle(Offset(0.50, 0.52), 0.30, 0.0),
    _Sparkle(Offset(0.80, 0.22), 0.13, 0.35),
    _Sparkle(Offset(0.24, 0.78), 0.10, 0.70),
  ];

  // A concave 4-point sparkle centred on the origin.
  Path _sparklePath(double r) {
    final double inner = r * 0.18;
    return Path()
      ..moveTo(0, -r)
      ..quadraticBezierTo(inner, -inner, r, 0)
      ..quadraticBezierTo(inner, inner, 0, r)
      ..quadraticBezierTo(-inner, inner, -r, 0)
      ..quadraticBezierTo(-inner, -inner, 0, -r)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill..isAntiAlias = true;
    for (final _Sparkle s in _sparkles) {
      final double phase = (t + s.phase) % 1.0;
      final double wave = (math.sin(phase * 2 * math.pi) + 1) / 2; // 0..1
      final double scale = 0.65 + 0.6 * wave;
      final double angle = phase * 2 * math.pi;
      final double radius = s.radius * size.width * scale;
      paint.color = color.withValues(alpha: 0.55 + 0.45 * wave);
      canvas.save();
      canvas.translate(s.pos.dx * size.width, s.pos.dy * size.height);
      canvas.rotate(angle);
      canvas.drawPath(_sparklePath(radius), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => oldDelegate.t != t || oldDelegate.color != color;
}
