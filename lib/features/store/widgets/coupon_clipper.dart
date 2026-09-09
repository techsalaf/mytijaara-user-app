import 'package:flutter/material.dart';

class CouponClipper extends CustomClipper<Path> {
  final double borderRadius;
  final double notchRadius;

  CouponClipper({
    this.borderRadius = 12.0,
    this.notchRadius = 10.0,
  });

  @override
  Path getClip(Size size) {
    Path path = Path();
    
    // 1. Start at top-left after the corner radius
    path.moveTo(borderRadius, 0);
    
    // Top line to top-right corner
    path.lineTo(size.width - borderRadius, 0);
    
    // Top-right corner arc
    path.arcToPoint(
      Offset(size.width, borderRadius),
      radius: Radius.circular(borderRadius),
    );
    
    // 2. Right side line down to the notch
    path.lineTo(size.width, (size.height / 2) - notchRadius);
    
    // Right side inward notch (semi-circle)
    path.arcToPoint(
      Offset(size.width, (size.height / 2) + notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false, // false makes it curve INWARD
    );
    
    // Right side line to bottom-right corner
    path.lineTo(size.width, size.height - borderRadius);
    
    // Bottom-right corner arc
    path.arcToPoint(
      Offset(size.width - borderRadius, size.height),
      radius: Radius.circular(borderRadius),
    );
    
    // 3. Bottom line to bottom-left corner
    path.lineTo(borderRadius, size.height);
    
    // Bottom-left corner arc
    path.arcToPoint(
      Offset(0, size.height - borderRadius),
      radius: Radius.circular(borderRadius),
    );
    
    // 4. Left side line up to the notch
    path.lineTo(0, (size.height / 2) + notchRadius);
    
    // Left side inward notch (semi-circle)
    path.arcToPoint(
      Offset(0, (size.height / 2) - notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false, // false makes it curve INWARD
    );
    
    // Left side line up to top-left corner
    path.lineTo(0, borderRadius);
    
    // Top-left corner arc
    path.arcToPoint(
      Offset(borderRadius, 0),
      radius: Radius.circular(borderRadius),
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}