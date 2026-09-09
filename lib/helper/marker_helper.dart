import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerHelper{

  static Future<BitmapDescriptor> convertAssetToBitmapDescriptor({
    required final String imagePath,
    final int? width,
    final int? height,
  }) async {
    try {
      if(GetPlatform.isWeb) {
        //return BitmapDescriptor.fromAssetImage(const ImageConfiguration(devicePixelRatio: 2.5, size: Size(50, 50), ), imagePath);
        return BitmapDescriptor.asset(const ImageConfiguration(devicePixelRatio: 2.5, size: Size(50, 50), ), imagePath);
      }
      final ByteData byteDataFromImage = await rootBundle.load(imagePath).timeout(const Duration(seconds: 8));
      final ui.Codec codec = await ui
          .instantiateImageCodec(byteDataFromImage.buffer.asUint8List(), targetHeight: height, targetWidth: width)
          .timeout(const Duration(seconds: 8));
      final ui.FrameInfo frameInfo = await codec.getNextFrame().timeout(const Duration(seconds: 8));
      final ByteData? byteDataFromFrame =
      await frameInfo.image.toByteData(format: ui.ImageByteFormat.png).timeout(const Duration(seconds: 8));
      if (byteDataFromFrame != null) {
        final Uint8List uint8List = byteDataFromFrame.buffer.asUint8List();
        //return BitmapDescriptor.fromBytes(uint8List);
        return BitmapDescriptor.bytes(uint8List);
      } else {
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      }
    } catch(_) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  static Future<BitmapDescriptor> createLabeledMarker({
    required String label,
    required String imagePath,
    int iconSize = 44,
  }) async {
    try {
      if (GetPlatform.isWeb) {
        return await convertAssetToBitmapDescriptor(imagePath: imagePath, width: iconSize);
      }

      final ByteData iconData = await rootBundle.load(imagePath).timeout(const Duration(seconds: 8));
      final ui.Codec iconCodec = await ui.instantiateImageCodec(
        iconData.buffer.asUint8List(), targetWidth: iconSize, targetHeight: iconSize,
      ).timeout(const Duration(seconds: 8));
      final ui.Image iconImage = (await iconCodec.getNextFrame().timeout(const Duration(seconds: 8))).image;

      final ui.ParagraphBuilder pb = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 11, fontWeight: FontWeight.w700))
        ..pushStyle(ui.TextStyle(color: const Color(0xFFFFFFFF), fontSize: 11, fontWeight: FontWeight.w700))
        ..addText(label);
      final ui.Paragraph paragraph = pb.build()..layout(const ui.ParagraphConstraints(width: 120));

      const double hPad = 8;
      const double vPad = 5;
      const double arrowH = 8;
      final double labelW = paragraph.maxIntrinsicWidth + hPad * 2;
      final double labelH = paragraph.height + vPad * 2;
      final double totalW = math.max(labelW, iconSize.toDouble());
      final double totalH = labelH + arrowH + iconSize;
      // Icon is centered horizontally so default anchor (0.5, 1.0) pins correctly.
      final double iconX = (totalW - iconSize) / 2;
      final double arrowTipX = iconX + iconSize / 2;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Label bubble — top-left
      final Paint bubblePaint = Paint()..color = const Color(0xFF1C1C2E);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, labelW, labelH), const Radius.circular(5)),
        bubblePaint,
      );
      // Downward-pointing arrow from label bottom to icon top-center
      canvas.drawPath(
        Path()
          ..moveTo(math.max(0.0, arrowTipX - 6), labelH)
          ..lineTo(math.min(labelW, arrowTipX + 6), labelH)
          ..lineTo(arrowTipX, labelH + arrowH)
          ..close(),
        bubblePaint,
      );
      canvas.drawParagraph(paragraph, Offset(hPad, vPad));
      // Icon centered at the bottom (map anchor = bottom-center of icon = default (0.5, 1.0))
      canvas.drawImage(iconImage, Offset(iconX, labelH + arrowH), Paint());

      final ui.Image img = await recorder.endRecording().toImage(totalW.ceil(), totalH.ceil());
      final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    } catch (_) {
      return convertAssetToBitmapDescriptor(imagePath: imagePath, width: iconSize);
    }
  }
}