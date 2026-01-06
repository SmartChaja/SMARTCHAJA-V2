// QrScannerOverlayShape class remains unchanged
import 'package:flutter/material.dart';

class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.6),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path()..addRect(rect);
    final Rect cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );
    path = Path.combine(
        PathOperation.difference, path, Path()..addRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius))));
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final Paint paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(getOuterPath(rect), paint);

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    final Rect cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );
    final double halfBorderWidth = borderWidth / 2;
    final RRect rrect = RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius));

    canvas.drawPath(
        Path()
          ..moveTo(rrect.left - halfBorderWidth, rrect.top + borderLength)
          ..lineTo(rrect.left - halfBorderWidth, rrect.top - halfBorderWidth)
          ..lineTo(rrect.left + borderLength, rrect.top - halfBorderWidth),
        borderPaint);
    canvas.drawPath(
        Path()
          ..moveTo(rrect.right - borderLength, rrect.top - halfBorderWidth)
          ..lineTo(rrect.right + halfBorderWidth, rrect.top - halfBorderWidth)
          ..lineTo(rrect.right + halfBorderWidth, rrect.top + borderLength),
        borderPaint);
    canvas.drawPath(
        Path()
          ..moveTo(rrect.left - halfBorderWidth, rrect.bottom - borderLength)
          ..lineTo(rrect.left - halfBorderWidth, rrect.bottom + halfBorderWidth)
          ..lineTo(rrect.left + borderLength, rrect.bottom + halfBorderWidth),
        borderPaint);
    canvas.drawPath(
        Path()
          ..moveTo(rrect.right - borderLength, rrect.bottom + halfBorderWidth)
          ..lineTo(rrect.right + halfBorderWidth, rrect.bottom + halfBorderWidth)
          ..lineTo(rrect.right + halfBorderWidth, rrect.bottom - borderLength),
        borderPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}